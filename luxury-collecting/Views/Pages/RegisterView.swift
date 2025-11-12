//
//  RegisterView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI

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
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .email
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
                            SecureField("请输入密码（至少6位）", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .confirmPassword
                                }
                        }
                        
                        // 确认密码输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text("确认密码")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            SecureField("请再次输入密码", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.go)
                                .onSubmit {
                                    register()
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
                            Text("注册")
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
                        .disabled(!isValid)
                        .opacity(isValid ? 1.0 : 0.6)
                        .padding(.top, 8)
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
                        dismiss()
                    }
                }
            }
            .onTapGesture {
                focusedField = nil
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
}

#Preview {
    RegisterView(authViewModel: AuthViewModel())
}

