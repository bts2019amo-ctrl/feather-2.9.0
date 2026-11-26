//
//  DownloadHeaderView.swift
//  Feather
//
//  Created by samara on 16.05.2025.
//

import SwiftUI
import Combine
import NimbleExtensions

struct DownloadHeaderView: View {
	@ObservedObject var downloadManager: DownloadManager
	@State private var _showDetails = false
	
	var body: some View {
		ZStack {
			if !downloadManager.manualDownloads.isEmpty {
				VStack {
					VStack(spacing: 12) {
						if let firstDownload = downloadManager.manualDownloads.first {
								DownloadItemView(download: firstDownload)
							
								if downloadManager.manualDownloads.count > 1 {
									HStack {
										Spacer()
										Button("+\(downloadManager.manualDownloads.count - 1) downloads") {
											_showDetails = true
										}
											.font(.caption.weight(.semibold))
									}
								}
						}
					}
					.padding(.horizontal)
				}
				.transition(.move(edge: .top).combined(with: .opacity))
			}
			.sheet(isPresented: $_showDetails) {
				DownloadCenterView(downloads: downloadManager.manualDownloads)
			}
		}
		.animation(.spring(), value: downloadManager.manualDownloads.count)
	}
}

private struct DownloadCenterView: View {
	let downloads: [Download]

	var body: some View {
		NavigationStack {
			List {
				Section("Em andamento") {
					ForEach(downloads) { download in
						DownloadItemView(download: download, showsCancel: true)
					}
				}
			}
			.navigationTitle("Downloads")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}

struct DownloadItemView: View {
	let download: Download
	var showsCancel = false
	@State private var progress: Double = 0
	@State private var bytesDownloaded: Int64 = 0
	@State private var totalBytes: Int64 = 0
	@State private var unpackageProgress: Double = 0
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(download.fileName)
				.font(.subheadline)
				.lineLimit(1)
			
			ProgressView(value: overallProgress)
				.progressViewStyle(.linear)
			
				HStack {
				Text(verbatim: "\(Int(overallProgress * 100))%")
					.contentTransition(.numericText())
				Spacer()
					if totalBytes > 0 {
						Text(verbatim: "\($bytesDownloaded.wrappedValue.formattedByteCount) / \(totalBytes.formattedByteCount)")
							.contentTransition(.numericText())
					}
					if showsCancel {
						Button(role: .destructive) {
							DownloadManager.shared.cancelDownload(download)
						} label: {
							Image(systemName: "xmark.circle.fill")
						}
						.buttonStyle(.borderless)
					}
			}
			.font(.caption)
			.foregroundColor(.secondary)
		}
		.padding(.vertical, 4)
		.onReceive(download.$progress) { self.progress = $0 }
		.onReceive(download.$bytesDownloaded) { self.bytesDownloaded = $0 }
		.onReceive(download.$totalBytes) { self.totalBytes = $0 }
		.onReceive(download.$unpackageProgress) { self.unpackageProgress = $0 }
	}
	
	private var overallProgress: Double {
		download.onlyArchiving
			? unpackageProgress
			: (0.3 * unpackageProgress) + (0.7 * progress)
	}
}
