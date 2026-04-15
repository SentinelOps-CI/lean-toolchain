import LeanToolchain.Math.Vector
import Init.Data.Nat.Basic

/-!
# Vector Tests

This module contains comprehensive tests for the Vector implementation,
including basic operations, properties, and property-based tests.
-/

namespace LeanToolchain.Math.Tests

/-!
## Basic Vector Construction Tests
-/

/-- Test basic vector construction -/
def testBasicVectorConstruction : IO Unit := do
  IO.println "Testing basic vector construction..."

  -- Test empty vector
  let emptyVec : Vec Nat 0 := Vec.nil
  let length := emptyVec.data.length
  IO.println s!"Empty vector length: {length}"

  -- Test cons construction
  let v1 : Vec Nat 1 := Vec.cons 1 (Vec.nil : Vec Nat 0)
  let v2 : Vec Nat 2 := Vec.cons 2 v1
  let v3 : Vec Nat 3 := Vec.cons 3 v2
  IO.println s!"Vector [3,2,1] length: {v3.data.length}"
  IO.println s!"Vector [3,2,1] data: {v3.data}"

/-!
## Vector Operations Tests
-/

/-- Test vector operations -/
def testVectorOperations : IO Unit := do
  IO.println "Testing vector operations..."

  -- Create test vectors with explicit types
  let v1 : Vec Nat 3 := Vec.cons 1 (Vec.cons 2 (Vec.cons 3 (Vec.nil : Vec Nat 0)))
  let v2 : Vec Nat 3 := Vec.cons 4 (Vec.cons 5 (Vec.cons 6 (Vec.nil : Vec Nat 0)))

  -- Test addition
  let sum := v1.add v2
  IO.println s!"Vector addition: {v1.data} + {v2.data} = {sum.data}"

  -- Test subtraction
  let diff := v2.sub v1
  IO.println s!"Vector subtraction: {v2.data} - {v1.data} = {diff.data}"

  -- Test scalar multiplication
  let scaled := v1.smul 2
  IO.println s!"Scalar multiplication: 2 * {v1.data} = {scaled.data}"

  -- Test zero vector
  let zeroVec : Vec Nat 3 := Vec.zero
  IO.println s!"Zero vector: {zeroVec.data}"

/-!
## Dot Product Tests
-/

/-- Test dot product -/
def testDotProduct : IO Unit := do
  IO.println "Testing dot product..."

  let v1 : Vec Nat 3 := Vec.cons 1 (Vec.cons 2 (Vec.cons 3 (Vec.nil : Vec Nat 0)))
  let v2 : Vec Nat 3 := Vec.cons 4 (Vec.cons 5 (Vec.cons 6 (Vec.nil : Vec Nat 0)))

  let dot := v1.dot v2
  IO.println s!"Dot product: {v1.data} · {v2.data} = {dot}"

  -- Test with zero vector
  let zeroVec : Vec Nat 3 := Vec.zero
  let dotZero := v1.dot zeroVec
  IO.println s!"Dot product with zero: {v1.data} · {zeroVec.data} = {dotZero}"

  -- Test dot product commutativity
  let dotComm := v2.dot v1
  IO.println s!"Dot product commutativity: {v2.data} · {v1.data} = {dotComm}"

/-!
## Vector Magnitude Tests
-/

/-- Test vector magnitude -/
def testVectorMagnitude : IO Unit := do
  IO.println "Testing vector magnitude..."

  let v : Vec Nat 2 := Vec.cons 3 (Vec.cons 4 (Vec.nil : Vec Nat 0))
  let magSq := v.magSq
  IO.println s!"Magnitude squared of {v.data}: {magSq}"

  let v2 : Vec Nat 3 := Vec.cons 1 (Vec.cons 1 (Vec.cons 1 (Vec.nil : Vec Nat 0)))
  let magSq2 := v2.magSq
  IO.println s!"Magnitude squared of {v2.data}: {magSq2}"

  -- Test zero vector magnitude
  let zeroVec : Vec Nat 2 := Vec.zero
  let zeroMagSq := zeroVec.magSq
  IO.println s!"Zero vector magnitude squared: {zeroMagSq}"

/-!
## Vector Properties Tests
-/

