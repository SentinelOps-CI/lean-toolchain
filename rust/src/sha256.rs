//! SHA-256 implementation extracted from Lean 4
//!
//! This module contains a complete SHA-256 implementation that matches
//! the behavior of the Lean 4 implementation.

// SHA-256 initial hash values
const SHA256_INITIAL_HASH: [u32; 8] = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
];

// SHA-256 round constants
const SHA256_ROUND_CONSTANTS: [u32; 64] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
];

// SHA-256 utility functions
fn rotate_right(x: u32, n: u32) -> u32 {
    (x >> n) | (x << (32 - n))
}

fn shift_right(x: u32, n: u32) -> u32 {
    x >> n
}

fn ch(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ (!x & z)
}

fn maj(x: u32, y: u32, z: u32) -> u32 {
    (x & y) ^ (x & z) ^ (y & z)
}

fn sigma0(x: u32) -> u32 {
    rotate_right(x, 2) ^ rotate_right(x, 13) ^ rotate_right(x, 22)
}

fn sigma1(x: u32) -> u32 {
    rotate_right(x, 6) ^ rotate_right(x, 11) ^ rotate_right(x, 25)
}

fn sigma0_prime(x: u32) -> u32 {
    rotate_right(x, 7) ^ rotate_right(x, 18) ^ shift_right(x, 3)
}

fn sigma1_prime(x: u32) -> u32 {
    rotate_right(x, 17) ^ rotate_right(x, 19) ^ shift_right(x, 10)
}

fn generate_message_schedule(block: &[u8; 64]) -> [u32; 64] {
    let mut w = [0u32; 64];

    // Convert block to 16 32-bit words (big-endian)
    for i in 0..16 {
        w[i] = ((block[i * 4] as u32) << 24) |
               ((block[i * 4 + 1] as u32) << 16) |
               ((block[i * 4 + 2] as u32) << 8) |
               (block[i * 4 + 3] as u32);
    }

    // Generate remaining 48 words
    for i in 16..64 {
        w[i] = w[i - 16]
            .wrapping_add(sigma0_prime(w[i - 15]))
            .wrapping_add(w[i - 7])
            .wrapping_add(sigma1_prime(w[i - 2]));
    }

    w
}

fn sha256_compress(hash: &mut [u32; 8], block: &[u8; 64]) {
    let w = generate_message_schedule(block);

    let mut a = hash[0];
    let mut b = hash[1];
    let mut c = hash[2];
    let mut d = hash[3];
    let mut e = hash[4];
    let mut f = hash[5];
    let mut g = hash[6];
    let mut h = hash[7];

    for i in 0..64 {
        let s1 = sigma1(e);
        let ch_val = ch(e, f, g);
        let temp1 = h
            .wrapping_add(s1)
            .wrapping_add(ch_val)
            .wrapping_add(SHA256_ROUND_CONSTANTS[i])
            .wrapping_add(w[i]);

        let s0 = sigma0(a);
        let maj_val = maj(a, b, c);
        let temp2 = s0.wrapping_add(maj_val);

        h = g;
        g = f;
        f = e;
        e = d.wrapping_add(temp1);
        d = c;
        c = b;
        b = a;
        a = temp1.wrapping_add(temp2);
    }

    hash[0] = hash[0].wrapping_add(a);
    hash[1] = hash[1].wrapping_add(b);
    hash[2] = hash[2].wrapping_add(c);
    hash[3] = hash[3].wrapping_add(d);
    hash[4] = hash[4].wrapping_add(e);
    hash[5] = hash[5].wrapping_add(f);
    hash[6] = hash[6].wrapping_add(g);
    hash[7] = hash[7].wrapping_add(h);
}

fn pad_message(message: &[u8]) -> Vec<u8> {
    let message_len = message.len();
    let message_len_bits = (message_len * 8) as u64;

    // Calculate padding length
    let padding_len = if message_len % 64 < 56 {
        56 - (message_len % 64)
    } else {
        120 - (message_len % 64)
    };

    let mut padded = Vec::with_capacity(message_len + padding_len + 8);
    padded.extend_from_slice(message);

    // Add 1-bit (0x80)
    padded.push(0x80);

    // Add zero padding
    padded.extend(std::iter::repeat(0u8).take(padding_len - 1));

    // Add 64-bit length (big-endian)
    padded.extend_from_slice(&message_len_bits.to_be_bytes());

    padded
}

pub fn sha256_hash(input: &[u8]) -> [u8; 32] {
    let padded = pad_message(input);
    let mut hash = SHA256_INITIAL_HASH;

    // Process each 512-bit block
    for chunk in padded.chunks_exact(64) {
        let mut block = [0u8; 64];
        block.copy_from_slice(chunk);
        sha256_compress(&mut hash, &block);
    }

    // Convert hash to bytes (big-endian)
    let mut result = [0u8; 32];
    for i in 0..8 {
        let bytes = hash[i].to_be_bytes();
        result[i * 4] = bytes[0];
        result[i * 4 + 1] = bytes[1];
        result[i * 4 + 2] = bytes[2];
        result[i * 4 + 3] = bytes[3];
    }

    result
}

#[no_mangle]
pub unsafe extern "C" fn sha256_hash_c(input: *const u8, input_len: usize, output: *mut u8) -> i32 {
    if input.is_null() || output.is_null() {
        return -1;
    }

    let input_slice = unsafe { std::slice::from_raw_parts(input, input_len) };
    let output_slice = unsafe { std::slice::from_raw_parts_mut(output, 32) };

    let hash = sha256_hash(input_slice);
    output_slice.copy_from_slice(&hash);

    0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sha256_empty() {
        let input = b"";
        let expected = [
            0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14,
            0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f, 0xb9, 0x24,
            0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c,
            0xa4, 0x95, 0x99, 0x1b, 0x78, 0x52, 0xb8, 0x55
        ];
        let result = sha256_hash(input);
        assert_eq!(result, expected);
    }

    #[test]
    fn test_sha256_abc() {
        let input = b"abc";
        let expected = [
            0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
            0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
            0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
            0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad
        ];
        let result = sha256_hash(input);
        assert_eq!(result, expected);
    }

    #[test]
    fn test_sha256_quick_brown_fox() {
        let input = b"The quick brown fox jumps over the lazy dog";
        let expected = [
            0xd7, 0xa8, 0xfb, 0xb3, 0x07, 0xd7, 0x80, 0x94,
            0x69, 0xca, 0x9a, 0xbc, 0xb0, 0x08, 0x2e, 0x4f,
            0x8d, 0x56, 0x51, 0xe4, 0x6d, 0x3c, 0xdb, 0x76,
            0x2d, 0x02, 0xd0, 0xbf, 0x37, 0xc9, 0xe5, 0x92
        ];
        let result = sha256_hash(input);
        assert_eq!(result, expected);
    }
}