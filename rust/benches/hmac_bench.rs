use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn hmac_benchmark(c: &mut Criterion) {
    let key = b"secret_key";
    let message = b"The quick brown fox jumps over the lazy dog";

    c.bench_function("hmac_sha256", |bencher| {
        bencher.iter(|| {
            black_box(hmac_sha256(
                black_box(key as &[u8]),
                black_box(message as &[u8]),
            ));
        })
    });
}

criterion_group!(benches, hmac_benchmark);
criterion_main!(benches);