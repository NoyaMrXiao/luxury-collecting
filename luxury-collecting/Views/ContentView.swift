//
//  ContentView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var viewModel = LuxuryItemViewModel()
    
    var body: some View {
        TabView {
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
            
            NavigationView {
                MyPageView(authViewModel: authViewModel)
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
        }
    }
}

#Preview {
    ContentView()
}
