<!--
Sync Impact Report:
Version Change: (none) → 1.0.0
New Constitution Created: 2025-12-31

Principles Defined:
1. Sandbox-First Design - App must operate within macOS App Sandbox constraints
2. Protocol-Driven Architecture - Protocol abstractions for testability and mocking
3. Structured Results Over Logs - Focus on structured data, not terminal output
4. Security-Scoped Access - All file system access via user-authorized bookmarks
5. Serial Execution - Rustup operations must be serialized to prevent conflicts

Templates Status:
✅ plan-template.md - Constitution Check section verified compatible
✅ spec-template.md - User scenarios align with testable requirements
✅ tasks-template.md - Task organization supports phased implementation
✅ agent-file-template.md - No agent-specific references to update
✅ checklist-template.md - Compatible with constitution principles

Follow-up TODOs: None
-->

# RustMate Constitution

## Core Principles

### I. Sandbox-First Design (NON-NEGOTIABLE)

All features MUST operate within macOS App Sandbox constraints for App Store distribution:

- NO direct access to user home directory without authorization
- NO system-wide daemon or helper installation
- NO arbitrary command execution - only whitelisted rustup/cargo operations
- XPC Services remain sandboxed and cannot escape permission boundaries
- File system access ONLY through Security-Scoped Bookmarks

**Rationale**: App Store requirement. Any feature requiring unsandboxed access must be
rejected or redesigned for sandbox compatibility.

### II. Protocol-Driven Architecture

All services MUST be protocol-based with concrete implementations separated from
consumers:

- Define `*ServiceProtocol` interfaces for all service layers
- ViewModels depend ONLY on protocols, never concrete implementations
- Provide both real (`XPC*Service`) and mock (`Mock*Service`) implementations
- Mock implementations MUST support SwiftUI Previews and unit tests without XPC

**Rationale**: Enables dependency injection, comprehensive testing, and SwiftUI Preview
support. Essential for TDD and maintaining development velocity.

### III. Structured Results Over Logs

All execution layer operations MUST return structured data models, not raw output:

- Define typed result models: `ToolchainInfo`, `ComponentInfo`, `TargetInfo`,
  `ProjectContextInfo`, `TaskResult`
- Tasks display status (running/success/failed/cancelled) and error summaries only
- Preserve stderr snippets (max 32KB) for error reporting, not continuous streaming
- NO terminal emulation, NO real-time log rendering
- Parse rustup/cargo output into structured data; fallback to snippet on parse failure

**Rationale**: Maintains UI responsiveness, reduces complexity, and provides better UX
than terminal output. Parsing failures are contained and recoverable.

### IV. Security-Scoped Access

All file system access MUST use Security-Scoped Bookmarks with explicit user
authorization:

- User MUST authorize `~/.cargo/bin` directory for rustup/cargo executable access
- User MUST authorize each project directory for project context features
- Bookmarks MUST be persisted securely (Keychain or encrypted storage)
- Access MUST use `startAccessingSecurityScopedResource()` / `stopAccessing...()` pairs
- NO assumptions about file system access without bookmark

**Rationale**: Sandbox requirement. Provides audit trail and user control over app
permissions.

### V. Serial Execution

All rustup write operations MUST be serialized within the execution layer:

- Use Swift Concurrency `actor RustupExecutor` (preferred) OR single serial
  `DispatchQueue`
- Read operations (list/show) MAY run in parallel but default to serial for simplicity
- Prevent rustup lock conflicts and state inconsistencies
- Ensure task ordering matches user expectations

**Rationale**: Rustup's internal state management is not designed for concurrent writes.
Serialization prevents race conditions and corrupted state.

## Security & Validation

### Command Whitelist

The XPC execution layer MUST enforce strict command and parameter validation:

- **Allowed commands**: `rustup toolchain`, `rustup component`, `rustup target`,
  `rustup show`, `rustc --version`, `cargo --version`
- **Toolchain name validation**: Regex `[A-Za-z0-9._-]+`, max length 128 chars
- **Target triple validation**: Regex `[A-Za-z0-9._-]+`, max length 128 chars
- **Project path validation**: Must be within authorized bookmark scope
- **NO arbitrary command strings** from UI layer

**Rationale**: Prevents command injection and ensures predictable behavior. XPC Service
is an attack surface and must validate all inputs.

### XPC Connection Validation

XPC Service MUST validate connection source:

- Verify client signature matches main app (TeamID/BundleID check)
- Protocol version handshake (reject mismatched versions)
- Reject connections from unknown clients

**Rationale**: Prevents unauthorized processes from invoking XPC service operations.

## Testing & Quality

### Test Requirements

- **Unit tests**: All service protocol implementations MUST have unit tests
- **Integration tests**: XPC communication and rustup parsing MUST have integration tests
- **Mock services**: MUST be maintained in sync with protocol changes
- **Output sample library**: Maintain samples of rustup output variations for parser tests

### Error Handling

All errors MUST be categorized as:

- **User-actionable** (provide fix instructions): rustup not found, permission denied,
  network failure
- **System/unknown** (preserve stderr snippet): parsing failure, unexpected exit codes

UI MUST provide clear next steps for user-actionable errors.

## Development Workflow

### State Management

ViewModels MUST refresh state at these points:

- App launch
- App return to foreground
- After any write operation completes
- (Future) File system monitoring of `~/.rustup/toolchains` when authorized

### Phased Implementation

Follow milestones defined in DESIGN.md:

- **M0**: MVVM skeleton + XPC Service + environment validation
- **M1**: Toolchain management (list/install/uninstall/setDefault/updateAll) + task UI
- **M2**: Component & target management + error handling polish
- **M3**: Project context view + bookmark management + override operations

Each milestone MUST be independently shippable with working features.

### Output Parsing Resilience

All rustup/cargo output parsing MUST:

- Use regex or line-by-line parsing with clear patterns
- Handle missing/unexpected fields gracefully (return `unknown` + snippet)
- Maintain test cases for known output variations
- Document assumptions about output format

**Rationale**: Rustup output is not a stable API. Parsing will break over time; plan for
it.

## Governance

This constitution supersedes all other development practices and preferences. Any
violation MUST be:

1. Identified in PR/code review
2. Either fixed immediately OR
3. Documented in implementation plan with explicit justification

**Amendment Process**:

- Amendments require documentation in Sync Impact Report (version bump + reasoning)
- Update all dependent templates (plan, spec, tasks) before finalizing
- Version changes follow semantic versioning:
  - MAJOR: Backward-incompatible principle removal or redefinition
  - MINOR: New principle or material guidance expansion
  - PATCH: Clarifications, wording, typo fixes

**Compliance**: All feature specifications, implementation plans, and tasks MUST include
a "Constitution Check" section validating compliance with these principles.

**Version**: 1.0.0 | **Ratified**: 2025-12-31 | **Last Amended**: 2025-12-31
