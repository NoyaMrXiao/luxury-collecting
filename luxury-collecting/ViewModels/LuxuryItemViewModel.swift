//
//  LuxuryItemViewModel.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation
import SwiftUI

/// 奢侈品列表视图模型
@MainActor
class LuxuryItemViewModel: ObservableObject {
    @Published var items: [LuxuryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let service: LuxuryItemServiceProtocol
    
    init(service: LuxuryItemServiceProtocol = LuxuryItemService()) {
        self.service = service
    }
    
    // MARK: - Public Methods
    
    func loadItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            items = try await service.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addItem(_ item: LuxuryItem) async {
        do {
            try await service.saveItem(item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteItem(_ item: LuxuryItem) async {
        do {
            try await service.deleteItem(item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateItem(_ item: LuxuryItem) async {
        do {
            try await service.updateItem(item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

