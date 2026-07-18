//! Matrix operations extracted from Lean 4
//!
//! Dense row-major `f64` kernels aligned with `LeanToolchain.Math.Matrix`:
//! addition, multiply, transpose, Bareiss determinant, Gaussian rank, and Gauss–Jordan inverse.

#[inline]
fn idx(row: usize, col: usize, cols: usize) -> usize {
    row * cols + col
}

#[no_mangle]
pub unsafe extern "C" fn matrix_add(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    rows: usize,
    cols: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let len = rows * cols;
    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] + b_slice[i];
    }

    0
}

#[no_mangle]
pub unsafe extern "C" fn matrix_multiply(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    m: usize,
    n: usize,
    p: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, m * n) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, n * p) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, m * p) };

    result_slice.fill(0.0);

    for i in 0..m {
        for k in 0..n {
            let aik = a_slice[idx(i, k, n)];
            for j in 0..p {
                result_slice[idx(i, j, p)] += aik * b_slice[idx(k, j, p)];
            }
        }
    }

    0
}

#[no_mangle]
pub unsafe extern "C" fn matrix_transpose(
    input: *const f64,
    output: *mut f64,
    rows: usize,
    cols: usize
) -> i32 {
    if input.is_null() || output.is_null() {
        return -1;
    }

    let input_slice = unsafe { std::slice::from_raw_parts(input, rows * cols) };
    let output_slice = unsafe { std::slice::from_raw_parts_mut(output, rows * cols) };

    for i in 0..rows {
        for j in 0..cols {
            output_slice[idx(j, i, rows)] = input_slice[idx(i, j, cols)];
        }
    }

    0
}

fn find_pivot(a: &[f64], nrows: usize, ncols: usize, start_row: usize, col: usize) -> Option<usize> {
    let mut best = None;
    let mut best_abs = 0.0_f64;
    for r in start_row..nrows {
        let v = a[idx(r, col, ncols)].abs();
        if v > best_abs {
            best_abs = v;
            best = Some(r);
        }
    }
    if best_abs == 0.0 {
        None
    } else {
        best
    }
}

fn swap_rows(a: &mut [f64], ncols: usize, r1: usize, r2: usize, width: usize) {
    if r1 == r2 {
        return;
    }
    for c in 0..width {
        a.swap(idx(r1, c, ncols), idx(r2, c, ncols));
    }
}

/// Bareiss fraction-free determinant (matches Lean `Matrix.det`).
#[no_mangle]
pub unsafe extern "C" fn matrix_det(a: *const f64, n: usize) -> f64 {
    if a.is_null() {
        return f64::NAN;
    }
    if n == 0 {
        return 1.0;
    }
    let mut m = unsafe { std::slice::from_raw_parts(a, n * n) }.to_vec();
    let mut sign = 1.0_f64;
    let mut prev_pivot = 1.0_f64;
    for k in 0..n {
        match find_pivot(&m, n, n, k, k) {
            None => return 0.0,
            Some(piv) => {
                if piv != k {
                    swap_rows(&mut m, n, k, piv, n);
                    sign = -sign;
                }
                let akk = m[idx(k, k, n)];
                if akk == 0.0 {
                    return 0.0;
                }
                for i in (k + 1)..n {
                    for j in (k + 1)..n {
                        let numer = akk * m[idx(i, j, n)] - m[idx(i, k, n)] * m[idx(k, j, n)];
                        m[idx(i, j, n)] = numer / prev_pivot;
                    }
                }
                prev_pivot = akk;
            }
        }
    }
    sign * m[idx(n - 1, n - 1, n)]
}

/// Gaussian-elimination rank (partial pivoting).
#[no_mangle]
pub unsafe extern "C" fn matrix_rank(a: *const f64, rows: usize, cols: usize) -> usize {
    if a.is_null() {
        return 0;
    }
    let mut m = unsafe { std::slice::from_raw_parts(a, rows * cols) }.to_vec();
    let mut rank = 0usize;
    let mut row = 0usize;
    let mut col = 0usize;
    while row < rows && col < cols {
        match find_pivot(&m, rows, cols, row, col) {
            None => {
                col += 1;
            }
            Some(piv_row) => {
                for c in 0..cols {
                    m.swap(idx(row, c, cols), idx(piv_row, c, cols));
                }
                let pivot = m[idx(row, col, cols)];
                for i in (row + 1)..rows {
                    let factor = m[idx(i, col, cols)] / pivot;
                    if factor != 0.0 {
                        for j in col..cols {
                            m[idx(i, j, cols)] -= factor * m[idx(row, j, cols)];
                        }
                    }
                }
                rank += 1;
                row += 1;
                col += 1;
            }
        }
    }
    rank
}

