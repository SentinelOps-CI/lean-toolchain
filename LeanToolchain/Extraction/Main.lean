import LeanToolchain.Extraction.CodeGenerator
import Init.System.IO

/-!
# Lean Toolchain Extraction

This module provides the main entry point for extracting Lean code to Rust.
It handles the extraction of cryptographic primitives and mathematical operations.
-/

namespace LeanToolchain.Extraction

/-- Configuration for extraction -/
structure ExtractionConfig where
  outputDir : String := "rust/src"
  generateTests : Bool := true
  generateBenchmarks : Bool := true
  optimizeCode : Bool := true

/-- Extract SHA-256 implementation to Rust -/
def extractSHA256 (config : ExtractionConfig) : IO Unit := do
  IO.println "Extracting SHA-256 implementation to Rust..."

  let rustCode := generateSHA256Module
  let outputPath := config.outputDir ++ "/sha256.rs"
  IO.FS.writeFile outputPath rustCode
  IO.println s!"SHA-256 extracted to {outputPath}"

/-- Extract HMAC implementation to Rust -/
def extractHMAC (config : ExtractionConfig) : IO Unit := do
  IO.println "Extracting HMAC implementation to Rust..."

  let rustCode := generateHMACModule
  let outputPath := config.outputDir ++ "/hmac.rs"
  IO.FS.writeFile outputPath rustCode
  IO.println s!"HMAC extracted to {outputPath}"

/-- Extract Vector implementation to Rust -/
def extractVector (config : ExtractionConfig) : IO Unit := do
  IO.println "Extracting Vector implementation to Rust..."

  let rustCode := generateVectorModule
  let outputPath := config.outputDir ++ "/vector.rs"
  IO.FS.writeFile outputPath rustCode
  IO.println s!"Vector extracted to {outputPath}"

/-- Extract Matrix implementation to Rust -/
def extractMatrix (config : ExtractionConfig) : IO Unit := do
  IO.println "Extracting Matrix implementation to Rust..."

  let rustCode := generateMatrixModule
  let outputPath := config.outputDir ++ "/matrix.rs"
  IO.FS.writeFile outputPath rustCode
  IO.println s!"Matrix extracted to {outputPath}"

/-- Generate Cargo.toml for Rust project -/
def generateCargoToml (_ : ExtractionConfig) : IO Unit := do
  IO.println "Generating Cargo.toml..."

  let cargoToml :=
    "[package]
name = \"lean-toolchain-rust\"
version = \"0.1.0\"
edition = \"2021\"

[lib]
name = \"lean_toolchain_rust\"
crate-type = [\"rlib\", \"staticlib\", \"cdylib\"]

[dependencies]
# Add dependencies as needed for the extracted code

[dev-dependencies]
criterion = \"0.5\"

[[bench]]
name = \"sha256_bench\"
harness = false

[[bench]]
name = \"hmac_bench\"
harness = false

[[bench]]
name = \"vector_bench\"
harness = false

[[bench]]
name = \"matrix_bench\"
harness = false"

  let outputPath := "rust/Cargo.toml"
  IO.FS.writeFile outputPath cargoToml
  IO.println s!"Cargo.toml generated at {outputPath}"

/-- Generate lib.rs for Rust project -/
def generateLibRs (config : ExtractionConfig) : IO Unit := do
  IO.println "Generating lib.rs..."

  let libRs := generateCompleteRustLibrary
  let outputPath := config.outputDir ++ "/lib.rs"
  IO.FS.writeFile outputPath libRs
  IO.println s!"lib.rs generated at {outputPath}"

/-- Generate benchmark files -/
def generateBenchmarks (config : ExtractionConfig) : IO Unit := do
  if config.generateBenchmarks then
    IO.println "Generating benchmark files..."

    let sha256Bench :=
      "use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn sha256_benchmark(c: &mut Criterion) {
    let input = b\"The quick brown fox jumps over the lazy dog\";

    c.bench_function(\"sha256_hash\", |bencher| {
        bencher.iter(|| {
            black_box(sha256_hash(black_box(input as &[u8])));
        })
    });
}

