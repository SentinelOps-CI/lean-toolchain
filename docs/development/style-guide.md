# Style Guide

## Overview

This style guide establishes coding standards and best practices for the Lean Toolchain project. Following these guidelines ensures code consistency, readability, and maintainability.

## General Principles

### 1. Clarity Over Cleverness

Write code that is easy to understand and maintain. Prefer explicit, readable code over clever but obscure solutions.

**Good:**

```lean
def addVectors (v1 v2 : Vec Nat n) : Vec Nat n :=
  v1.add v2
```

**Avoid:**

```lean
def addVectors := Vec.add
```

### 2. Type Safety First

Leverage Lean's type system to catch errors at compile time. Use dependent types and proofs where appropriate.

**Good:**

```lean
def getElement (v : Vec α n) (i : Fin n) : α :=
  v.get i
```

**Avoid:**

```lean
-- Do not use `sorry` to manufacture bounds; prefer `Fin n` or a real proof.
def getElement (v : Vec α n) (i : Nat) (h : i < n) : α :=
  v.get ⟨i, h⟩
```

### 3. Formal correctness

Prefer **proof-carrying** definitions for core APIs (`LeanToolchain/` is **`sorry`-free by policy**; see `scripts/check_sorry.sh`). When a lemma is not yet proved, do not merge `sorry` into production namespaces: use an allowlisted experimental file, a clearly named `Sketch` namespace, or discuss a waiver in `scripts/sorry_allowlist.txt` with maintainers.

## Naming Conventions

### Functions and Definitions

- Use **camelCase** for function names
- Use descriptive names that indicate the function's purpose
- Prefix boolean functions with `is`, `has`, `can`, etc.

**Good:**

```lean
def computeSHA256 (message : ByteArray) : ByteArray
def isValidHash (hash : String) : Bool
def hasValidLength (data : List α) (expected : Nat) : Bool
```

**Avoid:**

```lean
def sha256 (m : ByteArray) : ByteArray
def valid (h : String) : Bool
def check (d : List α) (n : Nat) : Bool
```

### Variables

- Use **camelCase** for variable names
- Use descriptive names that indicate the variable's purpose
- Use single letters only for mathematical variables (i, j, k, x, y, z)

**Good:**

```lean
def processMessage (inputMessage : ByteArray) : ByteArray :=
  let paddedMessage := padMessage inputMessage
  let finalHash := computeHash paddedMessage
  finalHash
```

**Avoid:**

```lean
def processMessage (m : ByteArray) : ByteArray :=
  let p := padMessage m
  let h := computeHash p
  h
```

### Types and Structures

- Use **PascalCase** for type and structure names
- Use descriptive names that indicate the type's purpose

**Good:**

```lean
structure Matrix (α : Type) (m n : Nat) where
  data : Vec (Vec α n) m

def Vec (α : Type) (n : Nat) :=
  { data : List α // data.length = n }
```

**Avoid:**

```lean
structure Mat (α : Type) (m n : Nat) where
  d : Vec (Vec α n) m

def V (α : Type) (n : Nat) :=
  { d : List α // d.length = n }
```

### Constants

- Use **UPPER_SNAKE_CASE** for constants
- Use descriptive names that indicate the constant's purpose

**Good:**

```lean
def SHA256_BLOCK_SIZE : Nat := 64
def HMAC_OUTER_PAD : UInt8 := 0x5c
def HMAC_INNER_PAD : UInt8 := 0x36
```

**Avoid:**

```lean
def BLOCK_SIZE : Nat := 64
def OUTER_PAD : UInt8 := 0x5c
def INNER_PAD : UInt8 := 0x36
```

## Code Organization

### Module Structure

Organize modules in the following order:

1. **Module documentation** (/-! ... -/)
2. **Imports**
3. **Namespace declaration**
4. **Constants and type definitions**
5. **Helper functions**
6. **Main functions**
7. **Theorems and proofs**
8. **Tests** (if included in the same file)

**Example:**

```lean
/-!
# SHA-256 Implementation

SHA-256 on `ByteArray` with supporting length and padding lemmas.
-/

import Init.Data.ByteArray
import Init.Data.Nat.Basic

namespace LeanToolchain.Crypto

-- Constants
def SHA256_BLOCK_SIZE : Nat := 64
def SHA256_INITIAL_HASH : Array UInt32 := #[...]

-- Helper functions
def rotateRight32 (x : UInt32) (n : Nat) : UInt32 :=
  (x >>> (n : UInt32)) ||| (x <<< ((32 - n) : UInt32))

-- Main functions
def sha256 (message : ByteArray) : ByteArray :=
  -- implementation

-- Theorems
theorem sha256_output_length (msg : ByteArray) : (sha256 msg).size = 32 :=
  -- proof

end LeanToolchain.Crypto
```

### Function Organization

Within a function, organize code in the following order:

