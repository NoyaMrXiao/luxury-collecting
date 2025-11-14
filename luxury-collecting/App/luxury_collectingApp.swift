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
        
        let publishableKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxcXNvd2lobm1qc3RmZWJha2N0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5MzAwMDAsImV4cCI6MjA3ODUwNjAwMH0.k_swLo6eSUDoMV8QWxjegOg-VamQsymzoTfyt439eb4"
        
        SupabaseService.shared.configure(url: url, anonKey: publishableKey)
    }
}
