# Feature Specification: Project Management with Toolchain Configuration

**Feature Branch**: `007-project-toolchain-management`  
**Created**: 2025-01-27  
**Status**: Draft  
**Input**: User description: "实现project 管理功能，主要管理每个项目的工具链配置"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Manage Project List and Import Projects (Priority: P1)

As a Rust developer working on multiple projects, I want to import and manage my Rust projects in a centralized list with visual status indicators so that I can quickly see which projects are properly configured and access them easily.

**Why this priority**: Project management is the foundation of this feature. Without the ability to import and view projects, users cannot access any project-specific configuration features. This is the entry point for all other functionality.

**Independent Test**: Can be fully tested by importing a Rust project folder, viewing it in the sidebar list with status indicator, and verifying the project appears with correct path and name. Delivers immediate value by organizing projects in one place.

**Acceptance Scenarios**:

1. **Given** I have a Rust project directory, **When** I drag and drop it into the app or click "+ Add Project", **Then** the project is added to the sidebar list with its name and path displayed
2. **Given** I have multiple projects imported, **When** I view the sidebar, **Then** I see all projects listed with colored status indicators (green/red/yellow) showing their health status
3. **Given** I have a project with proper toolchain configuration, **When** I view it in the list, **Then** it shows a green indicator indicating configuration is normal and installed
4. **Given** I have a project missing required components, **When** I view it in the list, **Then** it shows a red indicator indicating missing components or version not installed
5. **Given** I have a project with local override conflicts, **When** I view it in the list, **Then** it shows a yellow indicator indicating detected override conflicts
6. **Given** I select a project from the list, **When** I view the main content area, **Then** I see the project's detailed configuration panel with tabs for Toolchain, Cargo, and Info

---

### User Story 2 - Configure Project Toolchain via rust-toolchain.toml (Priority: P1)

As a Rust developer, I want to configure my project's toolchain settings (channel, version, components, targets) through a visual interface that manages the rust-toolchain.toml file so that I can lock my compilation environment version without manually editing configuration files.

**Why this priority**: Toolchain configuration is the core value proposition of this feature. This directly addresses the main requirement of managing toolchain configurations per project. Without this, the feature has no purpose.

**Independent Test**: Can be tested by selecting a project, navigating to Toolchain Settings tab, selecting a channel (e.g., stable), specifying a version (e.g., 1.75.0), selecting components (rustfmt, clippy), and verifying the rust-toolchain.toml file is created/updated correctly. Delivers value by making toolchain configuration accessible without file editing.

**Acceptance Scenarios**:

1. **Given** I have a project selected, **When** I navigate to the Toolchain Settings tab, **Then** I see options for Channel selection (Stable/Beta/Nightly) with current selection highlighted
2. **Given** I want to lock a specific version, **When** I enter "1.75.0" in the version input field, **Then** the rust-toolchain.toml file is updated with the specified version
3. **Given** I want to use nightly with a date, **When** I select Nightly channel and enter "nightly-2024-01-01", **Then** the configuration is saved with the date-specific nightly version
4. **Given** I view the Components section, **When** I check/uncheck components (rustfmt, clippy, rust-src, rust-analyzer), **Then** the rust-toolchain.toml file is updated to include/exclude those components
5. **Given** I view the Targets section, **When** I add a target like "wasm32-unknown-unknown", **Then** the target is added to the configuration and saved to rust-toolchain.toml
6. **Given** I change the Profile setting, **When** I select "minimal" or "default", **Then** the profile preference is saved to the configuration file

---

### User Story 3 - Configure Cargo Build Settings via .cargo/config.toml (Priority: P2)

As a Rust developer, I want to configure Cargo build settings (registry mirrors, aliases, linker options, rustflags) through a visual interface that manages the .cargo/config.toml file so that I can optimize build speed and network experience without manually editing configuration files.

**Why this priority**: Cargo configuration is important for developer productivity (faster builds, better network experience), but it's secondary to toolchain configuration. This can be developed independently once toolchain management exists.

