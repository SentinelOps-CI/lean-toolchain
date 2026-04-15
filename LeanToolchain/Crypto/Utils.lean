import Init.Data.ByteArray
import Init.Data.Nat.Bitwise
import Init.Data.List.Basic
import Init.Data.UInt
import Mathlib.Tactic

/-!
# Cryptographic Utilities

This module provides utility functions for cryptographic operations including
byte arrays, bit operations, and conversions.
-/

namespace LeanToolchain.Crypto

/-- Convert a string to a ByteArray -/
def stringToBytes (s : String) : ByteArray :=
  s.toUTF8

/-- Convert a single byte to hex string -/
def byteToHex (b : UInt8) : String :=
  let high := (b >>> 4).toUInt32.toNat
  let low := (b &&& 0xF).toUInt32.toNat
  let highChar := if high < 10 then Char.ofNat (high + 48) else Char.ofNat (high + 87)
  let lowChar := if low < 10 then Char.ofNat (low + 48) else Char.ofNat (low + 87)
  String.mk [highChar, lowChar]

/-- Convert a ByteArray to a hex string -/
def bytesToHex (bytes : ByteArray) : String :=
  let rec aux (acc : String) (i : Nat) : String :=
    if i >= bytes.size then acc
    else aux (acc ++ byteToHex bytes[i]!) (i + 1)
  aux "" 0

/-- Convert a hex character to its numeric value -/
def hexCharToNat (c : Char) : Option Nat :=
  let n := c.toNat
  if n >= 48 && n <= 57 then some (n - 48)  -- '0' to '9'
  else if n >= 97 && n <= 102 then some (n - 97 + 10)  -- 'a' to 'f'
  else if n >= 65 && n <= 70 then some (n - 65 + 10)   -- 'A' to 'F'
  else none

/-- Convert a hex string to a ByteArray -/
def hexToBytes (hex : String) : Option ByteArray :=
  let hex := hex.trim
  let chars := hex.toList
  if chars.length % 2 != 0 then none
  else
    let rec aux (acc : List UInt8) (cs : List Char) : Option (List UInt8) :=
      match cs with
      | [] => some acc.reverse
      | c1 :: c2 :: rest =>
        match hexCharToNat c1, hexCharToNat c2 with
        | some high, some low =>
          let byte := (high.toUInt8 <<< 4) ||| low.toUInt8
          aux (byte :: acc) rest
        | _, _ => none
      | _ => none -- Odd number of chars (should not happen)
    match aux [] chars with
    | some bytes => some (ByteArray.mk (Array.mk bytes))
    | none => none

/-- Right rotate a 32-bit word by n bits -/
def rotateRight32 (x : UInt32) (n : Nat) : UInt32 :=
  let n := n % 32
  (x >>> (n : UInt32)) ||| (x <<< ((32 - n) : UInt32))

/-- Right shift a 32-bit word by n bits -/
def shiftRight32 (x : UInt32) (n : Nat) : UInt32 :=
  x >>> (n : UInt32)

/-- Convert a list of UInt8 to a list of UInt32 (big-endian) -/
def bytesToWords (bytes : List UInt8) : List UInt32 :=
  let rec aux (acc : List UInt32) (bs : List UInt8) : List UInt32 :=
    match bs with
    | [] => acc.reverse
    | [b1] => ((b1.toUInt32 <<< 24) :: acc).reverse
    | [b1, b2] => (((b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16)) :: acc).reverse
    | [b1, b2, b3] => (((b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16) ||| (b3.toUInt32 <<< 8)) :: acc).reverse
    | b1 :: b2 :: b3 :: b4 :: rest =>
      let word := (b1.toUInt32 <<< 24) ||| (b2.toUInt32 <<< 16) ||| (b3.toUInt32 <<< 8) ||| b4.toUInt32
      aux (word :: acc) rest
  aux [] bytes

/-- Convert a list of UInt32 to a list of UInt8 (big-endian) -/
def wordsToBytes (words : List UInt32) : List UInt8 :=
  let rec aux (acc : List UInt8) (ws : List UInt32) : List UInt8 :=
    match ws with
    | [] => acc
    | word :: rest =>
      let bytes := [(word >>> 24).toUInt8, (word >>> 16).toUInt8, (word >>> 8).toUInt8, word.toUInt8]
      aux (acc ++ bytes) rest
  aux [] words

