//
//  ViewController.swift
//  srsly
//
//  Created by aang on 1/25/23.
//

import UIKit
import WebKit
import BigInt
import SwiftyJSON
import CryptoSwift
//import BLS12381

let SEQUENCER_URL = "http://bore.pub:45312"

let q_ = BInt("1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAAAB", radix: 16)!
let r_ = BInt("73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001", radix: 16)!

public class EC{
    var q: BInt
    var a: Fq
    var b: Fq

    init() {
        self.q = q_
        self.a = Fq(q: q_, value: BInt(0))
        self.b = Fq(q: q_, value: BInt(4))
    }
}

public class EC2 {
    var q: BInt
    var a: Fq2
    var b: Fq2

    init() {
        self.q = q_
        self.a = Fq2(q: q_, a: BInt(0), b: BInt(0))
        self.b = Fq2(q: q_, a: BInt(4), b: BInt(4))
    }

}

public class Fq2 {
    var q: BInt
    var a: BInt
    var b: BInt

    init(q: BInt, a: BInt, b: BInt) {
        self.q = q
        
        
        self.a = a.mod(q)
        self.b = b.mod(q)
    }

    static func +(lhs: Fq2, rhs: Fq2) -> Fq2 {
        let new_a = (lhs.a + rhs.a).mod(lhs.q)
        let new_b = (lhs.b + rhs.b).mod(lhs.q)
        return Fq2(q: lhs.q, a: new_a, b: new_b)
    }

    static func -(lhs: Fq2, rhs: Fq2) -> Fq2 {
        return ((lhs + Fq2(q: lhs.q, a: BInt(-1)*rhs.a, b: BInt(-1)*rhs.b)))
    }

    static func *(lhs: Fq2, rhs: Fq2) -> Fq2 {
        let new_a = (lhs.a * rhs.a - lhs.b * rhs.b)
        let new_b = (lhs.a * rhs.b + lhs.b * rhs.a)
        return Fq2(q: lhs.q, a: new_a, b: new_b)
    }

    func inverse() -> Fq2 {
        let afq = Fq(q: self.q, value: self.a)
        let bfq = Fq(q: self.q, value: self.b)
        let factor = afq*afq + bfq*bfq
        let new_a = afq/factor
        let bnu = Fq(q: self.q, value: BInt(-1)*self.b)
        let new_b = bnu/factor
        return Fq2(q: self.q, a: new_a.value, b: new_b.value)
    }

    static func /(lhs: Fq2, rhs: Fq2) -> Fq2 {
        return lhs*rhs.inverse()
    }
    
    static func ==(lhs: Fq2, rhs: Fq2) -> Bool {
        return ((lhs.a == rhs.a) && (lhs.b == rhs.b))
    }

    func one() -> Fq2 {
        return Fq2(q: self.q, a: BInt(1), b: BInt(0))
    }

    func zero() -> Fq2 {
        return Fq2(q: self.q, a: BInt(0), b: BInt(0))
    }

    func modsqrt() -> Fq2 {
        let a0 = Fq(q: self.q, value: self.a)
        let a1 = Fq(q: self.q, value: self.b)
        if a1.value == 0 {
            return Fq2(q: self.q, a: a0.modsqrt().value, b: BInt(0))
        }
        var alpha = Fq(q: self.q, value: a0.value.expMod(BInt(2), self.q) + a1.value.expMod(BInt(2), self.q))
        
        var gamma = alpha.value.jacobiSymbol(self.q)
        if gamma == BInt(-1) {
            return Fq2(q: self.q, a: BInt(0), b: BInt(0))
        }
        
        alpha = alpha.modsqrt()
        var delta = (a0 + alpha)/Fq(q: self.q, value: BInt(2))
        
        gamma = delta.value.jacobiSymbol(self.q)
        
        if gamma == BInt(-1) {
            delta = (a0 - alpha)/Fq(q: self.q, value: BInt(2))
        }
        
        let x0 = delta.modsqrt()
        let x1 = a1/(Fq(q: self.q, value: BInt(2)) * x0)
        return Fq2(q: self.q, a: x0.value, b: x1.value)
    }
    
    func exp(k : BInt) -> Fq2{
        var z = Fq2(q: self.q, a: self.a, b: self.b)
        var x = Fq2(q: self.q, a: self.a, b: self.b)

        if(k == BInt(0)){
            return z.one()
        }
        var e = k
        if(k.isNegative){
            x = x.inverse()
            e.negate()
        }
        z = z.one()
        var b = e.asMagnitudeBytes()
        for i in stride(from: 0, to: b.count, by: 1){
            var w = b[i]
            for j in stride(from: 0, to: 8, by: 1){
                z = z * z
                if (w & (0b10000000 >> j)) != 0 {
                    z = z * x
                }
            }
        }
        return z
    }
    
    func modsqrt_two() -> Fq2 {
        var minusOneA0 = Fq(q: self.q, value: BInt(1)).neg()
        var minusOneA1 = Fq(q: self.q, value: BInt(0)).neg()
        var minusone = Fq2(q: self.q, a: minusOneA0.value, b: minusOneA1.value)
        
        var x = Fq2(q: self.q, a: self.a, b: self.b)
        var sqrtExp1 = (self.q - BInt(3)) >> 2
        var a1 = x.exp(k: sqrtExp1)
        var alpha = a1 * a1 * x
        var x0 = x * a1
        if(alpha.a == minusone.a && alpha.b == minusone.b) {
            var aout = Fq(q: self.q, value: x0.b).neg()
            return Fq2(q: self.q, a: aout.value, b: x0.a)
        }
        a1 = a1.one()
        var b = a1 + alpha
        var sqrtExp2 = (self.q - BInt(1)) >> 1
        b = x0 * b.exp(k: sqrtExp2)
        return b
    }
}

public class Fq {
    var q: BInt
    var value: BInt

    init(q: BInt, value: BInt) {
        self.q = q
        self.value = value.mod(q)
    }

    func inverse() -> Fq {
        return Fq(q: self.q, value: self.value.modInverse(q))
    }

    static func /(lhs: Fq, rhs: Fq) -> Fq {
        return lhs*rhs.inverse()
    }

    func neg() -> Fq {
        return Fq(q: self.q, value: (BInt(-1) * self.value))
    }

    static func +(lhs: Fq, rhs: Fq) -> Fq {
        return Fq(q: lhs.q, value: (lhs.value + rhs.value))
    }

    static func -(lhs: Fq, rhs: Fq) -> Fq {
        return Fq(q: lhs.q, value: (lhs.value - rhs.value))
    }

    static func *(lhs: Fq, rhs: Fq) -> Fq {
        return Fq(q: lhs.q, value: (lhs.value * rhs.value))
    }
    
    static func **(lhs: Fq, rhs: Int) -> Fq {
        return Fq(q: lhs.q, value: (lhs.value ** rhs))
    }
    
    static func ==(lhs: Fq, rhs: Fq) -> Bool {
        return (lhs.value == rhs.value)
    }

    func one() -> Fq {
        return Fq(q: self.q, value: BInt(1))
    }

    func zero() -> Fq {
        return Fq(q: self.q, value: BInt(0))
    }

    func modsqrt() -> Fq {
        let val = self.value.sqrtMod(q_)!
        let otherval = (q_ - val).mod(q_)
        return Fq(q: self.q, value: max(val, otherval))
    }
    
    func exp(k : BInt) -> Fq{
        var z = Fq(q: self.q, value: self.value)
        var x = Fq(q: self.q, value: self.value)
        if(k == BInt(0)){
            return z.one()
        }
        var e = k
        if(k.isNegative){
            x = x.inverse()
            e.negate()
        }
        z = x
        for i in stride(from: e.bitWidth - 2, through: 0, by: -1){
            z = z * z
            if(e.testBit(i)){
                z = z * x
            }
        }
        return z
    }
    
