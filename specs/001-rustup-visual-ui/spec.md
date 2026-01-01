# Feature Specification: RustMate Visual Interface for Rustup Operations

**Feature Branch**: `001-rustup-visual-ui`
**Created**: 2025-12-31
**Status**: Draft
**Input**: User description: "@DESIGN.md 实现这个文档中的功能,主要实现rustup 的可视化操作"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Manage Rust Toolchains (Priority: P1)

As a Rust developer, I want to visually manage my installed toolchains (stable, beta, nightly) so that I can easily install, update, uninstall, and switch between different Rust versions without memorizing rustup commands.

**Why this priority**: Toolchain management is the core functionality of rustup and the primary use case. Without this, the application has no value. This is the foundation upon which all other features depend.

**Independent Test**: Can be fully tested by launching the app, viewing the list of installed toolchains, installing a new toolchain (e.g., stable), setting it as default, and verifying the toolchain list updates correctly. Delivers immediate value even without other features.

**Acceptance Scenarios**:

1. **Given** I have no toolchains installed, **When** I open the Toolchains view, **Then** I see an empty list with an "Install Toolchain" button
2. **Given** I click "Install Toolchain", **When** I select "stable" from the options, **Then** the app begins installing stable toolchain and shows installation progress
3. **Given** I have multiple toolchains installed, **When** I view the Toolchains list, **Then** I see all installed toolchains with the default toolchain clearly marked
4. **Given** I have stable and nightly installed, **When** I select nightly and click "Set as Default", **Then** nightly becomes the default toolchain (marked with default indicator)
5. **Given** I have an installed toolchain, **When** I select it and click "Update", **Then** the toolchain updates to the latest version and shows success/failure status
6. **Given** I have a non-default toolchain selected, **When** I click "Uninstall", **Then** the toolchain is removed from the list after confirmation

---

### User Story 2 - Manage Components for Toolchains (Priority: P2)

As a Rust developer, I want to install and manage components (rustfmt, clippy, rust-src) for specific toolchains so that I can have the tools I need without manually running rustup component commands.

**Why this priority**: Components are essential for productive Rust development (formatting, linting, IDE support), but they're secondary to having toolchains installed. This can be developed independently once toolchain management exists.

**Independent Test**: Can be tested by selecting an installed toolchain, viewing its components list, installing clippy, and verifying it appears as "installed". Delivers value for developers who want integrated tooling.

**Acceptance Scenarios**:

1. **Given** I have a toolchain selected, **When** I navigate to the Components view, **Then** I see a list of available components with their installation status
2. **Given** I see rustfmt is not installed, **When** I click "Install" next to rustfmt, **Then** rustfmt is installed for the selected toolchain and marked as installed
3. **Given** I have clippy installed, **When** I click "Uninstall" next to clippy, **Then** clippy is removed and marked as not installed
4. **Given** I switch to a different toolchain, **When** I view Components, **Then** I see the component status specific to that toolchain

---

### User Story 3 - Manage Target Platforms (Priority: P3)

As a Rust developer building cross-platform applications, I want to install and manage compilation targets (wasm32, aarch64-apple-darwin, etc.) for my toolchains so that I can compile for different platforms without remembering target triple names.

**Why this priority**: Target management is important for cross-platform development but not needed by all users. It can be independently developed and tested without affecting core toolchain functionality.

**Independent Test**: Can be tested by selecting a toolchain, viewing the Targets list, adding wasm32-unknown-unknown target, and verifying successful installation. Delivers value for developers doing cross-compilation.

**Acceptance Scenarios**:

1. **Given** I have a toolchain selected, **When** I navigate to the Targets view, **Then** I see a list of available targets with installation status
2. **Given** I want to compile for WebAssembly, **When** I install the wasm32-unknown-unknown target, **Then** the target is installed and marked as available
3. **Given** I have multiple targets installed, **When** I view the Targets list, **Then** I see all installed targets clearly marked
4. **Given** I no longer need a target, **When** I uninstall it, **Then** it's removed from the installed list

---

### User Story 4 - Understand Project Toolchain Context (Priority: P2)

As a Rust developer working on multiple projects, I want to see which toolchain is active for a specific project and understand why (toolchain file, override, or default) so that I can quickly understand my project's configuration without running rustup commands.

