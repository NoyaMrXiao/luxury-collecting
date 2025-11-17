//
//  ImageUploadHelper.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/14.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#endif

enum ImageUploadHelper {
    #if canImport(UIKit)
    /// 将任意图片数据转换为 jpeg 以便上传，并返回上传所需的信息
    static func prepareUploadData(from data: Data, compressionQuality: CGFloat = 0.9) -> ImageUploadData? {
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        let fileName = generateFileName()
        return ImageUploadData(data: jpegData, fileExtension: "jpg", fileName: fileName)
    }
    #else
    static func prepareUploadData(from data: Data) -> ImageUploadData? {
        ImageUploadData(data: data, fileExtension: "png", fileName: generateFileName())
    }
    #endif
    
    private static func generateFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let randomSuffix = UUID().uuidString.prefix(6)
        return sanitize("photo_\(timestamp)_\(randomSuffix)")
    }
    
    private static func sanitize(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filtered = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let sanitized = String(filtered).replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
        return sanitized.lowercased()
    }
}

