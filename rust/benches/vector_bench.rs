use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn vector_benchmark(c: &mut Criterion) {
    let a: Vec<f64> = (0..1000).map(|i| i as f64).collect();
    let b: Vec<f64> = (0..1000).map(|i| (i + 1) as f64).collect();
    let mut result = vec![0.0; 1000];

    c.bench_function("vector_add", |bencher| {
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

    c.bench_function("vector_dot_product", |bencher| {
        bencher.iter(|| {
            black_box(unsafe { vector_dot_product(a.as_ptr(), b.as_ptr(), 1000) });
        })
    });
}

criterion_group!(benches, vector_benchmark);
criterion_main!(benches);