criterion_group!(benches, sha256_benchmark);
criterion_main!(benches);"

    let hmacBench :=
      "use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn hmac_benchmark(c: &mut Criterion) {
    let key = b\"secret_key\";
    let message = b\"The quick brown fox jumps over the lazy dog\";

    c.bench_function(\"hmac_sha256\", |bencher| {
        bencher.iter(|| {
            black_box(hmac_sha256(
                black_box(key as &[u8]),
                black_box(message as &[u8]),
            ));
        })
    });
}

criterion_group!(benches, hmac_benchmark);
criterion_main!(benches);"

    let vectorBench :=
      "use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn vector_benchmark(c: &mut Criterion) {
    let a: Vec<f64> = (0..1000).map(|i| i as f64).collect();
    let b: Vec<f64> = (0..1000).map(|i| (i + 1) as f64).collect();
    let mut result = vec![0.0; 1000];

    c.bench_function(\"vector_add\", |bencher| {
        bencher.iter(|| {
            unsafe {
                vector_add(
                    black_box(a.as_ptr()),
                    black_box(b.as_ptr()),
                    result.as_mut_ptr(),
                    1000,
                );
            }
        })
    });

    c.bench_function(\"vector_dot_product\", |bencher| {
        bencher.iter(|| {
            black_box(unsafe { vector_dot_product(a.as_ptr(), b.as_ptr(), 1000) });
        })
    });
}

criterion_group!(benches, vector_benchmark);
criterion_main!(benches);"

    let matrixBench :=
      "use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn matrix_benchmark(c: &mut Criterion) {
    let size = 100;
    let a: Vec<f64> = (0..size*size).map(|i| i as f64).collect();
    let b: Vec<f64> = (0..size*size).map(|i| (i + 1) as f64).collect();
    let mut result = vec![0.0; size*size];

    c.bench_function(\"matrix_multiply\", |bencher| {
        bencher.iter(|| {
            unsafe {
                matrix_multiply(
                    black_box(a.as_ptr()),
                    black_box(b.as_ptr()),
                    result.as_mut_ptr(),
                    size,
                    size,
                    size,
                );
            }
        })
    });

    c.bench_function(\"matrix_transpose\", |bencher| {
        bencher.iter(|| {
            unsafe {
                matrix_transpose(black_box(a.as_ptr()), result.as_mut_ptr(), size, size);
            }
        })
    });
}

criterion_group!(benches, matrix_benchmark);
criterion_main!(benches);"

    IO.FS.writeFile "rust/benches/sha256_bench.rs" sha256Bench
    IO.FS.writeFile "rust/benches/hmac_bench.rs" hmacBench
    IO.FS.writeFile "rust/benches/vector_bench.rs" vectorBench
    IO.FS.writeFile "rust/benches/matrix_bench.rs" matrixBench

    IO.println "Benchmark files generated"

/-- Main extraction function -/
def extractAll (config : ExtractionConfig) : IO Unit := do
  IO.println "Starting Lean to Rust extraction..."
  IO.println "=================================="

  -- Create output directory
  IO.FS.createDirAll config.outputDir
  IO.FS.createDirAll "rust/benches"

  -- Extract all modules
  extractSHA256 config
  extractHMAC config
  extractVector config
  extractMatrix config

  -- Generate project files
  generateCargoToml config
  generateLibRs config
  generateBenchmarks config

  IO.println ""
  IO.println "Extraction completed successfully!"
  IO.println "Next steps:"
  IO.println "1. cd rust"
  IO.println "2. cargo build"
  IO.println "3. cargo test"
  IO.println "4. cargo bench"

end LeanToolchain.Extraction

/-- Lake `lean_exe` / `lean --run` entrypoint (must live in the root namespace). -/
def main : IO Unit := do
  let config : LeanToolchain.Extraction.ExtractionConfig := {}
  LeanToolchain.Extraction.extractAll config
