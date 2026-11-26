//
//  SettingsView.swift
//  Feather
//

import SwiftUI
import NimbleViews

struct SettingsView: View {
	var body: some View {
		NBNavigationView(.localized("Settings")) {
				Form {
					Section {
					NavigationLink(destination: AppearanceView()) {
						Label(.localized("Appearance"), systemImage: "paintbrush")
					}
					NavigationLink(destination: CertificatesView()) {
						Label(.localized("Certificates"), systemImage: "checkmark.seal")
					}
					NavigationLink(destination: InstallationView()) {
						Label(.localized("Installation"), systemImage: "arrow.down.circle")
					}
				}
				.safeAreaInset(edge: .top, spacing: 8) {
					LopfinderCard {
						HStack(spacing: 14) {
							Image(systemName: "slider.horizontal.3")
								.font(.title2)
								.foregroundStyle(LopfinderPalette.indigo)
								.frame(width: 42, height: 42)
								.background(LopfinderPalette.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
							VStack(alignment: .leading, spacing: 3) {
								Text("Preferências do Lopfinder").font(.headline)
								Text("Configurações essenciais e protegidas").font(.caption).foregroundStyle(.secondary)
							}
						}
					}
					.padding(.horizontal)
				}
			}
		}
	}
}
