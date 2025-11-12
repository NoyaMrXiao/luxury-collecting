//
//  LuxuryItemListView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

enum ViewMode {
    case grid
    case list
}

struct LuxuryItemListView: View {
    @ObservedObject var viewModel: LuxuryItemViewModel
    @State private var showingAddItem = false
    @State private var viewMode: ViewMode = .grid
    
    var body: some View {
        Group {
            if viewMode == .grid {
                gridView
            } else {
                listView
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    // 视图切换按钮
                    Button(action: {
                        withAnimation {
                            viewMode = viewMode == .grid ? .list : .grid
                        }
                    }) {
                        Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                    }
                    
                    // 添加按钮
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddLuxuryItemView(viewModel: viewModel)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // 网格视图
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 20) {
                ForEach(viewModel.items) { item in
                    NavigationLink(destination: LuxuryItemDetailView(item: item, viewModel: viewModel)) {
                        LuxuryItemRowView(item: item)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
    }
    
    // 列表视图（全屏swiper形式）
    private var listView: some View {
        Group {
            if viewModel.items.isEmpty {
                VStack {
                    Spacer()
                    Text("暂无收藏")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                                NavigationLink(destination: LuxuryItemDetailView(item: item, viewModel: viewModel)) {
                                    LuxuryItemSwiperView(item: item, viewModel: viewModel)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .id(index)
                            }
                        }
                    }
                    .scrollTargetBehavior(.paging)
                }
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        Task {
            for index in offsets {
                await viewModel.deleteItem(viewModel.items[index])
            }
        }
    }
}

#Preview {
    NavigationView {
        LuxuryItemListView(viewModel: LuxuryItemViewModel())
    }
}

