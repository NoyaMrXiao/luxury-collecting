//
//  BackgroundRemovalService.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation
#if os(iOS)
import UIKit
import Vision
import CoreVideo
#endif

/// 图片去背景服务
#if os(iOS)
@available(iOS 13.0, *)
class BackgroundRemovalService {
    
    /// 处理图片去背景
    /// - Parameter imageData: 图片数据
    /// - Returns: 处理后的图片数据（PNG格式，支持透明背景），如果处理失败则返回nil
    static func removeBackground(from imageData: Data) async -> Data? {
        guard let uiImage = UIImage(data: imageData) else { return nil }
        
        // 限制图片尺寸以提高处理速度和兼容性
        let maxDimension: CGFloat = 1024
        let resizedImage: UIImage
        if max(uiImage.size.width, uiImage.size.height) > maxDimension {
            let scale = maxDimension / max(uiImage.size.width, uiImage.size.height)
            let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
            resizedImage = await resizeImage(uiImage, to: newSize) ?? uiImage
        } else {
            resizedImage = uiImage
        }
        
        guard let cgImage = resizedImage.cgImage else { return nil }
        
        // 首先尝试使用 VNGenerateForegroundInstanceMaskRequest (iOS 16+)
        if #available(iOS 16.0, *) {
            if let processedImage = await tryForegroundInstanceMaskRemoval(image: resizedImage, cgImage: cgImage) {
                return processedImage.pngData()
            }
        }
        
        // 如果 iOS 16+ 的方法失败或不支持，使用备选方案
        if let processedImage = await trySaliencyBasedRemoval(image: resizedImage, cgImage: cgImage) {
            return processedImage.pngData()
        }
        
        return nil
    }
    
    // MARK: - 主要方法：前景实例蒙版（iOS 16+）
    @available(iOS 16.0, *)
    private static func tryForegroundInstanceMaskRemoval(image: UIImage, cgImage: CGImage) async -> UIImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let results = request.results,
                  let result = results.first else {
                return nil
            }
            
            // 获取前景蒙版
            let mask = try result.generateScaledMaskForImage(
                forInstances: result.allInstances,
                from: handler
            )
            
            // 应用蒙版去除背景
            return applyMaskToImage(originalImage: image, mask: mask)
        } catch {
            print("前景蒙版生成失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 备选方案：显著性检测
    private static func trySaliencyBasedRemoval(image: UIImage, cgImage: CGImage) async -> UIImage? {
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let results = request.results,
                  let saliencyMap = results.first else {
                return nil
            }
            
            // 使用显著性图生成蒙版
            return applySaliencyMaskToImage(originalImage: image, saliencyObservation: saliencyMap)
        } catch {
            print("显著性检测失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 辅助方法
    
    /// 调整图片尺寸
    private static func resizeImage(_ image: UIImage, to size: CGSize) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
                defer { UIGraphicsEndImageContext() }
                image.draw(in: CGRect(origin: .zero, size: size))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                continuation.resume(returning: resizedImage)
            }
        }
    }
    
    /// 使用显著性图去除背景
    private static func applySaliencyMaskToImage(originalImage: UIImage, saliencyObservation: VNSaliencyImageObservation) -> UIImage? {
        guard let cgImage = originalImage.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        // 绘制原始图片
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 获取显著性图
        let mask = saliencyObservation.pixelBuffer
        
        // 锁定像素缓冲区
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(mask),
              let pixelData = context.data else {
            return nil
        }
        
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)
        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        
        // 应用蒙版：将背景区域设为透明
        let pixelBuffer = pixelData.assumingMemoryBound(to: UInt8.self)
        let maskBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            let maskY = min(Int(Float(y) / Float(height) * Float(maskHeight)), maskHeight - 1)
            for x in 0..<width {
                let maskX = min(Int(Float(x) / Float(width) * Float(maskWidth)), maskWidth - 1)
                let maskIndex = maskY * maskBytesPerRow + maskX
                let maskValue = maskBuffer[maskIndex]
                
                let pixelIndex = (height - 1 - y) * width * 4 + x * 4
                
                // 如果显著性值较低（背景），则将alpha设为0（透明）
                if maskValue < 128 {
                    pixelBuffer[pixelIndex + 3] = 0 // Alpha通道设为0
                }
            }
        }
        
        guard let finalCGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: finalCGImage)
    }
    
    /// 将蒙版应用到图片上，去除背景
    private static func applyMaskToImage(originalImage: UIImage, mask: CVPixelBuffer) -> UIImage? {
        guard let cgImage = originalImage.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        // 绘制原始图片
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 锁定像素缓冲区
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(mask),
              let pixelData = context.data else {
            return nil
        }
        
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)
        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        
        // 应用蒙版：将背景区域设为透明
        let pixelBuffer = pixelData.assumingMemoryBound(to: UInt8.self)
        let maskBuffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        
        for y in 0..<height {
            let maskY = min(Int(Float(y) / Float(height) * Float(maskHeight)), maskHeight - 1)
            for x in 0..<width {
                let maskX = min(Int(Float(x) / Float(width) * Float(maskWidth)), maskWidth - 1)
                let maskIndex = maskY * maskBytesPerRow + maskX
                let maskValue = maskBuffer[maskIndex]
                
                let pixelIndex = (height - 1 - y) * width * 4 + x * 4
                
                // 如果蒙版值为0（背景），则将alpha设为0（透明）
                if maskValue < 128 {
                    pixelBuffer[pixelIndex + 3] = 0 // Alpha通道设为0
                }
            }
        }
        
        guard let finalCGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: finalCGImage)
    }
}
#endif

