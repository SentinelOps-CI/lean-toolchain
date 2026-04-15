//! Matrix operations extracted from Lean 4

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

    // Perform matrix multiplication
    for i in 0..m {
        for j in 0..p {
            for k in 0..n {
                result_slice[i * p + j] += a_slice[i * n + k] * b_slice[k * p + j];
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
            output_slice[j * rows + i] = input_slice[i * cols + j];
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
        // Expected: [[19, 22], [43, 50]]
        assert_eq!(result, [19.0, 22.0, 43.0, 50.0]);
    }
}