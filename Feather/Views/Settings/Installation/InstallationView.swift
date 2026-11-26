//
//  InstallationView.swift
//  Feather
//
//  Created by samara on 3.06.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
	@AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
	@State private var _showMethodChangedAlert = false

	private let _installationMethods: [String] = [
		.localized("Server"),
		.localized("idevice")
	]
	
	// MARK: Body
		var body: some View {
			NBList(.localized("Installation")) {
				Section {
					LopfinderCard(tint: LopfinderPalette.mint) {
						HStack(spacing: 14) {
							Image(systemName: "lock.shield.fill")
								.font(.title2)
								.foregroundStyle(LopfinderPalette.mint)
								.frame(width: 42, height: 42)
								.background(LopfinderPalette.mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
							VStack(alignment: .leading, spacing: 5) {
								Text("Instalação protegida").font(.headline)
								Text("As opções recomendadas ficam fixas para evitar falhas.").font(.caption).foregroundStyle(.secondary)
							}
						}
						HStack(spacing: 8) {
							LopfinderStatusBadge(title: "Server", systemImage: "server.rack")
							LopfinderStatusBadge(title: "Semi Local", systemImage: "network", color: LopfinderPalette.violet)
							LopfinderStatusBadge(title: "Localhost", systemImage: "lock.fill", color: LopfinderPalette.mint)
						}
					}
				}
				Section {
				Picker(.localized("Installation Type"), systemImage: "arrow.down.app", selection: $_installationMethod) {
					ForEach(_installationMethods.indices, id: \.description) { index in
						Text(_installationMethods[index]).tag(index)
					}
				}
				.disabled(true)
			} footer: {
				Text(.localized("Server (Recommended):\nUses a locally hosted server and itms-services:// to install applications.\n\nIDevice (advanced):\nUses a VPN and a pairing file. Writes to AFC and manually calls installd, while monitoring install progress by using a callback\nAdvantage: It is very reliable, does not need SSL certificates or a externally hosted server. Rather, works similarly to a computer."))
			}
			
			if _installationMethod == 0 {
				ServerView()
			} else if _installationMethod == 1 {
				TunnelView()
			}
		}
			.onAppear { _installationMethod = 0 }
			.onChange(of: _installationMethod) { _ in _installationMethod = 0 }
		.alert(.localized("Advanced Installation Method"), isPresented: $_showMethodChangedAlert) {
			Button(.localized("Switch Back"), role: .destructive) {
				_installationMethod = 0
			}
			Button(.localized("OK"), role: .cancel) {}
		} message: {
			Text(.localized("idevice warning"))
		}


		.animation(.default, value: _installationMethod)
	}
}
