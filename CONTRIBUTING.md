# Contributing

Thank you for your interest in contributing to lean-toolchain.

## Getting started

- Fork the repository and clone your fork.
- Install Lean 4 and Rust (see `README.md`).
- From the repository root, run `lake build` and `lake test`.
- If you touch the Rust generator or templates, run `lake exe extract` and `cargo test` / `cargo clippy --all-targets -- -D warnings` inside `rust/`.

## Toolchain policy (Lean + mathlib)

The Lean version is pinned in `lean-toolchain`. **mathlib** is required in `lakefile.lean` with a git reference that matches that Lean release (for example the `v4.21.0` tag line). When you bump Lean:

1. Update `lean-toolchain`.
2. Update the mathlib `require` line to the corresponding mathlib tag or revision.
3. Run `lake update` and fix any breakage before opening a PR.

## `sorry` policy

Production code under `LeanToolchain/` is expected to contain **no** `sorry` placeholders. CI runs `scripts/check_sorry.sh`, which fails on any occurrence except files explicitly listed in `scripts/sorry_allowlist.txt` (whole-file waivers only, one repo-relative path per line; use sparingly and justify in the PR).

## Coding standards

- Follow `.editorconfig` for whitespace and indentation.
- For Lean: descriptive names, docstrings where they aid readers, and constructive proofs.
- For generated Rust: `pub unsafe extern "C"` entrypoints are used for FFI-shaped APIs; keep `unsafe` blocks minimal and obvious.

## Commit messages

- Prefer [Conventional Commits](https://www.conventionalcommits.org/).

## Pull requests

- Ensure `lake build`, `lake test`, and (if applicable) the `rust/` checks above succeed.
- Link related issues in the PR description.

## Code of conduct

- Be respectful and inclusive.

## Documentation

- **MkDocs**: configuration lives in [`docs/mkdocs.yml`](docs/mkdocs.yml); start from [`docs/index.md`](docs/index.md) for the full map.
- **CI details**: [`docs/development/ci.md`](docs/development/ci.md).
- **Rust generator**: [`docs/development/extraction.md`](docs/development/extraction.md).
- **Security scope**: [`SECURITY.md`](SECURITY.md).

## CI

Pushes and pull requests run a local GitHub Actions workflow (see `.github/workflows/local-ci.yml`) that builds Lean, runs tests, regenerates `rust/` with `lake exe extract`, runs `cargo test` / `cargo clippy`, and enforces the sorry policy. Additional organization checks may run via SentinelOps (`formal-verify.yml`).

For a concise overview of how those pieces fit together, see [`docs/development/ci.md`](docs/development/ci.md).
