//! Lean Toolchain Rust Library
//!
//! This library contains Rust implementations extracted from Lean 4 code.
//! All functions are designed to be called from C/C++ code.

#![allow(clippy::missing_safety_doc)]

pub mod sha256;
pub mod hmac;
pub mod vector;
pub mod matrix;

// Re-export main functions for easier access
pub use sha256::*;
pub use hmac::*;
pub use vector::*;
pub use matrix::*;