**Independent Test**: Can be tested by navigating to the Cargo Config tab, switching registry mirror to a Chinese source (e.g., Tsinghua), adding a cargo alias (e.g., "b" -> "build"), and verifying the .cargo/config.toml file is created/updated correctly. Delivers value by simplifying build optimization.

**Acceptance Scenarios**:

1. **Given** I navigate to the Cargo Config tab, **When** I view the Registry Mirrors section, **Then** I see options to switch between Crates.io (default) and Chinese mirrors (Tsinghua, USTC, ByteDance)
2. **Given** I select a Chinese mirror, **When** I click "Apply", **Then** the .cargo/config.toml file is updated with the source replacement rules
3. **Given** I view the Aliases section, **When** I add an alias "b" mapping to "build", **Then** the alias is saved to the configuration file
4. **Given** I have existing aliases, **When** I edit or delete one, **Then** the changes are reflected in the .cargo/config.toml file
5. **Given** I view the Build Optimization section, **When** I enable a linker option (mold or zld), **Then** the linker configuration is saved to the config file
6. **Given** I want to set rustflags, **When** I enter environment variables in the rustflags editor, **Then** the rustflags are saved to the configuration

---

### User Story 4 - Diagnose Toolchain Conflicts and Environment Issues (Priority: P2)

As a Rust developer, I want to see diagnostics about my project's toolchain configuration including version mismatches, override conflicts, and MSRV compliance so that I can quickly identify and resolve configuration issues.

**Why this priority**: Diagnostics help users understand and fix configuration problems, which is essential for a good user experience. This can be developed independently as it primarily involves reading and analyzing existing configurations.

**Independent Test**: Can be tested by selecting a project with a version mismatch (e.g., project requests 1.75.0 but override is 1.70.0), viewing the Diagnostics tab, and verifying the mismatch is detected and displayed with a "Fix Mismatch" option. Delivers value by preventing build issues.

**Acceptance Scenarios**:

1. **Given** my project has a rust-toolchain.toml requesting version 1.75.0, **When** I have a local rustup override set to 1.70.0, **Then** the Diagnostics tab shows a warning banner indicating "Version Mismatch: Project requests 1.75.0, but local override is set to 1.70.0"
2. **Given** I see a version mismatch warning, **When** I click "Fix Mismatch", **Then** the system clears the override or updates it to match the project configuration
3. **Given** I navigate to Diagnostics tab, **When** I view the environment information, **Then** I see the actual Rust version that would be used in the current shell environment
4. **Given** my project's Cargo.toml specifies rust-version 1.70.0, **When** the configured toolchain is 1.65.0, **Then** a warning is displayed indicating MSRV (Minimum Supported Rust Version) violation
5. **Given** no conflicts exist, **When** I view Diagnostics, **Then** I see a success message indicating the configuration is healthy

---

### User Story 5 - Quick Access to Project Actions (Priority: P3)

As a Rust developer, I want quick access to common project actions (open in terminal, open in VS Code) from the project list so that I can efficiently switch between the app and other development tools.

**Why this priority**: Quick actions improve workflow efficiency but are not essential for core functionality. This can be added after core features are complete.

**Independent Test**: Can be tested by right-clicking or using a context menu on a project in the list, selecting "Open in Terminal", and verifying the terminal opens at the project directory. Delivers value by improving developer workflow.

**Acceptance Scenarios**:

1. **Given** I have a project in the list, **When** I right-click or use a context menu, **Then** I see options for "Open in Terminal" and "Open in VS Code"
2. **Given** I select "Open in Terminal", **When** the action executes, **Then** a terminal window opens at the project's directory path
3. **Given** I select "Open in VS Code", **When** the action executes, **Then** VS Code opens with the project directory as the workspace

### Edge Cases

