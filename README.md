# Lean Toolchain

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cryptographic, math, and data-parsing primitives formally proven in Lean 4.

## Overview

Lean Toolchain provides a collection of formally verified cryptographic algorithms, mathematical operations, and data parsing utilities. All implementations are proven correct in Lean 4 and can be extracted to high-performance Rust code.

## Key Features

- **Formally Verified**: All algorithms come with mathematical proofs of correctness
- **High Performance**: Extracted Rust code matches or exceeds industry standards
- **Comprehensive**: SHA-256, HMAC, linear algebra, CSV/JSON parsing
- **Developer Friendly**: Clear documentation, examples, and contribution guidelines

## Quick Start

### Prerequisites

- [Lean 4](https://leanprover.github.io/lean4/doc/quickstart.html)
- [Rust](https://rustup.rs/) (for extraction)

### Installation

```bash
# Clone the repository
git clone https://github.com/SentinelOps-CI/lean-toolchain.git
cd lean-toolchain

# Build the project
lake build

# Run tests
lake test
```

### Usage

```lean
import LeanToolchain.Crypto.SHA256
import LeanToolchain.Math.Vector

-- SHA-256 hashing
#eval sha256 "hello world"

-- Vector operations
#eval Vec.cons 1 (Vec.cons 2 Vec.nil)
```

## Project Structure

```
lean-toolchain/
├── LeanToolchain/           # Main library
│   ├── Crypto/             # Cryptographic primitives
│   ├── Math/               # Mathematical operations
│   └── Data/               # Data parsing utilities
├── docs/                   # Documentation
├── bench/                  # Benchmarks
└── scripts/                # Build and release scripts
```

## Development

### Running Tests

```bash
lake test
```

### Building Documentation

```bash
# Install mkdocs-material
pip install mkdocs-material

# Build docs
mkdocs build
```

### Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) and [Development Documentation](docs/development/contributing.md) for details.

## Documentation

- [API Reference](docs/api/)
- [Examples](docs/examples/)
- [Development Guide](docs/development/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Lean 4](https://leanprover.github.io/lean4/) - The theorem prover and programming language
- [RustCrypto](https://github.com/RustCrypto) - For reference implementations
- [NIST](https://www.nist.gov/) - For cryptographic test vectors
