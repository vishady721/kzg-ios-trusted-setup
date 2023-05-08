# bls12-381-swift

[BLS12-381](https://electriccoin.co/blog/new-snark-curve/) is a pairing friendly elliptic curve that's part of a larger family of curves described by [Barreto, Lynn, and Scott](https://eprint.iacr.org/2002/088.pdf). With a $q \approx 2^{384}$, and with an [embedding degree](https://hackmd.io/@benjaminion/bls12-381#Embedding-degree) of 12, this curves target the 128-bit security level.

Many protocols are putting it to use for digital signatures and zero-knowledge proofs: Zcash, Ethereum 2.0, Skale, Algorand, Dfinity, Chia, and more. This implementation aims to be helpful in Swift development contexts (iOS, macOS, etc.) and is located primarily in ```srsly/srsly/ViewController.swift```

[TODO: Single Module Import]

[TODO: Benchmarks]

[TODO: Not Audited Disclaimer]

# srsly: a swift kzg-ios-client

The [KZG scheme](https://www.iacr.org/archive/asiacrypt2010/6477178/6477178.pdf) commits to a polynomial by evaluating it at a secret value (specifically, a elliptic curve point). The Ethereum Foundation is conducting a ceremony where purpose is to construct this secret value in a way that no single person knows what this secret is and to do so such that people are convinced of this many years from now. 

An example use case of this curve implementation is the KZG ceremony. We implement an iOS client that supports the Ceremony's Special Contribution period. The files for the project as well as the curve are located in the ```srsly.xcodeproj```

## Ethereum PoT KZG Ceremony Contribution

This project was used to contribute to the Ethereum KZG ceremony's special contribution period on 04/16/2022 @ ~4:20 PDT. More details on the contributing address, witness, entropy generation, and overall process can be found in the [blog post](./blog.md)