**Why this priority**: Understanding project context is crucial for multi-project workflows and debugging toolchain issues. It's independent of other features and provides significant value for developers managing multiple repositories.

**Independent Test**: Can be tested by selecting a project directory, viewing the active toolchain explanation, and verifying it correctly identifies the source (rust-toolchain.toml, override, or default). Delivers value for project configuration understanding.

**Acceptance Scenarios**:

1. **Given** I select a project directory, **When** I view the Project Context, **Then** I see the active toolchain name and the reason why it's active
2. **Given** my project has a rust-toolchain.toml file, **When** I view Project Context, **Then** the reason shows "Configured via rust-toolchain.toml" with the file path
3. **Given** I have set a rustup override for a directory, **When** I view that project, **Then** the reason shows "Override set via rustup"
4. **Given** no project-specific configuration exists, **When** I view Project Context, **Then** the reason shows "Using default toolchain"
5. **Given** I want to change a project's toolchain, **When** I set an override, **Then** the active toolchain updates and the reason changes accordingly

---

### User Story 5 - Monitor and Control Operations (Priority: P2)

As a Rust developer, I want to see the progress and status of rustup operations (installing, updating, uninstalling) so that I understand what's happening and can identify and resolve issues when operations fail.

**Why this priority**: Feedback on long-running operations is essential for usability. Without it, users don't know if the app is working or frozen. This can be developed independently as a cross-cutting UI concern.

**Independent Test**: Can be tested by initiating a toolchain installation and observing the task status change from "running" to "success" or "failed" with appropriate error messages. Delivers value by making the app feel responsive and reliable.

**Acceptance Scenarios**:

1. **Given** I initiate any rustup operation, **When** I view the Tasks list, **Then** I see the operation with status "running"
2. **Given** an operation completes successfully, **When** I check the Tasks list, **Then** I see the operation marked as "success" with completion time
3. **Given** an operation fails, **When** I check the Tasks list, **Then** I see the operation marked as "failed" with an error summary
4. **Given** an operation is running, **When** I click "Cancel", **Then** the operation attempts to terminate (best effort)
5. **Given** I view a failed task, **When** I click on it, **Then** I see detailed error information with suggested fixes

---

### User Story 6 - Initial Setup and Environment Validation (Priority: P1)

As a new RustMate user, I want the app to check if rustup is installed and guide me through setup so that I can start using the app without debugging environment issues.

**Why this priority**: Without rustup, the app cannot function. This is a prerequisite check that should happen before any other functionality. It's a critical first-run experience.

**Independent Test**: Can be tested by running the app without rustup installed and verifying it shows clear error messages with installation instructions. Delivers value by preventing user frustration.

**Acceptance Scenarios**:

1. **Given** rustup is not installed on my system, **When** I launch RustMate, **Then** I see a clear message that rustup is required with installation instructions
2. **Given** rustup is installed but not in an accessible location, **When** I launch RustMate, **Then** I'm prompted to authorize access to the rustup executable
3. **Given** I complete authorization, **When** the app validates the environment, **Then** I see a success message and can proceed to use the app
4. **Given** the app cannot find rustup, **When** I use Settings to manually specify the rustup path, **Then** the app validates and accepts the custom path

---

### Edge Cases

- What happens when rustup is running operations outside the app (e.g., terminal commands) while the app is open?
- How does the system handle interrupted operations (network loss during download, process killed)?
- What happens when rustup's output format changes in a future version?
- How does the app behave when the user lacks write permissions to .rustup directory?
- What happens when trying to uninstall the default toolchain?
- How does the app handle projects with invalid rust-toolchain.toml files?
- What happens when the user tries to install a toolchain that doesn't exist (typo in custom toolchain name)?
- How does the app handle operations on multiple toolchains simultaneously?
- What happens when Security-Scoped Bookmarks expire or become invalid?
- How does the app behave when switching between projects rapidly while operations are running?

## Requirements *(mandatory)*

### Functional Requirements

#### Environment & Setup (FR-1XX)

- **FR-101**: System MUST validate rustup installation on first launch and on app activation
- **FR-102**: System MUST display clear error messages with actionable instructions when rustup is not found
- **FR-103**: System MUST allow users to manually specify rustup executable location via file picker (Security-Scoped Bookmark)
- **FR-104**: System MUST allow users to authorize access to .cargo/bin directory for automatic rustup discovery
- **FR-105**: System MUST persist authorized directory bookmarks across app launches
- **FR-106**: System MUST validate bookmark access before executing rustup commands

