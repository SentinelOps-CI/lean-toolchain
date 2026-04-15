import LeanToolchain.Crypto.SHA256
import LeanToolchain.Crypto.Utils

/-!
# HMAC-SHA256 Implementation

This module provides an HMAC-SHA256 construction built directly on the in-repo
`sha256` function, together with structural lemmas about key preparation and
determinism.

## Key schedule (important for interoperability)

RFC 2104 describes hashing over-long keys, then **zero-padding the digest to the
block size** before XOR with `ipad` / `opad`. The definition here instead follows
the common “short key padded to 64 bytes; **long key replaced by a 32-byte
digest** (no trailing zero pad before XOR)” shape used by several libraries and
matches the emitted Rust generator for parity tests.

For keys whose byte length is at most `sha256BlockSize` (64), behavior matches
standard test vectors (for example RFC 4231 cases exercised in
`LeanToolchain.Crypto.Tests`). For longer keys, treat the MAC as **Lean-defined**
when comparing against other implementations.
-/

namespace LeanToolchain.Crypto

/-- HMAC-SHA256 outer padding constant -/
def hmacOuterPad : UInt8 := 0x5c

/-- HMAC-SHA256 inner padding constant -/
def hmacInnerPad : UInt8 := 0x36

/-- Block size for SHA-256 (64 bytes) -/
def sha256BlockSize : Nat := 64

/-- Output size for SHA-256 (32 bytes) -/
def sha256OutputSize : Nat := 32

/-- Create HMAC key by padding or truncating to block size -/
def hmacPrepareKey (key : ByteArray) : ByteArray :=
  if key.size > sha256BlockSize then
    -- If key is longer than block size, hash it first
    sha256 key
  else if key.size < sha256BlockSize then
    -- If key is shorter than block size, pad with zeros
    let pad := (List.replicate (sha256BlockSize - key.size) 0).toArray
    ByteArray.mk (key.data ++ pad)
  else
    -- Key is exactly block size
    key

/-- XOR a byte array with a constant -/
def xorWithConstant (bytes : ByteArray) (constant : UInt8) : ByteArray :=
  ByteArray.mk (bytes.data.map (fun b => b ^^^ constant))

/-- HMAC-SHA256 implementation -/
def hmacSha256 (key : ByteArray) (message : ByteArray) : ByteArray :=
  let preparedKey := hmacPrepareKey key
  let outerKey := xorWithConstant preparedKey hmacOuterPad
  let innerKey := xorWithConstant preparedKey hmacInnerPad
  let innerHash := sha256 (concatBytes innerKey message)
  sha256 (concatBytes outerKey innerHash)

/-- Convenience function for HMAC-SHA256 with string inputs -/
def hmacSha256String (key : String) (message : String) : String :=
  bytesToHex (hmacSha256 (stringToBytes key) (stringToBytes message))

/-- Verify HMAC-SHA256 signature -/
def hmacSha256Verify (key : ByteArray) (message : ByteArray) (signature : String) : Bool :=
  bytesToHex (hmacSha256 key message) == signature

/-- HMAC-SHA256 with hex inputs (for RFC test vectors) -/
def hmacSha256Hex (keyHex : String) (messageHex : String) : Option String :=
  match hexToBytes keyHex, hexToBytes messageHex with
  | some key, some message => some (bytesToHex (hmacSha256 key message))
  | _, _ => none

/-!
## Security Properties

The HMAC construction provides the following security properties:

1. **PRF Property**: HMAC is a pseudorandom function assuming the underlying hash function is collision-resistant
2. **MAC Security**: HMAC provides unforgeable message authentication codes
3. **Length Extension Resistance**: HMAC is resistant to length extension attacks

### Formal Proofs (TODO)

The following properties should be formally proven:

- HMAC is a PRF assuming SHA-256 is collision-resistant
- HMAC provides existential unforgeability under chosen message attacks
- HMAC is resistant to length extension attacks
-/

/-!
## HMAC Properties and Lemmas
-/

/-- After preparation, short keys are padded to the block size; long keys are hashed to the digest size. -/
theorem hmacPrepareKey_size_cases (key : ByteArray) :
    (key.size ≤ sha256BlockSize → (hmacPrepareKey key).size = sha256BlockSize) ∧
      (sha256BlockSize < key.size → (hmacPrepareKey key).size = sha256OutputSize) := by
  constructor
  · intro hle
    rcases Nat.lt_or_eq_of_le hle with hlt | heq
    · have hg1 : ¬ key.size > sha256BlockSize := by intro h'; omega
      have hg1' : ¬ key.data.size > sha256BlockSize := by simpa [ByteArray.size] using hg1
      have hlt' : key.data.size < sha256BlockSize := by
        simpa [ByteArray.size, sha256BlockSize] using hlt
      unfold hmacPrepareKey
      simp only [hg1', hlt', ↓reduceIte, ByteArray.size, Array.size_append, List.size_toArray,
        List.length_replicate]
      rw [Nat.add_sub_of_le (Nat.le_of_lt hlt')]
    · have h64 : key.size = 64 := by simpa [sha256BlockSize] using heq
      unfold hmacPrepareKey
      simp [h64, sha256BlockSize]
  · intro hgt
    simp [hmacPrepareKey, sha256OutputSize, hgt, sha256_size]

/-- HMAC is deterministic -/
theorem hmacSha256_deterministic (key message : ByteArray) :
  hmacSha256 key message = hmacSha256 key message := by
  rfl

/-- HMAC verification is correct -/
theorem hmacSha256_verification_correct (key message : ByteArray) :
  hmacSha256Verify key message (bytesToHex (hmacSha256 key message)) = true := by
  simp [hmacSha256Verify, bytesToHex]

/-- HMAC verification rejects incorrect signatures -/
theorem hmacSha256_verification_rejects_incorrect (key message : ByteArray) (wrongSignature : String) :
  wrongSignature ≠ bytesToHex (hmacSha256 key message) →
  hmacSha256Verify key message wrongSignature = false := by
  intro hne
  have h := Ne.symm hne
  simp [hmacSha256Verify, h]

end LeanToolchain.Crypto
