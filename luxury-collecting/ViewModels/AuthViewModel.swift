//
//  AuthViewModel.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation
import SwiftUI

/// 认证视图模型
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private let usersKey = "luxury_collecting_users"
    private let currentUserKey = "luxury_collecting_current_user"
    
    init() {
        checkAuthentication()
    }
    
    // MARK: - Public Methods
    
    /// 检查是否已登录
    func checkAuthentication() {
        if let userData = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    /// 注册新用户
    func register(email: String, password: String, name: String?) async -> Bool {
        errorMessage = nil
        
        // 验证输入
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "邮箱和密码不能为空"
            return false
        }
        
        guard email.contains("@") else {
            errorMessage = "请输入有效的邮箱地址"
            return false
        }
        
        guard password.count >= 6 else {
            errorMessage = "密码长度至少为6位"
            return false
        }
        
        // 检查用户是否已存在
        var users = loadUsers()
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            errorMessage = "该邮箱已被注册"
            return false
        }
        
        // 创建新用户
        let newUser = User(email: email, password: password, name: name)
        users.append(newUser)
        
        // 保存用户列表
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
        
        // 自动登录
        await login(email: email, password: password)
        return true
    }
    
    /// 登录
    func login(email: String, password: String) async {
        errorMessage = nil
        
        // 验证输入
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "邮箱和密码不能为空"
            return
        }
        
        // 查找用户
        let users = loadUsers()
        guard let user = users.first(where: { 
            $0.email.lowercased() == email.lowercased() && $0.password == password 
        }) else {
            errorMessage = "邮箱或密码错误"
            return
        }
        
        // 保存当前用户
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: currentUserKey)
        }
        
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    /// 登出
    func logout() {
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // MARK: - Private Methods
    
    private func loadUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey) else {
            return []
        }
        return (try? JSONDecoder().decode([User].self, from: data)) ?? []
    }
}

