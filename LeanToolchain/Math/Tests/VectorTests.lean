import LeanToolchain.Math.Vector
import Init.Data.Nat.Basic

/-!
# Vector Tests

Executable assertions for construction, arithmetic, indexing, and algebraic identities.
-/

namespace LeanToolchain.Math.Tests

private def expect [BEq α] [ToString α] (label : String) (got expected : α) : IO Unit := do
  if got == expected then
    IO.println s!"  PASS {label}"
  else
    throw <| IO.userError s!"FAIL {label}: got {got}, expected {expected}"

private def expectTrue (label : String) (b : Bool) : IO Unit := do
  if b then
    IO.println s!"  PASS {label}"
  else
    throw <| IO.userError s!"FAIL {label}"

/-- Test basic vector construction -/
def testBasicVectorConstruction : IO Unit := do
  IO.println "Testing basic vector construction..."
  let emptyVec : Vec Nat 0 := Vec.nil
  expect "nil length" emptyVec.data.length 0
  let v3 : Vec Nat 3 := Vec.cons 3 (Vec.cons 2 (Vec.cons 1 Vec.nil))
  expect "cons length" v3.data.length 3
  expect "cons data" v3.data [3, 2, 1]

/-- Test vector operations -/
def testVectorOperations : IO Unit := do
  IO.println "Testing vector operations..."
  let v1 : Vec Nat 3 := Vec.mk' [1, 2, 3] (by rfl)
  let v2 : Vec Nat 3 := Vec.mk' [4, 5, 6] (by rfl)
  expect "add" (v1.add v2).data [5, 7, 9]
  expect "sub" (v2.sub v1).data [3, 3, 3]
  expect "smul" (v1.smul 2).data [2, 4, 6]
  expect "zero" (Vec.zero : Vec Nat 3).data [0, 0, 0]

/-- Test dot product -/
def testDotProduct : IO Unit := do
  IO.println "Testing dot product..."
  let v1 : Vec Nat 3 := Vec.mk' [1, 2, 3] (by rfl)
  let v2 : Vec Nat 3 := Vec.mk' [4, 5, 6] (by rfl)
  expect "dot" (v1.dot v2) 32
  expect "dot zero" (v1.dot Vec.zero) 0
  expect "dot comm" (v1.dot v2) (v2.dot v1)

/-- Test vector magnitude -/
def testVectorMagnitude : IO Unit := do
  IO.println "Testing vector magnitude..."
  let v : Vec Nat 2 := Vec.mk' [3, 4] (by rfl)
  expect "magSq 3-4" v.magSq 25
  let v2 : Vec Nat 3 := Vec.mk' [1, 1, 1] (by rfl)
  expect "magSq 1-1-1" v2.magSq 3
  expect "magSq zero" (Vec.zero : Vec Nat 2).magSq 0

/-- Test vector properties -/
def testVectorProperties : IO Unit := do
  IO.println "Testing vector properties..."
  let v1 : Vec Nat 2 := Vec.mk' [1, 2] (by rfl)
  let v2 : Vec Nat 2 := Vec.mk' [3, 4] (by rfl)
  let v3 : Vec Nat 2 := Vec.mk' [5, 6] (by rfl)
  expectTrue "add comm" ((v1.add v2).data == (v2.add v1).data)
  expectTrue "add assoc" (((v1.add v2).add v3).data == (v1.add (v2.add v3)).data)
  expectTrue "add zero" ((v1.add Vec.zero).data == v1.data)

/-- Test vector indexing -/
def testVectorIndexing : IO Unit := do
  IO.println "Testing vector indexing..."
  let v : Vec Nat 3 := Vec.mk' [10, 20, 30] (by rfl)
  expect "head" v.head 10
  expect "tail" v.tail.data [20, 30]
  expect "get 1" (v.get ⟨1, by decide⟩) 20
  expect "set 0" (v.set ⟨0, by decide⟩ 100).data [100, 20, 30]

/-- Test vector conversion -/
def testVectorConversion : IO Unit := do
  IO.println "Testing vector conversion..."
  let data := [1, 2, 3, 4, 5]
  let v := Vec.mk' data (by rfl)
  expect "toList roundtrip" v.toList data
  expect "data eq" v.data data

/-- Test scalar multiplication properties -/
def testScalarMultiplicationProperties : IO Unit := do
  IO.println "Testing scalar multiplication properties..."
  let v : Vec Nat 2 := Vec.mk' [1, 2] (by rfl)
  expect "smul 0" (v.smul 0).data (Vec.zero : Vec Nat 2).data
  expect "smul 1" (v.smul 1).data v.data
  expect "smul 2" (v.smul 2).data [2, 4]

/-- Test dot product properties -/
def testDotProductProperties : IO Unit := do
  IO.println "Testing dot product properties..."
  let v1 : Vec Nat 2 := Vec.mk' [1, 2] (by rfl)
  let v2 : Vec Nat 2 := Vec.mk' [3, 4] (by rfl)
  let v3 : Vec Nat 2 := Vec.mk' [5, 6] (by rfl)
  expect "bilinear left" ((v1.add v2).dot v3) (v1.dot v3 + v2.dot v3)
  expect "bilinear right" (v1.dot (v2.add v3)) (v1.dot v2 + v1.dot v3)
  expect "comm" (v1.dot v2) (v2.dot v1)

/-- Test cross product in ℝ³ (via Int) -/
def testCrossProduct : IO Unit := do
  IO.println "Testing cross product..."
  let e1 : Vec Int 3 := Vec.mk' [1, 0, 0] (by rfl)
  let e2 : Vec Int 3 := Vec.mk' [0, 1, 0] (by rfl)
  expect "e1 × e2 = e3" (@Vec.cross Int _ _ e1 e2).data [0, 0, 1]

/-- Test edge cases -/
def testEdgeCases : IO Unit := do
  IO.println "Testing edge cases..."
  expect "nil" (Vec.nil : Vec Nat 0).data ([] : List Nat)
  expect "singleton" (Vec.cons 42 Vec.nil).data [42]
  let v5 : Vec Nat 5 := Vec.mk' [1, 2, 3, 4, 5] (by rfl)
  expect "len 5" v5.data.length 5

/-- Test denser vectors without printing huge payloads -/
def testLargerVectors : IO Unit := do
  IO.println "Testing denser vectors..."
  let v10 : Vec Nat 10 := Vec.mk' (List.range 10) (by simp [List.length_range])
  let v20 : Vec Nat 20 := Vec.mk' (List.range 20) (by simp [List.length_range])
  expect "len 10" v10.data.length 10
  expect "len 20" v20.data.length 20
  expect "add len" (v10.add v10).data.length 10
  expect "dot range10" (v10.dot v10) ((List.range 10).foldl (fun acc i => acc + i * i) 0)

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
  testScalarMultiplicationProperties
  IO.println ""
  testDotProductProperties
  IO.println ""
  testCrossProduct
  IO.println ""
  testEdgeCases
  IO.println ""
  testLargerVectors
  IO.println "=== Vector Tests Complete ==="

end LeanToolchain.Math.Tests