    // expBySqrtExp is equivalent to z.Exp(x, 680447a8e5ff9a692c6e9ed90d2eb35d91dd2e13ce144afd9cc34a83dac3d8907aaffffac54ffffee7fbfffffffeaab)
    func modsqrt_two() -> Fq {
        return self.exp(k: (self.q+1)/4)
    }

}

public class AffinePointFq {
    var x: Fq
    var y: Fq
    var ifty: Bool
    var ec: EC

    init(x: Fq, y: Fq, ifty: Bool) {
        self.x = x
        self.y = y
        self.ifty = ifty
        self.ec = EC()
    }

    func is_on_curve() -> Bool {
        let left = self.y*self.y
        let right = self.x*self.x*self.x + self.ec.a*self.x + self.ec.b
        return (left == right)
    }

    func to_jacobian() -> JacobianPointFq {
        return JacobianPointFq(
            x: self.x, y: self.y, z: Fq(q: self.x.q, value: BInt(1)), ifty: self.ifty
        )
    }
}

public class AffinePointFq2 {
    var x: Fq2
    var y: Fq2
    var ifty: Bool
    var ec: EC2

    init(x: Fq2, y: Fq2, ifty: Bool) {
        self.x = x
        self.y = y
        self.ifty = ifty
        self.ec = EC2()
    }

    func is_on_curve() -> Bool {
        let left = self.y*self.y
        let right = self.x*self.x*self.x + self.ec.a*self.x + self.ec.b
        return (left == right)
    }

    func to_jacobian() -> JacobianPointFq2 {
        return JacobianPointFq2(
            x: self.x, y: self.y, z: Fq2(q: self.x.q, a: BInt(1), b: BInt(0)), ifty: self.ifty
        )
    }
}

class Lattice {
    var r: BInt
    var lambda: BInt
    var v1_0 : BInt
    var v1_1 : BInt
    var v2_0 : BInt
    var v2_1 : BInt
    var det : BInt
    var b1 : BInt
    var b2 : BInt

    init(r : BInt, lambda : BInt) {
        // precompute the lattice for GLV
        self.r = r
        self.lambda = lambda
        
        var _r = self.r
        let _lambda = self.lambda
        var rst = [[BInt]]()
        rst.append([BInt]())
        rst[0].append(_r)
        rst[0].append(BInt(1))
        rst[0].append(BInt(0))
        
        rst.append([BInt]())
        rst[1].append(_lambda)
        rst[1].append(BInt(0))
        rst[1].append(BInt(1))
        
        var tmp = [BInt]()
        tmp.append(BInt(0))
        tmp.append(BInt(0))
        tmp.append(BInt(0))
        
        let sqrt = _r.sqrt()
        
        var quotient = BInt(1)
        var remainder = BInt(0)
        
        while (rst[1][0] > sqrt) {
            quotient = rst[0][0]/rst[1][0]
            remainder = rst[0][0].mod(rst[1][0])
            
            tmp[0] = rst[1][0]
            tmp[1] = rst[1][1]
            tmp[2] = rst[1][2]
            
            rst[1][0] = remainder
            rst[1][1] = rst[1][1]*quotient
            rst[1][1] = rst[0][1] - rst[1][1]
            rst[1][2] = rst[1][2]*quotient
            rst[1][2] = rst[0][2] - rst[1][2]
            
            rst[0][0] = tmp[0]
            rst[0][1] = tmp[1]
            rst[0][2] = tmp[2]
        }

        quotient = rst[0][0]/rst[1][0]
        remainder = rst[0][0].mod(rst[1][0])
        _r = remainder
        var _t = rst[1][2]*quotient
        _t = rst[0][2] - _t
        
        
        self.v1_0 = rst[1][0]
        self.v1_1 = BInt(-1)*rst[1][2]
        
        tmp[0] = rst[0][0] * rst[0][0]
        tmp[1] = rst[0][2]*rst[0][2]
        tmp[0] = tmp[1] + tmp[0]
        tmp[2] = _r*_r
        tmp[1] = _t*_t
        tmp[1] = tmp[1] + tmp[2]

        if (tmp[0] > tmp[1]) {
            self.v2_0 = _r
            self.v2_1 = BInt(-1)*_t
        }
        else {
            self.v2_0 = rst[0][0]
            self.v2_1 = BInt(-1)*rst[0][2]
        }

        //determinant
        tmp[0] = self.v1_1 * self.v2_0
        let det = self.v1_0 * self.v2_1 - tmp[0]
        self.det = det
        
        //roundings
        let n = 2 * (((det.bitWidth + 32) >> 6) << 6)
        self.b1 = self.v2_1 << n
        self.b1 = rounding(n: self.b1, d: det)
        self.b2 = self.v1_1 << n
        self.b2 = rounding(n: self.b2, d: det)
    }

    func getVector(a : BInt, b : BInt) -> [BInt] {
        var res = [BInt]()
        res.reserveCapacity(2)
        var tmp = b * self.v2_0
        res.append((a * self.v1_0) + tmp)
        tmp = b * self.v2_1
        res.append((a * self.v1_1) + tmp)
        return res
    }

    func SplitScalar(s : BInt) -> [BInt] {
        var k1 = s * self.b1
        var k2 = BInt(-1) * s * self.b2
        let n = 2 * ((self.det.bitWidth + 32) >> 6) << 6
        k1 = k1 >> n
        k2 = k2 >> n
        var v = getVector(a: k1, b: k2)
        v[0] = s - v[0]
        v[1] = BInt(-1) * v[1]
        return v
    }
}


public class JacobianPointFq {
    var x: Fq
    var y: Fq
    var z: Fq
    var ifty: Bool
    var ec: EC
    
    init(x: Fq, y: Fq, z: Fq, ifty: Bool) {
        self.x = x
        self.y = y
        self.z = z
        self.ifty = ifty
        self.ec = EC()
    }

    func to_affine() -> AffinePointFq {
        let x = self.x/(self.z * self.z)
        let y = self.y/(self.z * self.z * self.z)
        return AffinePointFq(x: x, y: y, ifty: self.ifty)
    }

    func double() -> JacobianPointFq {
        let X = self.x
        let Y = self.y
        let Z = self.z
        if ((Y.value == 0) || (self.ifty)) {
            return JacobianPointFq(x: Fq(q: self.x.q, value: BInt(1)), y: Fq(q: self.x.q, value: BInt(1)), z: Fq(q: self.x.q, value: BInt(0)), ifty: true)
        }
        
        let Zsquared = Z**2
        let Zfour = Zsquared**2
        let Ysquared = Y**2
        let Yfour = Ysquared**2
        let S = Fq(q: self.ec.q, value: BInt(4)) * X * Ysquared

        var M = Fq(q: self.ec.q, value: BInt(3)) * (X**2)
        M = M + self.ec.a * Zfour

        let Xprime = M * M - Fq(q: self.ec.q, value: BInt(2)) * S
        let Yprime = M * (S - Xprime) - Fq(q: self.ec.q, value: BInt(8)) * Yfour
        let Zprime = Fq(q: self.ec.q, value: BInt(2)) * Y * Z
        return JacobianPointFq(x: Xprime, y: Yprime, z: Zprime, ifty: false)

    }
    
