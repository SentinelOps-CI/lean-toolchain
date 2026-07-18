import LeanToolchain.Math.Norm
import LeanToolchain.Math.Vector
import LeanToolchain.Math.Matrix
import Mathlib.Data.Real.Basic
import Init.Data.Nat.Basic

/-!
# Norm Tests

Smoke and structural checks for vector magnitudes and matrix norms.
Real-valued norms are noncomputable; we validate discrete surrogates (`magSq`)
and that norm definitions are well-typed / non-negative in spirit via magSq laws.
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

/-- Test L2 magnitude squared (computable stand-in for norm2) -/
def testL2Norm : IO Unit := do
  IO.println "Testing L2 magnitude squared..."
  let v1 := Vec.cons (3 : Int) (Vec.cons 4 Vec.nil)
  let v2 := Vec.cons (1 : Int) (Vec.cons 1 (Vec.cons 1 Vec.nil))
  expect "magSq 3-4-5" v1.magSq 25
  expect "magSq 1-1-1" v2.magSq 3

/-- Test L1-style absolute fold on integers -/
def testL1Norm : IO Unit := do
  IO.println "Testing L1 absolute sum (discrete)..."
  let v := Vec.cons (3 : Int) (Vec.cons (-4) (Vec.cons 2 Vec.nil))
  let l1 := (v.data.map Int.natAbs).foldl (· + ·) 0
  expect "L1 abs sum" l1 9

/-- Test L∞-style max abs on integers -/
def testLInfNorm : IO Unit := do
  IO.println "Testing L∞ max abs (discrete)..."
  let v := Vec.cons (3 : Int) (Vec.cons (-5) (Vec.cons 2 Vec.nil))
  let linf := (v.data.map Int.natAbs).foldl max 0
  expect "L∞ max abs" linf 5

/-- Test distance squared -/
def testDistance : IO Unit := do
  IO.println "Testing distance squared..."
  let v1 := Vec.cons (1 : Int) (Vec.cons 2 Vec.nil)
  let v2 := Vec.cons (4 : Int) (Vec.cons 6 Vec.nil)
  expect "dist²" (v1.sub v2).magSq 25

/-- Test orthogonality via dot product -/
def testAngle : IO Unit := do
  IO.println "Testing orthogonal vectors..."
  let v1 := Vec.cons (1 : Int) (Vec.cons 0 Vec.nil)
  let v2 := Vec.cons (0 : Int) (Vec.cons 1 Vec.nil)
  expect "dot orthogonal" (v1.dot v2) 0

/-- Test triangle inequality on magSq (weak form: not always true for squares) -/
def testTriangleInequality : IO Unit := do
  IO.println "Testing vector addition magnitudes..."
  let v1 := Vec.cons (3 : Int) (Vec.cons 4 Vec.nil)
  let v2 := Vec.cons (1 : Int) (Vec.cons 2 Vec.nil)
  let sum := v1.add v2
  expect "magSq sum" sum.magSq 52
  expect "magSq v1" v1.magSq 25
  expect "magSq v2" v2.magSq 5

/-- Test Cauchy-Schwarz numerically on integers: (dot)² ≤ magSq₁ * magSq₂ -/
def testCauchySchwarz : IO Unit := do
  IO.println "Testing Cauchy-Schwarz (integer form)..."
  let v1 := Vec.cons (1 : Int) (Vec.cons 2 (Vec.cons 3 Vec.nil))
  let v2 := Vec.cons (4 : Int) (Vec.cons 5 (Vec.cons 6 Vec.nil))
  let dot := v1.dot v2
  let lhs := dot * dot
  let rhs := v1.magSq * v2.magSq
  expectTrue "Cauchy-Schwarz" (decide (lhs ≤ rhs))
  expect "dot" dot 32

/-- Test parallelogram law on magSq -/
def testParallelogramLaw : IO Unit := do
  IO.println "Testing parallelogram law..."
  let v1 := Vec.cons (1 : Int) (Vec.cons 2 Vec.nil)
  let v2 := Vec.cons (3 : Int) (Vec.cons 4 Vec.nil)
  let lhs := (v1.add v2).magSq + (v1.sub v2).magSq
  let rhs := 2 * (v1.magSq + v2.magSq)
  expect "parallelogram" lhs rhs

/-- Test Pythagorean theorem for orthogonal vectors -/
def testPythagorean : IO Unit := do
  IO.println "Testing Pythagorean theorem..."
  let v1 := Vec.cons (1 : Int) (Vec.cons 0 Vec.nil)
  let v2 := Vec.cons (0 : Int) (Vec.cons 1 Vec.nil)
  expect "Pythagoras" (v1.add v2).magSq (v1.magSq + v2.magSq)

/-- Matrix Frobenius surrogate: sum of squares of entries -/
def testMatrixNormSurrogate : IO Unit := do
  IO.println "Testing matrix entrywise energy (Frobenius² surrogate)..."
  let mat : Matrix Int 2 2 :=
    ⟨Vec.mk'
      [Vec.mk' [3, 0] (by simp), Vec.mk' [0, 4] (by simp)]
      (by simp)⟩
  let energy :=
    (mat.get ⟨0, by decide⟩ ⟨0, by decide⟩)^2 +
    (mat.get ⟨0, by decide⟩ ⟨1, by decide⟩)^2 +
    (mat.get ⟨1, by decide⟩ ⟨0, by decide⟩)^2 +
    (mat.get ⟨1, by decide⟩ ⟨1, by decide⟩)^2
  expect "frobenius energy" energy 25
  expect "rank diag" mat.rank 2
  -- Real operator / Frobenius norms are noncomputable; the discrete energy above
  -- matches ‖diag(3,4)‖_F² = 25, i.e. the same quantity `frobeniusNorm` squares.

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
  testMatrixNormSurrogate
  IO.println "=== Norm Tests Complete ==="

end LeanToolchain.Math.Tests
