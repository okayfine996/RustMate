# Quickstart: 玻璃拟态 UI 视觉升级（验收与回归）

**Feature**: `004-glass-ui-refresh`  
**Date**: 2026-01-02

## 1) 目标

快速验证“对齐参考风格”的视觉升级是否满足：
- 层级清晰（首屏可扫）
- 跨页面一致（同一套 tokens/组件模式）
- 状态体系完整（空态/错态/进行中/成功）
- 可访问性可靠（浅/深色、较大字号、键盘焦点）

## 2) 开发运行

- 使用 Xcode 打开 `RustMate.xcodeproj`
- 选择 `RustMate` scheme，运行到本机

> 说明：本特性不要求联网或真实 rustup 环境才能做基础视觉验收；如需要数据，可使用现有 Mock services / fixtures（以项目现状为准）。

## 3) 手工验收矩阵（必做）

### A. Toolchains（P1）

- 首屏是否符合层级：标题 + 摘要 + 2~3 概览卡 + 列表
- 是否能一眼找到：
  - 当前全局默认工具链
  - Add Toolchain / Install / Update / Manage（至少一个主操作）
- 列表行：状态（DEFAULT/INSTALLED/UPDATE）是否可扫描且一致
- 进行中态：Update/Install 时是否有行内 progress，不遮挡信息
- 失败态：是否出现摘要 + 建议动作（重试/复制/设置）

### B. Components / Targets / Projects / Tasks / Settings（P2）

- 页面切换时布局规则是否一致（间距、标题层级、按钮层级、徽标）
- 空态/加载态/错态是否使用统一组件模式
- Projects：active toolchain 与来源解释是否层级清晰，override 操作入口一致
- Tasks：失败任务是否提供摘要 + 建议动作 + 复制

### C. 可访问性（P3）

在系统设置中分别验证：
- 浅色 / 深色模式
- 更大字号（至少 2 档）
- 减少动效（Reduce Motion）
- 键盘导航：侧边栏与主列表/按钮的焦点可见且顺序合理

## 4) 回归风险点（重点看）

- 玻璃效果导致对比不足（尤其浅色模式）
- 列表滚动卡顿（过度使用 blur/material/shadow）
- 主操作不再显眼（按钮层级混乱）
- 状态只剩文本（难以扫描）

## 5) 完成标准

满足 `spec.md` 的 Success Criteria（SC-001 ~ SC-004），并通过本 quickstart 的 A/B/C 三部分验收。

