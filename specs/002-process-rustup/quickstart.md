# Quickstart: Sandboxed Direct Rustup Execution

**Feature**: `specs/002-process-rustup/spec.md`  
**Date**: 2026-01-01

## Goal

验证 RustMate 在 App Sandbox 内可以通过“用户授权 + security-scoped bookmarks”稳定执行 rustup 操作，
且授权不足/失效时可恢复。

## Prerequisites

- macOS 上已安装 rustup（任意常见安装方式均可）
- RustMate 以沙盒配置运行

## Step 1: First-run Authorization

1. 启动 RustMate
2. 当系统提示需要授权时，按引导依次授权：
   - rustup 可执行文件所在目录（例如 `~/.cargo/bin` 或 Homebrew bin）
   - `.cargo`
   - `.rustup`

## Step 2: Validate Minimal Operation

1. 触发一个最小 rustup 操作（例如“检测环境/列出 toolchains”）
2. 预期结果：
   - UI 不冻结
   - 返回结构化成功结果（而不是长文本输出）

## Step 3: Recovery Paths

### Case A: 用户拒绝授权

- 预期：显示缺少授权提示，并提供再次授权入口

### Case B: 授权范围不足（选错目录）

- 预期：提示“授权范围不足/选择错误”，可重新选择

### Case C: 授权失效

- 预期：提示“授权已失效，需要重新授权”，可重新授权并重试

## Notes

- 如果验证失败，优先检查"授权范围是否覆盖 rustup 可执行与其数据目录"。

## Implementation Validation (2026-01-01)

### UI Labels (Final)

**Setup Screen:**
- "Rustup Executable Directory" - Directory containing rustup command (usually ~/.cargo/bin)
- "Cargo Home" - Cargo data directory (usually ~/.cargo)
- "Rustup Home" - Rustup toolchain directory (usually ~/.rustup)

**Settings > Permissions:**
- "Rustup Executable Directory" - Required to run rustup and cargo executables
- "Cargo Home Directory" - Required for Cargo configuration and cache
- "Rustup Home Directory" - Required to access installed toolchains
- Authorization states: Authorized (green), Not Authorized (gray), Expired (orange), Invalid (red)
- Actions: "Authorize..." / "Re-authorize..." / "Remove"

### Authorization Flow

1. **First Launch**: Setup screen requires all three directories before continuing
2. **Missing Authorization**: Shows alert with "Authorize" button that opens Settings
3. **Authorization Queue**: Multiple missing purposes are authorized sequentially (no modal conflicts)
4. **Completion**: "AllAuthorizationsCompleted" notification triggers automatic retry
5. **Re-authorization**: Stale/invalid bookmarks show "Re-authorize..." button with automatic cleanup

### Recovery Mechanisms

- **Case A (Denied)**: Alert with "Authorize" button → Opens Settings → Shows authorization buttons
- **Case B (Wrong Directory)**: Error message suggests correct path → "Re-authorize..." button removes old bookmark and prompts again
- **Case C (Stale)**: Orange "Expired" badge in Settings → "Re-authorize..." button refreshes bookmark

### Execution Mode

- **Local Execution**: ProcessRunner with security-scoped bookmarks (no XPC service)
- **Authorization Validation**: Settings screen validates all bookmarks on load
- **Persistence**: UserDefaults for metadata, Keychain for bookmark data

---

## Manual Validation Checklist (T059)

### Pre-flight Checks

- [ ] Rust and rustup are installed on the system
- [ ] RustMate is built in Debug configuration with sandbox enabled
- [ ] No previous RustMate bookmarks exist (fresh test or reset settings)

### Test 1: First Launch Authorization Flow

**Steps:**
1. Launch RustMate
2. Observe setup screen appears
3. Click "Authorize..." for Rustup Executable Directory
4. Select `~/.cargo/bin` in file picker
5. Click "Authorize..." for Cargo Home
6. Select `~/.cargo` in file picker
7. Click "Authorize..." for Rustup Home
8. Select `~/.rustup` in file picker
9. Click "Continue" button

**Expected Results:**
- [ ] Setup screen shows three authorization rows with clear descriptions
- [ ] Each authorization button opens file picker with correct default directory
- [ ] After all three authorizations, "Continue" button becomes enabled
- [ ] Clicking "Continue" transitions to main app interface

**Failure Indicators:**
- Authorization buttons don't work
- "Continue" button stays disabled after all authorizations
- App crashes or hangs

### Test 2: Minimal Rustup Operation

