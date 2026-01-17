//
//  AddAliasSheet.swift
//  RustMate
//
//  Sheet for adding new Cargo alias
//

import SwiftUI

struct AddAliasSheet: View {
    @ObservedObject var viewModel: ProjectCargoViewModel
    @Binding var isPresented: Bool
    @Binding var aliasName: String
    @Binding var aliasCommand: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlassTokens.Spacing.lg) {
            // Title
            Text("Add Cargo Alias")
                .font(.system(size: GlassTokens.Typography.headlineSize, weight: .semibold))
                .foregroundColor(GlassTokens.Colors.textPrimary)

            // Alias Name
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                Text("Alias Name")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                TextField("e.g., b", text: $aliasName)
                    .textFieldStyle(.plain)
                    .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                    .padding(GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.backgroundSecondary)
                    .cornerRadius(GlassTokens.Radius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                            .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                    )
            }

            // Command
            VStack(alignment: .leading, spacing: GlassTokens.Spacing.sm) {
                Text("Command")
                    .font(.system(size: GlassTokens.Typography.bodySize, weight: .medium))
                    .foregroundColor(GlassTokens.Colors.textPrimary)

                TextField("e.g., build", text: $aliasCommand)
                    .textFieldStyle(.plain)
                    .font(.system(size: GlassTokens.Typography.bodySize, design: .monospaced))
                    .padding(GlassTokens.Spacing.sm)
                    .background(GlassTokens.Colors.backgroundSecondary)
                    .cornerRadius(GlassTokens.Radius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassTokens.Radius.sm)
                            .stroke(GlassTokens.Colors.divider, lineWidth: GlassTokens.Stroke.thin)
                    )
            }

            Spacer()

            // Buttons
            HStack(spacing: GlassTokens.Spacing.md) {
                Button("Cancel") {
                    isPresented = false
                    aliasName = ""
                    aliasCommand = ""
                }
                .font(.system(size: GlassTokens.Typography.bodySize))
                .foregroundColor(GlassTokens.Colors.textSecondary)
                .buttonStyle(.plain)

                Spacer()

                Button("Add") {
                    if !aliasName.isEmpty && !aliasCommand.isEmpty {
                        viewModel.addAlias(name: aliasName, command: aliasCommand)
                        isPresented = false
                        aliasName = ""
                        aliasCommand = ""
                    }
                }
                .font(.system(size: GlassTokens.Typography.bodySize, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, GlassTokens.Spacing.lg)
                .padding(.vertical, GlassTokens.Spacing.md)
                .background(GlassTokens.Colors.accent)
                .cornerRadius(GlassTokens.Radius.md)
                .buttonStyle(.plain)
                .disabled(aliasName.isEmpty || aliasCommand.isEmpty)
            }
        }
        .padding(GlassTokens.Spacing.xxl)
        .frame(width: 500, height: 300)
    }
}
