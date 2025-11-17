//
//  LuxuryItemSwiperView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct LuxuryItemSwiperView: View {
    let item: LuxuryItem
    let viewModel: LuxuryItemViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                Spacer()
                
                // 商品图片
                productImage(width: geometry.size.width * 0.9, height: geometry.size.height * 0.7)
                
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

private extension LuxuryItemSwiperView {
    @ViewBuilder
    func productImage(width: CGFloat, height: CGFloat) -> some View {
        if let urlString = item.imageURL {
            if let remoteURL = URL(string: urlString),
               remoteURL.scheme?.hasPrefix("http") == true {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: width)
                            .frame(maxHeight: height)
                    case .failure:
                        placeholder(width: width, height: height)
                    case .empty:
                        placeholder(width: width, height: height)
                            .overlay(ProgressView())
                    @unknown default:
                        placeholder(width: width, height: height)
                    }
                }
            } else {
                #if os(iOS)
                if let legacyImage = legacyLocalImage(path: urlString) {
                    Image(uiImage: legacyImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: width)
                        .frame(maxHeight: height)
                } else {
                    placeholder(width: width, height: height)
                }
                #else
                placeholder(width: width, height: height)
                #endif
            }
        } else {
            placeholder(width: width, height: height)
        }
    }
    
    @ViewBuilder
    func placeholder(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .frame(width: width, height: height)
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

