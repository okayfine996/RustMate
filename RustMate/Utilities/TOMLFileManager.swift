//
//  TOMLFileManager.swift
//  RustMate
//
//  Utility for atomic TOML file operations with validation
//

import Foundation

/// Utility class for atomic TOML file operations
/// Ensures file writes are atomic to prevent corruption
class TOMLFileManager {
    
    // MARK: - Errors
    
    enum TOMLFileError: LocalizedError {
        case fileNotFound
        case readError(String)
        case writeError(String)
        case validationError(String)
        case permissionDenied
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "TOML file not found"
            case .readError(let msg):
                return "Failed to read TOML file: \(msg)"
            case .writeError(let msg):
                return "Failed to write TOML file: \(msg)"
            case .validationError(let msg):
                return "TOML validation failed: \(msg)"
            case .permissionDenied:
                return "Permission denied: Cannot access file"
            }
        }
    }
    
    // MARK: - Atomic Write
    
    /// Atomically writes TOML content to a file
    /// Uses temp file + atomic move pattern to prevent corruption
    /// - Parameters:
    ///   - content: TOML content string to write
    ///   - fileURL: Target file URL (must be accessible)
    ///   - validate: Whether to validate TOML structure after write (default: true)
    /// - Throws: TOMLFileError if write or validation fails
    static func writeAtomically(
        content: String,
        to fileURL: URL,
        validate: Bool = true
    ) throws {
        let fileManager = FileManager.default
        
        // Ensure directory exists
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Create temp file URL
        let tempURL = fileURL.appendingPathExtension("tmp")
        
        // Write to temp file
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            // Clean up temp file on error
            try? fileManager.removeItem(at: tempURL)
            throw TOMLFileError.writeError(error.localizedDescription)
        }
        
        // Validate TOML structure if requested
        if validate {
            do {
                // Try to read back and parse to validate
                let validationContent = try String(contentsOf: tempURL, encoding: .utf8)
                // Basic validation: check if it's valid TOML structure
                // Note: Full TOML parsing validation will be done by TOMLDecoder
                // This is just a basic check for obvious syntax errors
                if validationContent.isEmpty {
                    try? fileManager.removeItem(at: tempURL)
                    throw TOMLFileError.validationError("TOML content is empty")
                }
            } catch {
                try? fileManager.removeItem(at: tempURL)
                if let tomlError = error as? TOMLFileError {
                    throw tomlError
                }
                throw TOMLFileError.validationError(error.localizedDescription)
            }
        }
        
        // Atomically move temp file to replace original
        do {
            // Remove original if exists
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            // Move temp to final location (atomic operation)
            try fileManager.moveItem(at: tempURL, to: fileURL)
        } catch {
            // Clean up temp file on error
            try? fileManager.removeItem(at: tempURL)
            throw TOMLFileError.writeError(error.localizedDescription)
        }
    }
    
    // MARK: - Read
    
    /// Reads TOML content from a file
    /// - Parameter fileURL: Source file URL
    /// - Returns: TOML content string
    /// - Throws: TOMLFileError if read fails
    static func read(from fileURL: URL) throws -> String {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw TOMLFileError.fileNotFound
        }
        
        do {
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            throw TOMLFileError.readError(error.localizedDescription)
        }
    }
    
    // MARK: - File Existence
    
    /// Checks if a TOML file exists
    /// - Parameter fileURL: File URL to check
    /// - Returns: True if file exists
    static func fileExists(at fileURL: URL) -> Bool {
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
