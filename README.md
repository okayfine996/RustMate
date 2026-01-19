# RustMate

RustMate 是一款 macOS 应用，提供对 Rust 工具链（rustup）的可视化管理，面向日常开发与多工具链场景，强调清晰状态、结构化结果。

## 主要功能

- 工具链管理：列出/安装/卸载/更新 toolchain，切换全局默认
- 组件管理：为指定 toolchain 安装/移除常用组件（如 rustfmt、clippy 等）
- 目标平台管理：按 toolchain 管理 targets（如 wasm32、aarch64 等）
- 项目管理：书签化项目目录，查看项目当前激活的 toolchain 与覆盖来源
- 项目诊断：提示工具链不一致、、配置冲突等问题
- 项目配置：编辑 `rust-toolchain.toml` 与 `.cargo/config.toml` 相关设置
- 任务中心：展示操作任务的运行状态、成功/失败摘要与错误提示
- 菜单栏入口：在菜单栏快速查看并切换默认 toolchain
- 自动更新：基于 Sparkle 的更新服务，支持稳定/测试通道

## 界面预览
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/cb5b0b24-56c2-41c7-8629-759ff840a931" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/f8842cb3-9daa-4538-babe-677e7ba40f1d" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/bc16a808-510a-4015-8a14-74487d5c9048" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/50e9c40f-c728-4513-8c59-7a1996e13682" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/a25882a9-ae35-4234-a1c9-201113839583" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/95b042c4-2b96-4d74-864b-b0cb2526a975" />
## 使用前准备

- macOS 14.0+（Sonoma 或更新）
- 已安装 rustup（`rustup --version` 可正常输出）
- 首次运行需授权：
  - `~/.cargo/bin`（访问 rustup 可执行文件）
  - 需要管理的项目目录（用于读取/写入配置与诊断）



