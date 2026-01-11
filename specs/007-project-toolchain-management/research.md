# Research: Project Management with Toolchain Configuration

**Feature**: 007-project-toolchain-management  
**Date**: 2025-01-27  
**Purpose**: Resolve technical unknowns and make implementation decisions

## Research Questions

### 1. TOML Parsing Library for Swift

**Question**: What Swift library should we use for parsing and writing TOML files (rust-toolchain.toml and .cargo/config.toml)?

**Research Findings**:

**Option A: TOMLDecoder (Swift Package)**
- **Decision**: ✅ **Selected**
- **Rationale**: 
  - Native Swift implementation, actively maintained
  - Supports Codable protocol, aligns with existing codebase patterns (AppSettings uses Codable)
  - Can encode/decode to/from TOML format
  - Lightweight, no external dependencies
  - Works well with Swift Package Manager
- **Alternatives Considered**:
  - **Manual TOML parsing**: Too error-prone, maintenance burden
  - **Python script bridge**: Adds complexity, violates "no external dependencies" principle
  - **C library wrapper**: Unnecessary complexity for Swift codebase
- **Implementation**: Add as Swift Package dependency, use Codable models for configuration structs

**Package Details**:
- Package: `https://github.com/dduan/TOMLDecoder`
- Or: `https://github.com/LebJe/TOMLKit` (alternative, also Codable-based)
- Decision: Use TOMLDecoder for Codable integration

### 2. Atomic TOML File Writes

**Question**: How to ensure atomic writes to TOML files to prevent corruption if app crashes during write?

**Research Findings**:

**Decision**: ✅ **Write to temporary file, then atomic move**
- **Rationale**:
  - Standard pattern: Write to `.tmp` file, validate structure, then `moveItem(at:to:)` atomically
  - Foundation's `FileManager.moveItem` is atomic on macOS
  - If write fails, original file remains intact
  - If move fails, temp file can be cleaned up
- **Implementation**:
  1. Write TOML content to `{filename}.tmp`
  2. Validate TOML structure (parse back to ensure valid)
  3. Use `FileManager.moveItem(at:to:)` to replace original
  4. Clean up temp file on success
- **Error Handling**: If validation fails, delete temp file and return error without modifying original
- **Alternatives Considered**:
  - **Direct write**: Risk of corruption if interrupted
  - **Backup + restore**: More complex, unnecessary for small config files

### 3. Health Status Calculation Strategy

**Question**: How to efficiently calculate project health status (green/red/yellow) without blocking UI?

**Research Findings**:

**Decision**: ✅ **Async calculation with caching**
- **Rationale**:
  - Health status requires multiple checks: toolchain installation, component availability, version matches, override conflicts
  - These checks involve file I/O and potentially rustup commands (async operations)
  - UI should not block while calculating
  - Cache results and invalidate on configuration changes
- **Implementation**:
  1. Calculate health status asynchronously in background task
  2. Show loading state initially, then update with result
  3. Cache status per project (in-memory, keyed by project path + last modified time)
  4. Invalidate cache when:
     - Project configuration changes (rust-toolchain.toml modified)
     - rustup override changes detected
     - User manually refreshes
  5. Use Combine publishers for reactive updates
- **Status Calculation Logic**:
  - **Green**: Toolchain installed, components available, version matches, no conflicts
  - **Red**: Missing toolchain version, missing required components
  - **Yellow**: Override conflicts detected, version mismatches
- **Performance**: Cache for 30 seconds, recalculate on demand or when stale

### 4. Preserving User's Manual TOML Edits

**Question**: How to preserve sections of TOML files that the app doesn't manage?

**Research Findings**:

**Decision**: ✅ **Parse-preserve-merge strategy**
- **Rationale**:
  - Users may have custom sections in rust-toolchain.toml or .cargo/config.toml
  - App should only modify sections it manages, preserve everything else
  - Need to merge app-managed sections with user's custom sections
- **Implementation**:
  1. Parse entire TOML file into structured model
  2. Identify app-managed sections (e.g., `[toolchain]`, `[alias]`, `[build]`)
  3. Update only app-managed sections
  4. Preserve all other sections as-is
  5. Write merged TOML back to file
- **Challenges**:
  - TOML libraries may not preserve comments or formatting
  - Solution: Use TOML library that supports round-trip preservation, or accept that comments/formatting may be lost (document this limitation)
- **Alternative Considered**:
  - **Separate config files**: Too complex, breaks user expectations

### 5. Registry Mirror Configuration Format

**Question**: What is the correct TOML format for Cargo registry mirror configuration?

**Research Findings**:

**Decision**: ✅ **Use Cargo's source replacement format**
- **Rationale**:
  - Cargo uses `[source.crates-io]` section with `replace-with` key
  - Then define `[source.{name}]` with `registry` URL
  - Standard format documented in Cargo book
- **Format**:
  ```toml
  [source.crates-io]
  replace-with = "tsinghua"

  [source.tsinghua]
  registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
  ```
- **Implementation**: Pre-define mirror configurations for Tsinghua, USTC, ByteDance, allow switching between them
- **Validation**: Validate mirror URLs against whitelist before writing

### 6. Toolchain Version Validation

**Question**: How to validate toolchain version strings before writing to rust-toolchain.toml?

**Research Findings**:

**Decision**: ✅ **Regex pattern matching + optional rustup validation**
- **Rationale**:
  - Toolchain versions follow patterns: `stable`, `beta`, `nightly`, `1.75.0`, `nightly-2024-01-01`
  - Need to validate format before writing to prevent invalid configurations
  - Can optionally check if version exists via rustup, but this is async and may fail
- **Validation Rules**:
  - Channel names: `stable`, `beta`, `nightly` (exact match)
  - Version numbers: `\d+\.\d+\.\d+` (semver pattern)
  - Nightly dates: `nightly-\d{4}-\d{2}-\d{2}` (ISO date format)
  - Custom toolchains: `[A-Za-z0-9._-]+` (alphanumeric, dots, dashes, underscores)
- **Implementation**: Use Swift Regex (Swift 5.7+) for pattern matching, validate before writing
- **Error Handling**: Show validation error in UI, prevent write if invalid

## Implementation Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| TOML Library | TOMLDecoder (Codable-based) | Native Swift, Codable integration, lightweight |
| Atomic Writes | Temp file + atomic move | Prevents corruption, standard pattern |
| Health Status | Async calculation with caching | Non-blocking UI, efficient |
| Preserve Edits | Parse-preserve-merge | User-friendly, maintains custom sections |
| Mirror Format | Cargo source replacement | Standard Cargo format |
| Version Validation | Regex + optional rustup check | Fast validation, prevents errors |

## Open Questions (Resolved)

None - all technical questions have been resolved with clear implementation paths.

## Dependencies to Add

- **TOMLDecoder** (or TOMLKit): Swift Package dependency for TOML parsing
  - Add via Xcode: File → Add Package Dependencies
  - URL: `https://github.com/dduan/TOMLDecoder` (or alternative)
  - Version: Latest stable

## Notes

- TOML file writes should be infrequent (only on user configuration changes)
- Health status calculation can be expensive (multiple file reads + rustup commands), so caching is essential
- Consider showing "calculating..." indicator in UI while health status is being computed
- Document that manual TOML edits outside the app will be detected on next project selection/refresh