    func add_two(p2: JacobianPointFq) -> JacobianPointFq {
        if (self.ifty) {
            return p2
        }
        if (p2.ifty) {
            return self
        }
        let Z1Z1 = p2.z * p2.z
        let Z2Z2 = self.z * self.z
        let U1 = p2.x * Z2Z2
        let U2 = self.x * Z1Z1
        var S1 = (p2.y * self.z) * Z2Z2
        let S2 = (self.y * p2.z) * Z1Z1
        
        if(U1 == U2 && S1 == S2){
            return self.double()
        }
        
        let H = U2 - U1
        var I = (H + H)
        I = I * I
        let J = H * I
        var r = (S2 - S1)
        r = r + r
        let V = U1 * I
        let Xout = (r * r) - J - V - V
        var Yout = (V - Xout) * r
        S1 = (S1 * J)
        S1 = S1 + S1
        Yout = Yout - S1
        var Zout = self.z + p2.z
        Zout = ((Zout * Zout) - Z1Z1 - Z2Z2) * H
        return JacobianPointFq(x: Xout, y: Yout, z: Zout, ifty: false)
    }
    
    func neg() -> JacobianPointFq {
        return JacobianPointFq(x: self.x, y: self.y.neg(), z: self.z, ifty: false)
    }
    
    func phi(a: JacobianPointFq) -> JacobianPointFq {
        let thirdRootG1 = Fq(q: self.x.q, value: BInt("4002409555221667392624310435006688643935503118305586438271171395842971157480381377015405980053539358417135540939436")!)
        return JacobianPointFq(x: a.x * thirdRootG1, y: a.y, z: a.z, ifty: false)
    }

    func phi_2(pt: JacobianPointFq2) -> JacobianPointFq2 {
        let thirdRootG1 = Fq(q: self.x.q, value: BInt("4002409555221667392624310435006688643935503118305586438271171395842971157480381377015405980053539358417135540939436")!)
        let thirdRootG2 = thirdRootG1 ** 2
        return JacobianPointFq2(x: Fq2(q: q_, a: pt.x.a * thirdRootG2.value, b: pt.x.b * thirdRootG2.value), y: pt.y, z: pt.z, ifty: false)
    }
    
    func scalar_mult_glv(s: BInt, glvBasis: Lattice) -> JacobianPointFq {
        var table = [JacobianPointFq]()
        table.reserveCapacity(15)

        var res = JacobianPointFq(x: Fq(q: self.x.q, value: BInt(1)), y: Fq(q: self.x.q, value: BInt(1)), z: Fq(q: self.x.q, value: BInt(0)), ifty: true)
        table.append(JacobianPointFq(x: self.x, y: self.y, z: self.z, ifty: self.ifty))
        table.append(table[0].double())
        table.append(table[1].add_two(p2: table[0]))
        table.append(phi(a: table[0]))
        var k = glvBasis.SplitScalar(s: s)
        if(k[0] < BInt(0)){
            k[0] = BInt(-1) * k[0]
            table[0] = table[0].neg()
        }
        if(k[1] < BInt(0)){
            k[1] = BInt(-1) * k[1]
            table[3] = table[3].neg()
        }

        table.append(table[3].add_two(p2: table[0]))
        table.append(table[3].add_two(p2: table[1]))
        table.append(table[3].add_two(p2: table[2]))
        table.append(table[3].double())
        table.append(table[7].add_two(p2: table[0]))
        table.append(table[7].add_two(p2: table[1]))
        table.append(table[7].add_two(p2: table[2]))
        table.append(table[7].add_two(p2: table[3]))
        table.append(table[11].add_two(p2: table[0]))
        table.append(table[11].add_two(p2: table[1]))
        table.append(table[11].add_two(p2: table[2]))

        let k1 = Fq(q: r_, value: k[0]).value.magnitude
        let k2 = Fq(q: r_, value: k[1]).value.magnitude

        var maxBit = k[0].bitWidth
        if k[1].bitWidth > maxBit {
            maxBit = k[1].bitWidth
        }
        let hiWordIndex = (maxBit - 1) / 64
        for i in stride(from: hiWordIndex, through: 0, by: -1){
            var mask : UInt64 = 0x3
            mask = mask << 62
            for j in stride(from: 0, to: 32, by: 1){
                res = res.double()
                res = res.double()
                let b1 = (k1[i] & mask) >> (62 - 2 * j)
                let b2 = (k2[i] & mask) >> (62 - 2 * j)
                if b1 | b2 != 0 {
                    let idx = Int((b2 << 2) | b1)
                    res = res.add_two(p2: table[idx - 1])
                }
                mask = mask >> 2
            }
        }
        
        return res
    }
}

public class JacobianPointFq2 {
    var x: Fq2
    var y: Fq2
    var z: Fq2
    var ifty: Bool
    var ec: EC2

    init(x: Fq2, y: Fq2, z: Fq2, ifty: Bool) {
        self.x = x
        self.y = y
        self.z = z
        self.ifty = ifty
        self.ec = EC2()
    }

    func to_affine() -> AffinePointFq2 {
        let x = self.x/(self.z * self.z)
        let y = self.y/(self.z * self.z * self.z)
        return AffinePointFq2(x: x, y: y, ifty: self.ifty)
    }

    func double() -> JacobianPointFq2 {
        let X = self.x
        let Y = self.y
        let Z = self.z
        if ((Y.a == 0 && Y.b == 0) || (self.ifty)) {
            return JacobianPointFq2(x: Fq2(q: self.x.q, a: BInt(1), b: BInt(0)), y: Fq2(q: self.y.q, a: BInt(1), b: BInt(0)), z: Fq2(q: self.z.q, a: BInt(0), b: BInt(0)), ifty: true)
        }
        let S = Fq2(q: self.ec.q, a: BInt(4), b: BInt(0)) * X * Y * Y
        let Zsquared = Z * Z
        let Zfour = Zsquared * Zsquared
        let Ysquared = Y * Y
        let Yfour = Ysquared * Ysquared

        var M = Fq2(q: self.ec.q, a: BInt(3), b: BInt(0)) * X * X
        M = M + self.ec.a * Zfour

        let Xprime = M * M - Fq2(q: self.ec.q, a: BInt(2), b: BInt(0)) * S
        let Yprime = M * (S - Xprime) - Fq2(q: self.ec.q, a: BInt(8), b: BInt(0)) * Yfour
        let Zprime = Fq2(q: self.ec.q, a: BInt(2), b: BInt(0)) * Y * Z
        return JacobianPointFq2(x: Xprime, y: Yprime, z: Zprime, ifty: false)

    }
    
    func add_two(p2: JacobianPointFq2) -> JacobianPointFq2 {
        if (self.ifty) {
            return p2
        }
        if (p2.ifty) {
            return self
        }
        let Z1Z1 = p2.z * p2.z
        let Z2Z2 = self.z * self.z
        let U1 = p2.x * Z2Z2
        let U2 = self.x * Z1Z1
        var S1 = (p2.y * self.z) * Z2Z2
        let S2 = (self.y * p2.z) * Z1Z1
        
        if(U1 == U2 && S1 == S2){
            return self.double()
        }
        
        let H = U2 - U1
        var I = (H + H)
        I = I * I
        let J = H * I
        var r = (S2 - S1)
        r = r + r
        let V = U1 * I
        let Xout = (r * r) - J - V - V
        var Yout = (V - Xout) * r
        S1 = (S1 * J)
        S1 = S1 + S1
        Yout = Yout - S1
        var Zout = self.z + p2.z
        Zout = ((Zout * Zout) - Z1Z1 - Z2Z2) * H
        return JacobianPointFq2(x: Xout, y: Yout, z: Zout, ifty: false)
    }

    func neg() -> JacobianPointFq2 {
        return JacobianPointFq2(x: self.x, y: Fq2(q: self.y.q, a: BInt(-1) * self.y.a, b: BInt(-1) * self.y.b), z: self.z, ifty: false)
    }
    
    func phi_2(pt: JacobianPointFq2) -> JacobianPointFq2 {
        let thirdRootG1 = Fq(q: self.x.q, value: BInt("4002409555221667392624310435006688643935503118305586438271171395842971157480381377015405980053539358417135540939436")!)
        let thirdRootG2 = thirdRootG1 ** 2
        return JacobianPointFq2(x: Fq2(q: q_, a: pt.x.a * thirdRootG2.value, b: pt.x.b * thirdRootG2.value), y: pt.y, z: pt.z, ifty: false)
    }
    
