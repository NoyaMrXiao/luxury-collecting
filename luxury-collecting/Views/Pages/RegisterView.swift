//
//  RegisterView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI
import AuthenticationServices

struct RegisterView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email
        case password
        case confirmPassword
        case name
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    VStack(spacing: 8) {
                        Text("创建账号")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        Text("开始记录您的收藏之旅")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // 注册表单
                    VStack(spacing: 20) {
                        // 姓名输入（可选）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("姓名（可选）")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("请输入姓名", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .disabled(authViewModel.isLoading)
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                                .onSubmit {
                                    if !authViewModel.isLoading {
                                        focusedField = .email
                                    }
                                }
                        }
                        
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
                            SecureField("请输入密码（至少6位）", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .disabled(authViewModel.isLoading)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit {
                                    if !authViewModel.isLoading {
                                        focusedField = .confirmPassword
                                    }
                                }
                        }
                        
                        // 确认密码输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text("确认密码")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            SecureField("请再次输入密码", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .disabled(authViewModel.isLoading)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.go)
                                .onSubmit {
                                    if !authViewModel.isLoading {
                                        register()
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
                        
                        // 注册按钮
                        Button(action: register) {
                            HStack(spacing: 8) {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(authViewModel.isLoading ? "注册中..." : "注册")
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
                        .disabled(!isValid || authViewModel.isLoading)
                        .opacity((!isValid || authViewModel.isLoading) ? 0.6 : 1.0)
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("注册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if !authViewModel.isLoading {
                            dismiss()
                        }
                    }
                    .disabled(authViewModel.isLoading)
                }
            }
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
    
    private var isValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func register() {
        guard password == confirmPassword else {
            authViewModel.errorMessage = "两次输入的密码不一致"
            return
        }
        
        // 先取消焦点，避免键盘约束冲突
        focusedField = nil
        
        Task {
            let success = await authViewModel.register(
                email: email,
                password: password,
                name: name.isEmpty ? nil : name
            )
            if success {
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
    RegisterView(authViewModel: AuthViewModel())
}

