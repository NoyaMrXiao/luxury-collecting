//
//  ImageUploadData.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/14.
//

import Foundation

/// 图片上传所需的数据和元信息
struct ImageUploadData {
    let data: Data
    let fileExtension: String
    let fileName: String
    
    var mimeType: String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        default:
            return "application/octet-stream"
        }
    }
}

