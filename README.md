# RustMate

RustMate is a macOS application that provides visual management for Rust toolchains (rustup), designed for daily development and multi-toolchain scenarios with clear status display and structured results.

## Features

- **Toolchain Management**: List, install, uninstall, and update toolchains; switch the global default
- **Component Management**: Install and remove common components (e.g., rustfmt, clippy) for specific toolchains
- **Target Management**: Manage targets (e.g., wasm32, aarch64) per toolchain
- **Project Management**: Bookmark project directories; view active toolchain and override sources
- **Project Diagnostics**: Alerts for toolchain inconsistencies and configuration conflicts
- **Project Configuration**: Edit `rust-toolchain.toml` and `.cargo/config.toml` settings
- **Task Center**: Display task status, success/failure summaries, and error messages
- **Menu Bar Access**: Quickly view and switch default toolchain from the menu bar
- **Auto Update**: Sparkle-based update service with stable and beta channels

## Screenshots

<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/cb5b0b24-56c2-41c7-8629-759ff840a931" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/f8842cb3-9daa-4538-babe-677e7ba40f1d" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/bc16a808-510a-4015-8a14-74487d5c9048" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/50e9c40f-c728-4513-8c59-7a1996e13682" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/a25882a9-ae35-4234-a1c9-201113839583" />
<img width="1980" height="1200" alt="image" src="https://github.com/user-attachments/assets/95b042c4-2b96-4d74-864b-b0cb2526a975" />

## Requirements

- macOS 14.0+ (Sonoma or later)
- rustup installed (`rustup --version` should work)
- First-run permissions required:
  - `~/.cargo/bin` (to access rustup executables)
  - Project directories you want to manage (for reading/writing config and diagnostics)



