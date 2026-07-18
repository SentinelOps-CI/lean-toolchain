import LeanToolchain.Crypto.SHA256
import LeanToolchain.Crypto.Utils

/-!
# SHA-256 Tests

NIST vectors and structural checks. Failures abort the process (CI-hard).
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

/-- Test basic SHA-256 functionality against known digests -/
def testBasicSha256 : IO Unit := do
  IO.println "Testing basic SHA-256 functionality..."
  expectEq "empty" (sha256String "")
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  expectEq "abc" (sha256String "abc")
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  expectEq "hello world" (sha256String "hello world")
    "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"

/-- NIST SHA-256 test vectors -/
def nistTestVectors : List (String × String) :=
  [("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
   ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
   ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
      "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"),
   ("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu",
      "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1")]

/-- Test NIST vectors -/
def testNistVectors : IO Unit := do
  IO.println "Testing NIST SHA-256 test vectors..."
  for (input, expected) in nistTestVectors do
    let label := if input.isEmpty then "(empty)" else
      if input.length ≤ 16 then input else input.take 12 ++ "..."
    expectEq s!"NIST {label}" (sha256String input) expected

/-- Test SHA-256 with byte arrays -/
def testByteArraySha256 : IO Unit := do
  IO.println "Testing SHA-256 with byte arrays..."
  let testBytes := ByteArray.mk (Array.mk [0x61, 0x62, 0x63]) -- "abc"
  expectEq "bytes abc" (bytesToHex (sha256 testBytes))
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
  expectTrue "digest length 32" ((sha256 testBytes).size == 32)

/-- Test SHA-256 verification -/
def testSha256Verification : IO Unit := do
  IO.println "Testing SHA-256 verification..."
  let message := stringToBytes "test message"
  let expected := bytesToHex (sha256 message)
  expectTrue "verify positive" (sha256Verify message expected)
  expectTrue "verify negative" !(sha256Verify message ("00" ++ expected.drop 2))

/-- Test SHA-256 padding -/
def testSha256Padding : IO Unit := do
  IO.println "Testing SHA-256 padding..."
  let shortMessage := stringToBytes "short"
  let padded := padMessage shortMessage
  expectTrue "padded multiple of 64" (padded.size % 64 == 0)
  expectTrue "padded longer than input" (padded.size > shortMessage.size)

/-- Run all SHA-256 tests -/
def runAllSha256Tests : IO Unit := do
  IO.println "=== SHA-256 Tests ==="
  testBasicSha256
  IO.println ""
  testNistVectors
  IO.println ""
  testByteArraySha256
  IO.println ""
  testSha256Verification
  IO.println ""
  testSha256Padding
  IO.println "=== SHA-256 Tests Complete ==="

end LeanToolchain.Crypto.Tests
