//
//  MyPageView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct MyPageView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var presentedSheet: SheetType? = nil
    
    enum SheetType: Identifiable {
        case login
        case register
        
        var id: Self { self }
    }
    
    var body: some View {
        List {
            // 用户信息或登录引导
            Section {
                if authViewModel.isAuthenticated {
                    // 已登录：显示用户信息
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(authViewModel.currentUser?.username ?? authViewModel.currentUser?.email ?? "用户")
                                .font(.title3)
                                .fontWeight(.semibold)
                            if let email = authViewModel.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    // 未登录：显示登录引导
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "cloud.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("登录以保存数据到云端")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("注册账号后，您的收藏数据将永久保存，即使更换设备也不会丢失")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                presentedSheet = .login
                            }) {
                                Text("登录")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                presentedSheet = .register
                            }) {
                                Text("注册")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("常用")) {
                NavigationLink {
                    Text("统计与分析（占位）")
                        .navigationTitle("统计与分析")
                } label: {
                    Label("统计与分析", systemImage: "chart.bar")
                }
                
                NavigationLink {
                    Text("备份与恢复（占位）")
                        .navigationTitle("备份与恢复")
                } label: {
                    Label("备份与恢复", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            Section(header: Text("关于")) {
                NavigationLink {
                    VStack(spacing: 12) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("Luxury Collecting")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("版本 1.0.0")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                    .navigationTitle("关于")
                } label: {
                    Label("关于", systemImage: "info.circle")
                }
            }
            
            // 退出登录（仅登录时显示）
            if authViewModel.isAuthenticated {
                Section {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.logout()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("我的")
        .sheet(item: $presentedSheet) { sheetType in
            switch sheetType {
            case .login:
                LoginView(authViewModel: authViewModel, onShowRegister: {
                    presentedSheet = .register
                })
            case .register:
                RegisterView(authViewModel: authViewModel)
            }
        }
    }
}

#Preview {
    NavigationView {
        MyPageView(authViewModel: AuthViewModel())
    }
}