theorem wordsToBytes_aux_length (acc : List UInt8) (ws : List UInt32) :
    (wordsToBytes.aux acc ws).length = acc.length + 4 * ws.length := by
  induction ws generalizing acc with
  | nil => simp [wordsToBytes.aux]
  | cons w ws ih =>
    simp [wordsToBytes.aux, List.length_append, ih, Nat.mul_add, Nat.add_assoc, Nat.add_comm]

theorem wordsToBytes_length (ws : List UInt32) : (wordsToBytes ws).length = 4 * ws.length := by
  simp [wordsToBytes, wordsToBytes_aux_length]

/-- Create an array of `n` repeated bytes (uses `List.replicate` for length lemmas). -/
def replicate (n : Nat) (x : UInt8) : Array UInt8 :=
  (List.replicate n x).toArray

/-- Pad a message to a multiple of 512 bits (64 bytes).

Uses `Array` concatenation so `Array.size_append` applies cleanly in proofs. -/
def padMessage (message : ByteArray) : ByteArray :=
  let L := message.size
  let messageLengthBits := L * 8
  let paddingLength := (64 - ((L + 1 + 8) % 64)) % 64
  let withBit := message.data ++ #[(0x80 : UInt8)]
  let padded := withBit ++ (List.replicate paddingLength (0 : UInt8)).toArray
  let lengthArr := (wordsToBytes [0, messageLengthBits.toUInt32]).toArray
  ByteArray.mk (padded ++ lengthArr)

/-- Length after padding (bytes): original + 0x80 + zero run + 64-bit length field -/
def padMessageTotalLength (messageLength paddingLength : Nat) : Nat :=
  messageLength + 1 + paddingLength + 8

theorem padMessageTotalLength_mod_64 (messageLength paddingLength : Nat)
    (h : paddingLength = (64 - ((messageLength + 1 + 8) % 64)) % 64) :
    padMessageTotalLength messageLength paddingLength % 64 = 0 := by
  dsimp [padMessageTotalLength]
  subst h
  -- Let `base = messageLength + 9`; show `base + (64 - base % 64) % 64 ≡ 0 (mod 64)`.
  omega

/-- Lemma: padMessage always produces a length that is a multiple of 64 -/
theorem replicate_size (n : Nat) (x : UInt8) : (replicate n x).size = n := by
  simp [replicate]

theorem wordsToBytes_two (a b : UInt32) : (wordsToBytes [a, b]).length = 8 := by
  simpa using (wordsToBytes_length [a, b])

theorem padMessage_size_eq (msg : ByteArray) :
    (padMessage msg).size =
      padMessageTotalLength msg.size ((64 - ((msg.size + 1 + 8) % 64)) % 64) := by
  simp [padMessage, padMessageTotalLength, ByteArray.size, Array.size_append, List.length_replicate,
    List.size_toArray, wordsToBytes_two, Nat.add_assoc]

theorem padMessage_length_mod_64 (msg : ByteArray) : (padMessage msg).size % 64 = 0 := by
  rw [padMessage_size_eq]
  exact padMessageTotalLength_mod_64 _ _ rfl

/-- XOR two byte arrays of the same length -/
def xorBytes (a b : ByteArray) : Option ByteArray :=
  if a.size != b.size then none
  else
    let result := Array.mk (List.range a.size |>.map (fun i => a[i]! ^^^ b[i]!))
    some (ByteArray.mk result)

/-- Concatenate two byte arrays -/
def concatBytes (a b : ByteArray) : ByteArray :=
  ByteArray.mk (a.data ++ b.data)

/-- Extract a subarray from a byte array (inclusive start, exclusive `stop`) -/
def extractBytes (bytes : ByteArray) (start stop : Nat) : ByteArray :=
  if start >= bytes.size || stop > bytes.size || start >= stop then
    ByteArray.empty
  else
    ByteArray.mk (Array.mk (List.range (stop - start) |>.map (fun i => bytes[start + i]!)))

/-- Compare two byte arrays for equality -/
def bytesEqual (a b : ByteArray) : Bool :=
  if a.size != b.size then false
  else List.all (List.range a.size) (fun i => a[i]! == b[i]!)

end LeanToolchain.Crypto
