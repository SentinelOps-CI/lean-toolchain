use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn sha256_benchmark(c: &mut Criterion) {
    let input = b"The quick brown fox jumps over the lazy dog";

    c.bench_function("sha256_hash", |bencher| {
        bencher.iter(|| {
            black_box(sha256_hash(black_box(input as &[u8])));
        })
    });
}

criterion_group!(benches, sha256_benchmark);
criterion_main!(benches);