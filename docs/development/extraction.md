# Rust code generation

This project does **not** use compiler-backed extraction from Lean proof terms.

## How it works

| Piece | Role |
| --- | --- |
| `LeanToolchain/Extraction/CodeGenerator.lean` | String templates for `sha256.rs`, `hmac.rs`, `vector.rs`, `matrix.rs`, and `lib.rs` |
| `LeanToolchain/Extraction/Main.lean` | `lake exe extract` entrypoint: writes sources, `rust/Cargo.toml`, and Criterion benches under `rust/benches/` |

`CodeGenerator` intentionally avoids importing `LeanToolchain.Crypto.*` so the extractor does not pull the entire mathlib graph just to print strings.

## Outputs

- `rust/src/*.rs` — library sources (`rlib` + `cdylib` / `staticlib` in `Cargo.toml`).
- `rust/Cargo.toml` — package metadata and Criterion as a dev-dependency for benches.
- `rust/benches/*.rs` — Criterion harnesses for SHA-256, HMAC, vector, and matrix kernels (regenerated each extract).

Matrix kernels currently include add, multiply (ikj), transpose, Bareiss determinant, Gaussian rank, and Gauss–Jordan inverse, with unit tests in `matrix.rs`.

## Contract with Lean tests

The generated SHA-256 and HMAC implementations are checked against the **same** NIST and RFC 4231 vectors as `LeanToolchain/Crypto/Tests`, including integration tests in `rust/tests/crypto_parity.rs`. Matrix unit tests mirror the Lean determinant / rank / inverse examples used in `MatrixTests.lean`.

Whenever you change `CodeGenerator.lean` or `Main.lean`, run `lake exe extract` and commit the resulting `rust/` tree if CI expects a committed artifact (current `.github/workflows/local-ci.yml` regenerates in CI as well).

## FFI and `unsafe`

C-shaped entrypoints are emitted as `pub unsafe extern "C"` functions. Callers must uphold pointer and length invariants described in the generated Rust sources.

## Design decision: templates vs true extraction

Compiler-backed Lean-to-Rust/C extraction exists in research tooling but is heavyweight for this library’s mix of `ByteArray` crypto and mathlib-backed `ℝ` norms. This repository intentionally keeps **maintained template emission** plus shared NIST/RFC vectors as the contract between Lean and Rust. Revisit true extraction only if a future subset is pure executable Lean without mathlib `Real`.

## Further reading

- [Crypto API](../api/crypto.md) — Lean vs Rust responsibilities.
- [Math API](../api/math.md) — Lean matrix algorithms mirrored in Rust.
- [CI overview](ci.md) — where `lake exe extract` runs in automation.
