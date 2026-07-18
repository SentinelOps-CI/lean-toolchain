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

Linear-algebra kernels that need division (`rank`, `inv`, Bareiss `det`) treat `α` as a
field-like coefficient type (`BEq` for pivots). Prefer `Rat` or floating types for inversion;
over `Int`, truncated division can discard information.
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

/-- Row-major list-of-lists view (length `m`, each inner length `n`). -/
def Matrix.rowLists {α : Type} {m n : Nat} (mat : Matrix α m n) : List (List α) :=
  mat.data.data.map (·.data)

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

/-- Determinant via Laplace expansion along the first row. Correct on rings; cost `O(n!)`. -/
def Matrix.detLaplace {α : Type} [Add α] [Sub α] [Mul α] [Neg α] [OfNat α 0] [OfNat α 1]
    {n : Nat} (mat : Matrix α n n) : α :=
  match n with
  | 0 => 1
  | n' + 1 =>
    Fin.foldl (n' + 1) (fun acc jf =>
      let sign : α := if jf.val % 2 = 0 then 1 else -1
      let a0j := mat.get ⟨0, Nat.succ_pos _⟩ jf
      let minorDet := Matrix.detLaplace (minor0 mat jf)
      acc + sign * a0j * minorDet) 0

/-! ## Dense helpers for elimination algorithms -/

namespace Matrix.Elim
variable {α : Type}

@[inline] def isZero [BEq α] [OfNat α 0] (x : α) : Bool :=
  x == (0 : α)

def get (rows : List (List α)) (i j : Nat) (default : α) : α :=
  (rows.getD i []).getD j default

def set (rows : List (List α)) (i j : Nat) (x : α) : List (List α) :=
  match rows[i]? with
  | none => rows
  | some row => rows.set i (row.set j x)

def swapRows (rows : List (List α)) (i j : Nat) : List (List α) :=
  if i == j then rows
  else
    match rows[i]?, rows[j]? with
    | some ri, some rj => (rows.set i rj).set j ri
    | _, _ => rows

/-- First row index `≥ startRow` with a nonzero entry in column `col`. -/
def findPivot [BEq α] [OfNat α 0] (rows : List (List α)) (startRow nrows col : Nat) :
    Option Nat :=
  Id.run do
    let mut r := startRow
    while r < nrows do
      if !(isZero (get rows r col 0)) then
        return some r
      r := r + 1
    return none

/-- Bareiss fraction-free elimination determinant. `O(n³)` with exact division on integral domains. -/
def detBareiss [BEq α] [Add α] [Sub α] [Mul α] [Div α] [Neg α] [OfNat α 0] [OfNat α 1]
    (n : Nat) (rows0 : List (List α)) : α :=
  if n == 0 then (1 : α)
  else
    Id.run do
      let mut rows := rows0
      let mut sign : α := 1
      let mut prevPivot : α := 1
      for k in [0:n] do
        match findPivot rows k n k with
        | none => return (0 : α)
        | some piv =>
          if piv != k then
            rows := swapRows rows k piv
            sign := -sign
          let akk := get rows k k 0
          if isZero akk then return (0 : α)
          -- Update the trailing (n-k-1)² block
          for i in [k+1:n] do
            for j in [k+1:n] do
              let numer := akk * get rows i j 0 - get rows i k 0 * get rows k j 0
              let updated := numer / prevPivot
              rows := set rows i j updated
          prevPivot := akk
      return sign * get rows (n - 1) (n - 1) 0

/-- Row-reduce to upper echelon form; returns rank. -/
def rankOf [BEq α] [OfNat α 0] [Div α] [Mul α] [Sub α]
    (nrows ncols : Nat) (rows0 : List (List α)) : Nat :=
  Id.run do
    let mut rows := rows0
    let mut rank : Nat := 0
    let mut col : Nat := 0
    let mut row : Nat := 0
    while row < nrows && col < ncols do
      match findPivot rows row nrows col with
      | none =>
        col := col + 1
      | some piv =>
        rows := swapRows rows row piv
        let pivot := get rows row col 0
        for i in [row+1:nrows] do
          let factor := get rows i col 0 / pivot
          if !(isZero factor) then
            for j in [col:ncols] do
              let v := get rows i j 0 - factor * get rows row j 0
              rows := set rows i j v
        rank := rank + 1
        row := row + 1
        col := col + 1
    return rank

