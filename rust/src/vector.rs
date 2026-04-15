//! Vector operations extracted from Lean 4

#[no_mangle]
pub unsafe extern "C" fn vector_add(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    len: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] + b_slice[i];
    }

    0
}

#[no_mangle]
pub unsafe extern "C" fn vector_sub(
    a: *const f64,
    b: *const f64,
    result: *mut f64,
    len: usize
) -> i32 {
    if a.is_null() || b.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] - b_slice[i];
    }

    0
}

#[no_mangle]
pub unsafe extern "C" fn vector_smul(
    a: *const f64,
    scalar: f64,
    result: *mut f64,
    len: usize
) -> i32 {
    if a.is_null() || result.is_null() {
        return -1;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let result_slice = unsafe { std::slice::from_raw_parts_mut(result, len) };

    for i in 0..len {
        result_slice[i] = a_slice[i] * scalar;
    }

    0
}

#[no_mangle]
pub unsafe extern "C" fn vector_dot_product(
    a: *const f64,
    b: *const f64,
    len: usize
) -> f64 {
    if a.is_null() || b.is_null() {
        return 0.0;
    }

    let a_slice = unsafe { std::slice::from_raw_parts(a, len) };
    let b_slice = unsafe { std::slice::from_raw_parts(b, len) };

    let mut result = 0.0;
    for i in 0..len {
        result += a_slice[i] * b_slice[i];
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vector_add() {
        let a = [1.0, 2.0, 3.0];
        let b = [4.0, 5.0, 6.0];
        let mut result = [0.0_f64; 3];

        let res = unsafe { vector_add(a.as_ptr(), b.as_ptr(), result.as_mut_ptr(), 3) };
        assert_eq!(res, 0);
        assert_eq!(result, [5.0, 7.0, 9.0]);
    }

    #[test]
    fn test_vector_dot_product() {
        let a = [1.0, 2.0, 3.0];
        let b = [4.0, 5.0, 6.0];

        let result = unsafe { vector_dot_product(a.as_ptr(), b.as_ptr(), 3) };
        assert_eq!(result, 32.0);
    }
}