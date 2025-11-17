//
//  AddLuxuryItemView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI
#if os(iOS)
import PhotosUI
import UIKit
#endif

struct AddLuxuryItemView: View {
    @ObservedObject var viewModel: LuxuryItemViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var category: LuxuryItem.Category = .other
    @State private var price: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var description: String = ""
    #if os(iOS)
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImageUploadData: ImageUploadData?
    @State private var uploadedImageURL: String?
    @State private var isUploadingImage: Bool = false
    @State private var uploadErrorMessage: String?
    // 背景去除功能已注释
    // @State private var processedImageData: Data?
    // @State private var isProcessingImage: Bool = false
    #endif
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                        #if os(iOS)
                        .submitLabel(.next)
                        .onSubmit {
                            hideKeyboard()
                        }
                        #endif
                    TextField("品牌", text: $brand)
                        #if os(iOS)
                        .submitLabel(.done)
                        .onSubmit {
                            hideKeyboard()
                        }
                        #endif
                    Picker("类别", selection: $category) {
                        ForEach(LuxuryItem.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section("价格信息") {
                    TextField("价格", text: $price)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("完成") {
                                    hideKeyboard()
                                }
                            }
                        }
                        #endif
                    DatePicker("购买日期", selection: $purchaseDate, displayedComponents: .date)
                }
                
                #if os(iOS)
                Section("图片") {
                    VStack(alignment: .leading, spacing: 12) {
                        // 背景去除功能已注释，只使用原始图片
                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                            ZStack {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 180)
                                    .cornerRadius(8)
                                
                                // 背景去除处理状态UI已注释
                                // if isProcessingImage {
                                //     ProgressView()
                                //         .scaleEffect(1.5)
                                //         .padding()
                                //         .background(Color.black.opacity(0.3))
                                //         .cornerRadius(8)
                                // }
                            }
                            
                            // "已去除背景"提示已注释
                            // if processedImageData != nil {
                            //     HStack {
                            //         Image(systemName: "checkmark.circle.fill")
                            //             .foregroundColor(.green)
                            //         Text("已去除背景")
                            //             .font(.caption)
                            //             .foregroundColor(.secondary)
                            //     }
                            // }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.secondarySystemBackground))
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 28))
                                        .foregroundColor(.secondary)
                                    Text("尚未选择图片")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 24)
                            }
                            .frame(height: 120)
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            Label(selectedImageData == nil ? "选择图片" : "更换图片", systemImage: "photo")
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    await MainActor.run {
                                        self.selectedImageData = data
                                        self.uploadedImageURL = nil
                                        self.uploadErrorMessage = nil
                                        self.selectedImageUploadData = nil
                                    }
                                    
                                    if let uploadData = ImageUploadHelper.prepareUploadData(from: data) {
                                        await MainActor.run {
                                            self.selectedImageUploadData = uploadData
                                        }
                                        await uploadSelectedImage(with: uploadData)
                                    } else {
                                        await MainActor.run {
                                            self.uploadErrorMessage = "无法处理所选图片"
                                        }
                                    }
                                }
                            }
                        }
                        
                        if isUploadingImage {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("正在上传图片...")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        } else if let uploadedImageURL {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("图片已上传")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let uploadErrorMessage {
                            Text(uploadErrorMessage)
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }
                }
                #endif
                
                Section("备注") {
                    TextEditor(text: $description)
                        .frame(height: 100)
                        #if os(iOS)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("完成") {
                                    hideKeyboard()
                                }
                            }
                        }
                        #endif
                }
            }
            .navigationTitle("添加收藏")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveItem()
                    }
                    .disabled(!isValid || isUploadingImage)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !brand.isEmpty && !price.isEmpty && Double(price) != nil
    }
    
    private func saveItem() {
        guard let priceValue = Double(price) else { return }
        
        var item = LuxuryItem(
            name: name,
            brand: brand,
            category: category,
            price: priceValue,
            purchaseDate: purchaseDate,
            description: description.isEmpty ? nil : description,
            imageURL: nil
        )
        
        Task {
            #if os(iOS)
            if let uploadedImageURL {
                item.imageURL = uploadedImageURL
                await viewModel.addItem(item)
            } else {
                let uploadData = selectedImageUploadData ?? selectedImageData.flatMap { ImageUploadHelper.prepareUploadData(from: $0) }
                await viewModel.addItem(item, imageUploadData: uploadData)
            }
            #else
            await viewModel.addItem(item)
            #endif
            dismiss()
        }
    }
}

#if os(iOS)
extension AddLuxuryItemView {
    private func uploadSelectedImage(with uploadData: ImageUploadData) async {
        let sizeInKB = Double(uploadData.data.count) / 1024.0
        print("[AddLuxuryItemView] 🚀 Upload starting (\(String(format: "%.2f", sizeInKB)) KB, ext: \(uploadData.fileExtension))")
        await MainActor.run {
            self.isUploadingImage = true
            self.uploadErrorMessage = nil
        }
        
        do {
            let url = try await viewModel.uploadImage(
                data: uploadData.data,
                fileName: uploadData.fileName,
                fileExtension: uploadData.fileExtension
            )
            print("[AddLuxuryItemView] ✅ Upload succeeded: \(url)")
            await MainActor.run {
                self.uploadedImageURL = url
            }
        } catch {
            print("[AddLuxuryItemView] ❌ Upload failed: \(error)")
            await MainActor.run {
                self.uploadErrorMessage = error.localizedDescription
                self.uploadedImageURL = nil
            }
        }
        
        await MainActor.run {
            self.isUploadingImage = false
            print("[AddLuxuryItemView] 🛑 Upload flow finished")
        }
    }
}

extension AddLuxuryItemView {
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

#Preview {
    AddLuxuryItemView(viewModel: LuxuryItemViewModel())
}