    func scalar_mult_glv(s: BInt, glvBasis: Lattice) -> JacobianPointFq2 {
        var table = [JacobianPointFq2]()
        table.reserveCapacity(15)
        var res = JacobianPointFq2(x: Fq2(q: self.x.q, a: BInt(1), b: BInt(0)), y: Fq2(q: self.y.q, a: BInt(1), b: BInt(0)), z: Fq2(q: self.z.q, a: BInt(0), b: BInt(0)), ifty: true)
        table.append(self)
        table.append(table[0].double())
        table.append(table[1].add_two(p2: table[0]))
        table.append(phi_2(pt: table[0]))
        var k = glvBasis.SplitScalar(s: s)
        if(k[0] < BInt(0)){
            k[0] = BInt(-1) * k[0]
            table[0] = table[0].neg()
        }
        if(k[1] < BInt(0)){
            k[1] = BInt(-1) * k[1]
            table[3] = table[3].neg()
        }
        table.append(table[3].add_two(p2: table[0]))
        table.append(table[3].add_two(p2: table[1]))
        table.append(table[3].add_two(p2: table[2]))
        table.append(table[3].double())
        table.append(table[7].add_two(p2: table[0]))
        table.append(table[7].add_two(p2: table[1]))
        table.append(table[7].add_two(p2: table[2]))
        table.append(table[7].add_two(p2: table[3]))
        table.append(table[11].add_two(p2: table[0]))
        table.append(table[11].add_two(p2: table[1]))
        table.append(table[11].add_two(p2: table[2]))
        let k1 = k[0].mod(r_).magnitude
        let k2 = k[1].mod(r_).magnitude
        var maxBit = k[0].bitWidth
        if k[1].bitWidth > maxBit {
            maxBit = k[1].bitWidth
        }
        let hiWordIndex = (maxBit - 1) / 64
        for i in stride(from: hiWordIndex, through: 0, by: -1){
            var mask : UInt64 = 0x3
            mask = mask << 62
            for j in stride(from: 0, to: 32, by: 1){
                res = res.double()
                res = res.double()
                let b1 = (k1[i] & mask) >> (62 - 2 * j)
                let b2 = (k2[i] & mask) >> (62 - 2 * j)
                if b1 | b2 != 0 {
                    let idx = Int((b2 << 2) | b1)
                    res = res.add_two(p2: table[idx - 1])
                }
                mask = mask >> 2
            }
        }
        return res
    }
}

// TODO: LOOSE FUNCTIONS NEED A PROPER HOME

// "LOOSE FUNCTION"
public func x_to_y(x: Fq, ec: EC) -> Fq {
    let u = x * x * x + ec.a * x + ec.b
    let y = u.modsqrt()
    return y
}

// "LOOSE FUNCTION"
public func x_to_y(x: Fq2, ec: EC2) -> Fq2 {
    let u = x * x * x + ec.a * x + ec.b
    let y = u.modsqrt_two()
    return y
}

// "LOOSE FUNCTION"
func rounding(n : BInt, d : BInt) -> BInt {
    let one = BInt(1)
    let dshift = d >> 1
    let r = n.mod(d)
    var res = n / d
    if(r > dshift){
        res += one
    }
    return res
}

// "LOOSE FUNCTION"
func precompute_glv_basis() -> Lattice {
    let lambdaGLV = BInt("228988810152649578064853576960394133503", radix: 10)! //(x₀²-1)
    return Lattice(r: r_, lambda: lambdaGLV)
}

// "LOOSE FUNCTION"
func from_bytes_g1(bytes: Array<UInt8>, q: BInt) -> Fq{
    return Fq(q: q_, value: BInt(signed: bytes))
}

// "LOOSE FUNCTION"
func from_g1_to_string(jacobPoint: JacobianPointFq) -> String{
    let affPoint = jacobPoint.to_affine()
    var byteArray = affPoint.x.value.asSignedBytes()
//    if(byteArray.count < 48){
//        print("byteArray.count < 48; byteArray[0]:")
//        print(byteArray[0])
//    }
    while byteArray.count < 48 {
        byteArray.insert(UInt8(0), at: 0)
    }
    if (affPoint.y.value > (q_ - 1)/2) {
        byteArray[0] = byteArray[0]^(0xA0)
//        print("~160~")
    }
    else {
        byteArray[0] = byteArray[0]^(0x80)
//        print("~128~")
    }
    
    // length checks
    
    var hexRet = "0x"
    hexRet += byteArray.map{ String(format:"%02hhx", $0) }.joined(separator: "")
    //
    
//    print(hexRet.count == 98)
//    print(byteArray)
//    print(byteArray.map{ String(format:"%02hhx", $0) }.joined(separator: ""))
    print(hexRet)
//    print(hexRet.count)
//    print(affPoint.x.value, affPoint.y.value)
    
    return hexRet
}

// "LOOSE FUNCTION"
func from_bytes_g2(bytes: Array<UInt8>, q: BInt) -> Fq2{
    let butes = Array(bytes.reversed())
    
    var total = BInt(0)
    for (i, elem) in butes.enumerated() {
        total = total + (BInt(Int(elem)) << (8 * (i)))
    }
    let bval = from_bytes_g1(bytes: Array(bytes[0..<48]), q: q_).value
    let yikes = min(96, bytes.count)
    let aval = from_bytes_g1(bytes: Array(bytes[48..<yikes]), q: q_).value
    return Fq2(q: EC2().q, a: aval, b: bval)
}

// "LOOSE FUNCTION"
func from_g2_to_string(jacobPoint: JacobianPointFq2) -> String {
    let affPoint = jacobPoint.to_affine()
    let affPointa = affPoint.x.a
    let affPointb = affPoint.x.b
    let ya = affPoint.y.a
    let yb = affPoint.y.b
    
    var byteArrayA = affPointa.asSignedBytes()
    var byteArrayB = affPointb.asSignedBytes()
    
    while byteArrayA.count < 48 {
        byteArrayA.insert(UInt8(0), at: 0)
    }
    
    while byteArrayB.count < 48 {
        byteArrayB.insert(UInt8(0), at: 0)
    }
    
//    if(byteArrayA.count < 48){
//        print("byteArrayA.count < 48; byteArrayA[0]:")
//        print(byteArrayA[0])
//        print("byteArrayA[0]:")
//        print(byteArrayB[0])
//        // append 0 to the end of byteArrayA
//    }
//    if(byteArrayB.count < 48){
//        print("byteArrayB.count < 48; byteArrayB[0]:")
//        print(byteArrayB[0])
//    }
    
    if (yb == 0) {
        if (ya > (q_ - 1)/2) {
            byteArrayB[0] = byteArrayB[0]^0xA0
//            print("~160~ya>")
        }
        else {
            byteArrayB[0] = byteArrayB[0]^0x80
//            print("~128~ya<")
        }
    }
    else {
        if (yb > (q_ - 1)/2) {
            byteArrayB[0] = byteArrayB[0]^0xA0
//            print("~160~yb>")
        }
        else {
            byteArrayB[0] = byteArrayB[0]^0x80
//            print("~128~yb<")
        }
    }
    var hexRet = "0x"
    hexRet += byteArrayB.map{ String(format:"%02hhx", $0) }.joined(separator: "")
    hexRet += byteArrayA.map{ String(format:"%02hhx", $0) }.joined(separator: "")
    //

//    print(hexRet.count == 194)
//    print(byteArrayB)
//    print(byteArrayA)
//    print(byteArrayB.map{ String(format:"%02hhx", $0) }.joined(separator: ""))
//    print(byteArrayA.map{ String(format:"%02hhx", $0) }.joined(separator: ""))
    print(hexRet)
//    print(hexRet.count)
//    print(affPoint.x.a, affPoint.x.b)
//    print(affPoint.y.a, affPoint.y.b)
    
    return hexRet
}

