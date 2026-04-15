import LeanToolchain.Crypto.Tests.SHA256Tests
import LeanToolchain.Crypto.Tests.HMACTests
import LeanToolchain.Math.Tests.VectorTests
import LeanToolchain.Math.Tests.MatrixTests
import LeanToolchain.Math.Tests.NormTests

/-!
Combined test driver for `lake test`.
-/

def main : IO Unit := do
  LeanToolchain.Crypto.Tests.runAllSha256Tests
  IO.println ""
  LeanToolchain.Crypto.Tests.runAllHMACTests
  IO.println ""
  LeanToolchain.Math.Tests.runAllVectorTests
  IO.println ""
  LeanToolchain.Math.Tests.runAllMatrixTests
  IO.println ""
  LeanToolchain.Math.Tests.runAllNormTests
  IO.println ""
  IO.println "All Lean Toolchain smoke tests completed."
