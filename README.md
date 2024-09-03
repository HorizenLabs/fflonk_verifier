# FFlonk verifier

A Rust implementation of Polygon's FFlonk verifier for CDK prover. The proof is 768 bytes (24 big-endian
unsigned 256 bits integers) and the expected public input is 32 bytes (a big-endian unsigned 256 bits integer).
To build the proof and public input from the raw bytes you can use the implemented `TryFrom` trait.

The solidity reference implementation from Polygon
[is in solidity](https://github.com/0xPolygon/cdk-validium-contracts/blob/cecd53e0b1e39cd9df1a79215eedbbb636b4e0a7/contracts/verifiers/FflonkVerifier.sol)
where the [verfication key come from fork-id 6 PR](https://github.com/0xPolygon/cdk-validium-contracts/compare/v0.0.1...v0.0.2#diff-464c9f4dd9c1b875ceb2aace2024dd3ef9dfea0d4b30e9ef8cf9ca3c743671f2R51)

You can also deserialize verification keys (the circom's json format is supported): in this case you should
use `serde` feature.

## Usage

```rust
use fflonk_verifier::{verify, VerificationKey, Proof} ;
# use hex_literal::hex;

let data = hex!(
        r#"
        283e3f25323d02dabdb94a897dc2697a3b930d8781381ec574af89a201a91d5a
        2c2808c59f5c736ff728eedfea58effc2443722e78b2eb4e6759a278e9246d60
        0f9c56dc88e043ce0b90c402e96b1f4b1a246f4d0d69a4c340bc910e1f2fd805
        19e465e01bd7629f175931feed102cb6459a1be7b08018b93c142e961d0352d8
        0b8e5d340df28c2f454c5a2535ca01a230bb945ee24b1171481a9a2c6496fed6
        1cf8878e40adb52dc27da5e79718f118467319d15d64fed460d69d951376ac63
        1a6c44faaec76e296b43fe720d700a63fd530f9064878b5f72f2ffe7458c2f03
        1ac6ed8c1e0758dfb3702ed29bbc0c14b5e727c164b3ade07b9f164af0be54b0
        143b1a6534b2dcf2bd660e1b5b420d86c0c350fd9d614b639c5df98009f1375e
        141259679021d0a6a3aa3aae2516bace4a4a651265217ec0ea7c0d7f89b98710
        0abcc93d98ff40bae16eff6c29955f7a37155bb25672b12eb5074dcb7c3e2b00
        1718a257cca21ee593d1ba9f8e91e5168aed8e0b1893e11a6b583d975e747f80
        08a8c2150a04d8f867945ca1740dc3fc3b2fc4daff61b4725fb294435a1b9010
        1803690ae70fc212b7e929de9a22a4642ef4772546cf93ffd1b1196a3d9113a3
        009c506755578932ca3630508ca1ed6ee83df5ec9e26cb0b5800a70967a1a93a
        04d142b6a532935a31d84f75d16929df6d38c3a210ac4f435a8024dfb7e6c1f3
        246d58038a943f237325b44f03d106e523adfec4324615a2dd09e1e5b9143b41
        1c1cf09ee411cf9864d30df4904099920cee9ae8134d45dfeb29e46115d2e740
        098674b8fc2ca31fac6fcc9302860654fdc1b522b7e064b0759bc5924f332fa9
        21121b5af880f83fbce02f19dabb8f684593e7322fb80bfc0d054797b1d4eff4
        11b01bf68f81f2032ae4f7fc514bd76ca1b264f3989a92e6b3d74cda4f8a7149
        20e4c02f5a71082a8bcf5be0b5750a244bd040a776ec541dfc2c8ae73180e924
        0ada5414d66387211eec80d7d9d48498efa1e646d64bb1bf8775b3796a9fd0bf
        0fdf8244018ce57b018c093e2f75ed77d8dbdb1a7b60a2da671de2efe5f6b9d7
        "#
);
let vk = VerificationKey::default();
let proof = Proof::try_from(&data).unwrap();
let pubs = hex!("0d69b94acdfaca5bacc248a60b35b925a2374644ce0c1205db68228c8921d9d9").into();

verify(&vk, &proof, &pubs).unwrap();
```

## Bins

This crate also provide two simple binaries:

- `proof-converter`: to convert proofs against different formats
- `verifier`: to verify proofs

To compile and install them use

```sh
cargo cargo install --features bins --path .
```

or

- `cargo build --features bins` : to just compile and leave the binaries in
  `target/debug` folder.
- `cargo build --release --features bins` : to just compile in release mode
  and leave the binaries in `target/release` folder.

```text
$ proof-converter --help
Converts fflonk-proofs formats

Usage: proof-converter [OPTIONS] <INPUT> [OUTPUT]

Arguments:
  <INPUT>
          Input file

  [OUTPUT]
          Output file [or stdout if not specified]

Options:
  -i, --in-fmt <FORMAT>
          Input type
          
          [default: json]

          Possible values:
          - json:       Json
          - bytes:      Bytes
          - hex-string: Hex String

  -o, --out-fmt <FORMAT>
          Output type
          
          [default: hex-string]

          Possible values:
          - json:       Json
          - bytes:      Bytes
          - hex-string: Hex String

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```

```text
$ verifier --help
Verify fflonk-proofs

Usage: verifier [OPTIONS] <VK> <PROOF> <PUBS>

Arguments:
  <VK>
          Verification Key Json File

  <PROOF>
          Proof File

  <PUBS>
          Public input hex string

Options:
  -p, --proof-fmt <FORMAT>
          Proof format
          
          [default: hex-string]

          Possible values:
          - json:       Json
          - bytes:      Bytes
          - hex-string: Hex String

  -h, --help
          Print help (see a summary with '-h')

  -V, --version
          Print version
```