// "LOOSE FUNCTION"
func bytesToPointG2(bytes: Array<UInt8>) -> JacobianPointFq2 {
    var bites = bytes
    let m_byte = bites[0] & 0xE0
    if m_byte == 0x20 || m_byte == 0x60 || m_byte == 0xE0{
        print("Invalid first three bits")
    }

    let c_bit = (m_byte & 0x80) >> 7 // first bit
    let i_bit: UInt8 = (m_byte & 0x40) >> 6 // second bit
    let s_bit: UInt8 = (m_byte & 0x20) >> 5 // third bit

    if c_bit == 0{
        print("first bit must be 1 (only compressed point")
    }

    bites[0] = bites[0] & 0x1F

    if i_bit == 1{
        for e in bites{
            if(e != 0x00){
                print("Point at infinity set, but data not all zeroes")
                break
            }
        }
        return AffinePointFq2(x: Fq2(q: q_, a: BInt(0), b: BInt(0)), y: Fq2(q: q_, a: BInt(0), b: BInt(0)), ifty: true).to_jacobian()
    }

    let x = from_bytes_g2(bytes: bites, q: q_)
    let y_value = x_to_y(x: x, ec: EC2())
    let yvala = y_value.a
    let yvalb = y_value.b
    let othervala = (q_ - y_value.a).mod(q_)
    let othervalb = (q_ - y_value.b).mod(q_)
    var ya = BInt(0)
    var yb = BInt(0)
    if s_bit == 1 {
        if (yvalb == BInt(0)) {
            if (yvala > othervala) {
                ya = yvala
                yb = yvalb
            }
            else {
                ya = othervala
                yb = othervalb
            }
        }
        else {
            if (yvalb > othervalb) {
                ya = yvala
                yb = yvalb
            }
            else {
                ya = othervala
                yb = othervalb
            }
            
        }
    }
    else {
        if (yvalb == BInt(0)) {
            if (yvala > othervala) {
                ya = othervala
                yb = othervalb
            }
            else {
                ya = yvala
                yb = yvalb
            }
        }
        else {
            if (yvalb > othervalb) {
                ya = othervala
                yb = othervalb
            }
            else {
                ya = yvala
                yb = yvalb
            }
            
        }
    }
    return AffinePointFq2(x: x, y: Fq2(q: EC2().q, a: ya, b: yb), ifty: false).to_jacobian()
}

// "LOOSE FUNCTION"
func sign_fn(element: Fq, s_bit : UInt8) -> Fq {
    if ((element.value > ((q_ - 1) / 2)) == (s_bit != 0)) {
        return element
    }
    return Fq(q: q_, value: BInt(-1) * element.value)
}

// "LOOSE FUNCTION"
func bytesToPointG1(bytes: Array<UInt8>) -> JacobianPointFq {
    var bites = bytes
    let m_byte = bites[0] & 0xE0
    if m_byte == 0x20 || m_byte == 0x60 || m_byte == 0xE0{
        print("Invalid first three bits")
    }
    let c_bit = (m_byte & 0x80) >> 7
    let i_bit: UInt8 = (m_byte & 0x40) >> 6
    let s_bit: UInt8 = (m_byte & 0x20) >> 5
    if c_bit == 0{
        print("first bit must be 1 (only compressed point")
    }
    bites[0] = bites[0] & 0x1F
    if i_bit == 1{
        for e in bites{
            if(e != 0x00){
                print("Point at infinity set, but data not all zeroes")
                break
            }
        }
        return AffinePointFq(x: Fq(q: q_, value: BInt(0)), y: Fq(q: q_, value: BInt(0)), ifty: true).to_jacobian()
    }
    let x = from_bytes_g1(bytes: bites, q: q_)
    let y_value = x_to_y(x: x, ec: EC())
    let y = sign_fn(element: y_value, s_bit: s_bit)
    return AffinePointFq(x: x, y: y, ifty: false).to_jacobian()
}

struct Status: Codable {
    let lobby_size: Int
    let num_contributions: Int
    let sequencer_address: String
}

struct powersofTau_: Codable {
    var G1Powers: [String]
    var G2Powers: [String]
}
struct contribution_: Codable {
    var numG1Powers: Int
    var numG2Powers: Int
    var powersOfTau: powersofTau_
    var potPubkey: String
    var blsSignature: String
}
struct transcript: Codable {
    var contributions: [contribution_]
    var ecdsaSignature: String
}

class ViewController: UIViewController {