1. **Input validation** (if needed)
2. **Variable declarations**
3. **Main computation**
4. **Return statement**

**Example:**

```lean
def processBlock (hash : Array UInt32) (block : ByteArray) : Array UInt32 :=
  -- Input validation
  if block.size != 64 then
    return hash

  -- Variable declarations
  let words := bytesToWords block.data
  let schedule := generateMessageSchedule words

  -- Main computation
  let newHash := compressHash hash schedule

  -- Return
  newHash
```

## Documentation Standards

### Module Documentation

Every module should have a module-level documentation comment that explains:

- What the module provides
- Key concepts and algorithms
- Usage examples
- Dependencies and requirements

**Example (module doc + usage sketch):**

```lean
/-!
# Vector operations

Length-indexed `Vec α n`; see `LeanToolchain/Math/Vector.lean` for imports, definitions, and lemmas.
-/
```

### Function Documentation

Every public function should have a documentation comment that includes:

- A clear description of what the function does
- Parameter descriptions with types
- Return value description with type
- Usage example
- Any important notes or warnings

**Example:**
```lean
/-- Computes the SHA-256 hash of a byte array.

    This function implements the SHA-256 cryptographic hash function
    according to NIST FIPS 180-4. The input is padded according to
    SHA-256 specifications and processed in 512-bit blocks.

    **Parameters:**
    - `message : ByteArray` - The input message to hash

    **Returns:**
    - `ByteArray` - The 32-byte SHA-256 hash

    **Example:**
    ```lean
    let message := stringToBytes "hello world"
    let hash := sha256 message
    -- hash is a 32-byte array containing the SHA-256 hash
    ```

    **Note:** This function is not constant-time and should not be used
    for timing-sensitive applications.
-/
def sha256 (message : ByteArray) : ByteArray :=
  -- implementation
```

### Theorem Documentation

Every theorem should have a documentation comment that explains:

- What the theorem proves
- Why it's important
- Any assumptions or preconditions

**Example:**

```lean
/-- The output of SHA-256 is always 32 bytes.

    This theorem establishes that the SHA-256 function always produces
    a 256-bit (32-byte) output regardless of input size. This is a
    fundamental property of SHA-256 and is required for cryptographic
    applications.

    **Proof:** The SHA-256 algorithm processes input in 512-bit blocks
    and produces a 256-bit final hash by combining 8 32-bit words.
-/
theorem sha256_output_length (msg : ByteArray) : (sha256 msg).size = 32 :=
  -- proof
```

## Code Formatting

### Indentation

- Use **2 spaces** for indentation
- Align related code blocks
- Use consistent indentation within expressions

**Good:**

```lean
def complexFunction (x : Nat) (y : Nat) (z : Nat) : Nat :=
  let result1 := x + y
  let result2 := y + z
  let result3 := z + x
  result1 + result2 + result3
```

**Avoid:**

```lean
def complexFunction (x : Nat) (y : Nat) (z : Nat) : Nat :=
let result1 := x + y
let result2 := y + z
let result3 := z + x
result1 + result2 + result3
```

### Line Length

- Keep lines under **100 characters** when possible
- Break long expressions across multiple lines
- Use parentheses to clarify operator precedence

**Good:**

```lean
def longExpression :=
  (a + b + c) * (d + e + f) +
  (g + h + i) * (j + k + l)
```

**Avoid:**

```lean
def longExpression := (a + b + c) * (d + e + f) + (g + h + i) * (j + k + l)
```

### Spacing

- Use spaces around operators
- Use spaces after commas
- Use spaces after colons in type annotations
- Don't use spaces around parentheses

**Good:**

```lean
def add (x : Nat) (y : Nat) : Nat :=
  x + y

def createVector (a : α) (b : α) (c : α) : Vec α 3 :=
  Vec.cons a (Vec.cons b (Vec.cons c Vec.nil))
```

**Avoid:**

```lean
def add(x:Nat)(y:Nat):Nat :=
  x+y

def createVector(a:α,b:α,c:α):Vec α 3 :=
  Vec.cons a(Vec.cons b(Vec.cons c Vec.nil))
```

## Error Handling

### Use Option Types

Use `Option` types for operations that may fail instead of throwing exceptions.

**Good:**

```lean
def safeDivide (x : Nat) (y : Nat) : Option Nat :=
  if y = 0 then none else some (x / y)
```

**Avoid:**

```lean
def unsafeDivide (x : Nat) (y : Nat) : Nat :=
  x / y  -- May fail if y = 0
```

### Validate Inputs

Validate inputs at the beginning of functions and return appropriate error values.

**Good:**

```lean
def processData (data : List α) (expectedLength : Nat) : Option (Vec α expectedLength) :=
  if data.length = expectedLength then
    some (Vec.mk' data (by rfl))
  else
    none
```

**Avoid:**

