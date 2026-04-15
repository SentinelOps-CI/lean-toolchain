import LeanToolchain.Math.Vector
import LeanToolchain.Math.Matrix
import Mathlib.Data.Real.Basic
import Mathlib.Data.Real.Sqrt
import Init.Data.List.OfFn

/-!
# Norms over `ℝ`

Real-valued norms use `Real.sqrt` and list folds. Definitions are `noncomputable` because `ℝ`
and `Real.sqrt` are noncomputable in mathlib.
-/

namespace LeanToolchain.Math

open Real

/-- Euclidean (L2) norm for real vectors. -/
noncomputable def Vec.norm2 {n : Nat} (v : Vec ℝ n) : ℝ :=
  sqrt v.magSq

/-- Manhattan (L1) norm for real vectors. -/
noncomputable def Vec.norm1 {n : Nat} (v : Vec ℝ n) : ℝ :=
  (v.data.map fun x => abs x).foldl (· + ·) 0

/-- Sup norm (discrete maximum of absolute entries). -/
noncomputable def Vec.normInf {n : Nat} (v : Vec ℝ n) : ℝ :=
  (v.data.map fun x => abs x).foldl max 0

noncomputable def Vec.distance {n : Nat} (v1 v2 : Vec ℝ n) : ℝ :=
  (v1.sub v2).norm2

noncomputable def Vec.cosAngle {n : Nat} (v1 v2 : Vec ℝ n) : ℝ :=
  v1.dot v2 / (v1.norm2 * v2.norm2)

noncomputable def Matrix.frobeniusNorm {m n : Nat} (mat : Matrix ℝ m n) : ℝ :=
  sqrt
    (List.foldl (· + ·) 0
      (List.ofFn fun i : Fin m =>
        List.foldl (· + ·) 0
          (List.ofFn fun j : Fin n => (mat.get i j) ^ 2)))

noncomputable def Matrix.norm1 {m n : Nat} (mat : Matrix ℝ m n) : ℝ :=
  List.foldl max 0
    (List.ofFn fun j : Fin n =>
      List.foldl (· + ·) 0
        (List.ofFn fun i : Fin m => abs (mat.get i j)))

noncomputable def Matrix.normInf {m n : Nat} (mat : Matrix ℝ m n) : ℝ :=
  List.foldl max 0
    (List.ofFn fun i : Fin m =>
      List.foldl (· + ·) 0
        (List.ofFn fun j : Fin n => abs (mat.get i j)))

/-- Not computed; reserved for future work. -/
noncomputable def Matrix.operatorNorm {m n : Nat} (_mat : Matrix ℝ m n) : ℝ :=
  0

theorem Vec.norm2_nonneg {n : Nat} (v : Vec ℝ n) : 0 ≤ v.norm2 :=
  sqrt_nonneg _

theorem Matrix.frobeniusNorm_nonneg {m n : Nat} (mat : Matrix ℝ m n) :
    0 ≤ mat.frobeniusNorm :=
  sqrt_nonneg _

end LeanToolchain.Math
