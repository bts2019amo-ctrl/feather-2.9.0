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
			}
		}
	}
}
