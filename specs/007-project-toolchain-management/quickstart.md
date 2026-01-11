# Quickstart: Project Management with Toolchain Configuration

**Feature**: 007-project-toolchain-management  
**Date**: 2025-01-27  
**Purpose**: Get developers up and running with project toolchain configuration feature quickly

## Prerequisites

Before starting development, ensure you have:

- **macOS 13.0+** (Ventura or later)
- **Xcode 15+** with Swift 5.9+
- **Rustup installed** on your development machine (for testing)
- **Basic familiarity** with:
  - SwiftUI and Swift Concurrency (async/await, Actors)
  - TOML file format
  - App Sandbox constraints and Security-Scoped Bookmarks

## Project Setup

### 1. Add TOML Parsing Dependency

Add TOMLDecoder (or TOMLKit) as a Swift Package dependency:

1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/dduan/TOMLDecoder` (or `https://github.com/LebJe/TOMLKit`)
3. Select latest stable version
4. Add to RustMate target

### 2. Project Structure

New files to create:

```
RustMate/
├── Models/
│   ├── ProjectToolchainConfig.swift
│   ├── ProjectCargoConfig.swift
│   ├── ProjectDiagnostics.swift
│   └── ProjectHealthStatus.swift
├── Services/
│   ├── LocalExecution/
│   │   ├── LocalToolchainConfigService.swift
│   │   ├── LocalCargoConfigService.swift
│   │   └── ProjectDiagnosticsService.swift
│   └── Parsers/
│       ├── ToolchainConfigParser.swift
│       └── CargoConfigParser.swift
├── ViewModels/
│   ├── ProjectToolchainViewModel.swift
│   ├── ProjectCargoViewModel.swift
│   └── ProjectDiagnosticsViewModel.swift
├── Views/
│   └── Projects/
│       ├── ProjectToolchainSettingsView.swift
│       ├── ProjectCargoSettingsView.swift
│       └── ProjectDiagnosticsView.swift
└── Utilities/
    └── TOMLFileManager.swift
```

## Development Workflow

### Step 1: Implement Data Models

Start with `ProjectToolchainConfig` and `ProjectCargoConfig`:

1. Create models in `RustMate/Models/`
2. Make them `Codable` for TOML encoding/decoding
3. Add validation methods (version format, component names, etc.)
4. Write unit tests with fixtures

**Test Example**:
```swift
func testToolchainConfigValidation() {
    XCTAssertTrue(ProjectToolchainConfig.validateVersion("1.75.0"))
    XCTAssertTrue(ProjectToolchainConfig.validateVersion("nightly-2024-01-01"))
    XCTAssertFalse(ProjectToolchainConfig.validateVersion("invalid"))
}
```

### Step 2: Implement TOML Parsing

Create parsers using TOMLDecoder:

1. Implement `ToolchainConfigParser` to read/write rust-toolchain.toml
2. Implement `CargoConfigParser` to read/write .cargo/config.toml
3. Use `TOMLFileManager` for atomic writes (temp file + move)
4. Test with fixtures (valid/invalid TOML samples)

**Test Fixture** (`RustMateTests/Fixtures/toolchain-config-samples.toml`):
```toml
[toolchain]
channel = "stable"
version = "1.75.0"
components = ["rustfmt", "clippy"]
targets = ["wasm32-unknown-unknown"]
profile = "default"
```

### Step 3: Implement Services

Create LocalExecution services:

1. `LocalToolchainConfigService`: Read/write rust-toolchain.toml
2. `LocalCargoConfigService`: Read/write .cargo/config.toml
3. `ProjectDiagnosticsService`: Compute diagnostics and health status
4. All services must validate Security-Scoped Bookmarks before file access

**Service Example**:
```swift
class LocalToolchainConfigService {
    func readToolchainConfig(projectPath: String) async throws -> ProjectToolchainConfig {
        // Validate bookmark access
        // Read rust-toolchain.toml
        // Parse TOML to ProjectToolchainConfig
        // Return config
    }
}
```

