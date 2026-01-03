# Contract: Screen Coverage Map（页面覆盖映射）

**Feature**: `004-glass-ui-refresh`  
**Date**: 2026-01-02  
**Purpose**: 明确每个页面必须覆盖哪些模式与状态，便于验收与回归。

## Toolchains

- **Patterns**
  - Summary Cards（2~3 张）
  - List Row（toolchain rows）
  - Status Badge（DEFAULT/INSTALLED/UPDATE 等）
  - Segmented Filter / Chips（All/Stable/Beta/Nightly）
  - Inline Progress（更新/安装进行中）
  - Error Callout（失败摘要 + 动作）
- **States**
  - loading / empty / running / failed
- **Acceptance checks**
  - 首屏层级清晰（标题/摘要/概览/列表/主操作）
  - 主操作（Add/Install/Update/Manage）可发现且层级一致

## Components

- **Patterns**: List Row + Status Badge + Inline Progress + Error Callout
- **States**: loading / empty / running / failed

## Targets

- **Patterns**: List Row + Status Badge + Inline Progress + Error Callout
- **States**: loading / empty / running / failed

## Projects

- **Patterns**: List Row + Status Badge + Error Callout
- **States**: loading / empty / failed
- **Acceptance checks**
  - active toolchain 与来源解释层级清晰
  - Set/Clear override 入口层级一致

## Tasks

- **Patterns**: List Row（任务卡片化） + Status Badge + Error Callout
- **States**: empty / failed
- **Acceptance checks**
  - 失败任务提供摘要 + 建议动作 + 复制

## Settings

- **Patterns**: Section cards（或等效分组） + Error Callout
- **States**: failed（例如授权失效提示）

## Menu Bar（若已存在）

- **Patterns**: 小尺寸列表 + Status Badge + Inline Progress + Error Callout
- **States**: loading / failed

