//
//  LuxuryItemStorage.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation

/// 数据存储协议
protocol LuxuryItemStorageProtocol {
    func loadItems() async throws -> [LuxuryItem]
    func saveItems(_ items: [LuxuryItem]) async throws
}

/// UserDefaults 存储实现
class UserDefaultsStorage: LuxuryItemStorageProtocol {
    private let key = "luxury_items"
    
    func loadItems() async throws -> [LuxuryItem] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        return try JSONDecoder().decode([LuxuryItem].self, from: data)
    }
    
    func saveItems(_ items: [LuxuryItem]) async throws {
        let data = try JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: key)
    }
}

