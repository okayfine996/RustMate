# Implementation Plan: Project Management with Toolchain Configuration

**Branch**: `007-project-toolchain-management` | **Date**: 2025-01-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-project-toolchain-management/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature implements a comprehensive project management system for Rust projects with visual toolchain configuration. Users can import multiple Rust projects, view their health status (green/red/yellow indicators), and configure toolchain settings (rust-toolchain.toml) and Cargo build settings (.cargo/config.toml) through a Master-Detail UI interface. The system provides diagnostics to detect version mismatches, override conflicts, and MSRV violations.

**Technical Approach**: Extends existing LocalExecution services to read/write TOML configuration files, leverages existing ProjectBookmark model for project management, implements new ViewModels for toolchain and Cargo configuration, and adds diagnostic services to detect conflicts. All file operations use Security-Scoped Bookmarks within App Sandbox constraints.

## Technical Context

**Language/Version**: Swift 5.0 (project setting; actual version determined by Xcode toolchain, likely 5.9+)  
**Primary Dependencies**: SwiftUI, Foundation (Process, FileManager), Security (Security-Scoped Bookmarks), TOML parsing library (needs research)  
**Storage**: UserDefaults (project bookmarks, settings), Security-Scoped Bookmarks (project directory access), file system (rust-toolchain.toml, .cargo/config.toml)  
**Testing**: XCTest (unit tests for TOML parsing, configuration validation), SwiftUI previews (UI components)  
**Target Platform**: macOS 13.0+ (Ventura or later)  
**Project Type**: Single macOS application (SwiftUI app)  
**Performance Goals**: Project list loads within 2 seconds, configuration changes persist within 1 second, diagnostics computed within 5 seconds  
**Constraints**: App Sandbox compliance (all file access via Security-Scoped Bookmarks), no XPC (use LocalExecution services), TOML file writes must be atomic to prevent corruption  
**Scale/Scope**: Support 10-100 projects per user, handle projects with existing/legacy configuration files, preserve user's manual edits to TOML files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

用项目宪章（`.specify/memory/constitution.md`）生成并填写以下检查项（不通过则必须在"Complexity Tracking"里说明）：

- **用户价值**：✅ 通过。P1 用户旅程（项目管理与导入、工具链配置）可独立验收与演示。导入项目并查看状态指示器即可验证项目管理功能；配置工具链并验证 rust-toolchain.toml 文件更新即可验证配置功能。每个用户故事都有明确的独立测试方法。

- **简化优先 / XPC**：✅ 通过。不引入或扩展 XPC。所有文件操作（读取/写入 TOML 文件）和 rustup 命令执行都使用现有的 LocalExecution 服务，在应用沙盒内直接运行进程。XPC 不需要，因为文件 I/O 和进程执行可以通过 Security-Scoped Bookmarks 在本地处理。

- **安全/沙盒**：✅ 通过。涉及目录授权（Security-Scoped Bookmarks 用于项目目录访问）、参数校验（工具链版本字符串白名单验证、TOML 结构验证）、权限最小化（仅访问用户明确授权的项目目录）。所有项目路径必须通过 Security-Scoped Bookmarks 验证，工具链版本字符串必须符合白名单模式，TOML 写入前必须验证结构以防止损坏。

- **可测试**：✅ 通过。需要 fixtures/单测的逻辑：TOML 解析器（使用 fixtures 测试 rust-toolchain.toml 和 .cargo/config.toml 的读取/写入）、配置验证（工具链版本格式验证、组件/目标列表验证）、健康状态计算（基于工具链安装状态、组件可用性、版本匹配）。需要回归验证的边界：项目目录删除/移动后的书签处理、手动编辑 TOML 文件后的重新读取、版本冲突检测、MSRV 违规检测。

