# Security

This repository contains educational and reference cryptographic code (SHA-256, HMAC-SHA256) in Lean 4 and a **generated** Rust crate produced by a template-based code generator. It is **not** positioned as a certified cryptographic product or a drop-in replacement for audited libraries such as [RustCrypto](https://github.com/RustCrypto) or platform crypto APIs.

## Reporting vulnerabilities

If you believe you have found a security vulnerability that affects this repository (for example, incorrect hashing or MAC behavior relative to the documented specification, or unsafe FFI in the generated Rust), please report it responsibly:

1. **Do not** open a public GitHub issue for undisclosed exploit details.
2. Email maintainers with a clear description, reproduction steps (Lean version, commit hash, inputs), and impact analysis.
3. Allow a reasonable window for triage before any public disclosure you intend to make.

If your concern is only about **SentinelOps** or other organization-hosted CI, contact that team through your usual internal channel; this file covers the **open-source tree** in this repository.

## Scope and expectations

- **Constant-time / side channels**: Neither the Lean reference nor the emitted Rust is claimed to be constant-time. Do not use it where timing or micro-architectural leakage is in scope.
- **Formal claims**: Theorems in `LeanToolchain/` are about the **Lean definitions** as written. Generated Rust is maintained to match agreed **test vectors** and intended behavior; it is not extracted from proof terms by the Lean compiler.
- **HMAC interoperability**: Long-key behavior follows the Lean definition documented in [`docs/api/crypto.md`](docs/api/crypto.md) and `LeanToolchain/Crypto/HMAC.lean`; do not assume every other implementation agrees for keys longer than 64 bytes without checking.
- **Dependencies**: Follow Dependabot updates and review changelogs for `rust/` and GitHub Actions, especially when touching crypto-adjacent code paths.

## Supported versions

Security-sensitive fixes, when accepted, are applied to the default branch (`main` / `master`) consistent with repository policy. There is no separate LTS line unless documented otherwise in `README.md`.