    private var tableData = [String]()
    @IBOutlet var tableView : UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // clear cache on viewDidLoad()
        WKWebsiteDataStore.default().removeData(ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache], modifiedSince: Date(timeIntervalSince1970: 0), completionHandler:{ })
        // Do any additional setup after loading the view.
        // set the background color to be purple in hex
        view.backgroundColor = UIColor(red: 0.92, green: 0.88, blue: 0.99, alpha: 1.0)
        title = "♢ KZG Ceremony ♢"

        
        tableView.register(StatusTableViewCell.nib(), forCellReuseIdentifier: StatusTableViewCell.identifier)
        tableView.register(ContibutionTableViewCell.nib(), forCellReuseIdentifier: ContibutionTableViewCell.identifier)
        tableView.register(VerifyTableViewCell.nib(), forCellReuseIdentifier: VerifyTableViewCell.identifier)
        
        tableView.allowsSelection = false
        self.tableView.layer.cornerRadius = 10.0

        tableView.delegate = self
        tableView.dataSource = self
        
        fetchData()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        
    }
    
    @objc private func didPullToRefresh(){
        // refetch data here
        fetchData()
    }
    
    private func fetchData() {
        // https://eprint-sanity.com/info/status
        // {"lobby_size":0,"num_contributions":0,"sequencer_address":"0x9b1855fe5D1D3b3d91da8fdEF307161a74db0133"}
        
        tableData.removeAll()
        
        if tableView.refreshControl?.isRefreshing == true{
            print("refreshing data")
        } else {
            print("fetching first data")
        }
        
        guard let url = URL(string: SEQUENCER_URL + "/info/status") else {
            return
        }

        let task = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, response, error in
            // validate data exists
            guard let strongSelf = self, let data = data, error == nil else {
                print("something went wrong")
                return
            }

            var result: Status?
            do {
                result = try JSONDecoder().decode(Status.self, from: data)
            }
            catch {
                print("failed to convert \(error.localizedDescription)")
            }

            guard let json = result else {
                return
            }
            
            print(json)
            
            strongSelf.tableData.append("Lobby Size: \(json.lobby_size)")
            strongSelf.tableData.append("Total Contributions: \(json.num_contributions)")
            strongSelf.tableData.append("Sequencer Address: \(json.sequencer_address)")
            
            DispatchQueue.main.async {
                strongSelf.tableView.refreshControl?.endRefreshing()
                strongSelf.tableView.reloadData()
            }
        })
        task.resume()
    }
    
    @objc func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func refreshAction() {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContibutionTableViewCell") as! ContibutionTableViewCell
        cell.webView.reload()
    }
    
    func tryContributeRequest(sessionID: String, requerySequencerSlot: @escaping (Bool) -> Void, updatedSRS: @escaping (Bool) -> Void) {
        let debugfilename = "batchContribution5.json"
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell
        let sessionID1 = cell.sessionID.text!
        let trycontribute = SEQUENCER_URL + "/lobby/try_contribute"
        let requestURL: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: trycontribute)!)
        requestURL.addValue("Bearer " + sessionID1, forHTTPHeaderField: "Authorization")
        requestURL.httpMethod = "POST"
        let taskTryContribute = URLSession.shared.dataTask(with: requestURL as URLRequest) { data, resp, error in
            if error == nil {
                let result = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                if result!["error"] != nil {
                    print("error")
                    requerySequencerSlot(true)
                }
                else {
                    requerySequencerSlot(false)
                    print("NO error")
                    // get the type of result
                    let json = try? JSON(data: data!)
                    //GENERATE RANDOM NUMBER
                    // uses SecRandomCopyBytes under the hood
                    var frs = [BInt(bitWidth: 255).mod(r_), BInt(bitWidth: 255).mod(r_), BInt(bitWidth: 255).mod(r_), BInt(bitWidth: 255).mod(r_)]
                    //var frs = [BInt(secureRandomInt()).mod(r_), BInt(secureRandomInt()).mod(r_), BInt(secureRandomInt()).mod(r_), BInt(secureRandomInt()).mod(r_)]
                    print(frs)
                    // hold random numbers constant for testing
                    //var frs = [BInt("24411069964286119500368689318335993780931986328388456226470872197060711265599")!, BInt("23615580870708549094368572648105253581073636545533698131234972976882938249293")!, BInt("8431864758931758479209924752529198756466700704719542736340441542282952357472")!, BInt( "38583166546384429513519787018753669728844769024480308336347556097031580575413")!]
                    var contributions = Array<contribution_>()
                    
                    let basis: Lattice = precompute_glv_basis()
                    
                    let fileManager = FileManager.default
                    let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileUrl = documentsDirectory.appendingPathComponent(debugfilename)

                    if !fileManager.fileExists(atPath: fileUrl.path) {
                        print("File doesn't exist: \(fileUrl)")
                        

                    
                    for sets in 0...3 {
                        var tok = Date.timeIntervalSinceReferenceDate
                        var set_total_time = Double()
                        print("sets" + String(sets) + ": ")
                        var G1s = Array<String>()
                        var G2s = Array<String>()
                        var xi = BInt(1)
                        let numG1Powers = json?["contributions"][sets]["numG1Powers"].int
                        //UPDATE G1 POINTS
                        for i in 0...numG1Powers!{
                            let tik = Date.timeIntervalSinceReferenceDate
                            print("time per iter")
                            set_total_time += (tik-tok)
                            print(tik-tok)
                            tok = tik
                            print(i)
                            if let currentG1Power = json?["contributions"][sets]["powersOfTau"]["G1Powers"][i].string {
                                //Now you got your value
                                
                                let exampleG1PowerString = String(currentG1Power.dropFirst(2))
                                let exampleG1PowerBytes = Array<UInt8>.init(hex: exampleG1PowerString)
                                let jacobianPoint = bytesToPointG1(bytes: exampleG1PowerBytes)
                                
                                let scalarMultGLV = jacobianPoint.scalar_mult_glv(s: xi, glvBasis: basis)
                                print("oldG1Jac: ")
                                print(jacobianPoint.x.value, jacobianPoint.y.value, jacobianPoint.z.value)
                                print("i/xi" + String(i))
                                print(xi)
                                print()
                                print("newG1Jac: ")
                                print(scalarMultGLV.x.value, scalarMultGLV.y.value, scalarMultGLV.z.value)
                                print()
                                
                                //ENCODE THE VALUE -- THIS IS WHAT GOES IN THE JSON!!!!
                                let updatedG1HexGLV = from_g1_to_string(jacobPoint: scalarMultGLV) // Jacobian->Affine->Hex
                                //let newg1PtGLV = scalarMultGLV.to_affine()
                                G1s.append(updatedG1HexGLV)
                                //G1s.append(currentG1Power)
                            }
                            let numG2Powers = json?["contributions"][sets]["numG2Powers"].int
                            
                            //UPDATE G2 POINTS
                            if (i < numG2Powers!) {
                                if let currentG2Power = json?["contributions"][sets]["powersOfTau"]["G2Powers"][i].string {
                                    //Now you got your value
                                    
                                    let exampleG2PowerString = String(currentG2Power.dropFirst(2))
                                    let exampleG2PowerBytes = Array<UInt8>.init(hex: exampleG2PowerString)
                                    let jacobianPoint = bytesToPointG2(bytes: exampleG2PowerBytes)
                                    let scalarMultGLV = jacobianPoint.scalar_mult_glv(s: xi, glvBasis: basis)
                                    print("oldG2Jac: ")
                                    print(jacobianPoint.x.a, jacobianPoint.x.b, jacobianPoint.y.a, jacobianPoint.y.b, jacobianPoint.z.a, jacobianPoint.z.b)
                                    print("i/xi" + String(i))
                                    print(xi)
                                    print()
                                    print("newG2Jac: ")
                                    print(scalarMultGLV.x.a, scalarMultGLV.x.b, scalarMultGLV.y.a, scalarMultGLV.y.b, scalarMultGLV.z.a, scalarMultGLV.z.b)
                                    print()
                                    
                                    //ENCODE THE VALUE -- THIS IS WHAT GOES IN THE JSON!!!!
                                    let updatedG2HexGLV = from_g2_to_string(jacobPoint: scalarMultGLV)
                                    //print("newG2JacAffineAffineJacobian: ")
                                    //let newg2PtGLV = scalarMultGLV.to_affine()

                                    G2s.append(updatedG2HexGLV)
                                    
                                    //G2s.append(currentG2Power)
                                }
                            }
                            xi = (frs[sets]*xi).mod(r_)
                        }
                        print("total")
                        print(set_total_time)
                        print("avg itr:")
                        print(set_total_time/Double(numG1Powers!))
                        
                        let powersoftau = powersofTau_(G1Powers: G1s, G2Powers: G2s)
                        
                        //UPDATE WITNESS
                        
                        let potpubkeystring = json?["contributions"][sets]["potPubkey"].string!.dropFirst(2)
                        let G2pubkeybytes = Array<UInt8>.init(hex: String(potpubkeystring!))
                        let jacobPoint = bytesToPointG2(bytes: G2pubkeybytes)
                        let newWitness = jacobPoint.scalar_mult_glv(s: frs[sets], glvBasis: basis)
                        
                        //ENCODE THE WITNESS -- THIS IS WHAT GOES IN THE JSON!!!!!!
                        let encodedWitness = from_g2_to_string(jacobPoint: newWitness)

                        let numg1 = G1s.count;
                        let numg2 = G2s.count;
                        
                        //let tmppotPubKey = json?["contributions"][sets]["potPubkey"].stringValue
                        print(encodedWitness.count)
                        
                        let contrib = contribution_(numG1Powers: numg1, numG2Powers: numg2, powersOfTau: powersoftau, potPubkey: encodedWitness, blsSignature: "")
                        contributions.append(contrib)
                        let tik = Date.timeIntervalSinceReferenceDate
                        print(tik - tok)
                    }
                    }

                        // DELETE SECRET
                    frs[0] = BInt(0)
                    frs[1] = BInt(0)
                    frs[2] = BInt(0)
                    frs[3] = BInt(0)

                        
                        
                    //CONTRIBUTIONS IS AN ARRAY CONTAINING THE NEW CONTRIBUTION AND SIGNATURE, NEED TO CONVERT THIS TO JSON
                    var batchContrib = transcript(contributions: contributions, ecdsaSignature: "")
                    let jsonEncoder = JSONEncoder()
                    jsonEncoder.outputFormatting = .prettyPrinted
                    //this is the json :))
                    do {
                        var batchContribution = try jsonEncoder.encode(batchContrib)
                        
                        // print the debug file
                        let fileManager = FileManager.default
                        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let fileUrl = documentsDirectory.appendingPathComponent(debugfilename)

                        if let jsonData = try? Data(contentsOf: fileUrl),
                           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                            print("JSON contents: \(jsonObject)")
                            print(jsonObject)
                        } else {
                            print("Error reading file: \(fileUrl)")
                        }
                        
                        // load the debug file into batchContribution
                        // currently gives s potpubkey error
                        // {"code":"CeremonyError::PubKeyPairingFailed","error":"contribution invalid: Error in contribution 0: Pubkey pairing check failed"}
                        /*
                        if fileManager.fileExists(atPath: fileUrl.path) {
                            if let jsonString = try? String(contentsOf: fileUrl, encoding: .utf8){
                                // load the debug file into batchContribution
                                let decodedJson = try JSONDecoder().decode(transcript.self, from: jsonString.data(using: .utf8)!)
                                print("decoded")
                                batchContrib = transcript(contributions: decodedJson.contributions, ecdsaSignature: decodedJson.ecdsaSignature)
                                batchContribution = try jsonEncoder.encode(batchContrib)
                                
                                for keys in 0...3 {
                                    print("current:")
                                    print(batchContrib.contributions[keys].potPubkey)
                                    let g2generator = JacobianPointFq2(x: Fq2(q: q_, a: BInt("352701069587466618187139116011060144890029952792775240219908644239793785735715026873347600343865175952761926303160")!, b: BInt("3059144344244213709971259814753781636986470325476647558659373206291635324768958432433509563104347017837885763365758")!), y: Fq2(q: q_, a: BInt("1985150602287291935568054521177171638300868978215655730859378665066344726373823718423869104263333984641494340347905")!, b: BInt("927553665492332455747201965776037880757740193453592970025027978793976877002675564980949289727957565575433344219582")!), z: Fq2(q: q_, a: BInt("1")!, b: BInt("0")!), ifty: false)
                                    
                                    let newWitness = g2generator.scalar_mult_glv(s: frs[keys], glvBasis: basis)
                                    //ENCODE THE WITNESS -- THIS IS WHAT GOES IN THE JSON!!!!!!
                                    let encodedWitness = from_g2_to_string(jacobPoint: newWitness)
                                    batchContrib.contributions[keys].potPubkey = encodedWitness
                                }
                            } else{
                                print("string err")
                            }
                        }*/
                        
                        // save the data to debug file if the file doesn't exist
                        if !fileManager.fileExists(atPath: fileUrl.path) {
                            if let jsonString = String(data: batchContribution, encoding: .utf8){
                                let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(debugfilename)
                                try jsonString.write(to: fileUrl, atomically: true, encoding: .utf8)
                                print("JSON data saved to file: \(fileUrl)")
                            }
                        }
                        
                        let contributeurl = URL(string: SEQUENCER_URL + "/contribute")!
                        let request: NSMutableURLRequest = NSMutableURLRequest(url: contributeurl)
                        request.addValue("Bearer " + sessionID1, forHTTPHeaderField: "Authorization")
                        request.httpMethod = "POST"
                        request.httpBody = batchContribution
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        // 4 mins to post req
                        request.timeoutInterval = 60 * 4
                        
                        let session = URLSession.shared
                        let task = session.dataTask(with: request as URLRequest) { (data0, response0, error0) in
                            if let error0 = error0 {
                                print("here")
                                print(data0?.toHexString() as Any)
                                print(response0 as Any)
                                print("Error: \(error0)")
                            } else {
                                print(data0?.toHexString() as Any)
                                print(response0 as Any)
                                print(error0?.localizedDescription as Any)
                                
                                if let data0 = data0,
                                   let response0 = response0 as? HTTPURLResponse,
                                   response0.statusCode == 200 {
                                    print("contribution successful")
                                    print("raw hex receipt: ")
                                    print(data0.toHexString())
                                    let receipt = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                                    if let value = receipt![""] {
                                        print(value)
                                    }
                                    updatedSRS(true)
                                } else {
                                    // Handle unsuccessful response
                                    print("unsuccessful response")
                                    print(data0?.toHexString() as Any)
                                    print(response0 as Any)
                                    print(error0?.localizedDescription as Any)
                                    
                                    // hit try_contribute again, possibly?
                                    let requestURL2: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: trycontribute)!)
                                    requestURL2.addValue("Bearer " + sessionID1, forHTTPHeaderField: "Authorization")
                                    requestURL2.httpMethod = "POST"
                                    let taskTryContribute2 = URLSession.shared.dataTask(with: requestURL2 as URLRequest) { data1, resp1, error1 in
                                        if error1 == nil {
                                            let result1 = try? JSONSerialization.jsonObject(with: data1!, options: .allowFragments) as? [AnyHashable: Any]
                                            if result1!["error"] != nil {
                                                print("error")
                                                print("her")
                                            }
                                            else {
                                                // get the type of result
                                                let request2: NSMutableURLRequest = NSMutableURLRequest(url: contributeurl)
                                                request2.addValue("Bearer " + sessionID1, forHTTPHeaderField: "Authorization")
                                                request2.httpMethod = "POST"
                                                request2.httpBody = batchContribution
                                                request2.addValue("application/json", forHTTPHeaderField: "Content-Type")
                                                
                                                let session2 = URLSession.shared
                                                let task2 = session2.dataTask(with: request2 as URLRequest) { (data2, response2, error2) in
                                                    if let error2 = error2 {
                                                        print("her2")
                                                        print("Error: \(error2)")
                                                    } else {
                                                        if let data2 = data2, let response2 = response2 as? HTTPURLResponse, response2.statusCode == 200 {
                                                            print("sucessfully contributed")
                                                            print(data2)
                                                            updatedSRS(true)
                                                        } else {
                                                            print(data2?.toHexString())
                                                            print(response2)
                                                            print(error2)
                                                            // Handle unsuccessful response
                                                            print("truly unsuccessful response")
                                                            print("gg mofo")
                                                        }
                                                    }
                                                }
                                                task2.resume()
                                            }
                                            
                                        }
                                    }
                                    taskTryContribute2.resume()
                                }
                            }
                        }
                        task.resume()
                    } catch {
                        print("her3")
                        print(error.localizedDescription)
                    }
                }
                
            }
        }
        taskTryContribute.resume()
    }
    
    func githubAuthVC(authWithGit: Bool) {
        // Create github Auth ViewController
        let githubVC = UIViewController()
        // Create WebView
        let webView = WKWebView()
        webView.navigationDelegate = self
        githubVC.view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: githubVC.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: githubVC.view.leadingAnchor),
            webView.bottomAnchor.constraint(equalTo: githubVC.view.bottomAnchor),
            webView.trailingAnchor.constraint(equalTo: githubVC.view.trailingAnchor)
        ])
        
        let seqauth = SEQUENCER_URL + "/auth/request_link"
        
        let requestURL: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: seqauth)!)
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell
        fetchURL(with: requestURL as URLRequest, authWithGit: authWithGit) { result in
            print(result)
            let githubauthurl = URL(string: result)
            let urlRequest = URLRequest(url: githubauthurl!)
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if (authWithGit) {
                    cell.authtext = "Authorized with GitHub"
                }
                else {
                    cell.authtext = "Authorized with ETH"
                }
                cell.authType.text = cell.authtext
                cell.githubButton.isHidden = true
                cell.siweButton.isHidden = true
                webView.load(urlRequest)

                // Create Navigation Controller
                let navController = UINavigationController(rootViewController: githubVC)
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancelAction))
                githubVC.navigationItem.leftBarButtonItem = cancelButton
                let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshAction))
                githubVC.navigationItem.rightBarButtonItem = refreshButton
                let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                navController.navigationBar.titleTextAttributes = textAttributes
                githubVC.navigationItem.title = "authorization"
                navController.navigationBar.isTranslucent = false
                navController.navigationBar.tintColor = UIColor.white
                navController.navigationBar.barTintColor = UIColor.darkGray
                navController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
                navController.modalTransitionStyle = .coverVertical

                self.present(navController, animated: true, completion: nil)
                
            }
        }
    }
    
    func fetchURL(with requestURL: URLRequest, authWithGit: Bool, completion: @escaping (String) -> Void) {
        let taskGetURL = URLSession.shared.dataTask(with: requestURL as URLRequest) { data, _, error in
            if error == nil {
                let result = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]

                // GitHub Auth URL
                if authWithGit {
                    let authString = (result?["github_auth_url"] as! String)
                    completion(authString)
                }
                else {
                    let authString = (result?["eth_auth_url"] as! String)
                    completion(authString)
                }
            }
        }
        taskGetURL.resume()
    }

}

