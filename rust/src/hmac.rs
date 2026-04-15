//! HMAC-SHA256 implementation extracted from Lean 4

use super::sha256::sha256_hash;

const HMAC_OUTER_PAD: u8 = 0x5c;
const HMAC_INNER_PAD: u8 = 0x36;
const SHA256_BLOCK_SIZE: usize = 64;

fn xor_with_constant(bytes: &[u8; SHA256_BLOCK_SIZE], constant: u8) -> [u8; SHA256_BLOCK_SIZE] {
    let mut result = [0u8; SHA256_BLOCK_SIZE];
    for i in 0..SHA256_BLOCK_SIZE {
        result[i] = bytes[i] ^ constant;
    }
    result
}

/// XOR each byte with `constant` (used when the prepared key is a 32-byte digest).
fn xor_digest(bytes: &[u8; 32], constant: u8) -> [u8; 32] {
    let mut out = [0u8; 32];
    for i in 0..32 {
        out[i] = bytes[i] ^ constant;
    }
    out
}

pub fn hmac_sha256(key: &[u8], message: &[u8]) -> [u8; 32] {
    // Match `LeanToolchain.Crypto.hmacPrepareKey`: long keys become a 32-byte digest;
    // short keys are zero-padded to one block before XOR with ipad/opad.
    let (inner_key, outer_key): (Vec<u8>, Vec<u8>) = if key.len() > SHA256_BLOCK_SIZE {
        let d = sha256_hash(key);
        let ik = xor_digest(&d, HMAC_INNER_PAD);
        let ok = xor_digest(&d, HMAC_OUTER_PAD);
        (ik.to_vec(), ok.to_vec())
    } else {
        let mut prepared = [0u8; SHA256_BLOCK_SIZE];
        prepared[..key.len()].copy_from_slice(key);
        let ik = xor_with_constant(&prepared, HMAC_INNER_PAD);
        let ok = xor_with_constant(&prepared, HMAC_OUTER_PAD);
        (ik.to_vec(), ok.to_vec())
    };

    let mut inner_input = Vec::with_capacity(inner_key.len() + message.len());
    inner_input.extend_from_slice(&inner_key);
    inner_input.extend_from_slice(message);
    let inner_hash = sha256_hash(&inner_input);

    let mut outer_input = Vec::with_capacity(outer_key.len() + 32);
    outer_input.extend_from_slice(&outer_key);
    outer_input.extend_from_slice(&inner_hash);
    sha256_hash(&outer_input)
}

#[no_mangle]
pub unsafe extern "C" fn hmac_sha256_c(
    key: *const u8,
    key_len: usize,
    message: *const u8,
    message_len: usize,
    output: *mut u8
) -> i32 {
    if key.is_null() || message.is_null() || output.is_null() {
        return -1;
    }

    let key_slice = unsafe { std::slice::from_raw_parts(key, key_len) };
    let message_slice = unsafe { std::slice::from_raw_parts(message, message_len) };
    let output_slice = unsafe { std::slice::from_raw_parts_mut(output, 32) };

    let hmac = hmac_sha256(key_slice, message_slice);
    output_slice.copy_from_slice(&hmac);

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hmac_basic() {
        let key = b"key";
        let message = b"The quick brown fox jumps over the lazy dog";
        let expected = [
            0xf7, 0xbc, 0x83, 0xf4, 0x30, 0x53, 0x84, 0x24,
            0xb1, 0x32, 0x98, 0xe6, 0xaa, 0x6f, 0xb1, 0x43,
            0xef, 0x4d, 0x59, 0xa1, 0x49, 0x46, 0x17, 0x59,
            0x97, 0x47, 0x9d, 0xbc, 0x2d, 0x1a, 0x3c, 0xd8
        ];
        let result = hmac_sha256(key, message);
        assert_eq!(result, expected);
    }
}