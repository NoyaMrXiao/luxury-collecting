//
//  LuxuryItemListRowView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct LuxuryItemListRowView: View {
    let item: LuxuryItem
    
    var body: some View {
        HStack(spacing: 16) {
            // 商品图片
            productImage()
            
            // 商品信息
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(item.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(formatPrice(item.price))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: NSNumber(value: price)) ?? "¥\(price)"
    }
}

private extension LuxuryItemListRowView {
    @ViewBuilder
    func productImage() -> some View {
        if let urlString = item.imageURL {
            if let remoteURL = URL(string: urlString),
               remoteURL.scheme?.hasPrefix("http") == true {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                            .clipped()
                    case .failure:
                        placeholder
                    case .empty:
                        placeholder
                            .overlay(ProgressView())
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                #if os(iOS)
                if let legacyImage = legacyLocalImage(path: urlString) {
                    Image(uiImage: legacyImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    placeholder
                }
                #else
                placeholder
                #endif
            }
        } else {
            placeholder
        }
    }
    
    var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 100, height: 100)
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
        }
    }
    
    #if os(iOS)
    func legacyLocalImage(path: String) -> UIImage? {
        let resolvedPath: String
        if path.hasPrefix("file://"), let url = URL(string: path) {
            resolvedPath = url.path
        } else {
            resolvedPath = path
        }
        guard FileManager.default.fileExists(atPath: resolvedPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: resolvedPath)) else {
            return nil
        }
        return UIImage(data: data)
    }
    #endif
}

#Preview {
    LuxuryItemListRowView(
        item: LuxuryItem(
            name: "经典款手袋",
            brand: "Hermès",
            category: .bag,
            price: 50000,
            purchaseDate: Date()
        )
    )
    .padding()
}