/// Gauss–Jordan inverse. Returns 0 on success and writes into `out` (n×n).
/// Returns -1 on null pointers and -2 if the matrix is singular.
#[no_mangle]
pub unsafe extern "C" fn matrix_inv(a: *const f64, out: *mut f64, n: usize) -> i32 {
    if a.is_null() || out.is_null() {
        return -1;
    }
    if n == 0 {
        return 0;
    }
    let src = unsafe { std::slice::from_raw_parts(a, n * n) };
    let mut aug = vec![0.0_f64; n * 2 * n];
    for i in 0..n {
        for j in 0..n {
            aug[idx(i, j, 2 * n)] = src[idx(i, j, n)];
            aug[idx(i, n + j, 2 * n)] = if i == j { 1.0 } else { 0.0 };
        }
    }
    let width = 2 * n;
    for col in 0..n {
        match find_pivot(&aug, n, width, col, col) {
            None => return -2,
            Some(piv) => {
                for c in 0..width {
                    aug.swap(idx(col, c, width), idx(piv, c, width));
                }
                let pivot = aug[idx(col, col, width)];
                if pivot == 0.0 {
                    return -2;
                }
                for j in 0..width {
                    aug[idx(col, j, width)] /= pivot;
                }
                for i in 0..n {
                    if i != col {
                        let factor = aug[idx(i, col, width)];
                        if factor != 0.0 {
                            for j in 0..width {
                                aug[idx(i, j, width)] -= factor * aug[idx(col, j, width)];
                            }
                        }
                    }
                }
            }
        }
    }
    let out_slice = unsafe { std::slice::from_raw_parts_mut(out, n * n) };
    for i in 0..n {
        for j in 0..n {
            out_slice[idx(i, j, n)] = aug[idx(i, n + j, width)];
        }
    }
    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_matrix_add() {
        let a = [1.0, 2.0, 3.0, 4.0];
        let b = [5.0, 6.0, 7.0, 8.0];
        let mut result = [0.0_f64; 4];

        let res = unsafe { matrix_add(a.as_ptr(), b.as_ptr(), result.as_mut_ptr(), 2, 2) };
        assert_eq!(res, 0);
        assert_eq!(result, [6.0, 8.0, 10.0, 12.0]);
    }

    #[test]
    fn test_matrix_multiply() {
        let a = [1.0, 2.0, 3.0, 4.0];
        let b = [5.0, 6.0, 7.0, 8.0];
        let mut result = [0.0_f64; 4];

        let res = unsafe { matrix_multiply(a.as_ptr(), b.as_ptr(), result.as_mut_ptr(), 2, 2, 2) };
        assert_eq!(res, 0);
        assert_eq!(result, [19.0, 22.0, 43.0, 50.0]);
    }

    #[test]
    fn test_matrix_det_rank_inv() {
        let a = [1.0, 2.0, 3.0, 4.0];
        let det = unsafe { matrix_det(a.as_ptr(), 2) };
        assert!((det + 2.0).abs() < 1e-9);
        assert_eq!(unsafe { matrix_rank(a.as_ptr(), 2, 2) }, 2);

        let uni = [2.0, 1.0, 5.0, 3.0];
        let mut inv = [0.0_f64; 4];
        let rc = unsafe { matrix_inv(uni.as_ptr(), inv.as_mut_ptr(), 2) };
        assert_eq!(rc, 0);
        assert!((inv[0] - 3.0).abs() < 1e-9);
        assert!((inv[1] + 1.0).abs() < 1e-9);
        assert!((inv[2] + 5.0).abs() < 1e-9);
        assert!((inv[3] - 2.0).abs() < 1e-9);
    }
}