- What happens when a project directory is deleted or moved after being imported?
- How does the system handle projects that don't have a Cargo.toml file (not Rust projects)?
- What happens when rust-toolchain.toml or .cargo/config.toml files are manually edited outside the app?
- How does the system handle invalid toolchain version strings (e.g., typos, non-existent versions)?
- What happens when a project has both rust-toolchain.toml and rust-toolchain (legacy) files?
- How does the system handle projects with malformed TOML configuration files?
- What happens when the user tries to configure a toolchain version that doesn't exist?
- How does the system handle network failures when switching registry mirrors?
- What happens when Security-Scoped Bookmarks expire for imported projects?
- How does the system handle projects with conflicting override settings at different directory levels?
- What happens when a project's Cargo.toml specifies a rust-version that's higher than any available toolchain?
- How does the system handle projects imported from different user accounts or external drives?
- What happens when the .cargo directory doesn't exist and needs to be created?
- How does the system handle duplicate project imports (same path added twice)?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Constitution Constraints (mandatory)

- **No-default-XPC**: This feature MUST NOT require XPC by default. All file operations (reading/writing rust-toolchain.toml, .cargo/config.toml) and rustup commands MUST use LocalExecution services that run processes directly within the app sandbox. XPC is not needed as file I/O and process execution can be handled locally with Security-Scoped Bookmarks.
- **Sandbox & Security**: Input/path/args MUST be validated; permissions MUST be least-privilege. All project paths MUST be validated against Security-Scoped Bookmarks. Toolchain version strings MUST be validated against whitelist patterns. TOML file writes MUST validate structure before writing to prevent corruption. Registry mirror URLs MUST be validated against allowed list.
- **Structured Results**: Outputs MUST be structured status/errors; avoid relying on raw multi-line output. Toolchain configuration reads MUST parse TOML into structured models. Diagnostics MUST return structured conflict information rather than raw text. File operation results MUST return structured success/error status with specific error types.

### Functional Requirements

#### Project Management (FR-1XX)

- **FR-101**: System MUST allow users to import Rust projects by dragging and dropping folders or clicking "+ Add Project" button
- **FR-102**: System MUST create Security-Scoped Bookmarks for all imported project directories
- **FR-103**: System MUST display project list in left sidebar with project name and path
- **FR-104**: System MUST display colored status indicators for each project: green (healthy), red (missing components/version), yellow (override conflicts)
- **FR-105**: System MUST calculate project health status by checking: toolchain installation status, component availability, version matches, override conflicts
- **FR-106**: System MUST allow users to remove projects from the list
- **FR-107**: System MUST persist project bookmarks across app launches
- **FR-108**: System MUST validate that imported directories contain Rust projects (Cargo.toml present)
- **FR-109**: System MUST provide quick actions: "Open in Terminal" and "Open in VS Code" for each project
- **FR-110**: System MUST handle stale bookmarks by prompting user to re-authorize access

#### Toolchain Configuration - rust-toolchain.toml (FR-2XX)

- **FR-201**: System MUST allow users to select toolchain channel: Stable, Beta, or Nightly
- **FR-202**: System MUST allow users to specify exact version number (e.g., "1.75.0") or nightly date (e.g., "nightly-2024-01-01")
- **FR-203**: System MUST create or update rust-toolchain.toml file in project root when configuration changes
- **FR-204**: System MUST support version field as optional (empty means latest of selected channel)
- **FR-205**: System MUST allow users to manage components via checkboxes: rustfmt, clippy, rust-src, rust-analyzer
- **FR-206**: System MUST write components array to rust-toolchain.toml when components are selected/deselected
- **FR-207**: System MUST allow users to add compilation targets (e.g., wasm32-unknown-unknown, aarch64-apple-ios)
- **FR-208**: System MUST write targets array to rust-toolchain.toml when targets are added/removed
- **FR-209**: System MUST allow users to select profile: minimal or default
- **FR-210**: System MUST read existing rust-toolchain.toml file and populate UI with current values
- **FR-211**: System MUST validate toolchain version strings before writing to file
- **FR-212**: System MUST handle both rust-toolchain.toml (preferred) and legacy rust-toolchain file formats

#### Cargo Configuration - .cargo/config.toml (FR-3XX)

