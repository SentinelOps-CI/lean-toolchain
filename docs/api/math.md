# Mathematical API Reference

## Overview

`LeanToolchain.Math` provides **discrete** linear algebra (length-indexed `Vec`, nested-list `Matrix`) with a growing lemma suite, plus **ℝ-valued** norm definitions in `Norm.lean` built on mathlib’s `Real` and `sqrt`. Proofs cover the properties stated in the Lean files (for example additive laws for `Vec` and selected matrix identities); they are **not** a complete textbook development of numerical linear algebra.

Rust helpers for floating-point vectors and matrices are **generated** alongside crypto (see [`development/extraction.md`](../development/extraction.md)); they are template output for benchmarking and FFI-shaped experiments, not extracted proof terms.

## Vector Operations

### Vector Construction

#### `Vec.nil : Vec α 0`

Creates an empty vector of length 0.

**Example:**

```lean
let emptyVec : Vec Nat 0 := Vec.nil
```

#### `Vec.cons : α → Vec α n → Vec α (n + 1)`

Adds an element to the front of a vector.

**Parameters:**

- `x : α` - The element to add
- `v : Vec α n` - The vector to prepend to

**Returns:**

- `Vec α (n + 1)` - The new vector with the element added

**Example:**

```lean
let v1 : Vec Nat 1 := Vec.cons 1 Vec.nil
let v2 : Vec Nat 2 := Vec.cons 2 v1
-- v2 is [2, 1]
```

#### `Vec.mk' : List α → (data.length = n) → Vec α n`

Creates a vector from a list with a proof that the list length matches the dimension.

**Parameters:**

- `data : List α` - The list of elements
- `h : data.length = n` - Proof that the list length equals the dimension

**Returns:**

- `Vec α n` - The vector with the specified dimension

**Example:**

```lean
let data := [1, 2, 3, 4, 5]
let v := Vec.mk' data (by rfl)
-- v is a Vec Nat 5 containing [1, 2, 3, 4, 5]
```

#### `Vec.zero : Vec α n`

Creates a zero vector (all elements are 0).

**Returns:**

- `Vec α n` - A vector of length n with all elements set to 0

**Example:**

```lean
let zeroVec : Vec Nat 3 := Vec.zero
-- zeroVec is [0, 0, 0]
```

### Vector Access

#### `Vec.head : Vec α (n + 1) → α`

Gets the first element of a non-empty vector.

**Parameters:**

- `v : Vec α (n + 1)` - A non-empty vector

**Returns:**

- `α` - The first element

**Example:**

```lean
let v := Vec.cons 1 (Vec.cons 2 Vec.nil)
let first := v.head
-- first is 1
```

#### `Vec.tail : Vec α (n + 1) → Vec α n`

Gets all elements except the first of a non-empty vector.

**Parameters:**

- `v : Vec α (n + 1)` - A non-empty vector

**Returns:**

- `Vec α n` - The vector without the first element

**Example:**

```lean
let v := Vec.cons 1 (Vec.cons 2 Vec.nil)
let rest := v.tail
-- rest is [2]
```

#### `Vec.get : Vec α n → Fin n → α`

Gets an element at a specific index.

**Parameters:**

- `v : Vec α n` - The vector
- `i : Fin n` - The index (must be less than n)

**Returns:**

- `α` - The element at the specified index

**Example:**

```lean
let v := Vec.mk' [1, 2, 3] (by rfl)
let element := v.get ⟨1, by simp⟩
-- element is 2
```

#### `Vec.set : Vec α n → Fin n → α → Vec α n`

Sets an element at a specific index.

**Parameters:**

- `v : Vec α n` - The vector
- `i : Fin n` - The index (must be less than n)
- `x : α` - The new value

**Returns:**

- `Vec α n` - The vector with the updated element

**Example:**

```lean
let v := Vec.mk' [1, 2, 3] (by rfl)
let v2 := v.set ⟨1, by simp⟩ 42
-- v2 is [1, 42, 3]
```

### Vector Arithmetic

