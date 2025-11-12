//
//  LuxuryItemRowView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct LuxuryItemRowView: View {
    let item: LuxuryItem
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // 商品图片 - 基于ID生成稳定的随机高度以创造不对称效果
            let imageHeight: CGFloat = {
                let hash = item.id.uuidString.hashValue
                let normalized = abs(hash) % 100
                return 120 + CGFloat(normalized) * 0.6 // 120-180之间
            }()
            
            if let imageURL = item.imageURL,
               FileManager.default.fileExists(atPath: imageURL),
               let imageData = try? Data(contentsOf: URL(fileURLWithPath: imageURL)),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: imageHeight)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: imageHeight)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }
            }
            
            // 商品名称
            Text(item.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

#if os(iOS)
import UIKit
#endif

#Preview {
    LuxuryItemRowView(
        item: LuxuryItem(
            name: "经典款手袋",
            brand: "Hermès",
            category: .bag,
            price: 50000,
            purchaseDate: Date()
        )
    )
}

