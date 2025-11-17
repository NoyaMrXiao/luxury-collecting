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
    @State private var appearedItems: Set<UUID> = []
    @State private var showEmptyMessage = false
    
    var body: some View {
        Group {
            if viewMode == .grid {
                gridView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 0.9))
                    ))
            } else {
                listView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewMode)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // 视图切换按钮
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        // 重置动画状态，以便切换视图时重新触发动画
                        appearedItems.removeAll()
                        viewMode = viewMode == .grid ? .list : .grid
                    }
                }) {
                    Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                // 添加按钮
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showingAddItem = true
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
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
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    NavigationLink(destination: LuxuryItemDetailView(item: item, viewModel: viewModel)) {
                        gridItemView(item: item, index: index)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                        .modifier(AnimatedAppearModifier(isVisible: showEmptyMessage, initialScale: 0.8))
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showEmptyMessage = true
                            }
                        }
                    Spacer()
                }
            } else {
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                                NavigationLink(destination: LuxuryItemDetailView(item: item, viewModel: viewModel)) {
                                    listItemView(item: item, index: index)
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
    
    @ViewBuilder
    private func gridItemView(item: LuxuryItem, index: Int) -> some View {
        LuxuryItemRowView(item: item)
            .modifier(AnimatedAppearModifier(isVisible: appearedItems.contains(item.id), initialScale: 0.8))
            .onAppear {
                triggerAppear(
                    for: item.id,
                    delay: Double(index) * 0.05,
                    animation: .spring(response: 0.6, dampingFraction: 0.8)
                )
            }
    }
    
    @ViewBuilder
    private func listItemView(item: LuxuryItem, index: Int) -> some View {
        LuxuryItemSwiperView(item: item, viewModel: viewModel)
            .modifier(AnimatedAppearModifier(isVisible: appearedItems.contains(item.id), initialScale: 0.95))
            .onAppear {
                triggerAppear(
                    for: item.id,
                    delay: Double(index) * 0.1,
                    animation: .spring(response: 0.7, dampingFraction: 0.8)
                )
            }
    }
    
    private func triggerAppear(for id: UUID, delay: TimeInterval, animation: Animation) {
        guard !appearedItems.contains(id) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(animation) {
                _ = appearedItems.insert(id)
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

private struct AnimatedAppearModifier: ViewModifier {
    let isVisible: Bool
    let initialScale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : initialScale)
    }
}

#Preview {
    NavigationView {
        LuxuryItemListView(viewModel: LuxuryItemViewModel())
    }
}

