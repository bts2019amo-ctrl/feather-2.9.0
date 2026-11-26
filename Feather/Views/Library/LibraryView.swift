//
//  ContentView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
	@StateObject var downloadManager = DownloadManager.shared
	
	@State private var _selectedInfoAppPresenting: AnyApp?
	@State private var _selectedSigningAppPresenting: AnyApp?
	@State private var _selectedInstallAppPresenting: AnyApp?
	@State private var _isImportingPresenting = false
	@State private var _isDownloadingPresenting = false
	@State private var _alertDownloadString: String = "" // for _isDownloadingPresenting
	
	// MARK: Selection State
	@State private var _selectedAppUUIDs: Set<String> = []
	@State private var _editMode: EditMode = .inactive
	
		@State private var _searchText = ""
		@State private var _selectedScope: Scope = .all
		@State private var _sortOrder: SortOrder = .recent
		@State private var _showHistory = false
		@State private var _appToDelete: AnyApp?
	
	
	@Namespace private var _namespace
	
	// horror
	private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
		apps.filter {
			_searchText.isEmpty ||
				(($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _filteredSignedApps: [Signed] {
		filteredAndSortedApps(from: _signedApps)
	}
	
		private var _filteredImportedApps: [Imported] {
			filteredAndSortedApps(from: _importedApps)
		}

		private var _sortedSignedApps: [Signed] {
			sort(_filteredSignedApps)
		}

		private var _sortedImportedApps: [Imported] {
			sort(_filteredImportedApps)
		}

		private func sort<T: NSManagedObject>(_ apps: [T]) -> [T] {
			switch _sortOrder {
			case .recent:
				return apps
			case .name:
				return apps.sorted { ($0.value(forKey: "name") as? String ?? "") < ($1.value(forKey: "name") as? String ?? "") }
			}
		}
	
	// MARK: Fetch
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
		animation: .snappy
	) private var _signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
		animation: .snappy
	) private var _importedApps: FetchedResults<Imported>
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Library")) {
			NBListAdaptable {
				if
					!_filteredSignedApps.isEmpty,
					_selectedScope == .all || _selectedScope == .signed
				{
					NBSection(
						.localized("Signed"),
						secondary: _filteredSignedApps.count.description
					) {
							ForEach(_sortedSignedApps, id: \.uuid) { app in
							LibraryCellView(
								app: app,
								selectedInfoAppPresenting: $_selectedInfoAppPresenting,
								selectedSigningAppPresenting: $_selectedSigningAppPresenting,
								selectedInstallAppPresenting: $_selectedInstallAppPresenting,
								selectedAppUUIDs: $_selectedAppUUIDs
							)
							.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
						}
					}
				}
				
				if
					!_filteredImportedApps.isEmpty,
					_selectedScope == .all || _selectedScope == .imported
				{
					NBSection(
						.localized("Imported"),
						secondary: _filteredImportedApps.count.description
					) {
							ForEach(_sortedImportedApps, id: \.uuid) { app in
							LibraryCellView(
								app: app,
								selectedInfoAppPresenting: $_selectedInfoAppPresenting,
								selectedSigningAppPresenting: $_selectedSigningAppPresenting,
								selectedInstallAppPresenting: $_selectedInstallAppPresenting,
								selectedAppUUIDs: $_selectedAppUUIDs
							)
							.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
						}
					}
				}
			}
			.searchable(text: $_searchText, placement: .platform())
			.compatSearchScopes($_selectedScope) {
				ForEach(Scope.allCases, id: \.displayName) { scope in
					Text(scope.displayName).tag(scope)
				}
			}
			.scrollDismissesKeyboard(.interactively)
			.overlay {
				if
					_filteredSignedApps.isEmpty,
					_filteredImportedApps.isEmpty
				{
					if #available(iOS 17, *) {
						ContentUnavailableView {
							Label(.localized("No Apps"), systemImage: "questionmark.app.fill")
						} description: {
							Text(.localized("Get started by importing your first IPA file."))
						} actions: {
							Menu {
								_importActions()
							} label: {
								NBButton(.localized("Import"), style: .text)
							}
						}
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					EditButton()
				}
				
				if _editMode.isEditing {
					NBToolbarButton(
						.localized("Delete"),
						systemImage: "trash",
						isDisabled: _selectedAppUUIDs.isEmpty
					) {
						_bulkDeleteSelectedApps()
					}
				} else {
					NBToolbarMenu(
						systemImage: "plus",
						style: .icon,
						placement: .topBarTrailing
						) {
							_importActions()
							Divider()
							Button(.localized("Sort by name"), systemImage: "textformat.abc") {
								_sortOrder = .name
							}
							Button(.localized("Most recent"), systemImage: "clock") {
								_sortOrder = .recent
							}
							Divider()
							Button(.localized("Installation history"), systemImage: "clock.arrow.circlepath") {
								_showHistory = true
							}
						}
				}
			}
			.environment(\.editMode, $_editMode)
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
					.presentationDetents([.height(200)])
					.presentationDragIndicator(.visible)
			}
			.fullScreenCover(item: $_selectedSigningAppPresenting) { app in
				SigningView(app: app.base)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.sheet(isPresented: $_isImportingPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.ipa, .tipa],
					allowsMultipleSelection: true,
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						for url in urls {
							let id = "FeatherManualDownload_\(UUID().uuidString)"
							let dl = downloadManager.startArchive(from: url, id: id)
							try? downloadManager.handlePachageFile(url: url, dl: dl)
						}
					}
				)
				.ignoresSafeArea()
			}
				.alert(.localized("Import from URL"), isPresented: $_isDownloadingPresenting) {
				TextField(.localized("URL"), text: $_alertDownloadString)
					.textInputAutocapitalization(.never)
				Button(.localized("Cancel"), role: .cancel) {
					_alertDownloadString = ""
				}
				Button(.localized("OK")) {
					if let url = URL(string: _alertDownloadString) {
						_ = downloadManager.startDownload(from: url, id: "FeatherManualDownload_\(UUID().uuidString)")
					}
					}
				}
				.confirmationDialog(
					.localized("Delete application?"),
					isPresented: Binding(get: { _appToDelete != nil }, set: { if !$0 { _appToDelete = nil } }),
					presenting: _appToDelete
				) { app in
					Button(.localized("Delete"), role: .destructive) {
						Storage.shared.deleteApp(for: app.base)
						_appToDelete = nil
					}
					Button(.localized("Cancel"), role: .cancel) { _appToDelete = nil }
				} message: { app in
					Text(app.base.name ?? .localized("Unknown"))
				}
				.sheet(isPresented: $_showHistory) {
					InstallationHistoryView(signedApps: _signedApps.map { $0 })
				}
				.safeAreaInset(edge: .top, spacing: 8) {
					LibraryOverviewCard(
						signedCount: _signedApps.count,
						importedCount: _importedApps.count,
						downloadCount: downloadManager.manualDownloads.count
					)
					.padding(.horizontal)
				}
				.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
				if let latest = _signedApps.first {
					_selectedInstallAppPresenting = AnyApp(base: latest)
				}
			}
			.onChange(of: _editMode) { mode in
				if mode == .inactive {
					_selectedAppUUIDs.removeAll()
				}
			}
		}
	}
}

