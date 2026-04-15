import Lake
open Lake DSL

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.21.0"

package leanToolchain where
  -- Single executable invoked by `lake test` (crypto + math smoke tests).
  testRunner := "leanToolchainTests"

@[default_target]
lean_lib LeanToolchain

lean_exe leanToolchain {
  root := `Main
}

lean_exe cryptoTests {
  root := `LeanToolchain.Crypto.Tests.Main
}

lean_exe mathTests {
  root := `LeanToolchain.Math.Tests.Main
}

lean_exe leanToolchainTests {
  root := `LeanToolchain.Tests.Unified
}

-- Rust extraction targets
lean_exe extract {
  root := `LeanToolchain.Extraction.Main
}

lean_exe benchmarks {
  root := `LeanToolchain.Benchmarks.Main
}
