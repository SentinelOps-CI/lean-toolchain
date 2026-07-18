# Cryptographic API (Lean)

## What this module is

`LeanToolchain.Crypto` implements **SHA-256** and **HMAC-SHA256** as executable Lean definitions, with supporting byte utilities. Theorems in this tree are about those **Lean definitions** (length schedules, key preparation cases, determinism of verification, and similar structural facts).

This documentation describes the **Lean API**. It does **not** claim FIPS-140 or Common Criteria certification, constant-time execution, or resistance to side channels.

## Rust artifacts (code generation)

A **template-based** Rust crate under `rust/` is produced by `lake exe extract`. It is kept aligned with the same **NIST** and **RFC 4231** vectors as `LeanToolchain/Crypto/Tests` (see also `rust/tests/crypto_parity.rs`). That is **maintained parallel code**, not compiler-backed extraction from proof terms. Details: [`development/extraction.md`](../development/extraction.md).

## HMAC key handling (interop note)

For keys longer than the SHA-256 block size (64 bytes), this repository’s `hmacPrepareKey` hashes the key to a **32-byte** digest and uses that value directly with `ipad` / `opad`, rather than zero-padding that digest back to 64 bytes as in RFC 2104’s literal text. For keys of length at most 64 bytes, behavior matches standard vectors (including those used in `HMACTests.lean`). See the module docstring in `LeanToolchain/Crypto/HMAC.lean`.

## SHA-256

### `sha256 : ByteArray → ByteArray`

Computes the SHA-256 digest (32 bytes) of a message using the in-repo padding and compression definitions.

### `sha256String : String → String`

UTF-8 encodes the string, hashes with `sha256`, and returns lowercase hexadecimal.

### `sha256Verify : ByteArray → String → Bool`

Compares `bytesToHex (sha256 message)` to `expected` (caller supplies hex in the same format as `bytesToHex`).

## HMAC-SHA256

### `hmacSha256 : ByteArray → ByteArray → ByteArray`

Computes HMAC-SHA256 from the definitions in `HMAC.lean` (see key-handling note above).

### `hmacSha256String : String → String → String`

String convenience layer over UTF-8 bytes.

### `hmacSha256Verify : ByteArray → ByteArray → String → Bool`

Equality check against an expected hex signature.

### `hmacSha256Hex : String → String → Option String`

Parses hex-encoded key and message; returns `none` if parsing fails.

## Utilities (`Utils.lean`)

Common helpers include `stringToBytes`, `bytesToHex`, `hexToBytes`, `padMessage` (SHA padding on `ByteArray`), and related list/array lemmas used in proofs.

## Testing

Executable tests live under `LeanToolchain/Crypto/Tests/` and are run from the combined driver configured for `lake test` (see `LeanToolchain/Tests/Unified.lean`). They include NIST SHA-256 strings and RFC 4231 HMAC cases and **abort the process** on any vector mismatch (CI-hard failure, not print-only).

Lean-side timing experiments (if any) are wired through `lake exe benchmarks` from `LeanToolchain/Benchmarks/`; they are separate from the Rust Criterion benches under `rust/benches/`.

## Operational expectations (Lean vs generated Rust)

| Topic | Lean definitions | Generated Rust (`rust/`) |
| --- | --- | --- |
| Pointers / FFI | N/A (pure `ByteArray`) | C-shaped `extern "C"` entrypoints are **`unsafe`**; callers must enforce invariants documented in generated sources. |
| Threading | Pure functional code | Same as any Rust library: shared mutability is the caller’s responsibility. |
| Timing attacks | Not modeled or claimed | Not claimed constant-time. |

For vulnerability reporting, see the repository [`SECURITY.md`](https://github.com/SentinelOps-CI/lean-toolchain/blob/main/SECURITY.md).
