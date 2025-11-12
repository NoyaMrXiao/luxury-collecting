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
                        .onChange(of: selectedPhotoItem) { newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    await MainActor.run {
                                        self.selectedImageData = data
                                        // 背景去除功能已注释
                                        // self.processedImageData = nil
                                        // self.isProcessingImage = true
                                    }
                                    // 自动处理图片去背景功能已注释
                                    // #if os(iOS)
                                    // if let processedData = await BackgroundRemovalService.removeBackground(from: data) {
                                    //     await MainActor.run {
                                    //         self.processedImageData = processedData
                                    //         self.isProcessingImage = false
                                    //     }
                                    // } else {
                                    //     await MainActor.run {
                                    //         self.isProcessingImage = false
                                    //     }
                                    // }
                                    // #endif
                                }
                            }
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
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !brand.isEmpty && !price.isEmpty && Double(price) != nil
    }
    
    private func saveItem() {
        guard let priceValue = Double(price) else { return }
        
        var imagePathString: String? = nil
        #if os(iOS)
        // 背景去除功能已注释，只使用原始图片
        // let dataToSave = processedImageData ?? selectedImageData
        let dataToSave = selectedImageData
        if let data = dataToSave {
            let filename = UUID().uuidString + ".png" // 使用PNG格式以支持透明背景
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = documentsURL.appendingPathComponent(filename)
                do {
                    try data.write(to: fileURL, options: .atomic)
                    imagePathString = fileURL.path
                } catch {
                    // 失败时忽略图片保存，不阻塞文字信息保存
                    imagePathString = nil
                }
            }
        }
        #endif
        
        let item = LuxuryItem(
            name: name,
            brand: brand,
            category: category,
            price: priceValue,
            purchaseDate: purchaseDate,
            description: description.isEmpty ? nil : description,
            imageURL: imagePathString
        )
        
        Task {
            await viewModel.addItem(item)
            dismiss()
        }
    }
}

#Preview {
    AddLuxuryItemView(viewModel: LuxuryItemViewModel())
}