**Steps:**
1. After completing first launch setup
2. Navigate to "Toolchains" tab
3. Observe initial load

**Expected Results:**
- [ ] UI remains responsive (no freeze)
- [ ] Toolchain list loads and displays structured data
- [ ] No raw terminal output visible in UI
- [ ] Task status shows success (green checkmark)

**Failure Indicators:**
- UI freezes during operation
- Raw stdout/stderr visible instead of parsed data
- Error alert appears about missing authorization

### Test 3: Authorization Denied Recovery (Case A)

**Steps:**
1. Reset RustMate settings (Settings > Advanced > Reset All Settings)
2. Relaunch RustMate
3. On setup screen, click "Authorize..." for Rustup Executable Directory
4. Click "Cancel" in file picker (deny authorization)
5. Try to navigate away from setup or trigger an operation

**Expected Results:**
- [ ] Setup screen shows warning about missing authorization
- [ ] "Continue" button remains disabled
- [ ] Can retry authorization by clicking button again
- [ ] No crash or silent failure

### Test 4: Wrong Directory Selection (Case B)

**Steps:**
1. On setup screen, click "Authorize..." for Rustup Executable Directory
2. Select wrong directory (e.g., `~/Documents` instead of `~/.cargo/bin`)
3. Complete other authorizations correctly
4. Click "Continue" and try to use toolchain operations

**Expected Results:**
- [ ] Operation fails with clear error message
- [ ] Error message suggests correct directory path
- [ ] Settings > Permissions shows "Invalid" or "Not Authorized" state
- [ ] "Re-authorize..." button available to fix authorization

### Test 5: Stale Bookmark Detection (Case C)

**Steps:**
1. Complete all authorizations successfully
2. Verify toolchain operations work
3. Outside RustMate, rename `~/.cargo` to `~/.cargo.backup`
4. In RustMate, navigate to Settings > Permissions
5. Observe authorization states

**Expected Results:**
- [ ] Settings screen shows orange "Expired" badge for Cargo Home
- [ ] "Re-authorize..." button appears instead of "Remove"
- [ ] Clicking "Re-authorize..." opens file picker
- [ ] After selecting correct directory, authorization recovers
- [ ] Toolchain operations work again

### Test 6: Authorization Queue (Multiple Missing)

**Steps:**
1. Reset RustMate settings
2. Navigate to Toolchains and trigger an operation without setup
3. Click "Authorize" in the alert that appears

**Expected Results:**
- [ ] Settings opens automatically
- [ ] First missing authorization prompts immediately
- [ ] After completing first, second authorization prompts automatically
- [ ] After all authorizations, operation retries automatically
- [ ] No modal dialog conflicts or duplicate prompts

### Test 7: Settings Persistence

**Steps:**
1. Complete all authorizations
2. Quit RustMate completely
3. Relaunch RustMate

**Expected Results:**
- [ ] Setup screen does NOT appear (skipped)
- [ ] Main interface loads directly
- [ ] Settings > Permissions shows all authorizations as "Authorized" (green)
- [ ] Toolchain operations work without re-authorization

### Test 8: Project Authorization (Separate Flow)

**Steps:**
1. Navigate to Projects tab
2. Click "Add Project..."
3. Select a Rust project directory
4. Observe project context loads

**Expected Results:**
- [ ] Project authorization happens via file picker (no separate setup step)
- [ ] Project context loads showing active toolchain
- [ ] No errors about missing project directory authorization
- [ ] Project appears in Settings > Permissions > Project Directories

---

### Validation Results (To be filled during testing)

**Date:**
**Tester:**
**Build Version:**

**Test 1 (First Launch):** ⬜ Pass ⬜ Fail - Notes:
**Test 2 (Minimal Operation):** ⬜ Pass ⬜ Fail - Notes:
**Test 3 (Authorization Denied):** ⬜ Pass ⬜ Fail - Notes:
**Test 4 (Wrong Directory):** ⬜ Pass ⬜ Fail - Notes:
**Test 5 (Stale Bookmark):** ⬜ Pass ⬜ Fail - Notes:
**Test 6 (Authorization Queue):** ⬜ Pass ⬜ Fail - Notes:
**Test 7 (Persistence):** ⬜ Pass ⬜ Fail - Notes:
**Test 8 (Project Authorization):** ⬜ Pass ⬜ Fail - Notes:

**Overall Status:** ⬜ All Passed ⬜ Some Failed - Needs Fix
**Critical Issues:**
**Minor Issues:**
**Recommendations:**

