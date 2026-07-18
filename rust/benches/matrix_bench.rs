use criterion::{black_box, criterion_group, criterion_main, Criterion};
use lean_toolchain_rust::*;

fn matrix_benchmark(c: &mut Criterion) {
    let size = 100;
    let a: Vec<f64> = (0..size*size).map(|i| i as f64).collect();
    let b: Vec<f64> = (0..size*size).map(|i| (i + 1) as f64).collect();
    let mut result = vec![0.0; size*size];

    c.bench_function("matrix_multiply", |bencher| {
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

    c.bench_function("matrix_transpose", |bencher| {
        bencher.iter(|| {
            unsafe {
                matrix_transpose(black_box(a.as_ptr()), result.as_mut_ptr(), size, size);
            }
        })
    });

    let n = 32usize;
    let dense: Vec<f64> = (0..n * n).map(|i| (i as f64) * 0.017 - 1.0).collect();
    c.bench_function("matrix_det_32", |bencher| {
        bencher.iter(|| unsafe { black_box(matrix_det(dense.as_ptr(), n)) })
    });
    c.bench_function("matrix_rank_32", |bencher| {
        bencher.iter(|| unsafe { black_box(matrix_rank(dense.as_ptr(), n, n)) })
    });
}

criterion_group!(benches, matrix_benchmark);
criterion_main!(benches);
