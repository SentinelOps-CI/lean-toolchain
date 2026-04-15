import Init.Data.List.Basic
import Mathlib.Algebra.Group.Defs
import Mathlib.Algebra.Ring.Defs
import Mathlib.Data.List.Zip

set_option checkBinderAnnotations false

/-!
# Dimension-Indexed Vectors

Finite vectors as length-indexed lists; core lemmas for additive structure.
-/

namespace LeanToolchain.Math

structure Vec (α : Type) (n : Nat) where
  data : List α
  length_eq : data.length = n

def Vec.mk' {α : Type} (data : List α) (h : data.length = n) : Vec α n :=
  ⟨data, h⟩

def Vec.nil {α : Type} : Vec α 0 :=
  ⟨[], rfl⟩

def Vec.cons {α : Type} {n : Nat} (x : α) (v : Vec α n) : Vec α (n + 1) :=
  ⟨x :: v.data, by rw [List.length_cons, v.length_eq]⟩

def Vec.head {α : Type} {n : Nat} (v : Vec α (n + 1)) : α :=
  match v.data, v.length_eq with
  | x :: _, _ => x
  | [], h => nomatch h

def Vec.tail {α : Type} {n : Nat} (v : Vec α (n + 1)) : Vec α n :=
  match v.data, v.length_eq with
  | _ :: xs, h => ⟨xs, by rw [List.length_cons] at h; exact Nat.succ.inj h⟩
  | [], h => nomatch h

def Vec.get {α : Type} {n : Nat} (v : Vec α n) (i : Fin n) : α :=
  v.data[i.val]'(show i.val < v.data.length by rw [v.length_eq]; exact i.isLt)

def Vec.set {α : Type} {n : Nat} (v : Vec α n) (i : Fin n) (x : α) : Vec α n :=
  ⟨v.data.set i x, by rw [List.length_set, v.length_eq]⟩

def Vec.add {α : Type} [Add α] {n : Nat} (v1 v2 : Vec α n) : Vec α n :=
  ⟨List.zipWith (· + ·) v1.data v2.data, by
    rw [List.length_zipWith, v1.length_eq, v2.length_eq, Nat.min_self]⟩

def Vec.sub {α : Type} [Sub α] {n : Nat} (v1 v2 : Vec α n) : Vec α n :=
  ⟨List.zipWith (· - ·) v1.data v2.data, by
    rw [List.length_zipWith, v1.length_eq, v2.length_eq, Nat.min_self]⟩

def Vec.smul {α β : Type} [HMul α β β] {n : Nat} (c : α) (v : Vec β n) : Vec β n :=
  ⟨v.data.map (fun x => c * x), by rw [List.length_map, v.length_eq]⟩

def Vec.dot {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v1 v2 : Vec α n) : α :=
  List.foldl (· + ·) 0 (List.zipWith (· * ·) v1.data v2.data)

def Vec.magSq {α : Type} [Add α] [Mul α] [OfNat α 0] {n : Nat} (v : Vec α n) : α :=
  v.dot v

def Vec.toList {α : Type} {n : Nat} (v : Vec α n) : List α :=
  v.data

def Vec.zero {α : Type} [OfNat α 0] {n : Nat} : Vec α n :=
  ⟨List.replicate n 0, by rw [List.length_replicate]⟩

def Vec.neg {α : Type} [Neg α] {n : Nat} (v : Vec α n) : Vec α n :=
  ⟨v.data.map Neg.neg, by rw [List.length_map, v.length_eq]⟩

def Vec.cross {α : Type} [Sub α] [Mul α] {v1 v2 : Vec α 3} : Vec α 3 :=
  let x1 := v1.get ⟨0, by simp⟩
  let y1 := v1.get ⟨1, by simp⟩
  let z1 := v1.get ⟨2, by simp⟩
  let x2 := v2.get ⟨0, by simp⟩
  let y2 := v2.get ⟨1, by simp⟩
  let z2 := v2.get ⟨2, by simp⟩
  Vec.cons (y1 * z2 - z1 * y2) (Vec.cons (z1 * x2 - x1 * z2) (Vec.cons (x1 * y2 - y1 * x2) Vec.nil))

theorem Vec.nil_empty {α : Type} : (Vec.nil : Vec α 0).data = [] := rfl

theorem Vec.cons_length {α : Type} {n : Nat} (x : α) (v : Vec α n) :
    (Vec.cons x v).data.length = n + 1 := by rw [Vec.cons, List.length_cons, v.length_eq]

theorem Vec.head_cons {α : Type} {n : Nat} (x : α) (v : Vec α n) :
    (Vec.cons x v).head = x := by simp [Vec.cons, Vec.head]

theorem Vec.tail_cons {α : Type} {n : Nat} (x : α) (v : Vec α n) :
    (Vec.cons x v).tail = v := by
  cases v
  simp [Vec.cons, Vec.tail]

theorem Vec.ext {α : Type} {n : Nat} (v1 v2 : Vec α n) (h : v1.data = v2.data) : v1 = v2 := by
  cases v1; cases v2
  congr

open List

private lemma zipWith_add_comm {α : Type} [AddCommSemigroup α] (xs ys : List α) :
    zipWith (· + ·) xs ys = zipWith (· + ·) ys xs := by
  induction xs generalizing ys with
  | nil => cases ys <;> simp [zipWith]
  | cons x xs ih =>
    cases ys with
    | nil => simp [zipWith]
    | cons y ys => simp [zipWith, ih, add_comm x y]

private lemma zipWith_add_assoc {α : Type} [AddMonoid α] (xs ys zs : List α)
    (hxy : xs.length = ys.length) (hyz : ys.length = zs.length) :
    zipWith (· + ·) (zipWith (· + ·) xs ys) zs = zipWith (· + ·) xs (zipWith (· + ·) ys zs) := by
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
        simp [zipWith, add_assoc, ih _ _ hxy hyz]

private lemma zipWith_add_zero_right {α : Type} [AddZeroClass α] (l : List α) :
    zipWith (· + ·) l (replicate l.length 0) = l := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp [zipWith, replicate, ih, add_zero]

theorem Vec.add_comm {α : Type} [AddCommSemigroup α] {n : Nat} (v1 v2 : Vec α n) :
    v1.add v2 = v2.add v1 := by
  cases v1; cases v2
  apply Vec.ext
  simp [Vec.add, zipWith_add_comm]

theorem Vec.add_assoc {α : Type} [AddMonoid α] {n : Nat} (v1 v2 v3 : Vec α n) :
    (v1.add v2).add v3 = v1.add (v2.add v3) := by
  match v1, v2, v3 with
  | ⟨d1, h1⟩, ⟨d2, h2⟩, ⟨d3, h3⟩ =>
    apply Vec.ext
    simpa [Vec.add] using
      zipWith_add_assoc d1 d2 d3 (h1.trans h2.symm) (h2.trans h3.symm)

theorem Vec.add_zero {α : Type} [AddMonoid α] {n : Nat} (v : Vec α n) :
    v.add Vec.zero = v := by
  match v with
  | ⟨d, h⟩ =>
    apply Vec.ext
    dsimp only [Vec.add, Vec.zero]
    rw [h.symm]
    exact zipWith_add_zero_right d

theorem Vec.add_congr {α : Type} [Add α] {n : Nat} {v1 v2 v3 v4 : Vec α n}
    (h1 : v1 = v2) (h2 : v3 = v4) : v1.add v3 = v2.add v4 := by rw [h1, h2]

end LeanToolchain.Math
