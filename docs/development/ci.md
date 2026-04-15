# Continuous integration

This repository uses **two complementary** mechanisms.

## SentinelOps (`formal-verify.yml`)

The workflow [`.github/workflows/formal-verify.yml`](https://github.com/SentinelOps-CI/lean-toolchain/blob/main/.github/workflows/formal-verify.yml) dispatches to **SentinelOps** remote CI. That path may enforce organization-wide policy, secrets, or resource tiers that are not visible from a public fork.

## Local GitHub Actions (`local-ci.yml`)

The workflow [`.github/workflows/local-ci.yml`](https://github.com/SentinelOps-CI/lean-toolchain/blob/main/.github/workflows/local-ci.yml) runs on **GitHub-hosted** `ubuntu-22.04` and `macos-14` and is the **reproducible** check contributors can mirror locally. Job order:

1. **`bash scripts/check_sorry.sh`** — fails on `sorry` in `LeanToolchain/` except whole-file entries in `scripts/sorry_allowlist.txt`.
2. **`lake build`** — default Lake targets (including mathlib-backed modules).
3. **`lake test`** — `leanToolchainTests` unified driver (crypto + math smoke tests).
4. **`lake exe extract`** — refresh generated `rust/` sources and manifests.
5. **`cargo test`** and **`cargo clippy --all-targets -- -D warnings`** — from the `rust/` directory.

Toolchains: **Lean** via [`leanprover/lean-action`](https://github.com/leanprover/lean-action), **Rust** via [`dtolnay/rust-toolchain`](https://github.com/dtolnay/rust-toolchain) with Clippy enabled.

## Dependabot

[`.github/dependabot.yml`](https://github.com/SentinelOps-CI/lean-toolchain/blob/main/.github/dependabot.yml) opens weekly update PRs for GitHub Actions and `rust/` Cargo dependencies.

