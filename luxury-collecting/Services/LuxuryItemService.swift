//
//  LuxuryItemService.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation

/// 奢侈品服务协议
protocol LuxuryItemServiceProtocol {
    func fetchItems() async throws -> [LuxuryItem]
    func saveItem(_ item: LuxuryItem) async throws
    func updateItem(_ item: LuxuryItem) async throws
    func deleteItem(_ item: LuxuryItem) async throws
}

/// 奢侈品服务实现
class LuxuryItemService: LuxuryItemServiceProtocol {
    private let storage: LuxuryItemStorageProtocol
    
    init(storage: LuxuryItemStorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
    }
    
    func fetchItems() async throws -> [LuxuryItem] {
        return try await storage.loadItems()
    }
    
    func saveItem(_ item: LuxuryItem) async throws {
        var items = try await storage.loadItems()
        items.append(item)
        try await storage.saveItems(items)
    }
    
    func updateItem(_ item: LuxuryItem) async throws {
        var items = try await storage.loadItems()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            try await storage.saveItems(items)
        }
    }
    
    func deleteItem(_ item: LuxuryItem) async throws {
        var items = try await storage.loadItems()
        items.removeAll(where: { $0.id == item.id })
        try await storage.saveItems(items)
    }
}

