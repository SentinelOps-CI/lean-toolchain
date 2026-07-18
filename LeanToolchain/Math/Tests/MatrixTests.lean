import LeanToolchain.Math.Matrix
import LeanToolchain.Math.Vector
import Mathlib.Data.Rat.Defs
import Init.Data.Nat.Basic

/-!
# Matrix Tests

Executable checks for construction, arithmetic, Bareiss determinant, rank, and inversion.
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

private def mat2 (a b c d : Int) : Matrix Int 2 2 :=
  ⟨Vec.mk'
    [Vec.mk' [a, b] (by simp), Vec.mk' [c, d] (by simp)]
    (by simp)⟩

private def mat3diag (x y z : Int) : Matrix Int 3 3 :=
  ⟨Vec.mk'
    [ Vec.mk' [x, 0, 0] (by simp)
    , Vec.mk' [0, y, 0] (by simp)
    , Vec.mk' [0, 0, z] (by simp)
    ]
    (by simp)⟩

/-- Test basic matrix construction -/
def testBasicMatrixConstruction : IO Unit := do
  IO.println "Testing basic matrix construction..."
  let zeroMat : Matrix Int 2 2 := Matrix.zero
  expect "zero (0,0)" (zeroMat.get ⟨0, by decide⟩ ⟨0, by decide⟩) 0
  let idMat : Matrix Int 2 2 := Matrix.identity
  expect "identity (0,0)" (idMat.get ⟨0, by decide⟩ ⟨0, by decide⟩) 1
  expect "identity (0,1)" (idMat.get ⟨0, by decide⟩ ⟨1, by decide⟩) 0
  expect "identity (1,1)" (idMat.get ⟨1, by decide⟩ ⟨1, by decide⟩) 1

/-- Test matrix operations -/
def testMatrixOperations : IO Unit := do
  IO.println "Testing matrix operations..."
  let mat1 := mat2 1 2 3 4
  let mat2' := mat2 5 6 7 8
  let sum := mat1.add mat2'
  expect "add (0,0)" (sum.get ⟨0, by decide⟩ ⟨0, by decide⟩) 6
  expect "add (1,1)" (sum.get ⟨1, by decide⟩ ⟨1, by decide⟩) 12
  let diff := mat2'.sub mat1
  expect "sub (0,0)" (diff.get ⟨0, by decide⟩ ⟨0, by decide⟩) 4
  let scaled := mat1.smul (2 : Int)
  expect "smul (1,0)" (scaled.get ⟨1, by decide⟩ ⟨0, by decide⟩) 6

/-- Test matrix multiplication -/
def testMatrixMultiplication : IO Unit := do
  IO.println "Testing matrix multiplication..."
  let a := mat2 1 2 3 4
  let b := mat2 5 6 7 8
  let product := a.mul b
  expect "mul (0,0)" (product.get ⟨0, by decide⟩ ⟨0, by decide⟩) 19
  expect "mul (0,1)" (product.get ⟨0, by decide⟩ ⟨1, by decide⟩) 22
  expect "mul (1,0)" (product.get ⟨1, by decide⟩ ⟨0, by decide⟩) 43
  expect "mul (1,1)" (product.get ⟨1, by decide⟩ ⟨1, by decide⟩) 50

/-- Test matrix transpose -/
def testMatrixTranspose : IO Unit := do
  IO.println "Testing matrix transpose..."
  let mat := mat2 1 2 3 4
  let t := mat.transpose
  expect "transpose (0,1)" (t.get ⟨0, by decide⟩ ⟨1, by decide⟩) 3
  expect "transpose (1,0)" (t.get ⟨1, by decide⟩ ⟨0, by decide⟩) 2

/-- Test matrix trace -/
def testMatrixTrace : IO Unit := do
  IO.println "Testing matrix trace..."
  let mat := mat2 1 2 3 4
  expect "trace" mat.trace 5

/-- Test determinants (Bareiss vs Laplace vs 2×2 formula) -/
def testMatrixDeterminant : IO Unit := do
  IO.println "Testing matrix determinants..."
  let mat := mat2 1 2 3 4
  expect "det2x2" mat.det2x2 (-2)
  expect "det Bareiss 2x2" mat.det (-2)
  expect "det Laplace 2x2" mat.detLaplace (-2)
  let m3 := mat3diag 2 3 4
  expect "det Bareiss diag 3x3" m3.det 24
  expect "det Laplace diag 3x3" m3.detLaplace 24

