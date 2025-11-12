//
//  SupabaseService.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/12.
//

import Foundation
import Supabase

/// Supabase 客户端配置错误
enum SupabaseConfigurationError: Error {
    case missingURL
    case invalidURL(String)
    case missingAnonKey
    case notConfigured
}

/// 统一管理 Supabase 客户端
final class SupabaseService {
    static let shared = SupabaseService()
    
    private let lock = NSLock()
    private var client: SupabaseClient?
    
    private init() {
        // 尝试自动加载默认配置
        if let configuration = Self.loadDefaultConfiguration() {
            client = SupabaseClient(
                supabaseURL: configuration.url,
                supabaseKey: configuration.anonKey
            )
        }
    }
    
    // MARK: - Public API
    
    /// 配置 Supabase 客户端
    /// - Parameters:
    ///   - url: Supabase 项目 URL
    ///   - anonKey: Supabase 匿名访问密钥
    func configure(url: URL, anonKey: String) {
        lock.lock()
        defer { lock.unlock() }
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
    
    /// 获取已配置的 Supabase 客户端
    /// - Throws: 如果尚未配置会抛出 `SupabaseConfigurationError.notConfigured`
    func getClient() throws -> SupabaseClient {
        lock.lock()
        defer { lock.unlock() }
        guard let client else {
            throw SupabaseConfigurationError.notConfigured
        }
        return client
    }
    
    // MARK: - Helpers
    
    private static func loadDefaultConfiguration() -> (url: URL, anonKey: String)? {
        do {
            let urlString = try loadValue(for: "SUPABASE_URL")
            let anonKey = try loadValue(for: "SUPABASE_ANON_KEY")
            
            guard let url = URL(string: urlString), !urlString.isEmpty else {
                throw SupabaseConfigurationError.invalidURL(urlString)
            }
            
            guard !anonKey.isEmpty else {
                throw SupabaseConfigurationError.missingAnonKey
            }
            
            return (url, anonKey)
        } catch {
            #if DEBUG
            print("⚠️ Supabase 默认配置加载失败: \(error)")
            #endif
            return nil
        }
    }
    
    private static func loadValue(for key: String) throws -> String {
        if let envValue = ProcessInfo.processInfo.environment[key], !envValue.isEmpty {
            return envValue
        }
        
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String, !plistValue.isEmpty {
            return plistValue
        }
        
        switch key {
        case "SUPABASE_URL":
            throw SupabaseConfigurationError.missingURL
        case "SUPABASE_ANON_KEY":
            throw SupabaseConfigurationError.missingAnonKey
        default:
            throw SupabaseConfigurationError.notConfigured
        }
    }
}