#### Toolchain Management (FR-2XX)

- **FR-201**: System MUST display a list of all installed toolchains with their names and versions
- **FR-202**: System MUST clearly indicate which toolchain is set as default
- **FR-203**: System MUST allow users to install toolchains by selecting from predefined options (stable, beta, nightly) or entering custom names
- **FR-204**: System MUST allow users to uninstall toolchains with confirmation prompt
- **FR-205**: System MUST prevent uninstallation of the default toolchain without first setting another as default
- **FR-206**: System MUST allow users to set any installed toolchain as the default
- **FR-207**: System MUST allow users to update all toolchains or a specific toolchain
- **FR-208**: System MUST refresh the toolchain list after any write operation (install/uninstall/update)
- **FR-209**: System MUST refresh the toolchain list when app returns to foreground

#### Component Management (FR-3XX)

- **FR-301**: System MUST display available components for a selected toolchain with installation status
- **FR-302**: System MUST allow users to install components for a specific toolchain
- **FR-303**: System MUST allow users to uninstall installed components
- **FR-304**: System MUST show component status specific to the selected toolchain (not global)
- **FR-305**: System MUST support management of key components: rustfmt, clippy, rust-src, llvm-tools-preview

#### Target Platform Management (FR-4XX)

- **FR-401**: System MUST display available compilation targets for a selected toolchain with installation status
- **FR-402**: System MUST allow users to install targets for a specific toolchain
- **FR-403**: System MUST allow users to uninstall installed targets
- **FR-404**: System MUST show target status specific to the selected toolchain

#### Project Context (FR-5XX)

- **FR-501**: System MUST allow users to select project directories via file picker and create Security-Scoped Bookmarks
- **FR-502**: System MUST display the active toolchain for a selected project directory
- **FR-503**: System MUST explain the reason for the active toolchain with priority: RUSTUP_TOOLCHAIN env → rust-toolchain.toml → rustup override → default
- **FR-504**: System MUST display the source file path when toolchain is determined by rust-toolchain.toml
- **FR-505**: System MUST allow users to set toolchain overrides for projects via configurable strategy (write rust-toolchain.toml OR use rustup override set)
- **FR-506**: System MUST allow users to clear toolchain overrides
- **FR-507**: System MUST persist recent project bookmarks for quick access

#### Task & Operation Management (FR-6XX)

- **FR-601**: System MUST display status for all rustup operations: running, success, failed, cancelled
- **FR-602**: System MUST show operation metadata: operation name, target (toolchain/component/target), start time, end time
- **FR-603**: System MUST display error summaries for failed operations (truncated stderr up to 32KB)
- **FR-604**: System MUST allow users to attempt to cancel running operations (best-effort termination)
- **FR-605**: System MUST serialize rustup write operations to prevent lock conflicts
- **FR-606**: System MUST provide "Copy Error" functionality for failed operations
- **FR-607**: System MUST show suggested fixes for common error scenarios (network failure, permission issues)

#### Settings & Configuration (FR-7XX)

- **FR-701**: System MUST allow users to configure rustup/cargo executable paths
- **FR-702**: System MUST allow users to optionally configure RUSTUP_HOME and CARGO_HOME environment variables
- **FR-703**: System MUST allow users to select toolchain override strategy: write rust-toolchain.toml OR use rustup override
- **FR-704**: System MUST display and manage authorized directory bookmarks
- **FR-705**: System MUST allow users to revoke authorization for specific bookmarks

#### Security & Sandboxing (FR-8XX)

- **FR-801**: System MUST operate within macOS App Sandbox constraints
- **FR-802**: System MUST use Security-Scoped Bookmarks for all file system access outside the app container
- **FR-803**: System MUST validate all rustup command parameters against whitelist patterns
- **FR-804**: System MUST restrict toolchain/target/component names to `[A-Za-z0-9._-]+` with length limits
- **FR-805**: System MUST validate project paths are within authorized bookmark scope before operations

### Key Entities

- **Toolchain**: Represents an installed Rust toolchain (e.g., stable, beta, nightly-2024-01-01)
  - Attributes: name, version string, isDefault flag, installation status
  - Relationships: contains multiple Components and Targets