/-- Gauss–Jordan inversion of an `n × n` matrix. Returns `none` if singular. -/
def invert [BEq α] [OfNat α 0] [OfNat α 1] [Div α] [Mul α] [Sub α] [Add α]
    (n : Nat) (rows0 : List (List α)) : Option (List (List α)) :=
  if n == 0 then some []
  else
    Id.run do
      -- Augment with identity: each row is [A_i | I_i]
      let mut aug : List (List α) :=
        List.ofFn fun i : Fin n =>
          let left := rows0.getD i.val (List.replicate n 0)
          let right := List.ofFn fun j : Fin n => if i.val = j.val then (1 : α) else (0 : α)
          left ++ right
      let width := 2 * n
      for col in [0:n] do
        match findPivot aug col n col with
        | none => return none
        | some piv =>
          aug := swapRows aug col piv
          let pivot := get aug col col 0
          if isZero pivot then return none
          -- Scale pivot row to 1
          for j in [0:width] do
            aug := set aug col j (get aug col j 0 / pivot)
          -- Eliminate column in all other rows
          for i in [0:n] do
            if i != col then
              let factor := get aug i col 0
              if !(isZero factor) then
                for j in [0:width] do
                  let v := get aug i j 0 - factor * get aug col j 0
                  aug := set aug i j v
      let invRows := aug.map fun row => row.drop n
      return some invRows

end Matrix.Elim

/-- Determinant: Bareiss `O(n³)` when `Div` is available (preferred); see also `detLaplace`. -/
def Matrix.det {α : Type} [BEq α] [Add α] [Sub α] [Mul α] [Div α] [Neg α]
    [OfNat α 0] [OfNat α 1] {n : Nat} (mat : Matrix α n n) : α :=
  Matrix.Elim.detBareiss n mat.rowLists

def Matrix.add {α : Type} [Add α] {m n : Nat} (mat1 mat2 : Matrix α m n) : Matrix α m n :=
  let rows := List.zipWith Vec.add mat1.data.data mat2.data.data
  ⟨Vec.mk' rows (by rw [List.length_zipWith, mat1.data.length_eq, mat2.data.length_eq, Nat.min_self])⟩

def Matrix.sub {α : Type} [Sub α] {m n : Nat} (mat1 mat2 : Matrix α m n) : Matrix α m n :=
  let rows := List.zipWith Vec.sub mat1.data.data mat2.data.data
  ⟨Vec.mk' rows (by rw [List.length_zipWith, mat1.data.length_eq, mat2.data.length_eq, Nat.min_self])⟩

def Matrix.smul {α β : Type} [HMul α β β] {m n : Nat} (c : α) (mat : Matrix β m n) : Matrix β m n :=
  let rows := mat.data.data.map (Vec.smul c)
  ⟨Vec.mk' rows (by rw [List.length_map, mat.data.length_eq])⟩

/-- Matrix product. Precomputes columns of `mat2` once (`O(n·p)`), then `O(m·n·p)` dots. -/
def Matrix.mul {α : Type} [Add α] [Mul α] [OfNat α 0] {m n p : Nat}
    (mat1 : Matrix α m n) (mat2 : Matrix α n p) : Matrix α m p :=
  let cols : List (Vec α n) := List.ofFn fun j : Fin p => mat2.col j
  let rows := List.ofFn fun i : Fin m =>
    Vec.mk' (List.ofFn fun j : Fin p =>
      Vec.dot (mat1.row i) (cols.getD j.val Vec.zero))
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
  let cols : List (Vec α m) := List.ofFn fun j : Fin n => mat.col j
  let result := List.ofFn fun j : Fin n => Vec.dot vec (cols.getD j.val Vec.zero)
  Vec.mk' result (by rw [List.length_ofFn])

