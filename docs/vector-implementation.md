# Vector implementation (`LeanToolchain.Math.Vector`)

## Role

`Vec α n` is a **length-indexed** vector: a `List α` together with a proof that the list has length `n`. This keeps dimensions in the type and works well with `Matrix α m n`, which stores `m` rows as a `Vec (Vec α n) m`.

## Definition

```lean
structure Vec (α : Type) (n : Nat) where
  data : List α
  length_eq : data.length = n
```

## Construction and accessors

| Name | Purpose |
| --- | --- |
| `Vec.nil` | Empty vector (`n = 0`) |
| `Vec.cons` | Prepend one element |
| `Vec.mk' data h` | From a list, with `h : data.length = n` (often `rfl` for literals) |
| `Vec.head` / `Vec.tail` | Non-empty vector views |
| `Vec.get` / `Vec.set` | Index with `Fin n` |
| `Vec.toList` | Forget the index, recover `data` |

There is **no** `Vec.fromList` alias; use `Vec.mk'`.

## Operations

Element-wise `add`, `sub`, `smul`, dot product `dot`, `magSq`, `zero`, `neg`, and `cross` (length 3 only) are defined as in `LeanToolchain/Math/Vector.lean`. They require the usual typeclass instances on `α` (for example `[AddMonoid α]` for additive lemmas).

## Proven lemmas (current)

The file currently exports a focused additive bundle:

- `Vec.add_comm` (with `[AddCommSemigroup α]`)
- `Vec.add_assoc` (with `[AddMonoid α]`)
- `Vec.add_zero` (with `[AddMonoid α]`)
- `Vec.add_congr`
- Structural lemmas such as `Vec.ext`, `Vec.cons_length`, `Vec.head_cons`, `Vec.tail_cons`

Other algebraic facts (full scalar or dot-product theory) may be added over time; check `Vector.lean` for the authoritative list.

## Norms and tests

Real-valued norms (`norm2`, `norm1`, …) for `Vec ℝ n` live in `LeanToolchain/Math/Norm.lean` (mathlib-backed, `noncomputable` where needed).

Executable tests and examples: `LeanToolchain/Math/Tests/VectorTests.lean`, also invoked from `LeanToolchain/Tests/Unified.lean` for `lake test`.

## Related material

- API-style listing: [`api/math.md`](api/math.md)
- Matrix layer: `LeanToolchain/Math/Matrix.lean`
- Rust template output (separate from Lean terms): [`development/extraction.md`](development/extraction.md)