// MARK: - Extension: View
extension LibraryView {
	@ViewBuilder
	private func _importActions() -> some View {
		Button(.localized("Import from Files"), systemImage: "folder") {
			_isImportingPresenting = true
		}
		Button(.localized("Import from URL"), systemImage: "globe") {
			_isDownloadingPresenting = true
		}
	}
}

// MARK: - Extension: Bulk Delete
extension LibraryView {
	private func _bulkDeleteSelectedApps() {
		let selectedApps = _getAllApps().filter { app in
			guard let uuid = app.uuid else { return false }
			return _selectedAppUUIDs.contains(uuid)
		}
		
		for app in selectedApps {
			Storage.shared.deleteApp(for: app)
		}
		
		_selectedAppUUIDs.removeAll()
		
		// _editMode = .inactive
	}
	
	private func _getAllApps() -> [AppInfoPresentable] {
		var allApps: [AppInfoPresentable] = []
		
		if _selectedScope == .all || _selectedScope == .signed {
			allApps.append(contentsOf: _filteredSignedApps)
		}
		
		if _selectedScope == .all || _selectedScope == .imported {
			allApps.append(contentsOf: _filteredImportedApps)
		}
		
		return allApps
	}
}

// MARK: - Extension: View (Sort)
extension LibraryView {
	enum Scope: CaseIterable {
		case all
		case signed
		case imported
		
			var displayName: String {
				switch self {
				case .all: return .localized("All")
				case .signed: return .localized("Signed")
				case .imported: return .localized("Imported")
				}
			}
		}

		enum SortOrder {
			case recent
			case name
		}
	}
}

private struct LibraryOverviewCard: View {
	let signedCount: Int
	let importedCount: Int
	let downloadCount: Int

	var body: some View {
		LopfinderCard {
			HStack(spacing: 16) {
				VStack(alignment: .leading, spacing: 4) {
					Text("Sua biblioteca").font(.headline)
					Text("Tudo organizado em um só lugar").font(.caption).foregroundStyle(.secondary)
				}
				Spacer()
				Image(systemName: "square.grid.2x2.fill").font(.title2).foregroundStyle(LopfinderPalette.indigo)
			}
			Divider().padding(.vertical, 4)
			HStack {
				LopfinderMetric(title: "Assinados", value: "\(signedCount)", systemImage: "checkmark.seal.fill", color: LopfinderPalette.mint)
				Spacer()
				LopfinderMetric(title: "Importados", value: "\(importedCount)", systemImage: "square.and.arrow.down", color: LopfinderPalette.violet)
				if downloadCount > 0 {
					Spacer()
					LopfinderMetric(title: "Ativos", value: "\(downloadCount)", systemImage: "arrow.down.circle.fill", color: LopfinderPalette.warning)
				}
			}
		}
	}
}

private struct InstallationHistoryView: View {
	let signedApps: [Signed]

	var body: some View {
		NavigationStack {
			List {
				if signedApps.isEmpty {
					LopfinderEmptyState(title: "Sem histórico", message: "As instalações concluídas aparecerão aqui.", systemImage: "clock.arrow.circlepath")
				} else {
					ForEach(signedApps, id: \.uuid) { app in
						Label {
							VStack(alignment: .leading) {
								Text(app.name ?? "Aplicativo")
								Text(app.date?.formatted(date: .abbreviated, time: .shortened) ?? "Data desconhecida")
									.font(.caption).foregroundStyle(.secondary)
							}
						} icon: {
							Image(systemName: "checkmark.circle.fill").foregroundStyle(LopfinderPalette.mint)
						}
					}
				}
			}
			.navigationTitle("Histórico")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}
