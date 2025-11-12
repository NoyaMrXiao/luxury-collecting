//
//  LuxuryItemListRowView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct LuxuryItemListRowView: View {
    let item: LuxuryItem
    
    var body: some View {
        HStack(spacing: 16) {
            // 商品图片
            if let imageURL = item.imageURL,
               FileManager.default.fileExists(atPath: imageURL),
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: imageURL)),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .clipped()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 100, height: 100)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }
            }
            
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

#if os(iOS)
import UIKit
#endif

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

