# Installation

## Lean 4

Install [Elan](https://github.com/leanprover/elan) and a compatible Lean toolchain. This repository pins Lean in the `lean-toolchain` file at the repo root (for example `leanprover/lean4:v4.21.0`).

```bash
git clone https://github.com/SentinelOps-CI/lean-toolchain.git
cd lean-toolchain
lake build
```

The first `lake build` downloads **mathlib** and other dependencies; expect a long compile on a cold cache.

## Rust (optional)

Required if you work on the generated crate or run parity tests:

1. Install [Rust](https://rustup.rs/) (stable).
2. After Lean changes to the extractor or templates, run `lake exe extract`, then `cargo test` (and `cargo clippy --all-targets -- -D warnings` if you touch Rust) inside `rust/`.

## Documentation tools (optional)

To build the MkDocs site from the same machine:

```bash
pip install mkdocs-material
mkdocs build -f docs/mkdocs.yml
```

See [Documentation home](../index.md) for what the pages cover.
