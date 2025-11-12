//
//  LoginView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingRegister = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部装饰区域
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 60)
                    
                    Text("奢侈品收藏柜")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("记录您的每一件珍藏")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 40)
                
                // 登录表单
                VStack(spacing: 20) {
                    // 邮箱输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("邮箱")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("请输入邮箱", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    // 密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                login()
                            }
                    }
                    
                    // 错误提示
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 登录按钮
                    Button(action: login) {
                        Text("登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                    .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    .padding(.top, 8)
                    
                    // 注册链接
                    HStack {
                        Text("还没有账号？")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(action: {
                            showingRegister = true
                        }) {
                            Text("立即注册")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingRegister) {
                RegisterView(authViewModel: authViewModel)
            }
            .onTapGesture {
                focusedField = nil
            }
        }
    }
    
    private func login() {
        Task {
            await authViewModel.login(email: email, password: password)
            if authViewModel.isAuthenticated {
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
}