#### `Vec.add : Vec α n → Vec α n → Vec α n`

Element-wise addition of two vectors.

**Parameters:**

- `v1 : Vec α n` - First vector
- `v2 : Vec α n` - Second vector

**Returns:**

- `Vec α n` - The sum of the vectors

**Example:**

```lean
let v1 := Vec.mk' [1, 2, 3] (by rfl)
let v2 := Vec.mk' [4, 5, 6] (by rfl)
let sum := v1.add v2
-- sum is [5, 7, 9]
```

#### `Vec.sub : Vec α n → Vec α n → Vec α n`

Element-wise subtraction of two vectors.

**Parameters:**

- `v1 : Vec α n` - First vector
- `v2 : Vec α n` - Second vector

**Returns:**

- `Vec α n` - The difference of the vectors

**Example:**

```lean
let v1 := Vec.mk' [4, 5, 6] (by rfl)
let v2 := Vec.mk' [1, 2, 3] (by rfl)
let diff := v1.sub v2
-- diff is [3, 3, 3]
```

#### `Vec.smul : α → Vec β n → Vec β n`

Scalar multiplication of a vector.

**Parameters:**

- `c : α` - The scalar
- `v : Vec β n` - The vector

**Returns:**

- `Vec β n` - The scaled vector

**Example:**

```lean
let v := Vec.mk' [1, 2, 3] (by rfl)
let scaled := v.smul 2
-- scaled is [2, 4, 6]
```

### Vector Products

#### `Vec.dot : Vec α n → Vec α n → α`

Computes the dot product of two vectors.

**Parameters:**

- `v1 : Vec α n` - First vector
- `v2 : Vec α n` - Second vector

**Returns:**

- `α` - The dot product

**Example:**

```lean
let v1 := Vec.mk' [1, 2, 3] (by rfl)
let v2 := Vec.mk' [4, 5, 6] (by rfl)
let dot := v1.dot v2
-- dot is 32 (1*4 + 2*5 + 3*6)
```

#### `Vec.magSq : Vec α n → α`

Computes the magnitude squared of a vector.

**Parameters:**

- `v : Vec α n` - The vector

**Returns:**

- `α` - The magnitude squared (dot product with itself)

**Example:**

```lean
let v := Vec.mk' [3, 4] (by rfl)
let magSq := v.magSq
-- magSq is 25 (3*3 + 4*4)
```

### Vector Conversion

#### `Vec.toList : Vec α n → List α`

Converts a vector to a list.

**Parameters:**

- `v : Vec α n` - The vector

**Returns:**

- `List α` - The list representation

**Example:**

```lean
let v := Vec.mk' [1, 2, 3] (by rfl)
let list := v.toList
-- list is [1, 2, 3]
```

There is no separate `Vec.fromList` helper: use `Vec.mk' data h` with `h : data.length = n` (often `rfl` when the list is literal).

## Matrix Operations

### Matrix Construction

#### `Matrix.mk' : List (List α) → (data.length = m) → (∀ row, row ∈ data → row.length = n) → Matrix α m n`

Creates a matrix from a list of lists with proofs about dimensions.

**Parameters:**

- `data : List (List α)` - The matrix data as a list of rows
- `h : data.length = m` - Proof that the number of rows equals m
- `h' : ∀ row, row ∈ data → row.length = n` - Proof that each row has length n

**Returns:**

- `Matrix α m n` - The matrix

**Example:**

```lean
let data := [[1, 2], [3, 4]]
let mat := Matrix.mk' data rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
-- mat is a 2x2 matrix
```

#### `Matrix.zero : Matrix α m n`

Creates a zero matrix (all elements are 0).

**Returns:**

- `Matrix α m n` - A matrix with all elements set to 0

**Example:**

```lean
let zeroMat : Matrix Nat 2 2 := Matrix.zero
-- zeroMat is [[0, 0], [0, 0]]
```

#### `Matrix.identity : Matrix α n n`

Creates an identity matrix.

**Returns:**

- `Matrix α n n` - An n×n identity matrix

**Example:**

