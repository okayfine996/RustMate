# RustMate

RustMate 是一款 macOS SwiftUI 应用，提供对 Rust 工具链（rustup）的可视化管理，面向日常开发与多工具链场景，强调清晰状态、结构化结果与沙盒安全访问。

## 主要功能

- 工具链管理：列出/安装/卸载/更新 toolchain，切换全局默认
- 组件管理：为指定 toolchain 安装/移除常用组件（如 rustfmt、clippy 等）
- 目标平台管理：按 toolchain 管理 targets（如 wasm32、aarch64 等）
- 项目管理：书签化项目目录，查看项目当前激活的 toolchain 与覆盖来源
- 项目诊断：提示工具链不一致、MSRV 违规、配置冲突等问题
- 项目配置：编辑 `rust-toolchain.toml` 与 `.cargo/config.toml` 相关设置
- 任务中心：展示操作任务的运行状态、成功/失败摘要与错误提示
- 菜单栏入口：在菜单栏快速查看并切换默认 toolchain
- 自动更新：基于 Sparkle 的更新服务，支持稳定/测试通道

## 界面预览

（截图待补）

## 使用前准备

- macOS 13.0+（Ventura 或更新）
- 已安装 rustup（`rustup --version` 可正常输出）
- 首次运行需授权：
  - `~/.cargo/bin`（访问 rustup 可执行文件）
  - 需要管理的项目目录（用于读取/写入配置与诊断）

## 运行机制概览

RustMate 在沙盒环境下通过安全作用域书签访问 rustup 与项目目录，并以结构化结果驱动 UI 状态更新与任务记录，强调清晰反馈与可操作的错误提示。

## 待补充内容

- 截图与动图
- 发布/下载方式与版本记录