```lean
def processData (data : List α) (expectedLength : Nat) : Vec α expectedLength :=
  Vec.mk' data expectedLength sorry  -- Unsafe
```

## Performance Considerations

### Avoid Unnecessary Allocations

Minimize memory allocations in performance-critical code.

**Good:**

```lean
def efficientSum (data : List Nat) : Nat :=
  List.foldl (· + ·) 0 data
```

**Avoid:**

```lean
def inefficientSum (data : List Nat) : Nat :=
  let intermediate := data.map id  -- Unnecessary allocation
  List.foldl (· + ·) 0 intermediate
```

### Use Appropriate Data Structures

Choose data structures based on the operations you need to perform.

**Good:**

```lean
-- For random access
def getElement (arr : Array α) (i : Fin arr.size) : α :=
  arr[i]

-- For sequential access
def processList (data : List α) : List β :=
  data.map processElement
```

## Testing Standards

### Test Coverage

- Write tests for all public functions
- Test edge cases (empty inputs, boundary values)
- Test error conditions
- Use property-based testing where appropriate

**Example:**

```lean
def testVectorAddition : IO Unit := do
  -- Test basic functionality
  let v1 := Vec.mk' [1, 2, 3] (by rfl)
  let v2 := Vec.mk' [4, 5, 6] (by rfl)
  let sum := v1.add v2
  assert! sum.toList = [5, 7, 9]

  -- Test edge case: zero vector
  let zero := Vec.zero
  let result := v1.add zero
  assert! result.toList = v1.toList

  -- Test property: commutativity
  let sum1 := v1.add v2
  let sum2 := v2.add v1
  assert! sum1.toList = sum2.toList
```

### Property-Based Testing

Use property-based testing to verify mathematical properties.

**Example:**

```lean
def testVectorProperties : IO Unit := do
  -- Test commutativity of addition
  for i in List.range 10 do
    let v1 := generateRandomVector i
    let v2 := generateRandomVector i
    let sum1 := v1.add v2
    let sum2 := v2.add v1
    assert! sum1.toList = sum2.toList

  -- Test associativity of addition
  for i in List.range 10 do
    let v1 := generateRandomVector i
    let v2 := generateRandomVector i
    let v3 := generateRandomVector i
    let sum1 := (v1.add v2).add v3
    let sum2 := v1.add (v2.add v3)
    assert! sum1.toList = sum2.toList
```

## Security Considerations

### Cryptographic Code

- Never log sensitive data (keys, passwords, etc.)
- Use constant-time operations where timing attacks are a concern
- Validate all inputs to cryptographic functions
- Use cryptographically secure random number generators

**Good:**

```lean
def secureHash (message : ByteArray) : ByteArray :=
  -- Validate input
  if message.size > MAX_MESSAGE_SIZE then
    panic! "Message too large"

  -- Process securely
  let hash := sha256 message

  -- Don't log sensitive data
  hash
```

**Avoid:**

```lean
def insecureHash (message : ByteArray) : ByteArray :=
  -- Logging sensitive data
  IO.println s!"Hashing message: {message}"

  -- No input validation
  sha256 message
```

## Proof automation (optional)

mathlib already depends on **Aesop**. When a proof is mostly search over a local
algebraic goal, importing `Aesop` in that file (or a leaf module) is acceptable.
Prefer short, stable proofs (`simp`, `omega`, `rfl`) when they communicate the
mathematical step directly; reach for automation when it removes repetitive
case splits without hiding the main idea.

## Version Control

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Examples:**

```
feat(crypto): add SHA-256 implementation

feat(math): implement vector operations

fix(vector): correct dot product calculation

docs(api): update cryptographic API documentation

test(crypto): add NIST test vectors for SHA-256
```

### Branch Naming

Use descriptive branch names:

- `feature/add-hmac-implementation`
- `bugfix/fix-vector-addition`
- `docs/update-api-reference`
- `test/add-crypto-benchmarks`

## Code Review Guidelines

### What to Look For

- **Correctness**: Does the code do what it's supposed to do?
- **Readability**: Is the code easy to understand?
- **Performance**: Are there any obvious performance issues?
- **Security**: Are there any security vulnerabilities?
- **Testing**: Is the code adequately tested?
- **Documentation**: Is the code properly documented?

### Review Process

1. **Functionality**: Verify that the code implements the intended functionality
2. **Style**: Check that the code follows the style guide
3. **Tests**: Ensure that tests are comprehensive and pass
4. **Documentation**: Verify that documentation is complete and accurate
5. **Security**: Check for potential security issues
6. **Performance**: Look for performance optimizations

## Conclusion

Following this style guide ensures that the Lean Toolchain codebase remains consistent, readable, and maintainable. All contributors should familiarize themselves with these guidelines and apply them to their code.

Remember that the goal is to write code that is not only correct but also clear, well-documented, and easy to understand for future developers.