/-- Matrix power by exponentiation by squaring (`O(log k)` multiplications). -/
def Matrix.pow {α : Type} [Add α] [Mul α] [OfNat α 0] [OfNat α 1] {n : Nat}
    (mat : Matrix α n n) : Nat → Matrix α n n
  | 0 => Matrix.identity
  | 1 => mat
  | k + 2 =>
    let k' := k + 2
    if k' % 2 == 0 then
      let half := Matrix.pow mat (k' / 2)
      half.mul half
    else
      mat.mul (Matrix.pow mat (k' - 1))

/-- Matrix inverse via Gauss–Jordan. Returns `none` if no pivot is found (singular / degenerate).

Prefer a field with exact division (`Rat`, floating point). Over `Int`, truncated division can
destroy correctness unless all pivots are units (e.g. unipotent matrices). Lift with
`Matrix.map (↑ : Int → Rat)` and invert over `Rat` for exact integer problems. -/
def Matrix.inv {α : Type} [BEq α] [Add α] [Sub α] [Mul α] [Div α] [OfNat α 0] [OfNat α 1]
    {n : Nat} (mat : Matrix α n n) : Option (Matrix α n n) :=
  match Matrix.Elim.invert n mat.rowLists with
  | none => none
  | some rows =>
    if rows.length == n then
      let data :=
        List.ofFn fun i : Fin n =>
          Vec.mk' (List.ofFn fun j : Fin n => (rows.getD i.val []).getD j.val 0)
            (by rw [List.length_ofFn])
      some ⟨Vec.mk' data (by rw [List.length_ofFn])⟩
    else
      none

/-- Matrix rank via Gaussian elimination over a field-like coefficient type.

Same division caveat as `inv`: prefer `Rat` / floats over `Int`. -/
def Matrix.rank {α : Type} [BEq α] [Add α] [Sub α] [Mul α] [Div α] [OfNat α 0]
    {m n : Nat} (mat : Matrix α m n) : Nat :=
  Matrix.Elim.rankOf m n mat.rowLists

/-- Entrywise map (used e.g. to lift `Int` matrices to `Rat`). -/
def Matrix.map {α β : Type} {m n : Nat} (f : α → β) (mat : Matrix α m n) : Matrix β m n :=
  let rows := mat.data.data.map fun row =>
    Vec.mk' (row.data.map f) (by rw [List.length_map, row.length_eq])
  ⟨Vec.mk' rows (by rw [List.length_map, mat.data.length_eq])⟩

/-- Closed-form eigenvalues of a `2 × 2` matrix (characteristic polynomial). -/
def Matrix.eigenvalues2x2 {α : Type} [Add α] [Sub α] [Mul α] [Div α] [OfNat α 0] [OfNat α 1]
    [OfNat α 2] [OfNat α 4] (mat : Matrix α 2 2)
    (sqrt : α → α) : α × α :=
  let a := mat.get ⟨0, by decide⟩ ⟨0, by decide⟩
  let b := mat.get ⟨0, by decide⟩ ⟨1, by decide⟩
  let c := mat.get ⟨1, by decide⟩ ⟨0, by decide⟩
  let d := mat.get ⟨1, by decide⟩ ⟨1, by decide⟩
  let tr := a + d
  let det := a * d - b * c
  let disc := tr * tr - (4 : α) * det
  let s := sqrt disc
  ((tr + s) / (2 : α), (tr - s) / (2 : α))

/-- Monic characteristic polynomial of a `2 × 2` matrix: `x² - tr·x + det`, highest degree first. -/
def Matrix.charPoly2x2 {α : Type} [Add α] [Sub α] [Mul α] [Neg α] [OfNat α 0] [OfNat α 1]
    (mat : Matrix α 2 2) : List α :=
  let tr := mat.trace
  let d := mat.det2x2
  [1, -tr, d]

/-- Sum of principal `2 × 2` minors of a `3 × 3` matrix (coeff of `x` in `det(xI - A)`). -/
def Matrix.principalMinorSum3x3 {α : Type} [Add α] [Sub α] [Mul α] [OfNat α 0]
    (mat : Matrix α 3 3) : α :=
  let a00 := mat.get ⟨0, by decide⟩ ⟨0, by decide⟩
  let a01 := mat.get ⟨0, by decide⟩ ⟨1, by decide⟩
  let a02 := mat.get ⟨0, by decide⟩ ⟨2, by decide⟩
  let a10 := mat.get ⟨1, by decide⟩ ⟨0, by decide⟩
  let a11 := mat.get ⟨1, by decide⟩ ⟨1, by decide⟩
  let a12 := mat.get ⟨1, by decide⟩ ⟨2, by decide⟩
  let a20 := mat.get ⟨2, by decide⟩ ⟨0, by decide⟩
  let a21 := mat.get ⟨2, by decide⟩ ⟨1, by decide⟩
  let a22 := mat.get ⟨2, by decide⟩ ⟨2, by decide⟩
  (a00 * a11 - a01 * a10) + (a00 * a22 - a02 * a20) + (a11 * a22 - a12 * a21)

/-- Monic characteristic polynomial of a `3 × 3` matrix: `x³ - tr·x² + σ·x - det`, highest first. -/
def Matrix.charPoly3x3 {α : Type}
    [BEq α] [Add α] [Sub α] [Mul α] [Div α] [Neg α] [OfNat α 0] [OfNat α 1]
    (mat : Matrix α 3 3) : List α :=
  let tr := mat.trace
  let σ := mat.principalMinorSum3x3
  let d := mat.det
  [1, -tr, σ, -d]

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
