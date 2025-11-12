//
//  luxury_collectingApp.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

@main
struct luxury_collectingApp: App {
    init() {
        configureSupabase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureSupabase() {
        guard let url = URL(string: "https://xqqsowihnmjstfebakct.supabase.co") else {
            assertionFailure("Supabase URL 配置无效")
            return
        }
        
        let publishableKey = ProcessInfo.processInfo.environment["SUPABASE_PUBLISHABLE_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String
        
        guard let key = publishableKey, !key.isEmpty else {
            assertionFailure("Supabase Publishable Key 未配置")
            return
        }
        
        SupabaseService.shared.configure(url: url, anonKey: key)
    }
}
