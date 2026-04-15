# Lean Toolchain documentation

This site tracks the **Lean 4** library in this repository: cryptographic primitives (`LeanToolchain/Crypto`), discrete linear algebra (`LeanToolchain/Math`), benchmarks, and the **template-based Rust generator** behind the `rust/` crate.

## Start here

| Topic | Where to read |
| --- | --- |
| Clone, build, first commands | [Quick start](getting-started/quick-start.md) |
| Lean, Elan, Rust setup | [Installation](getting-started/installation.md) |
| Contributing rules, toolchain bumps, `sorry` policy | [Contributing](development/contributing.md) (links to repo root) |
| SentinelOps vs GitHub Actions | [CI overview](development/ci.md) |
| What `lake exe extract` actually does | [Rust code generation](development/extraction.md) |
| Lean coding style, proof tips | [Style guide](development/style-guide.md) |
| Crypto API (Lean + generated Rust contract) | [Crypto API](api/crypto.md) |
| Vectors, matrices, norms (Lean) | [Math API](api/math.md) |
| `Vec` design notes | [Vector implementation](vector-implementation.md) |

## Repository entrypoints

- **Root README**: [README.md](https://github.com/SentinelOps-CI/lean-toolchain/blob/main/README.md) (overview, layout, security pointer).
- **Security expectations**: [SECURITY.md](https://github.com/SentinelOps-CI/lean-toolchain/blob/main/SECURITY.md).

## Building these docs

From the repository root (with `mkdocs` and the Material theme installed, for example `pip install mkdocs-material`):

```bash
mkdocs build -f docs/mkdocs.yml
```

The HTML output defaults to `site/` relative to the current working directory unless overridden in your `mkdocs` setup.

## Toolchain

The Lean release is pinned in `lean-toolchain`; **mathlib** is pinned in `lakefile.lean` and must stay compatible with that Lean version.
