//
//  LuxuryItemRowView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

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
            
            productImage(height: imageHeight)
            
            // 商品名称
            Text(item.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }
}

private extension LuxuryItemRowView {
    @ViewBuilder
    func productImage(height: CGFloat) -> some View {
        if let imageURL = item.imageURL {
            if let remoteURL = URL(string: imageURL),
               remoteURL.scheme?.hasPrefix("http") == true {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                            .clipped()
                    case .failure:
                        placeholder(height: height)
                    case .empty:
                        placeholder(height: height)
                            .overlay(ProgressView())
                    @unknown default:
                        placeholder(height: height)
                    }
                }
            } else {
                #if os(iOS)
                if let legacyImage = legacyLocalImage(path: imageURL) {
                    Image(uiImage: legacyImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: height)
                } else {
                    placeholder(height: height)
                }
                #else
                placeholder(height: height)
                #endif
            }
        } else {
            placeholder(height: height)
        }
    }
    
    @ViewBuilder
    func placeholder(height: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color(.secondarySystemBackground))
                .frame(height: height)
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

