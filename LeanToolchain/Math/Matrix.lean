import LeanToolchain.Math.Vector
import Init.Data.Nat.Basic
import Init.Data.List.Basic
import Init.Data.List.Lemmas
import Init.Data.List.OfFn
import Init.Data.Fin.Fold

set_option checkBinderAnnotations false

/-!
# Matrices with shape-level naturals

Matrices are `Vec (Vec α n) m`: `m` rows, each of length `n`.
-/

namespace LeanToolchain.Math

/-- A matrix of size `m × n` with elements of type `α`. -/
structure Matrix (α : Type) (m n : Nat) where
  data : Vec (Vec α n) m

/-- Create a matrix from a list of lists (must have uniform row lengths). -/
def Matrix.mk' {α : Type} (data : List (List α)) (h : data.length = m)
    (h' : ∀ row, row ∈ data → row.length = n) : Matrix α m n :=
  let rows := data.attach.map fun x : { r // r ∈ data } =>
    Vec.mk' x.val (h' x.val x.property)
  ⟨Vec.mk' rows (by rw [List.length_map, List.length_attach, h])⟩

private lemma dropCol_length {α : Type} {n : Nat} (v : Vec α (n + 1)) (j : Fin (n + 1)) :
    (v.data.take j.val ++ v.data.drop (j.val + 1)).length = n := by
  rw [List.length_append, List.length_take, List.length_drop, v.length_eq]
  obtain ⟨jv, hj⟩ := j
  simp at hj ⊢
  omega

private def dropCol {α : Type} {n : Nat} (v : Vec α (n + 1)) (j : Fin (n + 1)) : Vec α n :=
  Vec.mk' (v.data.take j.val ++ v.data.drop (j.val + 1)) (dropCol_length v j)

/-- Zero matrix. -/
def Matrix.zero {α : Type} [OfNat α 0] {m n : Nat} : Matrix α m n :=
  let row : Vec α n := Vec.zero
  let rows : List (Vec α n) := List.replicate m row
  ⟨Vec.mk' rows (by rw [List.length_replicate])⟩

/-- Identity matrix. -/
def Matrix.identity {α : Type} [OfNat α 0] [OfNat α 1] {n : Nat} : Matrix α n n :=
  let rows : List (Vec α n) :=
    List.ofFn fun i : Fin n =>
      Vec.mk' (List.ofFn fun j : Fin n => if i.val = j.val then 1 else 0)
        (by rw [List.length_ofFn])
  ⟨Vec.mk' rows (by rw [List.length_ofFn])⟩

def Matrix.get {α : Type} {m n : Nat} (mat : Matrix α m n) (i : Fin m) (j : Fin n) : α :=
  (mat.data.get i).get j

def Matrix.set {α : Type} {m n : Nat} (mat : Matrix α m n) (i : Fin m) (j : Fin n) (x : α) :
    Matrix α m n :=
  let row := mat.data.get i
  let newRow := row.set j x
  let rows := mat.data.data.set i.val newRow
  ⟨Vec.mk' rows (by rw [List.length_set, mat.data.length_eq])⟩

def Matrix.row {α : Type} {m n : Nat} (mat : Matrix α m n) (i : Fin m) : Vec α n :=
  mat.data.get i

def Matrix.col {α : Type} {m n : Nat} (mat : Matrix α m n) (j : Fin n) : Vec α m :=
  Vec.mk' (List.ofFn fun i : Fin m => mat.get i j)
    (by simp [List.length_ofFn, mat.data.length_eq])

/-- Minor: remove row `0` and column `col` from a square `(n+1) × (n+1)` matrix. -/
def Matrix.minor0 {α : Type} {n : Nat} (mat : Matrix α (n + 1) (n + 1)) (col : Fin (n + 1)) :
    Matrix α n n :=
  let rows := mat.data.data.drop 1 |>.map (fun row => dropCol row col)
  ⟨Vec.mk' rows (by
    rw [List.length_map, List.length_drop, mat.data.length_eq]
    omega)⟩

/-- Determinant (Laplace expansion along the first row for `n ≥ 1`; `0 × 0` is `1`). -/
def Matrix.det {α : Type} [Add α] [Sub α] [Mul α] [Neg α] [OfNat α 0] [OfNat α 1] {n : Nat}
    (mat : Matrix α n n) : α :=
  match n with
  | 0 => 1
  | n' + 1 =>
    Fin.foldl (n' + 1) (fun acc jf =>
      let sign : α := if jf.val % 2 = 0 then 1 else -1
      let a0j := mat.get ⟨0, Nat.succ_pos _⟩ jf
      let minorDet := Matrix.det (minor0 mat jf)
      acc + sign * a0j * minorDet) 0

