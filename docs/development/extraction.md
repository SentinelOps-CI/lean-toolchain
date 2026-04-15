# Rust code generation

This project does **not** use compiler-backed extraction from Lean proof terms.

## How it works

| Piece | Role |
| --- | --- |
| `LeanToolchain/Extraction/CodeGenerator.lean` | Large string templates for `sha256.rs`, `hmac.rs`, `vector.rs`, `matrix.rs`, and `lib.rs` |
| `LeanToolchain/Extraction/Main.lean` | `lake exe extract` entrypoint: writes files, `rust/Cargo.toml`, and Criterion bench stubs under `rust/benches/` |

`CodeGenerator` intentionally avoids importing `LeanToolchain.Crypto.*` so the extractor does not pull the entire mathlib graph just to print strings.

## Outputs

- `rust/src/*.rs` — library sources (`rlib` + `cdylib` / `staticlib` in `Cargo.toml`).
- `rust/Cargo.toml` — package metadata and dev-dependency on Criterion for benches.
- `rust/benches/*.rs` — harness-less Criterion templates (regenerated each extract).

## Contract with Lean tests

The generated SHA-256 and HMAC implementations are checked against the **same** NIST and RFC 4231 vectors as `LeanToolchain/Crypto/Tests`, including integration tests in `rust/tests/crypto_parity.rs`.

Whenever you change `CodeGenerator.lean` or `Main.lean`, run `lake exe extract` and commit the resulting `rust/` tree if CI expects a committed artifact (current `.github/workflows/local-ci.yml` regenerates in CI as well).

## FFI and `unsafe`

C-shaped entrypoints are emitted as `pub unsafe extern "C"` functions. Callers must uphold pointer and length invariants described in the generated Rust sources.

## Further reading

- [Crypto API](../api/crypto.md) — Lean vs Rust responsibilities.
- [CI overview](ci.md) — where `lake exe extract` runs in automation.