### Step 4: Implement ViewModels

Create ViewModels following MVVM pattern:

1. `ProjectToolchainViewModel`: Manages toolchain config UI state
2. `ProjectCargoViewModel`: Manages Cargo config UI state
3. `ProjectDiagnosticsViewModel`: Manages diagnostics UI state
4. Use `@Published` properties for reactive UI updates
5. Use Combine for async operations

**ViewModel Example**:
```swift
@MainActor
class ProjectToolchainViewModel: ObservableObject {
    @Published var config: ProjectToolchainConfig?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service: ToolchainConfigService
    
    func loadConfig(projectPath: String) async {
        isLoading = true
        do {
            config = try await service.readToolchainConfig(projectPath: projectPath)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
```

### Step 5: Implement Views

Create SwiftUI views:

1. `ProjectToolchainSettingsView`: Tab for toolchain configuration
2. `ProjectCargoSettingsView`: Tab for Cargo configuration
3. `ProjectDiagnosticsView`: Tab for diagnostics
4. Integrate with existing `ProjectContextView` (add tabs)
5. Use existing shared components for consistency

**View Example**:
```swift
struct ProjectToolchainSettingsView: View {
    @StateObject private var viewModel: ProjectToolchainViewModel
    
    var body: some View {
        Form {
            // Channel selection
            // Version input
            // Components checkboxes
            // Targets list
        }
    }
}
```

## Testing Strategy

### Unit Tests

Test each layer independently:

1. **Models**: Validation logic, Codable conformance
2. **Parsers**: TOML parsing with fixtures (valid/invalid samples)
3. **Services**: Mock file system, test error handling
4. **ViewModels**: Mock services, test state updates

### Integration Tests

Test end-to-end flows:

1. **Read Config**: Import project → read rust-toolchain.toml → display in UI
2. **Write Config**: Modify UI → write to file → verify file content
3. **Health Status**: Calculate status → display indicator → verify color
4. **Diagnostics**: Compute diagnostics → display warnings → fix conflicts

### Manual Testing

Test with real projects:

1. Create test Rust project with rust-toolchain.toml
2. Import project in app
3. Verify configuration loads correctly
4. Modify configuration
5. Verify file updates correctly
6. Test health status calculation
7. Test diagnostics (create version mismatch scenario)

## Common Issues & Solutions

### Issue: TOML File Corruption

**Problem**: File gets corrupted during write (app crashes mid-write)

**Solution**: Use atomic writes (temp file + move). Implemented in `TOMLFileManager`.

### Issue: Health Status Calculation Blocks UI

**Problem**: Calculating health status takes too long, UI freezes

**Solution**: Calculate asynchronously, show loading state, cache results.

### Issue: User's Manual Edits Lost

**Problem**: App overwrites user's custom TOML sections

**Solution**: Parse-preserve-merge strategy. Only modify app-managed sections.

### Issue: Security-Scoped Bookmark Expired

**Problem**: Cannot access project directory after app restart

**Solution**: Check bookmark validity, prompt user to re-authorize if stale.

## Verification Checklist

Before considering feature complete:

- [ ] Can import Rust project and see in sidebar
- [ ] Can view project health status (green/red/yellow indicator)
- [ ] Can read existing rust-toolchain.toml and display in UI
- [ ] Can modify toolchain config and save to file
- [ ] Can read existing .cargo/config.toml and display in UI
- [ ] Can modify Cargo config and save to file
- [ ] Can view diagnostics (version mismatches, MSRV violations)
- [ ] Can fix version mismatches (clear override)
- [ ] Health status updates correctly after config changes
- [ ] User's manual TOML edits are preserved
- [ ] Atomic file writes prevent corruption
- [ ] All file operations validate Security-Scoped Bookmarks

## Next Steps

After completing this feature:

1. Run full test suite
2. Test with multiple projects (10+ projects)
3. Test edge cases (deleted projects, moved projects, stale bookmarks)
4. Performance testing (health status calculation with many projects)
5. User acceptance testing
