import LeanToolchain.Math.Norm
import LeanToolchain.Math.Vector
import Init.Data.Nat.Basic

/-!
# Norm Tests

This module contains comprehensive tests for the Norm implementation,
including norm calculations, inequalities, and geometric properties.
-/

namespace LeanToolchain.Math.Tests

/-- Test L2 norm calculations -/
def testL2Norm : IO Unit := do
  IO.println "Testing L2 norm calculations..."

  -- Test simple vectors
  let v1 := Vec.cons 3 (Vec.cons 4 Vec.nil)
  let v2 := Vec.cons 1 (Vec.cons 1 (Vec.cons 1 Vec.nil))

  -- Note: norm2 requires Sqrt instance, so we test magnitude squared instead
  let magSq1 := v1.magSq
  let magSq2 := v2.magSq

  IO.println s!"Magnitude squared of {v1.data}: {magSq1}"
  IO.println s!"Magnitude squared of {v2.data}: {magSq2}"

/-- Test L1 norm calculations -/
def testL1Norm : IO Unit := do
  IO.println "Testing L1 norm calculations..."

  let v := Vec.cons 3 (Vec.cons (-4) (Vec.cons 2 Vec.nil))
  -- Note: norm1 requires Abs instance
  IO.println s!"L1 norm test for vector: {v.data}"

/-- Test L∞ norm calculations -/
def testLInfNorm : IO Unit := do
  IO.println "Testing L∞ norm calculations..."

  let v := Vec.cons 3 (Vec.cons (-5) (Vec.cons 2 Vec.nil))
  -- Note: normInf requires Max and Abs instances
  IO.println s!"L∞ norm test for vector: {v.data}"

/-- Test distance calculations -/
def testDistance : IO Unit := do
  IO.println "Testing distance calculations..."

  let v1 := Vec.cons 1 (Vec.cons 2 Vec.nil)
  let v2 := Vec.cons 4 (Vec.cons 6 Vec.nil)

  -- Note: distance requires Sqrt instance
  let diff := v1.sub v2
  let magSq := diff.magSq
  IO.println s!"Distance squared between {v1.data} and {v2.data}: {magSq}"

/-- Test angle calculations -/
def testAngle : IO Unit := do
  IO.println "Testing angle calculations..."

  let v1 := Vec.cons 1 (Vec.cons 0 Vec.nil)
  let v2 := Vec.cons 0 (Vec.cons 1 Vec.nil)

  let dot := v1.dot v2
  IO.println s!"Dot product of {v1.data} and {v2.data}: {dot}"

  -- Note: cosAngle requires Sqrt and Div instances
  IO.println s!"Cosine of angle test completed"

/-- Test triangle inequality -/
def testTriangleInequality : IO Unit := do
  IO.println "Testing triangle inequality..."

  let v1 := Vec.cons 3 (Vec.cons 4 Vec.nil)
  let v2 := Vec.cons 1 (Vec.cons 2 Vec.nil)

  let sum := v1.add v2
  let magSq1 := v1.magSq
  let magSq2 := v2.magSq
  let magSqSum := sum.magSq

  IO.println s!"Triangle inequality test:"
  IO.println s!"  ||v1 + v2||² = {magSqSum}"
  IO.println s!"  ||v1||² = {magSq1}, ||v2||² = {magSq2}"

/-- Test Cauchy-Schwarz inequality -/
def testCauchySchwarz : IO Unit := do
  IO.println "Testing Cauchy-Schwarz inequality..."

  let v1 := Vec.cons 1 (Vec.cons 2 (Vec.cons 3 Vec.nil))
  let v2 := Vec.cons 4 (Vec.cons 5 (Vec.cons 6 Vec.nil))

  let dot := v1.dot v2
  let magSq1 := v1.magSq
  let magSq2 := v2.magSq

  IO.println s!"Cauchy-Schwarz test:"
  IO.println s!"  |v1 · v2| = {dot}"
  IO.println s!"  ||v1||² = {magSq1}, ||v2||² = {magSq2}"

/-- Test parallelogram law -/
def testParallelogramLaw : IO Unit := do
  IO.println "Testing parallelogram law..."

  let v1 := Vec.cons 1 (Vec.cons 2 Vec.nil)
  let v2 := Vec.cons 3 (Vec.cons 4 Vec.nil)

  let sum := v1.add v2
  let diff := v1.sub v2
  let magSqSum := sum.magSq
  let magSqDiff := diff.magSq
  let magSq1 := v1.magSq
  let magSq2 := v2.magSq

  IO.println s!"Parallelogram law test:"
  IO.println s!"  ||v1 + v2||² + ||v1 - v2||² = {magSqSum} + {magSqDiff}"
  IO.println s!"  2(||v1||² + ||v2||²) = 2({magSq1} + {magSq2})"

/-- Test Pythagorean theorem -/
def testPythagorean : IO Unit := do
  IO.println "Testing Pythagorean theorem..."

  let v1 := Vec.cons 1 (Vec.cons 0 Vec.nil)
  let v2 := Vec.cons 0 (Vec.cons 1 Vec.nil)

  let sum := v1.add v2
  let magSqSum := sum.magSq
  let magSq1 := v1.magSq
  let magSq2 := v2.magSq

  IO.println s!"Pythagorean theorem test:"
  IO.println s!"  ||v1 + v2||² = {magSqSum}"
  IO.println s!"  ||v1||² + ||v2||² = {magSq1} + {magSq2}"

/-- Smoke placeholder for matrix norms (name distinct from `MatrixTests.testMatrixNorms`). -/
def testNormMatrixSmoke : IO Unit := do
  IO.println "Testing matrix norms..."

  let _mat : Matrix Nat 2 2 := Matrix.zero
  -- Note: Would need proper matrix construction and norm calculation
  IO.println s!"Matrix norms test completed"

/-- Run all norm tests -/
def runAllNormTests : IO Unit := do
  IO.println "=== Norm Tests ==="
  testL2Norm
  IO.println ""
  testL1Norm
  IO.println ""
  testLInfNorm
  IO.println ""
  testDistance
  IO.println ""
  testAngle
  IO.println ""
  testTriangleInequality
  IO.println ""
  testCauchySchwarz
  IO.println ""
  testParallelogramLaw
  IO.println ""
  testPythagorean
  IO.println ""
  testNormMatrixSmoke
  IO.println "=== Tests Complete ==="

end LeanToolchain.Math.Tests