- **Component**: Represents an installable rustup component for a specific toolchain
  - Attributes: name (e.g., clippy, rustfmt), installation status
  - Relationships: belongs to a specific Toolchain

- **Target**: Represents a compilation target platform
  - Attributes: triple (e.g., wasm32-unknown-unknown), installation status
  - Relationships: belongs to a specific Toolchain

- **ProjectContext**: Represents a project directory and its toolchain configuration
  - Attributes: directory path, active toolchain name, reason for toolchain selection, source file path (if applicable)
  - Relationships: references a Toolchain as active

- **TaskRecord**: Represents a rustup operation execution
  - Attributes: operation type, target entity, status (running/success/failed/cancelled), start time, end time, exit code, stdout snippet, stderr snippet, error message
  - Relationships: may relate to Toolchain, Component, or Target being operated on

- **AuthorizedDirectory**: Represents a user-authorized directory with Security-Scoped Bookmark
  - Attributes: path, bookmark data, purpose (rustup access, cargo access, project access)
  - Relationships: ProjectContexts must reference authorized directories

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view their installed toolchains within 2 seconds of launching the app
- **SC-002**: Users can install a new toolchain (stable/beta/nightly) with no more than 3 clicks
- **SC-003**: 95% of rustup operations (install/uninstall/update) complete successfully or show actionable error messages
- **SC-004**: Users can identify why a project is using a specific toolchain within 5 seconds of selecting the project
- **SC-005**: Failed operations display error summaries that allow users to understand and resolve issues without consulting external documentation in 80% of cases
- **SC-006**: The app remains responsive during long-running rustup operations (UI never freezes)
- **SC-007**: Users can complete first-time setup (authorizing rustup access) within 2 minutes
- **SC-008**: Task status updates appear in the UI within 1 second of state changes
- **SC-009**: Component and target management requires 50% fewer clicks than equivalent terminal commands
- **SC-010**: 90% of users can successfully switch their project toolchain on first attempt without external help

### User Satisfaction Metrics

- Developers report feeling confident about which toolchain their project uses
- Developers successfully manage toolchains without needing to remember rustup command syntax
- First-time users complete setup and first toolchain operation without getting stuck
- Users find error messages helpful for resolving issues (measured via feedback)

## Assumptions

1. Users have basic familiarity with Rust development concepts (toolchains, components, targets)
2. Users have rustup already installed OR are willing to install it following provided instructions
3. Users are comfortable using macOS file pickers to authorize directory access
4. The format of rustup command output remains reasonably stable (with fallback parsing)
5. Most users will use standard toolchain configurations (stable, beta, nightly) rather than complex custom toolchains
6. Network connectivity is available for downloading toolchains (app will handle offline gracefully with error messages)
7. Users have sufficient disk space for multiple toolchains (app will surface disk space errors from rustup)
8. The app will be distributed via App Store, requiring strict sandbox compliance

## Out of Scope

The following are explicitly **not** included in this feature:

1. **Cargo command execution**: No support for running cargo build, cargo test, etc. (rustup management only)
2. **Terminal/log streaming**: No real-time output display; only status and error summaries
3. **Real-time file system monitoring**: No automatic detection of external rustup changes (refresh on foreground/manual only)
4. **Rust installation**: App assumes rustup exists; doesn't install Rust from scratch
5. **Registry management**: No management of cargo registries or alternate sources
6. **Custom toolchain compilation**: No support for building rustup from source or managing custom-compiled toolchains
7. **Network proxy configuration**: Relies on system or rustup's proxy settings
8. **Offline toolchain installation**: No support for installing from local archives (rustup must download)
9. **Non-macOS platforms**: This specification is macOS-specific
10. **Advanced rustup features**: No support for toolchain links, custom channels, or experimental features not exposed via standard rustup commands

## Dependencies

- **External**: rustup must be installed on the user's system (version 1.25.0 or later recommended)
- **System**: macOS 13.0+ (for modern SwiftUI features and Security-Scoped Bookmarks)
- **Entitlements**: App Sandbox, User Selected File (Read/Write) for Security-Scoped Bookmarks
- **Future**: If adding non-sandbox distribution, some requirements around Security-Scoped Bookmarks would be relaxed
