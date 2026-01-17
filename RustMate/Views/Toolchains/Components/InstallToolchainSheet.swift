//
//  InstallToolchainSheet.swift
//  RustMate
//
//  Sheet for installing new toolchains
//  Extracted from ToolchainListView to reduce complexity
//

import SwiftUI

struct InstallToolchainSheet: View {
    @ObservedObject var viewModel: ToolchainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var toolchainName = ""
    @State private var selectedSuggestion: String?
    @State private var isInstalling = false
    @State private var validationError: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Content
            contentSection

            Divider()

            // Footer
            footerSection
        }
        .frame(width: 500, height: 450)
    }

    // MARK: - Sections

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Install Toolchain")
                .font(.title.bold())

            Text("Choose a toolchain to install")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var contentSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Suggestions
                if !viewModel.suggestedToolchains.isEmpty {
                    suggestionsSection
                }

                // Custom name
                customNameSection

                // Info
                infoSection
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Toolchains")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                ForEach(viewModel.suggestedToolchains, id: \.self) { suggestion in
                    Button {
                        selectedSuggestion = suggestion
                        toolchainName = suggestion
                    } label: {
                        HStack {
                            Text(suggestion)
                                .font(.subheadline)
                            Spacer()
                            if selectedSuggestion == suggestion {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(selectedSuggestion == suggestion ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var customNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Toolchain Name")
                .font(.headline)

            TextField("e.g., stable, nightly, 1.75.0", text: $toolchainName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: toolchainName) { _, _ in
                    validationError = nil
                }

            if let error = validationError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Text("Examples: stable, beta, nightly, 1.75.0, nightly-2024-01-01")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var infoSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.blue)
            Text("This will download and install the specified toolchain using rustup.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var footerSection: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Install") {
                installToolchain()
            }
            .buttonStyle(.borderedProminent)
            .disabled(toolchainName.isEmpty || isInstalling)
        }
        .padding(16)
    }

    // MARK: - Actions

    private func installToolchain() {
        let trimmedName = toolchainName.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            validationError = "Please enter a toolchain name"
            return
        }

        if !ToolchainInfo.validateName(trimmedName) {
            validationError = "Invalid toolchain name. Use only letters, numbers, dots, hyphens, and underscores (max 128 characters)"
            return
        }

        Task {
            await viewModel.installToolchain(name: trimmedName)
        }

        dismiss()
    }
}