- **结构化结果**：✅ 通过。对外暴露的结果以结构化状态/错误为主。工具链配置读取必须解析 TOML 为结构化模型（ProjectToolchainConfig, ProjectCargoConfig）。诊断必须返回结构化冲突信息（ProjectDiagnostics），而不是原始文本。文件操作结果必须返回结构化成功/错误状态，包含特定错误类型。

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
RustMate/
├── Models/
│   ├── ProjectBookmark.swift          # Existing - extended with healthStatus
│   ├── AppSettings.swift              # Existing
│   └── [NEW] ProjectToolchainConfig.swift
│   └── [NEW] ProjectCargoConfig.swift
│   └── [NEW] ProjectDiagnostics.swift
│   └── [NEW] ProjectHealthStatus.swift
├── Services/
│   ├── LocalExecution/                # Existing - extended for TOML file operations
│   │   ├── LocalProjectContextService.swift  # Existing - extended
│   │   └── [NEW] LocalToolchainConfigService.swift
│   │   └── [NEW] LocalCargoConfigService.swift
│   │   └── [NEW] ProjectDiagnosticsService.swift
│   ├── Parsers/                       # Existing - extended for TOML parsing
│   │   └── [NEW] ToolchainConfigParser.swift
│   │   └── [NEW] CargoConfigParser.swift
│   ├── Protocols/                     # Existing
│   └── Mock/                          # Existing - extended with mocks
│       └── [NEW] MockToolchainConfigService.swift
│       └── [NEW] MockCargoConfigService.swift
├── ViewModels/
│   ├── ProjectsViewModel.swift        # Existing - extended for health status
│   └── [NEW] ProjectToolchainViewModel.swift
│   └── [NEW] ProjectCargoViewModel.swift
│   └── [NEW] ProjectDiagnosticsViewModel.swift
├── Views/
│   ├── Projects/
│   │   ├── ProjectsListView.swift     # Existing - extended with status indicators
│   │   ├── ProjectContextView.swift    # Existing
│   │   └── [NEW] ProjectToolchainSettingsView.swift
│   │   └── [NEW] ProjectCargoSettingsView.swift
│   │   └── [NEW] ProjectDiagnosticsView.swift
│   └── Shared/                         # Existing - reusable components
└── Utilities/
    ├── BookmarkManager.swift          # Existing
    └── [NEW] TOMLFileManager.swift    # Atomic TOML file operations

RustMateTests/
├── ParserTests/
│   └── [NEW] ToolchainConfigParserTests.swift
│   └── [NEW] CargoConfigParserTests.swift
├── ViewModelTests/
│   └── [NEW] ProjectToolchainViewModelTests.swift
│   └── [NEW] ProjectCargoViewModelTests.swift
│   └── [NEW] ProjectDiagnosticsViewModelTests.swift
└── Fixtures/
    └── [NEW] toolchain-config-samples.toml
    └── [NEW] cargo-config-samples.toml
```

**Structure Decision**: 保持当前单一 macOS App 结构。新增的配置服务和解析器放入 `RustMate/Services/`，新的 ViewModels 和 Views 遵循现有的 MVVM 架构模式。TOML 文件操作使用新的 `TOMLFileManager` 工具类确保原子写入。测试使用 fixtures 验证 TOML 解析和配置验证逻辑。

## Phase 0: Research (output: `research.md`)

✅ **Complete** - See `research.md` for technical decisions:
- TOML parsing library: TOMLDecoder (Codable-based)
- Atomic file writes: Temp file + atomic move pattern
- Health status calculation: Async with caching
- Preserving user edits: Parse-preserve-merge strategy
- Registry mirror format: Cargo source replacement format
- Version validation: Regex pattern matching

## Phase 1: Design (outputs: `data-model.md`, `contracts/`, `quickstart.md`)

✅ **Complete** - See:
- `data-model.md`: Domain models (ProjectToolchainConfig, ProjectCargoConfig, ProjectDiagnostics, ProjectHealthStatus)
- `contracts/toolchain-config-service.md`: Service interface for rust-toolchain.toml operations
- `contracts/cargo-config-service.md`: Service interface for .cargo/config.toml operations
- `contracts/diagnostics-service.md`: Service interface for diagnostics computation
- `quickstart.md`: Development workflow and testing strategy

## Post-Design Constitution Check

- **用户价值**：✅ 通过。P1 用户旅程（项目管理与导入、工具链配置）可独立验收与演示。数据模型和契约已定义，支持完整的用户流程。

- **简化优先 / XPC**：✅ 通过。不引入或扩展 XPC。所有服务使用 LocalExecution 模式，在应用沙盒内直接运行。契约定义了清晰的接口，无需 XPC。

- **安全/沙盒**：✅ 通过。所有服务契约要求 Security-Scoped Bookmark 验证。输入验证规则已定义（版本格式、组件名称、目标名称、镜像 URL 白名单）。

- **可测试**：✅ 通过。数据模型定义了验证规则，服务契约定义了错误类型，quickstart 提供了测试策略。Fixtures 用于 TOML 解析测试。

- **结构化结果**：✅ 通过。所有服务返回结构化结果（ProjectToolchainConfig, ProjectCargoConfig, ProjectDiagnostics），错误类型是结构化的（ConfigError, DiagnosticsError），不是原始文本。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
