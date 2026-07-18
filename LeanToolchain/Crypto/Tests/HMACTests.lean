import LeanToolchain.Crypto.HMAC
import LeanToolchain.Crypto.Utils

/-!
# HMAC-SHA256 Tests

RFC 4231 vectors and structural checks. Failures abort the process (CI-hard).
-/

namespace LeanToolchain.Crypto.Tests

private def expectEq (label : String) (got expected : String) : IO Unit := do
  if got == expected then
    IO.println s!"  PASS {label}"
  else
    throw <| IO.userError s!"FAIL {label}: got {got}, expected {expected}"

private def expectTrue (label : String) (b : Bool) : IO Unit := do
  if b then
    IO.println s!"  PASS {label}"
  else
    throw <| IO.userError s!"FAIL {label}"

/-- Test basic HMAC-SHA256 functionality -/
def testBasicHMAC : IO Unit := do
  IO.println "Testing basic HMAC-SHA256 functionality..."
  -- RFC 4231 test case 2 (key = "Jefe")
  expectEq "Jefe / what do ya want..."
    (hmacSha256String "Jefe" "what do ya want for nothing?")
    "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"

/-- RFC 4231 HMAC-SHA256 test vectors -/
def rfc4231TestVectors : List (String × String × String) :=
  [("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b", "4869205468657265",
      "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"),
   ("4a656665", "7768617420646f2079612077616e7420666f72206e6f7468696e673f",
      "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"),
   ("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
      "773ea91e36800e46854db8ebd09181a72959098b3ef8c122d9635514ced565fe"),
   ("0102030405060708090a0b0c0d0e0f10111213141516171819",
      "cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd",
      "82558a389a443c0ea4cc819899f2083a85f0faa3e578f8077a2e3ff46729665b")]

/-- Test RFC 4231 vectors -/
def testRfc4231Vectors : IO Unit := do
  IO.println "Testing RFC 4231 HMAC-SHA256 test vectors..."
  let mut i := 0
  for (keyHex, messageHex, expected) in rfc4231TestVectors do
    i := i + 1
    match hmacSha256Hex keyHex messageHex with
    | some actual =>
      expectEq s!"RFC4231 case {i}" actual expected
    | none =>
      throw <| IO.userError s!"FAIL RFC4231 case {i}: hex parse failed"

/-- Test HMAC-SHA256 with byte arrays -/
def testByteArrayHMAC : IO Unit := do
  IO.println "Testing HMAC-SHA256 with byte arrays..."
  let key := ByteArray.mk (Array.mk [0x6b, 0x65, 0x79]) -- "key"
  let message := ByteArray.mk (Array.mk [0x74, 0x65, 0x73, 0x74]) -- "test"
  let hexHmac := bytesToHex (hmacSha256 key message)
  expectTrue "hmac length 64 hex chars" (hexHmac.length == 64)
  expectEq "string/bytes agree" hexHmac (hmacSha256String "key" "test")

/-- Test HMAC-SHA256 verification -/
def testHMACVerification : IO Unit := do
  IO.println "Testing HMAC-SHA256 verification..."
  let key := stringToBytes "secret"
  let message := stringToBytes "message"
  let signature := bytesToHex (hmacSha256 key message)
  expectTrue "verify positive" (hmacSha256Verify key message signature)
  expectTrue "verify negative" !(hmacSha256Verify key message ("ff" ++ signature.drop 2))

/-- Test HMAC key preparation -/
def testHMACKeyPreparation : IO Unit := do
  IO.println "Testing HMAC key preparation..."
  let shortKey := ByteArray.mk (Array.mk [0x61, 0x62, 0x63]) -- "abc"
  let preparedShort := hmacPrepareKey shortKey
  expectTrue "short key -> block size" (preparedShort.size == sha256BlockSize)
  let longKey := ByteArray.mk (Array.mk (List.replicate 100 0x61))
  let preparedLong := hmacPrepareKey longKey
  expectTrue "long key -> digest size" (preparedLong.size == sha256OutputSize)

/-- Test that distinct messages yield distinct tags (smoke for length-extension resistance) -/
def testLengthExtensionResistance : IO Unit := do
  IO.println "Testing HMAC distinctness under message extension..."
  let key := "secret"
  let hmac1 := hmacSha256String key "original message"
  let hmac2 := hmacSha256String key "original message with extension"
  expectTrue "distinct tags" (hmac1 != hmac2)

/-- Run all HMAC tests -/
def runAllHMACTests : IO Unit := do
  IO.println "=== HMAC-SHA256 Tests ==="
  testBasicHMAC
  IO.println ""
  testRfc4231Vectors
  IO.println ""
  testByteArrayHMAC
  IO.println ""
  testHMACVerification
  IO.println ""
  testHMACKeyPreparation
  IO.println ""
  testLengthExtensionResistance
  IO.println "=== HMAC-SHA256 Tests Complete ==="

end LeanToolchain.Crypto.Tests
