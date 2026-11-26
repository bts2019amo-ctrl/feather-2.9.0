//
//  LibraryAppIconView.swift
//  Feather
//
//  Created by samara on 11.04.2025.
//

import SwiftUI
import UIKit.UIImpactFeedbackGenerator
import NimbleExtensions
import NimbleViews

// MARK: - View
struct LibraryCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(\.editMode) private var editMode

	var certInfo: Date.ExpirationInfo? {
		Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
	}

	var certRevoked: Bool {
		Storage.shared.getCertificate(from: app)?.revoked == true
	}

	var app: AppInfoPresentable
	@Binding var selectedInfoAppPresenting: AnyApp?
	@Binding var selectedSigningAppPresenting: AnyApp?
	@Binding var selectedInstallAppPresenting: AnyApp?
	@Binding var selectedAppUUIDs: Set<String>
	var compact = false
	@State private var _confirmDelete = false

	// MARK: Selections
	private var _isSelected: Bool {
		guard let uuid = app.uuid else { return false }
		return selectedAppUUIDs.contains(uuid)
	}

	private func _toggleSelection() {
		guard let uuid = app.uuid else { return }
		if selectedAppUUIDs.contains(uuid) {
			selectedAppUUIDs.remove(uuid)
		} else {
			selectedAppUUIDs.insert(uuid)
		}
		UIImpactFeedbackGenerator(style: .light).impactOccurred()
	}

	// MARK: Body
	var body: some View {
			let isRegular = horizontalSizeClass != .compact && !compact
		let isEditing = editMode?.wrappedValue == .active

			HStack(spacing: isRegular ? 14 : 12) {
			if isEditing {
				Button {
					_toggleSelection()
				} label: {
					Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
						.foregroundColor(_isSelected ? .accentColor : .secondary)
						.font(.title2)
				}
				.buttonStyle(.borderless)
			}

				FRAppIconView(app: app, size: isRegular ? 56 : 50)
					.shadow(color: .black.opacity(0.12), radius: 5, y: 2)

				VStack(alignment: .leading, spacing: 4) {
					Text(app.name ?? .localized("Unknown"))
						.font(isRegular ? .headline : .subheadline.weight(.semibold))
						.lineLimit(1)
					Text(_desc)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
					Label(_statusTitle, systemImage: _statusIcon)
						.font(.caption2.weight(.semibold))
						.foregroundStyle(_statusColor)
				}
				.frame(maxWidth: .infinity, alignment: .leading)

			if !isEditing {
				_buttonActions(for: app)
			}
		}
			.padding(.horizontal, isRegular ? 12 : 4)
			.padding(.vertical, isRegular ? 10 : 6)
		.background(
			isRegular
				? RoundedRectangle(cornerRadius: 18, style: .continuous)
				.fill(_isSelected && isEditing ? Color.accentColor.opacity(0.1) : Color(.quaternarySystemFill))
				: nil
		)
		.contentShape(Rectangle())
			.onTapGesture {
				if isEditing {
					_toggleSelection()
				}
			}
			.animation(.snappy, value: _isSelected)
			.swipeActions {
			if !isEditing {
				_actions(for: app)
			}
		}
			.contextMenu {
				if !isEditing {
					_contextActions(for: app)
					Divider()
					_contextActionsExtra(for: app)
					Divider()
					_actions(for: app)
				}
			}
			.confirmationDialog("Excluir aplicativo?", isPresented: $_confirmDelete) {
				Button("Excluir", role: .destructive) { Storage.shared.deleteApp(for: app) }
				Button("Cancelar", role: .cancel) { }
			} message: {
				Text(app.name ?? "Este aplicativo será removido da biblioteca.")
			}
		}

		private var _desc: String {
			if let version = app.version, let id = app.identifier {
				return "\(version) • \(id)"
			} else {
				return .localized("Unknown")
			}
		}

		private var _statusTitle: String {
			if certRevoked { return "Revogado" }
			if app.isSigned { return "Assinado" }
			return "Importado"
		}

		private var _statusIcon: String {
			if certRevoked { return "xmark.octagon.fill" }
			return app.isSigned ? "checkmark.seal.fill" : "arrow.down.circle"
		}

		private var _statusColor: Color {
			if certRevoked { return .red }
			return app.isSigned ? .green : .secondary
		}
	}


// MARK: - Extension: View
extension LibraryCellView {
	@ViewBuilder
		private func _actions(for app: AppInfoPresentable) -> some View {
			Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
				_confirmDelete = true
				UIImpactFeedbackGenerator(style: .medium).impactOccurred()
			}
	}

	@ViewBuilder
	private func _contextActions(for app: AppInfoPresentable) -> some View {
		Button(.localized("Get Info"), systemImage: "info.circle") {
			selectedInfoAppPresenting = AnyApp(base: app)
		}
	}

	@ViewBuilder
	private func _contextActionsExtra(for app: AppInfoPresentable) -> some View {
		if app.isSigned {
			if let id = app.identifier {
				Button(.localized("Open"), systemImage: "app.badge.checkmark") {
					UIApplication.openApp(with: id)
				}
			}
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Re-sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Export"), systemImage: "square.and.arrow.up") {
				selectedInstallAppPresenting = AnyApp(base: app, archive: true)
			}
		} else {
			Button(.localized("Install"), systemImage: "square.and.arrow.down") {
				selectedInstallAppPresenting = AnyApp(base: app)
			}
			Button(.localized("Sign"), systemImage: "signature") {
				selectedSigningAppPresenting = AnyApp(base: app)
			}
		}
	}

	@ViewBuilder
	private func _buttonActions(for app: AppInfoPresentable) -> some View {
		Group {
			if app.isSigned {
				Button {
					selectedInstallAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: .localized("Install"),
						revoked: certRevoked,
						expiration: certInfo
					)
				}
			} else {
				Button {
					selectedSigningAppPresenting = AnyApp(base: app)
				} label: {
					FRExpirationPillView(
						title: .localized("Sign"),
						revoked: false,
						expiration: nil
					)
				}
			}
		}
		.buttonStyle(.borderless)
	}
}
