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
open Classical

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

/-- Eigenvalues of a real `1 × 1` matrix. -/
noncomputable def Matrix.eigenvalues1x1Real (mat : Matrix ℝ 1 1) : List ℝ :=
  [mat.get ⟨0, by decide⟩ ⟨0, by decide⟩]

/-- Eigenvalues of a real `2 × 2` matrix via the quadratic formula. -/
noncomputable def Matrix.eigenvalues2x2Real (mat : Matrix ℝ 2 2) : ℝ × ℝ :=
  Matrix.eigenvalues2x2 mat Real.sqrt

/-- Largest eigenvalue of a real symmetric `2 × 2` (used for Gram matrices). -/
noncomputable def Matrix.largestEigenvalue2x2 (mat : Matrix ℝ 2 2) : ℝ :=
  let pair := mat.eigenvalues2x2Real
  max pair.1 pair.2

/--
Rayleigh-quotient power iteration for the dominant eigenvalue of a square matrix.
Used for spectral norms when the Gram matrix is larger than `2 × 2`, and as the
general-purpose spectral estimator for `n ≥ 3`.
-/
noncomputable def Matrix.dominantEigenvalue {n : Nat} (G : Matrix ℝ n n) (iters : Nat := 32) : ℝ :=
  if n = 0 then 0
  else
    let ones : Vec ℝ n := Vec.mk' (List.replicate n (1 : ℝ)) (by rw [List.length_replicate])
    let rec go (k : Nat) (v : Vec ℝ n) : ℝ :=
      let Gv := G.mulVec v
      match k with
      | 0 =>
        let denom := v.magSq
        if denom = 0 then 0 else v.dot Gv / denom
      | k' + 1 =>
        let nrm := Gv.norm2
        if nrm = 0 then 0 else go k' (Gv.smul (1 / nrm))
    go iters ones

/--
Eigenvalue list by size:
* `n ≤ 2`: closed form
* `n ≥ 3`: singleton containing the power-iteration dominant estimate (not a full spectrum)
-/
noncomputable def Matrix.eigenvaluesReal {n : Nat} (mat : Matrix ℝ n n) : List ℝ :=
  if n = 0 then
    []
  else if h1 : n = 1 then
    let mat1 : Matrix ℝ 1 1 := h1 ▸ mat
    mat1.eigenvalues1x1Real
  else if h2 : n = 2 then
    let mat2 : Matrix ℝ 2 2 := h2 ▸ mat
    let pair := mat2.eigenvalues2x2Real
    [pair.1, pair.2]
  else
    [mat.dominantEigenvalue 48]

/--
Induced operator 2-norm `‖A‖₂ = √(λ_max(AᵀA))`.

* `n = 0`: `0`
* `n = 1`: exact Euclidean column norm
* `n = 2`: exact via the quadratic formula on the Gram matrix
* `n ≥ 3`: power iteration on `AᵀA` (default 32 iterations)
-/
noncomputable def Matrix.operatorNorm {m n : Nat} (mat : Matrix ℝ m n) : ℝ :=
  if n = 0 then
    0
  else if h1 : n = 1 then
    sqrt
      (List.foldl (· + ·) 0
        (List.ofFn fun i : Fin m =>
          (mat.get i ⟨0, by rw [h1]; exact Nat.succ_pos 0⟩) ^ 2))
  else if h2 : n = 2 then
    let mat2 : Matrix ℝ m 2 := h2 ▸ mat
    sqrt (mat2.transpose.mul mat2).largestEigenvalue2x2
  else
    sqrt ((mat.transpose.mul mat).dominantEigenvalue 32)

private theorem foldl_add_nonneg (xs : List ℝ) (acc : ℝ)
    (ha : 0 ≤ acc) (hx : ∀ x ∈ xs, 0 ≤ x) : 0 ≤ xs.foldl (· + ·) acc := by
  induction xs generalizing acc with
  | nil => simpa
  | cons x xs ih =>
    simp only [List.foldl_cons]
    exact ih (acc + x) (add_nonneg ha (hx x (by simp)))
      (fun y hy => hx y (by simp [hy]))

private theorem foldl_max_nonneg (xs : List ℝ) (acc : ℝ)
    (ha : 0 ≤ acc) : 0 ≤ xs.foldl max acc := by
  induction xs generalizing acc with
  | nil => simpa
  | cons x xs ih =>
    simp only [List.foldl_cons]
    exact ih (max acc x) (le_trans ha (le_max_left acc x))

theorem Vec.norm1_nonneg {n : Nat} (v : Vec ℝ n) : 0 ≤ v.norm1 := by
  simp only [Vec.norm1]
  refine foldl_add_nonneg _ 0 le_rfl ?_
  intro x hx
  obtain ⟨y, _, rfl⟩ := List.mem_map.1 hx
  exact abs_nonneg y

theorem Vec.normInf_nonneg {n : Nat} (v : Vec ℝ n) : 0 ≤ v.normInf := by
  simpa [Vec.normInf] using foldl_max_nonneg (v.data.map abs) 0 le_rfl

theorem Vec.norm2_nonneg {n : Nat} (v : Vec ℝ n) : 0 ≤ v.norm2 :=
  sqrt_nonneg _

theorem Matrix.frobeniusNorm_nonneg {m n : Nat} (mat : Matrix ℝ m n) :
    0 ≤ mat.frobeniusNorm :=
  sqrt_nonneg _

theorem Matrix.operatorNorm_nonneg {m n : Nat} (mat : Matrix ℝ m n) :
    0 ≤ mat.operatorNorm := by
  dsimp only [Matrix.operatorNorm]
  split_ifs
  · exact le_rfl
  · exact sqrt_nonneg _
  · exact sqrt_nonneg _
  · exact sqrt_nonneg _

theorem Matrix.norm1_nonneg {m n : Nat} (mat : Matrix ℝ m n) : 0 ≤ mat.norm1 := by
  simpa [Matrix.norm1] using foldl_max_nonneg
    (List.ofFn fun j : Fin n =>
      List.foldl (· + ·) 0 (List.ofFn fun i : Fin m => abs (mat.get i j)))
    0 le_rfl

theorem Matrix.normInf_nonneg {m n : Nat} (mat : Matrix ℝ m n) : 0 ≤ mat.normInf := by
  simpa [Matrix.normInf] using foldl_max_nonneg
    (List.ofFn fun i : Fin m =>
      List.foldl (· + ·) 0 (List.ofFn fun j : Fin n => abs (mat.get i j)))
    0 le_rfl

end LeanToolchain.Math
