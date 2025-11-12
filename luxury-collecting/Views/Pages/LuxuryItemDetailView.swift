//
//  LuxuryItemDetailView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct LuxuryItemDetailView: View {
    let item: LuxuryItem
    @ObservedObject var viewModel: LuxuryItemViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var currentItem: LuxuryItem
    
    init(item: LuxuryItem, viewModel: LuxuryItemViewModel) {
        self.item = item
        self.viewModel = viewModel
        _currentItem = State(initialValue: item)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 商品图片 - 全宽展示
                if let imageURL = currentItem.imageURL,
                   FileManager.default.fileExists(atPath: imageURL),
                   let imageData = try? Data(contentsOf: URL(fileURLWithPath: imageURL)),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 400)
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 64))
                                .foregroundColor(.secondary)
                            Text("暂无图片")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 商品信息卡片区域
                VStack(spacing: 16) {
                    // 名称和品牌卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text(currentItem.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(currentItem.brand)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 价格和类别信息卡片
                    HStack(spacing: 12) {
                        // 价格
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("价格")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(formatPrice(currentItem.price))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        
                        // 类别
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("类别")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(currentItem.category.rawValue)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // 购买日期卡片
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("购买日期")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(formatDate(currentItem.purchaseDate))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
                    .padding(.horizontal, 16)
                    
                    // 备注卡片
                    if let description = currentItem.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "note.text")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text("备注")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color(.secondarySystemBackground))
        .navigationTitle("商品详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditView = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditLuxuryItemView(viewModel: viewModel, item: currentItem)
        }
        .alert("删除收藏", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("确定要删除「\(currentItem.name)」吗？此操作无法撤销。")
        }
        .onChange(of: viewModel.items) { items in
            // 当列表更新时，更新当前显示的 item
            if let updatedItem = items.first(where: { $0.id == currentItem.id }) {
                currentItem = updatedItem
            }
        }
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: price)) ?? "¥\(price)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func deleteItem() {
        Task {
            await viewModel.deleteItem(currentItem)
            dismiss()
        }
    }
}

#if os(iOS)
import UIKit
#endif

#Preview {
    NavigationView {
        LuxuryItemDetailView(
            item: LuxuryItem(
                name: "经典款手袋",
                brand: "Hermès",
                category: .bag,
                price: 50000,
                purchaseDate: Date(),
                description: "这是一款非常经典的奢侈品手袋，采用优质皮革制作，工艺精湛。"
            ),
            viewModel: LuxuryItemViewModel()
        )
    }
}

