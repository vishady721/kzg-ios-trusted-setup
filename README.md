# bls12-381-swift

[BLS12-381](https://electriccoin.co/blog/new-snark-curve/) is a pairing friendly elliptic curve that's part of a larger family of curves described by [Barreto, Lynn, and Scott](https://eprint.iacr.org/2002/088.pdf). With a $q \approx 2^{384}$, and with an [embedding degree](https://hackmd.io/@benjaminion/bls12-381#Embedding-degree) of 12, this curves target the 128-bit security level.

Many protocols are putting it to use for digital signatures and zero-knowledge proofs: Zcash, Ethereum 2.0, Skale, Algorand, Dfinity, Chia, and more. This implementation aims to be helpful in Swift development contexts (iOS, macOS, etc.) and is located primarily in ```srsly/srsly/ViewController.swift```

[TODO: Single Module Import]

[TODO: Benchmarks]

[TODO: Not Audited Disclaimer]

# srsly: a swift kzg-ios-client

The [KZG scheme](https://www.iacr.org/archive/asiacrypt2010/6477178/6477178.pdf) commits to a polynomial by evaluating it at a secret value (specifically, a elliptic curve point). The Ethereum Foundation is conducting a ceremony where purpose is to construct this secret value in a way that no single person knows what this secret is and to do so such that people are convinced of this many years from now. 

An example use case of this curve implementation is the KZG ceremony. We implement an iOS client that supports the Ceremony's Special Contribution period. The files for the project as well as the curve are located in the ```srsly.xcodeproj```

## Contribution Receipt

This project was used to contribute to the Ethereum KZG ceremony's special contribution period on 04/16/2022 @ ~4:23 PDT. The following is the contribution receipt for contribution #83344 visible on the [ceremony website](https://ceremony.ethereum.org/):

```javascript
{
  "identity": "eth|0xdf369cde73ce4d75deba0d9a6f67873ea9350b9b",
  "witness": [
    "0xb2c3a994728990489e9b4baccf2ca2d178478b8adb60e9d339bb8d6305d9a726e20be519208b03189c175d6b1e1231c81079cca38a8fef5b576b714225dab3e46241d18510b19de9639b84e136f3fef055a60ef610ba2daeaf6df03583b80665",
    "0xb32320ac9ea45e0e7e83809e441166ff82fb55eaf5b617f04b7971c0972780f41ffab86d5e8b729c4886acf25212cd6102df3edee2367278370ffe71f7021d7abb4dc2b10fb01f965c34c02f249f93b2c2e1de250cd54c094be8561e004f0678",
    "0xb9dcedee0b1467900783e50cdd08f9bc849af9cc9ae7f81df3aeecaaec2df83c68525c7fe90adf82a3e6999dad693c451166b3f5304258713dff5faf73ee4d7eedadc18ae80150fe44252b33f4820cb52feb6b1045db54668f2b3a5bd2654993",
    "0x8a000e8d0c2a591585307e1a98558f7dbab8d6867297870d70c8d66efb4c72972b84f233bf6b2938c5c2b9d6d009489605a6b547b6aa91bdd0b3fb2c799ccd5774131c1e12d993cd25bf16b682e95c2616e90be0a7302a0b126dedaf16ced798"
  ]
}
```

# [Blog Post](./blog.md)