def Matrix.add {α : Type} [Add α] {m n : Nat} (mat1 mat2 : Matrix α m n) : Matrix α m n :=
  let rows := List.zipWith Vec.add mat1.data.data mat2.data.data
  ⟨Vec.mk' rows (by rw [List.length_zipWith, mat1.data.length_eq, mat2.data.length_eq, Nat.min_self])⟩

def Matrix.sub {α : Type} [Sub α] {m n : Nat} (mat1 mat2 : Matrix α m n) : Matrix α m n :=
  let rows := List.zipWith Vec.sub mat1.data.data mat2.data.data
  ⟨Vec.mk' rows (by rw [List.length_zipWith, mat1.data.length_eq, mat2.data.length_eq, Nat.min_self])⟩

def Matrix.smul {α β : Type} [HMul α β β] {m n : Nat} (c : α) (mat : Matrix β m n) : Matrix β m n :=
  let rows := mat.data.data.map (Vec.smul c)
  ⟨Vec.mk' rows (by rw [List.length_map, mat.data.length_eq])⟩

def Matrix.mul {α : Type} [Add α] [Mul α] [OfNat α 0] {m n p : Nat}
    (mat1 : Matrix α m n) (mat2 : Matrix α n p) : Matrix α m p :=
  let rows := List.ofFn fun i : Fin m =>
    Vec.mk' (List.ofFn fun j : Fin p =>
      Vec.dot (mat1.row i) (mat2.col j))
      (by rw [List.length_ofFn])
  ⟨Vec.mk' rows (by rw [List.length_ofFn])⟩

def Matrix.transpose {α : Type} {m n : Nat} (mat : Matrix α m n) : Matrix α n m :=
  ⟨Vec.mk' (List.ofFn fun i : Fin n =>
      Vec.mk' (List.ofFn fun j : Fin m => mat.get j i)
        (by simp [List.length_ofFn]))
    (by simp [List.length_ofFn])⟩

def Matrix.trace {α : Type} [Add α] [OfNat α 0] {n : Nat} (mat : Matrix α n n) : α :=
  List.foldl (· + ·) 0 (List.ofFn fun i : Fin n => mat.get i i)

def Matrix.det2x2 {α : Type} [Sub α] [Mul α] {mat : Matrix α 2 2} : α :=
  mat.get ⟨0, by decide⟩ ⟨0, by decide⟩ * mat.get ⟨1, by decide⟩ ⟨1, by decide⟩ -
  mat.get ⟨0, by decide⟩ ⟨1, by decide⟩ * mat.get ⟨1, by decide⟩ ⟨0, by decide⟩

def Matrix.mulVec {α : Type} [Add α] [Mul α] [OfNat α 0] {m n : Nat}
    (mat : Matrix α m n) (vec : Vec α n) : Vec α m :=
  let result := List.ofFn fun i : Fin m => Vec.dot (mat.row i) vec
  Vec.mk' result (by rw [List.length_ofFn])

def Vec.mulMat {α : Type} [Add α] [Mul α] [OfNat α 0] {m n : Nat}
    (vec : Vec α m) (mat : Matrix α m n) : Vec α n :=
  let result := List.ofFn fun j : Fin n => Vec.dot vec (mat.col j)
  Vec.mk' result (by rw [List.length_ofFn])

def Matrix.pow {α : Type} [Add α] [Mul α] [OfNat α 0] [OfNat α 1] {n : Nat}
    (mat : Matrix α n n) (k : Nat) : Matrix α n n :=
  match k with
  | 0 => Matrix.identity
  | 1 => mat
  | k + 2 => mat.mul (mat.pow (k + 1))

/-- Placeholder: true inversion needs elimination over the coefficient ring. -/
def Matrix.inv {α : Type} [Add α] [Sub α] [Mul α] [Div α] [OfNat α 0] [OfNat α 1] {n : Nat}
    (_mat : Matrix α n n) : Option (Matrix α n n) :=
  none

/-- Placeholder: rank is not computed in this library yet. -/
def Matrix.rank {α : Type} [Add α] [Sub α] [Mul α] [OfNat α 0] {m n : Nat}
    (_mat : Matrix α m n) : Nat :=
  0

/-- Placeholder: eigenvalues are not computed in this library yet. -/
def Matrix.eigenvalues {α : Type} [Add α] [Sub α] [Mul α] [OfNat α 0] {n : Nat}
    (_mat : Matrix α n n) : List α :=
  []

/-! 
## Basic lemmas
-/

