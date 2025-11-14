//
//  LoginView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    var onShowRegister: (() -> Void)?
    
    @State private var email: String = ""
    @State private var password: String = ""
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
                            .disabled(authViewModel.isLoading)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                if !authViewModel.isLoading {
                                    focusedField = .password
                                }
                            }
                    }
                    
                    // 密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .disabled(authViewModel.isLoading)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                if !authViewModel.isLoading {
                                    login()
                                }
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
                        HStack(spacing: 8) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(authViewModel.isLoading ? "登录中..." : "登录")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
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
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    .opacity((email.isEmpty || password.isEmpty || authViewModel.isLoading) ? 0.6 : 1.0)
                    .padding(.top, 8)
                    
                    // 注册链接
                    HStack {
                        Text("还没有账号？")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(action: {
                            if !authViewModel.isLoading {
                                dismiss()
                                // 延迟一下，确保当前 sheet 完全关闭后再显示新的
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onShowRegister?()
                                }
                            }
                        }) {
                            Text("立即注册")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .disabled(authViewModel.isLoading)
                        .opacity(authViewModel.isLoading ? 0.6 : 1.0)
                    }
                    .padding(.top, 8)
                    
                    // 分隔线
                    HStack {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("或")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 16)
                    
                    // 第三方登录按钮组
                    VStack(spacing: 12) {
                        // Sign in with Apple 按钮
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleSignInResult(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(12)
                        .disabled(authViewModel.isLoading)
                        .opacity(authViewModel.isLoading ? 0.6 : 1.0)
                        
                        // Google 登录按钮
                        Button(action: {
                            handleGoogleSignIn()
                        }) {
                            HStack(spacing: 12) {
                                Image("google")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("使用 Google 账号继续")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .cornerRadius(12)
                        .disabled(authViewModel.isLoading)
                        .opacity(authViewModel.isLoading ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                focusedField = nil
            }
            .onChange(of: authViewModel.isLoading) { isLoading in
                if isLoading {
                    // 加载开始时取消焦点，避免键盘约束冲突
                    focusedField = nil
                }
            }
        }
    }
    
    private func login() {
        // 先取消焦点，避免键盘约束冲突
        focusedField = nil
        Task {
            await authViewModel.login(email: email, password: password)
            if authViewModel.isAuthenticated {
                dismiss()
            }
        }
    }
    
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                let success = await authViewModel.signInWithApple(authorization: authorization)
                if success {
                    dismiss()
                }
            }
        case .failure(let error):
            authViewModel.errorMessage = "Apple 登录失败: \(error.localizedDescription)"
        }
    }
    
    private func handleGoogleSignIn() {
        focusedField = nil
        Task {
            let success = await authViewModel.signInWithGoogle()
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel(), onShowRegister: nil)
}

