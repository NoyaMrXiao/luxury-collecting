//
//  ContentView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var viewModel = LuxuryItemViewModel()
    
    var body: some View {
        TabView (selection: $selectedTab) {
            NavigationView {
                LuxuryItemListView(viewModel: viewModel)
                    .task {
                        await viewModel.loadItems()
                    }
                    .navigationTitle("我的奢侈品收藏柜")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("收藏", systemImage: "list.bullet")
            }
            .tag(0)
            
            NavigationView {
                MyPageView(authViewModel: authViewModel)
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
            .tag(1)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            triggerHaptic()
            print("selectedTab changed from \(oldValue) to \(newValue)")
        }
    }
    private func triggerHaptic() {
       let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

#Preview {
    ContentView()
}