theorem Matrix.ext_get {α : Type} {m n : Nat} {A B : Matrix α m n}
    (h : ∀ (i : Fin m) (j : Fin n), A.get i j = B.get i j) : A = B := by
  cases A with | mk va =>
  cases B with | mk vb =>
  refine congrArg Matrix.mk ?_
  apply Vec.ext
  apply List.ext_getElem
  · rw [va.length_eq, vb.length_eq]
  · intro i hi hi'
    apply Vec.ext
    apply List.ext_getElem
    · simp [Vec.length_eq]
    · intro j hj hj'
      have him : i < m := by simpa [va.length_eq] using hi
      have hjn : j < n := by
        have hlen := (va.data[i]'hi).length_eq
        simpa [hlen] using hj
      exact h ⟨i, him⟩ ⟨j, hjn⟩

private theorem zipWith_Vec_add_comm {α : Type} {n : Nat} [AddCommSemigroup α]
    (xs ys : List (Vec α n)) :
    List.zipWith Vec.add xs ys = List.zipWith Vec.add ys xs := by
  induction xs generalizing ys with
  | nil =>
    cases ys with
    | nil => rfl
    | cons _ _ => rfl
  | cons x xs ih =>
    cases ys with
    | nil => rfl
    | cons y ys => simp [List.zipWith, Vec.add_comm x y, ih]

private theorem zipWith_Vec_add_assoc {α : Type} {n : Nat} [AddMonoid α]
    (xs ys zs : List (Vec α n))
    (hxy : xs.length = ys.length) (hyz : ys.length = zs.length) :
    List.zipWith Vec.add (List.zipWith Vec.add xs ys) zs =
      List.zipWith Vec.add xs (List.zipWith Vec.add ys zs) := by
  induction xs generalizing ys zs with
  | nil =>
    cases ys with
    | nil =>
      cases zs with
      | nil => rfl
      | cons _ _ => cases hyz
    | cons _ _ => cases hxy
  | cons x xs ih =>
    cases ys with
    | nil => cases hxy
    | cons y ys =>
      cases zs with
      | nil => cases hyz
      | cons z zs =>
        simp [Nat.succ.injEq] at hxy hyz
        simp [List.zipWith, Vec.add_assoc x y z, ih _ _ hxy hyz]

private theorem zipWith_Vec_add_zero {α : Type} {n : Nat} [AddMonoid α] (xs : List (Vec α n)) :
    List.zipWith Vec.add xs (List.replicate xs.length Vec.zero) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp [List.zipWith, List.replicate, Vec.add_zero, ih]

theorem Matrix.add_comm {α : Type} [AddCommSemigroup α] {m n : Nat} (mat1 mat2 : Matrix α m n) :
    mat1.add mat2 = mat2.add mat1 := by
  cases mat1 with | mk va =>
  cases mat2 with | mk vb =>
  refine congrArg Matrix.mk ?_
  apply Vec.ext
  simpa [Matrix.add] using zipWith_Vec_add_comm va.data vb.data

theorem Matrix.add_assoc {α : Type} [AddMonoid α] {m n : Nat}
    (mat1 mat2 mat3 : Matrix α m n) :
    (mat1.add mat2).add mat3 = mat1.add (mat2.add mat3) := by
  match mat1, mat2, mat3 with
  | ⟨v1⟩, ⟨v2⟩, ⟨v3⟩ =>
    refine congrArg Matrix.mk ?_
    apply Vec.ext
    simpa [Matrix.add] using
      zipWith_Vec_add_assoc v1.data v2.data v3.data
        (v1.length_eq.trans v2.length_eq.symm) (v2.length_eq.trans v3.length_eq.symm)

theorem Matrix.zero_data_data {α : Type} [OfNat α 0] {m n : Nat} :
    (Matrix.zero : Matrix α m n).data.data = List.replicate m Vec.zero :=
  rfl

theorem Matrix.add_zero {α : Type} [AddMonoid α] {m n : Nat} (mat : Matrix α m n) :
    mat.add Matrix.zero = mat := by
  cases mat with | mk v =>
  have hr : List.replicate m (Vec.zero : Vec α n) = List.replicate v.data.length (Vec.zero : Vec α n) := by
    rw [v.length_eq]
  refine congrArg Matrix.mk ?_
  apply Vec.ext
  simp [Matrix.add, Matrix.zero_data_data, hr]
  exact zipWith_Vec_add_zero v.data

theorem Matrix.pow_zero {α : Type} [Add α] [Mul α] [OfNat α 0] [OfNat α 1] {n : Nat}
    (mat : Matrix α n n) : mat.pow 0 = Matrix.identity := by
  simp [Matrix.pow]

theorem Matrix.pow_one {α : Type} [Add α] [Mul α] [OfNat α 0] [OfNat α 1] {n : Nat}
    (mat : Matrix α n n) : mat.pow 1 = mat := by
  simp [Matrix.pow]

end LeanToolchain.Math
