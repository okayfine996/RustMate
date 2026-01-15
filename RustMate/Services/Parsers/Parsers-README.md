# Rustup Output Parsers

This directory contains parsers for rustup command output.

## Parsers

- `ToolchainParser.swift` - Parses `rustup toolchain list` output
- `ComponentParser.swift` - Parses `rustup component list` output
- `TargetParser.swift` - Parses `rustup target list` output
- `ShowParser.swift` - Parses `rustup show` output for active toolchain and override sources

## Design Principles

- **Resilient parsing**: Always provide fallback for unknown formats
- **Structured output**: Return domain models (`Toolchain`, `Component`, `Target`, `ProjectContext`)
- **No side effects**: Pure functions that transform strings to models
- **Test sample library**: Maintain test cases for rustup output variations

## Parsing Strategy

1. Use regex/string scanning for stable markers (e.g., `(default)`, `overridden by`)
2. On parse failure: Return `unknown` reason + snippet for UI fallback display
3. Never throw - always return a result (success with data, or success with partial/unknown data)

## Usage

```swift
let output = try await processRunner.run(command: "rustup", args: ["toolchain", "list"])
let toolchains = ToolchainParser.parse(output.stdout)
```
