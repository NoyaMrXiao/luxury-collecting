//
//  LuxuryItemService.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation
import Supabase

/// 奢侈品服务协议
protocol LuxuryItemServiceProtocol {
    func fetchItems() async throws -> [LuxuryItem]
    func saveItem(_ item: LuxuryItem) async throws
    func updateItem(_ item: LuxuryItem) async throws
    func deleteItem(_ item: LuxuryItem) async throws
    func uploadImage(data: Data, fileName: String?, fileExtension: String) async throws -> String
}

/// Supabase 相关错误
enum LuxuryItemServiceError: LocalizedError {
    case supabaseNotConfigured
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .supabaseNotConfigured:
            return "Supabase 尚未配置"
        case .notAuthenticated:
            return "请先登录以同步云端数据"
        }
    }
}

/// 奢侈品服务实现（使用 Supabase）
class LuxuryItemService: LuxuryItemServiceProtocol {
    private let supabaseService: SupabaseService
    
    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
    }
    
    func fetchItems() async throws -> [LuxuryItem] {
        let client = try resolveClient()
        let userId = try await requireAuthenticatedUserId(using: client)
        
        let rows: [LuxuryItemRow] = try await client
            .from("luxury_items")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("purchase_date", ascending: false)
            .execute()
            .value
        
        return rows.map { $0.toDomainModel() }
    }
    
    func saveItem(_ item: LuxuryItem) async throws {
        let client = try resolveClient()
        let userId = try await requireAuthenticatedUserId(using: client)
        let payload = LuxuryItemInsertPayload(item: item, userId: userId)
        
        _ = try await client
            .from("luxury_items")
            .insert(payload)
            .execute()
    }
    
    func updateItem(_ item: LuxuryItem) async throws {
        let client = try resolveClient()
        let userId = try await requireAuthenticatedUserId(using: client)
        let payload = LuxuryItemUpdatePayload(item: item, userId: userId)
        
        _ = try await client
            .from("luxury_items")
            .update(payload)
            .eq("id", value: item.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    func deleteItem(_ item: LuxuryItem) async throws {
        let client = try resolveClient()
        let userId = try await requireAuthenticatedUserId(using: client)
        
        _ = try await client
            .from("luxury_items")
            .delete()
            .eq("id", value: item.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    func uploadImage(data: Data, fileName: String?, fileExtension: String) async throws -> String {
        let client = try resolveClient()
        let userId = try await requireAuthenticatedUserId(using: client)
        let bucket = client.storage.from(storageBucketName)
        let objectPath = makeStoragePath(for: userId, fileName: fileName, fileExtension: fileExtension)
        let fileOptions = FileOptions(
            cacheControl: "3600",
            contentType: mimeType(for: fileExtension),
            upsert: false
        )
        
        try await bucket.upload(objectPath, data: data, options: fileOptions)
        let publicURL = try bucket.getPublicURL(path: objectPath)
        return publicURL.absoluteString
    }
}

// MARK: - Helpers
private extension LuxuryItemService {
    var storageBucketName: String { "luxury" }
    
    func resolveClient() throws -> SupabaseClient {
        do {
            return try supabaseService.getClient()
        } catch {
            throw LuxuryItemServiceError.supabaseNotConfigured
        }
    }
    
    func requireAuthenticatedUserId(using client: SupabaseClient) async throws -> UUID {
        do {
            let session = try await client.auth.session
            guard !session.isExpired else {
                throw LuxuryItemServiceError.notAuthenticated
            }
            return session.user.id
        } catch {
            throw LuxuryItemServiceError.notAuthenticated
        }
    }
    
    func makeStoragePath(for userId: UUID, fileName: String?, fileExtension: String) -> String {
        let baseName = sanitizeFileName(fileName) ?? UUID().uuidString
        let sanitizedExtension = fileExtension.lowercased()
        return "users/\(userId.uuidString)/\(baseName).\(sanitizedExtension)"
    }
    
    func mimeType(for fileExtension: String) -> String {
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
    
    func sanitizeFileName(_ fileName: String?) -> String? {
        guard let fileName, !fileName.isEmpty else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let filteredScalars = fileName.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        var sanitized = String(filteredScalars).lowercased()
        sanitized = sanitized.replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        if sanitized.isEmpty {
            return nil
        }
        return String(sanitized.prefix(64))
    }
}

// MARK: - DTOs
private struct LuxuryItemRow: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let brand: String
    let category: String
    let price: Double
    let purchase_date: Date
    let description: String?
    let image_url: String?
    
    func toDomainModel() -> LuxuryItem {
        LuxuryItem(
            id: id,
            name: name,
            brand: brand,
            category: LuxuryItem.Category(rawValue: category) ?? .other,
            price: price,
            purchaseDate: purchase_date,
            description: description,
            imageURL: image_url
        )
    }
}

private struct LuxuryItemInsertPayload: Encodable {
    let id: UUID
    let user_id: UUID
    let name: String
    let brand: String
    let category: String
    let price: Double
    let purchase_date: Date
    let description: String?
    let image_url: String?
    
    init(item: LuxuryItem, userId: UUID) {
        self.id = item.id
        self.user_id = userId
        self.name = item.name
        self.brand = item.brand
        self.category = item.category.rawValue
        self.price = item.price
        self.purchase_date = item.purchaseDate
        self.description = item.description
        self.image_url = item.imageURL
    }
}

private struct LuxuryItemUpdatePayload: Encodable {
    let name: String
    let brand: String
    let category: String
    let price: Double
    let purchase_date: Date
    let description: String?
    let image_url: String?
    let user_id: UUID
    
    init(item: LuxuryItem, userId: UUID) {
        self.name = item.name
        self.brand = item.brand
        self.category = item.category.rawValue
        self.price = item.price
        self.purchase_date = item.purchaseDate
        self.description = item.description
        self.image_url = item.imageURL
        self.user_id = userId
    }
}