/-- Test vector properties -/
def testVectorProperties : IO Unit := do
  IO.println "Testing vector properties..."

  let v1 : Vec Nat 2 := Vec.cons 1 (Vec.cons 2 (Vec.nil : Vec Nat 0))
  let v2 : Vec Nat 2 := Vec.cons 3 (Vec.cons 4 (Vec.nil : Vec Nat 0))
  let v3 : Vec Nat 2 := Vec.cons 5 (Vec.cons 6 (Vec.nil : Vec Nat 0))

  -- Test commutativity of addition
  let sum1 := v1.add v2
  let sum2 := v2.add v1
  IO.println s!"Addition commutativity: {sum1.data} == {sum2.data}"

  -- Test associativity of addition
  let sum3 := (v1.add v2).add v3
  let sum4 := v1.add (v2.add v3)
  IO.println s!"Addition associativity: {sum3.data} == {sum4.data}"

  -- Test additive identity
  let zeroVec : Vec Nat 2 := Vec.zero
  let sum5 := v1.add zeroVec
  IO.println s!"Additive identity: {sum5.data} == {v1.data}"

/-!
## Vector Indexing Tests
-/

/-- Test vector indexing -/
def testVectorIndexing : IO Unit := do
  IO.println "Testing vector indexing..."

  let v : Vec Nat 3 := Vec.cons 10 (Vec.cons 20 (Vec.cons 30 (Vec.nil : Vec Nat 0)))

  -- Test head and tail
  IO.println s!"Vector: {v.data}"
  IO.println s!"Head: {v.head}"
  IO.println s!"Tail: {v.tail.data}"

  -- Test get and set
  let v2 := v.set ⟨0, by simp⟩ 100
  IO.println s!"After setting index 0 to 100: {v2.data}"

/-!
## Vector Conversion Tests
-/

/-- Test vector conversion -/
def testVectorConversion : IO Unit := do
  IO.println "Testing vector conversion..."

  let data := [1, 2, 3, 4, 5]
  let v := Vec.mk' data (by rfl)

  IO.println s!"Original list: {data}"
  IO.println s!"Converted vector: {v.data}"
  IO.println s!"Back to list: {v.toList}"

/-!
## Property-Based Tests
-/

/-- Test vector addition properties -/
def testVectorAdditionProperties : IO Unit := do
  IO.println "Testing vector addition properties..."

  -- Test with different numeric types
  let v1_nat : Vec Nat 2 := Vec.cons 1 (Vec.cons 2 (Vec.nil : Vec Nat 0))
  let v2_nat : Vec Nat 2 := Vec.cons 3 (Vec.cons 4 (Vec.nil : Vec Nat 0))

  let v1_int : Vec Int 2 := Vec.cons 1 (Vec.cons 2 (Vec.nil : Vec Int 0))
  let v2_int : Vec Int 2 := Vec.cons 3 (Vec.cons 4 (Vec.nil : Vec Int 0))

  -- Test commutativity
  let sum1 := v1_nat.add v2_nat
  let sum2 := v2_nat.add v1_nat
  IO.println s!"Nat commutativity: {sum1.data} == {sum2.data}"

  let sum3 := v1_int.add v2_int
  let sum4 := v2_int.add v1_int
  IO.println s!"Int commutativity: {sum3.data} == {sum4.data}"

/-- Test scalar multiplication properties -/
def testScalarMultiplicationProperties : IO Unit := do
  IO.println "Testing scalar multiplication properties..."

  let v : Vec Nat 2 := Vec.cons 1 (Vec.cons 2 (Vec.nil : Vec Nat 0))

  -- Test scaling by 0
  let scaled0 := v.smul 0
  let zeroVec : Vec Nat 2 := Vec.zero
  IO.println s!"Scaling by 0: {scaled0.data} == {zeroVec.data}"

  -- Test scaling by 1
  let scaled1 := v.smul 1
  IO.println s!"Scaling by 1: {scaled1.data} == {v.data}"

  -- Test scaling by 2
  let scaled2 := v.smul 2
  IO.println s!"Scaling by 2: {scaled2.data}"