```lean
let idMat : Matrix Nat 2 2 := Matrix.identity
-- idMat is [[1, 0], [0, 1]]
```

### Matrix Access

#### `Matrix.get : Matrix α m n → Fin m → Fin n → α`

Gets an element at a specific position.

**Parameters:**

- `mat : Matrix α m n` - The matrix
- `i : Fin m` - The row index
- `j : Fin n` - The column index

**Returns:**

- `α` - The element at position (i, j)

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let element := mat.get ⟨0, by simp⟩ ⟨1, by simp⟩
-- element is 2
```

#### `Matrix.set : Matrix α m n → Fin m → Fin n → α → Matrix α m n`

Sets an element at a specific position.

**Parameters:**

- `mat : Matrix α m n` - The matrix
- `i : Fin m` - The row index
- `j : Fin n` - The column index
- `x : α` - The new value

**Returns:**

- `Matrix α m n` - The matrix with the updated element

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let mat2 := mat.set ⟨0, by simp⟩ ⟨1, by simp⟩ 42
-- mat2 has 42 at position (0, 1)
```

#### `Matrix.row : Matrix α m n → Fin m → Vec α n`

Gets a row of the matrix.

**Parameters:**

- `mat : Matrix α m n` - The matrix
- `i : Fin m` - The row index

**Returns:**

- `Vec α n` - The i-th row as a vector

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let row := mat.row ⟨0, by simp⟩
-- row is [1, 2]
```

#### `Matrix.col : Matrix α m n → Fin n → Vec α m`

Gets a column of the matrix.

**Parameters:**

- `mat : Matrix α m n` - The matrix
- `j : Fin n` - The column index

**Returns:**

- `Vec α m` - The j-th column as a vector

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let col := mat.col ⟨0, by simp⟩
-- col is [1, 3]
```

### Matrix Arithmetic

#### `Matrix.add : Matrix α m n → Matrix α m n → Matrix α m n`

Element-wise addition of two matrices.

**Parameters:**

- `mat1 : Matrix α m n` - First matrix
- `mat2 : Matrix α m n` - Second matrix

**Returns:**

- `Matrix α m n` - The sum of the matrices

**Example:**

```lean
let mat1 := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let mat2 := Matrix.mk' [[5, 6], [7, 8]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let sum := mat1.add mat2
-- sum is [[6, 8], [10, 12]]
```

#### `Matrix.sub : Matrix α m n → Matrix α m n → Matrix α m n`

Element-wise subtraction of two matrices.

**Parameters:**

- `mat1 : Matrix α m n` - First matrix
- `mat2 : Matrix α m n` - Second matrix

**Returns:**

- `Matrix α m n` - The difference of the matrices

**Example:**

```lean
let mat1 := Matrix.mk' [[5, 6], [7, 8]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let mat2 := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let diff := mat1.sub mat2
-- diff is [[4, 4], [4, 4]]
```

#### `Matrix.smul : α → Matrix β m n → Matrix β m n`

Scalar multiplication of a matrix.

**Parameters:**

- `c : α` - The scalar
- `mat : Matrix β m n` - The matrix

**Returns:**

- `Matrix β m n` - The scaled matrix

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let scaled := mat.smul 2
-- scaled is [[2, 4], [6, 8]]
```

### Matrix Multiplication

#### `Matrix.mul : Matrix α m n → Matrix α n p → Matrix α m p`

Matrix multiplication.

**Parameters:**

- `mat1 : Matrix α m n` - First matrix (m×n)
- `mat2 : Matrix α n p` - Second matrix (n×p)

**Returns:**

- `Matrix α m p` - The product matrix (m×p)

**Example:**

```lean
let mat1 := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let mat2 := Matrix.mk' [[5, 6], [7, 8]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let product := mat1.mul mat2
-- product is [[19, 22], [43, 50]]
```

#### `Matrix.mulVec : Matrix α m n → Vec α n → Vec α m`

Matrix-vector multiplication.

**Parameters:**

- `mat : Matrix α m n` - The matrix
- `vec : Vec α n` - The vector

**Returns:**

- `Vec α m` - The result vector

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let vec := Vec.mk' [5, 6] (by rfl)
let result := mat.mulVec vec
-- result is [17, 39]
```