- **FR-301**: System MUST allow users to switch registry mirrors: Crates.io (default), Tsinghua, USTC, ByteDance
- **FR-302**: System MUST write source replacement rules to .cargo/config.toml when mirror is changed
- **FR-303**: System MUST create .cargo directory if it doesn't exist
- **FR-304**: System MUST allow users to add, edit, and delete cargo aliases (e.g., "b" -> "build")
- **FR-305**: System MUST write aliases to .cargo/config.toml in the [alias] section
- **FR-306**: System MUST allow users to enable/disable linker options: mold, zld
- **FR-307**: System MUST write linker configuration to .cargo/config.toml when enabled
- **FR-308**: System MUST provide a simple editor for rustflags environment variables
- **FR-309**: System MUST write rustflags to .cargo/config.toml [build] section
- **FR-310**: System MUST allow users to configure HTTP/HTTPS proxy settings for Cargo
- **FR-311**: System MUST read existing .cargo/config.toml file and populate UI with current values
- **FR-312**: System MUST preserve existing .cargo/config.toml content that is not managed by the UI

#### Diagnostics & Environment Detection (FR-4XX)

- **FR-401**: System MUST detect and display actual Rust version that would be used in current shell environment
- **FR-402**: System MUST detect version mismatches between rust-toolchain.toml and rustup override settings
- **FR-403**: System MUST display warning banner when version mismatch is detected with "Fix Mismatch" action
- **FR-404**: System MUST allow users to clear rustup override conflicts via "Clear Override" button
- **FR-405**: System MUST check Cargo.toml for rust-version field and compare with configured toolchain
- **FR-406**: System MUST display MSRV (Minimum Supported Rust Version) violation warnings when toolchain version is lower than required
- **FR-407**: System MUST show diagnostic status with badge count on Diagnostics tab (e.g., "1" for one issue)
- **FR-408**: System MUST refresh diagnostics when project configuration changes
- **FR-409**: System MUST detect and display toolchain source priority: RUSTUP_TOOLCHAIN env → rust-toolchain.toml → rustup override → default

#### UI Architecture (FR-5XX)

- **FR-501**: System MUST implement Master-Detail layout: left sidebar for project list, right content area for configuration
- **FR-502**: System MUST display breadcrumbs showing "Projects > [Project Name]" in content area header
- **FR-503**: System MUST provide Tab navigation in content area: "Toolchain Version", "Cargo & Build", "Diagnostics"
- **FR-504**: System MUST show page title and description in content area header
- **FR-505**: System MUST provide refresh and folder/file icons in content area header
- **FR-506**: System MUST update content area when different project is selected in sidebar
- **FR-507**: System MUST maintain selected project state across app sessions

### Key Entities

- **ProjectBookmark**: Represents an imported Rust project with security-scoped access
  - Attributes: id, path, displayName, bookmarkData, addedDate, isFavorite, healthStatus
  - Relationships: references a ProjectToolchainConfig and ProjectCargoConfig

- **ProjectToolchainConfig**: Represents toolchain configuration for a project (rust-toolchain.toml)
  - Attributes: channel (stable/beta/nightly), version (optional string), components (array), targets (array), profile (minimal/default)
  - Relationships: belongs to a ProjectBookmark, stored in rust-toolchain.toml file

- **ProjectCargoConfig**: Represents Cargo build configuration for a project (.cargo/config.toml)
  - Attributes: registryMirror (source URL), aliases (map of alias -> command), linker (mold/zld/none), rustflags (string), proxySettings (HTTP/HTTPS URLs)
  - Relationships: belongs to a ProjectBookmark, stored in .cargo/config.toml file

- **ProjectDiagnostics**: Represents diagnostic information about a project's configuration
  - Attributes: actualToolchainVersion, configuredVersion, overrideVersion, hasMismatch, msrvViolation, conflictDetails
  - Relationships: belongs to a ProjectBookmark, derived from reading configuration files and environment

