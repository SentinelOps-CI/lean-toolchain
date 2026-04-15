# Quick start

From the repository root:

```bash
lake build
lake test
```

`lake test` runs the unified smoke driver (`lean_exe leanToolchainTests` in `lakefile.lean`), covering crypto and math IO tests.

### Focused executables

```bash
lake exe cryptoTests   # SHA-256 / HMAC tests only
lake exe mathTests     # Vector / matrix / norm tests only
lake exe benchmarks    # Lean-side benchmarks entrypoint
```

### Rust crate (generated)

```bash
lake exe extract
cd rust
cargo test
cargo clippy --all-targets -- -D warnings
```

`lake exe extract` overwrites generated sources under `rust/src/`, `rust/Cargo.toml`, and `rust/benches/` from `LeanToolchain/Extraction`. **Hand-written** integration tests live in `rust/tests/` (for example `crypto_parity.rs`) and are preserved across extract runs.

### Policy check (optional locally)

```bash
bash scripts/check_sorry.sh
```

This mirrors the first step of `.github/workflows/local-ci.yml`.
