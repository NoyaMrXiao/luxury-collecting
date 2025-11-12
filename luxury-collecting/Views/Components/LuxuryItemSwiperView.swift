//
//  LuxuryItemSwiperView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct LuxuryItemSwiperView: View {
    let item: LuxuryItem
    let viewModel: LuxuryItemViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                Spacer()
                
                // 商品图片
                if let imageURL = item.imageURL,
                   FileManager.default.fileExists(atPath: imageURL),
                   let imageData = try? Data(contentsOf: URL(fileURLWithPath: imageURL)),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: geometry.size.width * 0.9)
                        .frame(maxHeight: geometry.size.height * 0.7)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.7)
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
                
                // 商品名称
                Text(item.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
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
    LuxuryItemSwiperView(
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

