//
//  LuxuryItem.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation

/// 奢侈品模型
struct LuxuryItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var brand: String
    var category: Category
    var price: Double
    var purchaseDate: Date
    var description: String?
    var imageURL: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: Category,
        price: Double,
        purchaseDate: Date = Date(),
        description: String? = nil,
        imageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.price = price
        self.purchaseDate = purchaseDate
        self.description = description
        self.imageURL = imageURL
    }
}

// MARK: - Category
extension LuxuryItem {
    enum Category: String, Codable, CaseIterable {
        case watch = "手表"
        case bag = "包袋"
        case jewelry = "珠宝"
        case clothing = "服装"
        case shoes = "鞋履"
        case accessories = "配饰"
        case other = "其他"
    }
}