/-- Test rank and inverse -/
def testRankAndInverse : IO Unit := do
  IO.println "Testing rank and inverse..."
  let full := mat2 1 2 3 4
  expect "rank full" full.rank 2
  let singular := mat2 1 2 2 4
  expect "rank singular" singular.rank 1
  match full.inv with
  | none => throw <| IO.userError "FAIL inv: unexpectedly singular"
  | some _ =>
    IO.println "  PASS inv exists for full-rank 2x2"
  -- Prefer a unipotent integer matrix so Gauss–Jordan only divides by unit pivots
  -- (truncated `Int` division is unsafe for non-unit pivots even when det = ±1).
  let uni := mat2 1 2 0 1
  expect "det unipotent" uni.det 1
  match uni.inv with
  | none => throw <| IO.userError "FAIL inv unipotent: unexpectedly singular"
  | some inv =>
    let prod := uni.mul inv
    expect "inv*M (0,0)" (prod.get ⟨0, by decide⟩ ⟨0, by decide⟩) 1
    expect "inv*M (0,1)" (prod.get ⟨0, by decide⟩ ⟨1, by decide⟩) 0
    expect "inv*M (1,0)" (prod.get ⟨1, by decide⟩ ⟨0, by decide⟩) 0
    expect "inv*M (1,1)" (prod.get ⟨1, by decide⟩ ⟨1, by decide⟩) 1
    expect "inv entry (0,1)" (inv.get ⟨0, by decide⟩ ⟨1, by decide⟩) (-2)
  expectTrue "singular inv is none" singular.inv.isNone
  -- Exact inverse over `Rat` (truncated `Int` division cannot invert [[1,2],[3,4]])
  let fullRat : Matrix Rat 2 2 := full.map (fun i : Int => (i : Rat))
  match fullRat.inv with
  | none => throw <| IO.userError "FAIL Rat inv: unexpectedly singular"
  | some inv =>
    let prod := fullRat.mul inv
    expect "Rat inv*M (0,0)" (prod.get ⟨0, by decide⟩ ⟨0, by decide⟩) 1
    expect "Rat inv*M (0,1)" (prod.get ⟨0, by decide⟩ ⟨1, by decide⟩) 0
    expect "Rat inv*M (1,0)" (prod.get ⟨1, by decide⟩ ⟨0, by decide⟩) 0
    expect "Rat inv*M (1,1)" (prod.get ⟨1, by decide⟩ ⟨1, by decide⟩) 1
    expect "Rat inv (0,0)" (inv.get ⟨0, by decide⟩ ⟨0, by decide⟩) (-2)
    expect "Rat inv (0,1)" (inv.get ⟨0, by decide⟩ ⟨1, by decide⟩) 1
  expect "Rat rank" fullRat.rank 2
  -- Characteristic polynomials
  expectTrue "charPoly2x2 shape" (full.charPoly2x2 == [1, -5, (-2 : Int)])
  let m3 := mat3diag 2 3 4
  expectTrue "charPoly3x3 shape" (m3.charPoly3x3 == [1, -9, 26, (-24 : Int)])
  -- Exponentiation by squaring
  let id2 : Matrix Int 2 2 := Matrix.identity
  expectTrue "pow 0" ((full.pow 0).rowLists == id2.rowLists)
  expectTrue "pow 1" ((full.pow 1).rowLists == full.rowLists)
  expectTrue "pow 2 = mul" ((full.pow 2).rowLists == (full.mul full).rowLists)
  expectTrue "pow 5 matches naive" ((full.pow 5).rowLists == (full.mul (full.mul (full.mul (full.mul full)))).rowLists)

/-- Test matrix properties -/
def testMatrixProperties : IO Unit := do
  IO.println "Testing matrix properties..."
  let mat1 := mat2 1 2 3 4
  let mat2' := mat2 5 6 7 8
  let mat3' := mat2 9 1 2 3
  expectTrue "add comm"
    ((mat1.add mat2').rowLists == (mat2'.add mat1).rowLists)
  expectTrue "add assoc"
    (((mat1.add mat2').add mat3').rowLists == (mat1.add (mat2'.add mat3')).rowLists)

/-- Test matrix-vector operations -/
def testMatrixVectorOperations : IO Unit := do
  IO.println "Testing matrix-vector operations..."
  let mat := mat2 1 2 3 4
  let vec := Vec.mk' [5, 6] (by rfl)
  let result := mat.mulVec vec
  expect "mulVec 0" (result.get ⟨0, by decide⟩) 17
  expect "mulVec 1" (result.get ⟨1, by decide⟩) 39
  expect "row0" ((mat.row ⟨0, by decide⟩).get ⟨1, by decide⟩) 2
  expect "col1" ((mat.col ⟨1, by decide⟩).get ⟨1, by decide⟩) 4

/-- Run all matrix tests -/
def runAllMatrixTests : IO Unit := do
  IO.println "=== Matrix Tests ==="
  testBasicMatrixConstruction
  IO.println ""
  testMatrixOperations
  IO.println ""
  testMatrixMultiplication
  IO.println ""
  testMatrixTranspose
  IO.println ""
  testMatrixTrace
  IO.println ""
  testMatrixDeterminant
  IO.println ""
  testRankAndInverse
  IO.println ""
  testMatrixProperties
  IO.println ""
  testMatrixVectorOperations
  IO.println "=== Matrix Tests Complete ==="

end LeanToolchain.Math.Tests
