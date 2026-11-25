//
//  TabbarView.swift
//  feather
//

import SwiftUI

struct TabbarView: View {
	@State private var selectedTab: TabEnum = .library

	var body: some View {
		ZStack {
			TabView(selection: $selectedTab) {
				ForEach(TabEnum.defaultTabs, id: \.hashValue) { tab in
					TabEnum.view(for: tab)
						.tabItem {
							Label(tab.title, systemImage: tab.icon)
						}
						.tag(tab)
				}
			}
			.background(Color.clear)
			.toolbarBackground(.hidden, for: .tabBar)
		}
	}
}