- **ProjectHealthStatus**: Represents the health/status of a project's configuration
  - Attributes: status (healthy/missingComponents/versionMismatch/overrideConflict), indicatorColor (green/red/yellow), lastChecked
  - Relationships: belongs to a ProjectBookmark, calculated from toolchain and diagnostics information

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can import a Rust project and see it in the project list within 3 seconds
- **SC-002**: Users can configure a project's toolchain (channel, version, components) with no more than 5 clicks
- **SC-003**: 95% of toolchain configuration changes are successfully written to rust-toolchain.toml without file corruption
- **SC-004**: Users can identify project health status (green/red/yellow indicator) within 2 seconds of selecting a project
- **SC-005**: Version mismatch conflicts are detected and displayed to users within 5 seconds of project selection
- **SC-006**: Users can switch registry mirrors and have the change take effect (visible in .cargo/config.toml) within 2 seconds
- **SC-007**: 90% of users can successfully configure their first project's toolchain on first attempt without external help
- **SC-008**: Diagnostic warnings appear in the UI within 3 seconds of configuration changes that create conflicts
- **SC-009**: Project list loads and displays all imported projects within 2 seconds of app launch
- **SC-010**: Users can add a cargo alias and verify it's saved to .cargo/config.toml within 1 second
- **SC-011**: MSRV violations are detected and displayed when toolchain version is lower than Cargo.toml rust-version requirement
- **SC-012**: Quick actions (Open in Terminal, Open in VS Code) execute successfully in 95% of cases

### User Satisfaction Metrics

- Developers report feeling confident about their project's toolchain configuration after using the feature
- Developers successfully manage multiple projects' toolchain configurations without confusion
- Users find the visual status indicators helpful for quickly identifying project issues
- First-time users can import and configure a project without consulting documentation
- Users report that the feature reduces time spent manually editing TOML configuration files

## Assumptions

1. Users have rustup installed and are familiar with Rust project structure (Cargo.toml, rust-toolchain.toml)
2. Users understand the difference between toolchain channels (stable, beta, nightly)
3. Users are comfortable with macOS file system permissions and Security-Scoped Bookmarks
4. Projects are standard Rust projects with Cargo.toml files in the root directory
5. Users may have existing rust-toolchain.toml or .cargo/config.toml files that the app will read and modify
6. The TOML file format for rust-toolchain.toml and .cargo/config.toml remains stable
7. Users have network connectivity when switching registry mirrors (app will handle offline gracefully)
8. VS Code is installed at standard location (/usr/local/bin/code or via PATH) for "Open in VS Code" action
9. Terminal application is available at standard location for "Open in Terminal" action
10. Users may manually edit configuration files outside the app, and the app should detect and handle these changes

## Out of Scope

The following are explicitly **not** included in this feature:

1. **Cargo command execution**: No support for running cargo build, cargo test, or other cargo commands
2. **Real-time file monitoring**: No automatic detection of external file changes (refresh on manual action or project selection only)
3. **Project build status**: No integration with build systems or CI/CD to show build success/failure
4. **Version control integration**: No Git operations or branch management
5. **Multi-workspace support**: No support for managing multiple workspaces or monorepos as single units
6. **Project templates**: No creation of new Rust projects from templates
7. **Dependency management**: No management of Cargo.toml dependencies or crate versions
8. **Build artifact management**: No management of target/ directory or build outputs
9. **Advanced Cargo features**: No support for workspace configurations, profiles, or advanced Cargo.toml features beyond basic toolchain and build settings
10. **Cross-platform support**: This specification is macOS-specific (Security-Scoped Bookmarks, macOS-specific paths)
11. **Project search/filtering**: No advanced search or filtering capabilities for large project lists (basic list display only)
12. **Project grouping/categories**: No support for organizing projects into folders or categories
13. **Project sharing/sync**: No cloud sync or sharing of project configurations between devices
14. **Advanced diagnostics**: No deep analysis of build errors or compilation issues beyond toolchain/version conflicts

## Dependencies

- **External**: rustup must be installed on the user's system (version 1.25.0 or later recommended)
- **External**: Projects must be valid Rust projects with Cargo.toml files
- **System**: macOS 13.0+ (for modern SwiftUI features, Security-Scoped Bookmarks, and file system access)
- **Entitlements**: App Sandbox, User Selected File (Read/Write) for Security-Scoped Bookmarks
- **Internal**: Existing LocalExecution services for file I/O and process execution (from previous features)
- **Internal**: Existing ProjectBookmark and ProjectContextInfo models (from previous features)
- **Internal**: TOML parsing library for reading/writing configuration files
- **Future**: If adding non-sandbox distribution, some requirements around Security-Scoped Bookmarks would be relaxed
