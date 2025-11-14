//
//  AuthViewModel.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import UIKit

/// 认证视图模型
@MainActor
class AuthViewModel: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    override init() {
        super.init()
        Task {
            await refreshSession()
        }
    }
    
    // MARK: - Public Methods
    
    /// 检查是否已登录
    func checkAuthentication() {
        Task {
            await refreshSession()
        }
    }
    
    /// 注册新用户（使用 Supabase Authentication）
    func register(email: String, password: String, name: String?) async -> Bool {
        errorMessage = nil
        
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
        
        guard let client = try? SupabaseService.shared.getClient() else {
            errorMessage = "Supabase 未配置"
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 使用 Supabase Auth 注册
            var data: [String: AnyJSON]? = nil
            if let name = name, !name.isEmpty {
                // 将用户名存储在 user_metadata 中
                data = ["username": .string(name)]
            }
            
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: data
            )
            
            // 如果注册成功，更新用户信息
            if let session = response.session {
                await updateUserFromSession(session)
                
                // 如果提供了用户名，尝试同步到自定义 users 表（可选）
                if let name = name, !name.isEmpty {
                    await syncUserToCustomTable(userId: session.user.id, email: email, username: name)
                }
                
                return true
            } else {
                // 如果启用了邮箱验证，可能需要验证邮箱
                errorMessage = "注册成功，请检查邮箱验证链接"
                return false
            }
        } catch {
            errorMessage = parseSupabaseError(error)
            return false
        }
    }
    
    /// 登录（使用 Supabase Authentication）
    func login(email: String, password: String) async {
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "邮箱和密码不能为空"
            return
        }
        
        guard let client = try? SupabaseService.shared.getClient() else {
            errorMessage = "Supabase 未配置"
            isAuthenticated = false
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 使用 Supabase Auth 登录
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            // 更新用户信息
            await updateUserFromSession(session)
        } catch {
            errorMessage = parseSupabaseError(error)
            isAuthenticated = false
        }
    }
    
    /// 使用 Apple 账号注册/登录
    func signInWithApple(authorization: ASAuthorization) async -> Bool {
        errorMessage = nil
        
        guard let client = try? SupabaseService.shared.getClient() else {
            errorMessage = "Supabase 未配置"
            return false
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "无法获取 Apple ID 凭证"
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 获取用户标识符
            let userID = appleIDCredential.user
            
            // 获取用户信息
            var email: String? = nil
            var fullName: String? = nil
            
            if let emailValue = appleIDCredential.email {
                email = emailValue
            }
            
            if let givenName = appleIDCredential.fullName?.givenName,
               let familyName = appleIDCredential.fullName?.familyName {
                fullName = "\(givenName) \(familyName)"
            } else if let givenName = appleIDCredential.fullName?.givenName {
                fullName = givenName
            } else if let familyName = appleIDCredential.fullName?.familyName {
                fullName = familyName
            }
            
            // 获取 identity token
            guard let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "无法获取身份令牌"
                return false
            }
            
            // 使用 Supabase 的 OAuth 方式进行 Apple 登录
            // 注意：Supabase 需要配置 Apple OAuth provider
            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken
                )
            )
            
            // 更新用户信息
            await updateUserFromSession(session)
            
            // 如果提供了用户名，尝试同步到自定义 users 表
            if let fullName = fullName, !fullName.isEmpty {
                let authUser = session.user
                await syncUserToCustomTable(
                    userId: authUser.id,
                    email: email ?? authUser.email ?? "",
                    username: fullName
                )
            }
            
            return true
        } catch {
            // 如果 signInWithIdToken 不存在，尝试使用 OAuth URL 方式
            errorMessage = parseSupabaseError(error)
            
            // 如果直接使用 identity token 失败，可以尝试 OAuth URL 方式
            // 但这需要配置 URL scheme 和回调处理
            return false
        }
    }
    
    /// 使用 Google 账号注册/登录
    func signInWithGoogle() async -> Bool {
        errorMessage = nil
        
        guard let client = try? SupabaseService.shared.getClient() else {
            errorMessage = "Supabase 未配置"
            return false
        }
        
        isLoading = true
        
        // 使用 continuation 等待 OAuth 回调完成
        return await withCheckedContinuation { continuation in
            // 使用标志确保 continuation 只被 resume 一次
            var hasResumed = false
            let resumeOnce: (Bool) -> Void = { result in
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(returning: result)
                }
            }
            
            Task { @MainActor [weak self] in
                guard let self = self else {
                    resumeOnce(false)
                    return
                }
                
                do {
                    // 获取 OAuth URL
                    // Supabase Swift SDK 2.x 的 signInWithOAuth 使用 configure 回调接收 URL
                    let redirectURL = URL(string: "luxury-collecting://auth-callback")!
                    
                    try await client.auth.signInWithOAuth(
                        provider: .google,
                        redirectTo: redirectURL
                    ) { url in
                        // 使用 ASWebAuthenticationSession 打开浏览器进行认证
                        let authSession = ASWebAuthenticationSession(
                            url: url,
                            callbackURLScheme: "luxury-collecting"
                        ) { [weak self] callbackURL, error in
                            Task { @MainActor [weak self] in
                                guard let self = self else {
                                    resumeOnce(false)
                                    return
                                }
                                
                                if let error = error {
                                    // 用户取消或其他错误
                                    if let authError = error as? ASWebAuthenticationSessionError,
                                       authError.code == .canceledLogin {
                                        self.errorMessage = nil // 用户取消，不显示错误
                                    } else {
                                        self.errorMessage = "Google 登录失败: \(error.localizedDescription)"
                                    }
                                    self.isLoading = false
                                    resumeOnce(false)
                                    return
                                }
                                
                                guard let callbackURL = callbackURL else {
                                    self.errorMessage = "无法获取回调 URL"
                                    self.isLoading = false
                                    resumeOnce(false)
                                    return
                                }
                                
                                // 处理 OAuth 回调
                                do {
                                    let session = try await client.auth.session(from: callbackURL)
                                    await self.updateUserFromSession(session)
                                    
                                    // 尝试从用户信息中获取用户名
                                    let authUser = session.user
                                    if let fullName = authUser.userMetadata["full_name"] as? String,
                                       !fullName.isEmpty {
                                        await self.syncUserToCustomTable(
                                            userId: authUser.id,
                                            email: authUser.email ?? "",
                                            username: fullName
                                        )
                                    }
                                    
                                    self.isLoading = false
                                    resumeOnce(true)
                                } catch {
                                    self.errorMessage = self.parseSupabaseError(error)
                                    self.isLoading = false
                                    resumeOnce(false)
                                }
                            }
                        }
                        
                        // 设置展示上下文
                        authSession.presentationContextProvider = self
                        authSession.prefersEphemeralWebBrowserSession = false
                        
                        // 开始认证流程
                        if !authSession.start() {
                            self.isLoading = false
                            self.errorMessage = "无法启动 Google 登录"
                            resumeOnce(false)
                        }
                        
                        // 返回 URL（configure 闭包需要返回 URL）
                        return url
                    }
                } catch {
                    self.isLoading = false
                    self.errorMessage = self.parseSupabaseError(error)
                    resumeOnce(false)
                }
            }
        }
    }
    
    /// 登出
    func logout() async {
        guard let client = try? SupabaseService.shared.getClient() else {
            self.currentUser = nil
            self.isAuthenticated = false
            return
        }
        
        do {
            try await client.auth.signOut()
        } catch {
            // 即使登出失败，也清除本地状态
            print("登出时出错: \(error)")
        }
        
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    // MARK: - Private Methods
    
    /// 刷新会话（检查当前登录状态）
    private func refreshSession() async {
        guard let client = try? SupabaseService.shared.getClient() else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        do {
            // 获取当前会话
            let session = try await client.auth.session
            await updateUserFromSession(session)
        } catch {
            // 没有有效会话
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    /// 从 Supabase Auth 会话更新用户信息
    private func updateUserFromSession(_ session: Session) async {
        // 检查会话是否已过期
        if session.isExpired {
            // 会话已过期，清除认证状态
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }
        
        let authUser = session.user
        
        // 从 user_metadata 获取用户名
        var username: String? = nil
        if let usernameValue = authUser.userMetadata["username"] {
            if case .string(let name) = usernameValue {
                username = name
            }
        }
        
        // 创建 User 对象
        self.currentUser = User(
            id: authUser.id,
            email: authUser.email ?? "",
            username: username,
            isActive: true,
            createdAt: authUser.createdAt,
            updatedAt: authUser.updatedAt
        )
        
        self.isAuthenticated = true
    }
    
    /// 同步用户信息到自定义 users 表（可选，用于兼容现有数据结构）
    private func syncUserToCustomTable(userId: UUID, email: String, username: String?) async {
        guard let client = try? SupabaseService.shared.getClient() else {
            return
        }
        
        do {
            // 检查用户是否已存在
            let existing: PostgrestResponse<DBUser>? = try? await client
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            if existing?.value == nil {
                // 如果不存在，插入新记录
                let payload = DBUserInsert(
                    id: userId,
                    email: email,
                    username: username,
                    is_active: true
                )
                
                _ = try await client
                    .from("users")
                    .insert(payload)
                    .execute()
            } else {
                // 如果存在，更新用户名
                if let username = username {
                    _ = try await client
                        .from("users")
                        .update(["username": username])
                        .eq("id", value: userId.uuidString)
                        .execute()
                }
            }
        } catch {
            // 同步失败不影响认证流程
            print("同步用户信息到自定义表失败: \(error)")
        }
    }
    
    private func parseSupabaseError(_ error: Error) -> String {
        // 处理常见的 Supabase Auth 错误
        let errorString = error.localizedDescription
        
        // 提取更友好的错误信息
        if errorString.contains("Invalid login credentials") || errorString.contains("invalid_credentials") {
            return "邮箱或密码错误"
        } else if errorString.contains("User already registered") || errorString.contains("already_registered") {
            return "该邮箱已被注册"
        } else if errorString.contains("Email not confirmed") {
            return "请先验证您的邮箱"
        } else if errorString.contains("Password should be at least") {
            return "密码长度不符合要求"
        }
        
        return errorString
    }
    
    // MARK: - DB mapping (用于同步到自定义表)
    private struct DBUser: Codable {
        let id: UUID
        let email: String
        let username: String?
        let is_active: Bool?
        let created_at: Date?
        let updated_at: Date?
    }
    
    private struct DBUserInsert: Codable {
        let id: UUID
        let email: String
        let username: String?
        let is_active: Bool
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension AuthViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // 返回主窗口作为展示上下文
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            // 如果没有找到窗口，创建一个临时的
            return ASPresentationAnchor()
        }
        return window
    }
}

