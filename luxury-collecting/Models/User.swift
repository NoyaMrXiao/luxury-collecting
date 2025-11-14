//
//  User.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation

/// 用户模型（来自自建 users 表）
struct User: Codable, Equatable {
    let id: UUID
    var email: String
    var username: String?
    var isActive: Bool
    var createdAt: Date?
    var updatedAt: Date?
    
    init(
        id: UUID,
        email: String,
        username: String? = nil,
        isActive: Bool = true,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