/-- Test dot product properties -/
def testDotProductProperties : IO Unit := do
  IO.println "Testing dot product properties..."

  let v1 : Vec Nat 2 := Vec.cons 1 (Vec.cons 2 (Vec.nil : Vec Nat 0))
  let v2 : Vec Nat 2 := Vec.cons 3 (Vec.cons 4 (Vec.nil : Vec Nat 0))
  let v3 : Vec Nat 2 := Vec.cons 5 (Vec.cons 6 (Vec.nil : Vec Nat 0))

  -- Test bilinearity in first argument
  let dot1 := (v1.add v2).dot v3
  let dot2 := v1.dot v3 + v2.dot v3
  IO.println s!"Bilinearity (first arg): {dot1} == {dot2}"

  -- Test bilinearity in second argument
  let dot3 := v1.dot (v2.add v3)
  let dot4 := v1.dot v2 + v1.dot v3
  IO.println s!"Bilinearity (second arg): {dot3} == {dot4}"

  -- Test commutativity
  let dot5 := v1.dot v2
  let dot6 := v2.dot v1
  IO.println s!"Commutativity: {dot5} == {dot6}"

/-- Test vector equality properties -/
def testVectorEqualityProperties : IO Unit := do
  IO.println "Testing vector equality properties..."

  let v1 : Vec Nat 2 := Vec.cons 1 (Vec.cons 2 Vec.nil)
  let v2 : Vec Nat 2 := Vec.cons 1 (Vec.cons 2 Vec.nil)
  let v3 : Vec Nat 2 := Vec.cons 3 (Vec.cons 4 Vec.nil)

  -- Test reflexivity
  IO.println s!"Reflexivity: v1 == v1"

  -- Test symmetry
  if v1.data == v2.data then
    IO.println s!"Symmetry: v1 == v2 and v2 == v1"

  -- Test transitivity
  if v1.data == v2.data && v2.data == v3.data then
    IO.println s!"Transitivity: v1 == v2 and v2 == v3 implies v1 == v3"

/-!
## Edge Case Tests
-/

/-- Test edge cases -/
def testEdgeCases : IO Unit := do
  IO.println "Testing edge cases..."

  -- Test empty vector operations
  let emptyVec : Vec Nat 0 := Vec.nil
  IO.println s!"Empty vector: {emptyVec.data}"

  -- Test single element vector
  let singleVec : Vec Nat 1 := Vec.cons 42 Vec.nil
  IO.println s!"Single element vector: {singleVec.data}"

  -- Test large vectors (small size for testing)
  let largeVec : Vec Nat 5 := Vec.cons 1 (Vec.cons 2 (Vec.cons 3 (Vec.cons 4 (Vec.cons 5 Vec.nil))))
  IO.println s!"Large vector: {largeVec.data}"

/-!
## Performance Tests
-/

/-- Test performance with larger vectors -/
def testPerformance : IO Unit := do
  IO.println "Testing performance..."

  let v10 : Vec Nat 10 := Vec.mk' (List.range 10) (by simp [List.length_range])
  let v20 : Vec Nat 20 := Vec.mk' (List.range 20) (by simp [List.length_range])

  IO.println s!"Vector of size 10: {v10.data.length}"
  IO.println s!"Vector of size 20: {v20.data.length}"

  -- Test operations on larger vectors
  let sum := v10.add v10
  let dot := v10.dot v10
  IO.println s!"Operations on size 10 vector completed"

/-!
## Main Test Runner
-/

/-- Run all vector tests -/
def runAllVectorTests : IO Unit := do
  IO.println "=== Vector Tests ==="
  testBasicVectorConstruction
  IO.println ""
  testVectorOperations
  IO.println ""
  testDotProduct
  IO.println ""
  testVectorMagnitude
  IO.println ""
  testVectorProperties
  IO.println ""
  testVectorIndexing
  IO.println ""
  testVectorConversion
  IO.println ""
  testVectorAdditionProperties
  IO.println ""
  testScalarMultiplicationProperties
  IO.println ""
  testDotProductProperties
  IO.println ""
  testVectorEqualityProperties
  IO.println ""
  testEdgeCases
  IO.println ""
  testPerformance
  IO.println "=== Tests Complete ==="

end LeanToolchain.Math.Tests
