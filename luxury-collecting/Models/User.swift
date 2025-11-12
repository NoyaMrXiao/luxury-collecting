//
//  User.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation

/// 用户模型
struct User: Codable, Equatable {
    let id: UUID
    var email: String
    var password: String // 实际应用中应该存储哈希值
    var name: String?
    
    init(id: UUID = UUID(), email: String, password: String, name: String? = nil) {
        self.id = id
        self.email = email
        self.password = password
        self.name = name
    }
}