//func secureRandomBytes(count: Int) -> [Int8] {
//    var bytes = [Int8](repeating: 0, count: count)
//
//    // Fill bytes with secure random data
//    let _ = SecRandomCopyBytes(
//        kSecRandomDefault,
//        count,
//        &bytes
//    )
//
//    // A status of errSecSuccess indicates success
//    return bytes
//}
//
//func secureRandomInt() -> Int {
//    let count = MemoryLayout<Int>.size
//    var bytes = [Int8](repeating: 0, count: count)
//
//    // Fill bytes with secure random data
//    let _ = SecRandomCopyBytes(
//        kSecRandomDefault,
//        count,
//        &bytes
//    )
//
//    // A status of errSecSuccess indicates success
//        // Convert bytes to Int
//        let int = bytes.withUnsafeBytes { pointer in
//            return pointer.load(as: Int.self)
//        }
//
//        return int
//
//}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        self.RequestForCallbackURL(request: navigationAction.request)
        decisionHandler(.allow)
    }

    func RequestForCallbackURL(request: URLRequest) {
        // Get the authorization code string after the '?code=' and before '&state='
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ContibutionTableViewCell") as! ContibutionTableViewCell
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell

        let requestURLString = (request.url?.absoluteString)! as String
        if requestURLString.contains("code=") {
            self.dismiss(animated: true)
            cell.webView.removeFromSuperview()
            let codestate = (requestURLString.components(separatedBy: "code=")[1].components(separatedBy: "&state="))
            let code = codestate[0]
            let state = codestate[1]
            print("code: " + code)
            print("state: " + state)
            githubRequestForSessionID(authCode: code, authState: state) {
                result in cell.sessionIDString = result
                DispatchQueue.main.async {
                    cell.contributeButton.isHidden = false
                    cell.sessionID!.text = result
                    print(result)
//                    self.tableView.beginUpdates()
//                    let indexPath = IndexPath(item:  1, section: 0)
//                    self.tableView.reloadRows(at: [indexPath], with: .top)
//                    self.tableView.endUpdates()
//                    cell.updateAuthState(id: result)
                }
            }
        }
    }
    
    func githubRequestForSessionID(authCode: String, authState: String, completion: @escaping (String) -> Void) {
        // Set the GET parameters.
        let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell

        let rqueryItems = [URLQueryItem(name: "state", value: authState), URLQueryItem(name: "code", value: authCode)]
        var rurlComps = URLComponents(string: "")!
        if cell.authWithGit {
            rurlComps = URLComponents(string: SEQUENCER_URL + "/auth/callback/github")!
        }
        else {
            rurlComps = URLComponents(string: SEQUENCER_URL + "/auth/callback/eth")!
        }
        rurlComps.queryItems = rqueryItems
        let url = rurlComps.url!
        let requestURL: NSMutableURLRequest = NSMutableURLRequest(url: url)
        requestURL.timeoutInterval = 60 * 2
        let task = URLSession.shared.dataTask(with: requestURL as URLRequest) { data, _, error in
            if error == nil {
                let result = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [AnyHashable: Any]
                if let value = result!["session_id"] {
                    print(value)
                    completion(value as! String)
                }
                else {
                    if let value = result!["error"] {
                        print(value)
                        completion(value as! String)
                    }
                }
            }
        
        }
        
        task.resume()
    }
}


extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("you tapped me \(indexPath)")
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        /*
        var xa = BInt("1813827748302988098834340692419448334289720132472004970100876603457467003965612298842876139728606298276291116315801", radix: 10)!
        var xb = BInt("916532624661717562374082193356498735277758221850401593021102364889487311599727202886089651666036385196447446423502", radix: 10)!
        let yea = Fq2(q: q_, a: xa, b: xb)
        let y = yea.exp_two()
        print(y.a, y.b)
         */
        // TESTING SHIT -- THIS IS HOW U USE THE STUFF
        
      
        /*
        var x = BInt(secureRandomInt())
        x = x.mod(q_)
        //print(x)
        let exampleG1PowerString = "b7c73ffc5be8d5a79674e760a5bf503187f243ef1990d257f2a121917612ef0effbde5dfa91731bdd03ef89895f22c80"
        print(exampleG1PowerString)
        let exampleG1PowerBytes = Array<UInt8>.init(hex: exampleG1PowerString)
        print(exampleG1PowerBytes)
        let jacobianPoint1 = bytesToPointG1(bytes: exampleG1PowerBytes)
        let hextring = from_g1_to_string(jacobPoint: jacobianPoint1)
        //print("hextring", hextring)
        //let jacobianPoint4 = jacobianPoint1.scalar_mult(c: BInt(x))
        print(jacobianPoint1.x.value, jacobianPoint1.y.value, jacobianPoint1.z.value, jacobianPoint1.ifty)
        //print(jacobianPoint4.x.value, jacobianPoint4.y.value, jacobianPoint4.z.value, jacobianPoint4.ifty)
        let exampleG2PowerString = "b9c379f94f1c31faf685c036b3991d503c3e9452adc51918beefe96d1dbef2ce4aaf51f300172db1b16dd355d7e51877141ee88bc36cb617fb221573443f8455a1207d5e25fd75444bbbf74f9c3eb1c8857d2b02c2e4baef8ca8a3028280c13d"
        print(exampleG2PowerString)
        let exampleG2PowerBytes = Array<UInt8>.init(hex: exampleG2PowerString)
        print(exampleG2PowerBytes)
        let jacobianPoint2 = bytesToPointG2(bytes: exampleG2PowerBytes)
        let hexstring2 = from_g2_to_string(jacobPoint: jacobianPoint2)
        print("hexstring2", hexstring2)
        //let jacobianPoint3 = jacobianPoint2.scalar_mult(c: BInt(x))
        print(jacobianPoint2.x.a, jacobianPoint2.x.b, jacobianPoint2.y.a, jacobianPoint2.y.b, jacobianPoint2.z.a, jacobianPoint2.z.b, jacobianPoint2.ifty)
       // print(jacobianPoint3.x.a, jacobianPoint3.x.b, jacobianPoint3.y.a, jacobianPoint3.y.b, jacobianPoint3.z.a, jacobianPoint3.z.b, jacobianPoint3.ifty)
        */
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0{
            //let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! StatusTableViewCell
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatusTableViewCell", for: indexPath) as! StatusTableViewCell
            cell.lobbySizeLabel?.text = tableData[0]
            cell.numberContrubtionsLabel?.text = tableData[1]
            cell.sequencerAddressLabel?.text = tableData[2]
            cell.center.y = tableView.center.y
            //cell.viewController = self
            cell.clipsToBounds = true
            return cell
        }
        else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContibutionTableViewCell", for: indexPath) as! ContibutionTableViewCell
            //let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! ContibutionTableViewCell

            cell.viewController = self
            cell.clipsToBounds = true
            return cell
        } else {
            //let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! VerifyTableViewCell
            let cell = tableView.dequeueReusableCell(withIdentifier: "VerifyTableViewCell", for: indexPath) as! VerifyTableViewCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0{
            // first cell
            return CGFloat(200)
        }
        else if indexPath.row == 1{
            return CGFloat(350)
        }
        return CGFloat(250)
    }
}

