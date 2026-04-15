//! Integration tests mirroring `LeanToolchain/Crypto/Tests` vectors (NIST SHA-256, RFC 4231 HMAC).

use lean_toolchain_rust::{hmac_sha256, sha256_hash};

fn hex_decode(s: &str) -> Vec<u8> {
    assert_eq!(
        s.len() % 2,
        0,
        "hex string must have even length: {s:?}"
    );
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16).unwrap_or_else(|_| {
            panic!("invalid hex at {} in {:?}", i, s);
        }))
        .collect()
}

fn hex_decode_fixed<const N: usize>(s: &str) -> [u8; N] {
    let v = hex_decode(s);
    assert_eq!(v.len(), N, "wrong decoded length for {s:?}");
    let mut out = [0u8; N];
    out.copy_from_slice(&v);
    out
}

#[test]
fn nist_sha256_vectors_match_lean_tests() {
    let cases = [
        (
            "",
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        ),
        (
            "abc",
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        ),
        (
            "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
            "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
        ),
        (
            "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
            "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1",
        ),
    ];
    for (msg, want_hex) in cases {
        let got = sha256_hash(msg.as_bytes());
        let want = hex_decode_fixed::<32>(want_hex);
        assert_eq!(got, want, "SHA256 mismatch for message len {}", msg.len());
    }
}

#[test]
fn rfc4231_hmac_vectors_match_lean_tests() {
    let cases = [
        (
            "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
            "4869205468657265",
            "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
        ),
        (
            "4a656665",
            "7768617420646f2079612077616e7420666f72206e6f7468696e673f",
            "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
        ),
        (
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
            "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe",
        ),
        (
            "0102030405060708090a0b0c0d0e0f10111213141516171819",
            "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd",
            "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b",
        ),
    ];
    for (key_hex, msg_hex, want_hex) in cases {
        let key = hex_decode(key_hex);
        let msg = hex_decode(msg_hex);
        let got = hmac_sha256(&key, &msg);
        let want = hex_decode_fixed::<32>(want_hex);
        assert_eq!(
            got, want,
            "HMAC mismatch key_hex={key_hex} msg_hex={msg_hex}"
        );
    }
}
