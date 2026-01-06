//
//  UpdateModels.swift
//  RustMate
//
//  T007: Structured update state and error models
//  Based on specs/005-sparkle-auto-update/data-model.md
//

import Foundation

// MARK: - Update State

/// Represents the current state of the update process
enum UpdateState: Equatable {
    case idle                           // Not checking / completed
    case checking                       // Checking for updates
    case noUpdate                       // No update available
    case updateAvailable(UpdateInfo)    // New version detected
    case downloading(progress: Double)  // Downloading update (0.0-1.0)
    case readyToInstall(UpdateInfo)     // Downloaded, ready to install
    case failed(UpdateError)            // Update failed
    
    var isInProgress: Bool {
        switch self {
        case .checking, .downloading:
            return true
        default:
            return false
        }
    }
    
    var displayText: String {
        switch self {
        case .idle:
            return "Up to date"
        case .checking:
            return "Checking for updates..."
        case .noUpdate:
            return "No updates available"
        case .updateAvailable(let info):
            return "Update available: \(info.version)"
        case .downloading(let progress):
            return "Downloading... \(Int(progress * 100))%"
        case .readyToInstall(let info):
            return "Ready to install \(info.version)"
        case .failed(let error):
            return "Update failed: \(error.userMessage)"
        }
    }
}

// MARK: - Update Info

/// Information about an available update
struct UpdateInfo: Equatable {
    let version: String                 // Display version (e.g., "1.2.0")
    let buildNumber: String             // Build number for comparison
    let releaseNotesURL: URL?           // Optional release notes link
    let downloadSize: Int64?            // File size in bytes
    
    var formattedSize: String? {
        guard let size = downloadSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Update Error

/// Structured error for update failures with user-actionable messages
struct UpdateError: Error, Equatable {
    let category: ErrorCategory
    let userMessage: String             // User-friendly message
    let recoverySuggestion: String      // Actionable next step
    let debugContext: [String: String]? // Optional debug info
    
    enum ErrorCategory: String, Codable {
        case networkUnavailable         // No network connection
        case feedUnavailable            // Cannot reach appcast
        case invalidFeed                // Malformed appcast
        case signatureInvalid           // Signature verification failed
        case downloadFailed             // Download error
        case unsupportedSystemVersion   // System version too old
        case unknown                    // Unexpected error
    }
    
    // MARK: - Factory Methods
    
    static func networkUnavailable() -> UpdateError {
        UpdateError(
            category: .networkUnavailable,
            userMessage: "无法检查更新",
            recoverySuggestion: "请检查网络连接后重试",
            debugContext: nil
        )
    }
    
    static func feedUnavailable(url: String) -> UpdateError {
        UpdateError(
            category: .feedUnavailable,
            userMessage: "更新源不可用",
            recoverySuggestion: "请稍后重试或检查网络设置",
            debugContext: ["feed_url": url]
        )
    }
    
    static func invalidFeed(reason: String) -> UpdateError {
        UpdateError(
            category: .invalidFeed,
            userMessage: "更新信息格式错误",
            recoverySuggestion: "请联系开发者报告此问题",
            debugContext: ["reason": reason]
        )
    }
    
    static func signatureInvalid() -> UpdateError {
        UpdateError(
            category: .signatureInvalid,
            userMessage: "更新包签名验证失败",
            recoverySuggestion: "此更新可能已被篡改，已阻止安装。请从官方渠道重新下载。",
            debugContext: nil
        )
    }
    
    static func downloadFailed(reason: String) -> UpdateError {
        UpdateError(
            category: .downloadFailed,
            userMessage: "下载更新失败",
            recoverySuggestion: "请检查网络连接后重试",
            debugContext: ["reason": reason]
        )
    }
    
    static func unsupportedSystemVersion(required: String, current: String) -> UpdateError {
        UpdateError(
            category: .unsupportedSystemVersion,
            userMessage: "系统版本不满足要求",
            recoverySuggestion: "此更新需要 macOS \(required) 或更高版本，当前系统为 \(current)",
            debugContext: ["required": required, "current": current]
        )
    }
    
    static func unknown(message: String) -> UpdateError {
        UpdateError(
            category: .unknown,
            userMessage: "更新失败",
            recoverySuggestion: "请稍后重试或联系支持",
            debugContext: ["message": message]
        )
    }
}