#### `Vec.mulMat : Vec α m → Matrix α m n → Vec α n`

Vector-matrix multiplication.

**Parameters:**

- `vec : Vec α m` - The vector
- `mat : Matrix α m n` - The matrix

**Returns:**

- `Vec α n` - The result vector

**Example:**

```lean
let vec := Vec.mk' [1, 2] (by rfl)
let mat := Matrix.mk' [[3, 4], [5, 6]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let result := vec.mulMat mat
-- result is [13, 16]
```

### Matrix Operations

#### `Matrix.transpose : Matrix α m n → Matrix α n m`

Transposes a matrix.

**Parameters:**

- `mat : Matrix α m n` - The matrix

**Returns:**

- `Matrix α n m` - The transposed matrix

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let transposed := mat.transpose
-- transposed is [[1, 3], [2, 4]]
```

#### `Matrix.trace : Matrix α n n → α`

Computes the trace of a square matrix.

**Parameters:**

- `mat : Matrix α n n` - The square matrix

**Returns:**

- `α` - The trace (sum of diagonal elements)

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let trace := mat.trace
-- trace is 5 (1 + 4)
```

#### `Matrix.det2x2 : Matrix α 2 2 → α`

Computes the determinant of a 2×2 matrix.

**Parameters:**

- `mat : Matrix α 2 2` - The 2×2 matrix

**Returns:**

- `α` - The determinant

**Example:**

```lean
let mat := Matrix.mk' [[1, 2], [3, 4]] rfl (by intro row h; rcases h with rfl | rfl <;> rfl)
let det := mat.det2x2
-- det is -2 (1*4 - 2*3)
```

## Mathematical properties (status)

Many **expected** identities (dot product laws, full matrix ring laws, and so on) are standard algebraically but are **not** all stated or proved in the current `LeanToolchain/Math` files. Treat `Vector.lean` and `Matrix.lean` as the source of truth for what is actually in the library today; the lists below are **design intent**, not a guarantee of existing `theorem` declarations.

### Vector (typical goals)

- Addition is commutative / associative on `AddCommSemigroup` / `AddMonoid` carriers (see proved lemmas in `Vector.lean`).
- Further facts about `smul`, `dot`, and `magSq` may be added incrementally.

### Matrix (typical goals)

- Matrix addition should behave as a componentwise monoid where instances allow.
- Multiplication and distributivity are defined operationally; separate lemma modules may grow over time.

## Performance Characteristics

- **Vector Operations**: O(n) time complexity where n is the vector length
- **Matrix Addition/Subtraction**: O(m×n) time complexity
- **Matrix Multiplication**: O(m×n×p) time complexity for m×n × n×p matrices
- **Matrix Transpose**: O(m×n) time complexity
- **Memory Usage**: Linear in the size of the data structures

## Type Safety

The implementation provides strong type safety:

- **Dimension Checking**: All operations preserve vector and matrix dimensions
- **Index Bounds**: All indexing operations use `Fin` types to ensure bounds safety
- **Type Constraints**: Operations require appropriate typeclass instances (Add, Mul, etc.)

## Testing

Executable smoke tests live under `LeanToolchain/Math/Tests/` (vectors, matrices, norms) and are included in the combined `lake test` driver (`LeanToolchain/Tests/Unified.lean`). They print examples and basic checks; they are **not** a substitute for a full random-testing or benchmarking harness.

## Rust helpers (code generation)

Floating-point vector and matrix **FFI-shaped** helpers are emitted into the same `rust/` crate as the crypto modules when you run `lake exe extract`. They exist for benchmarks and experiments; they are **not** Lean-term extraction and are not covered by the same theorems as the Lean `Vec` / `Matrix` types.

```bash
lake exe extract
cd rust
cargo test
cargo clippy --all-targets -- -D warnings
```

See [`development/extraction.md`](../development/extraction.md) for the full picture.
