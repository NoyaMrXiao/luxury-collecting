//
//  EditLuxuryItemView.swift
//  luxury-collecting
//
//  Created by ode-xiao on 2025/11/11.
//

import SwiftUI
#if os(iOS)
import PhotosUI
import UIKit
#endif

struct EditLuxuryItemView: View {
    @ObservedObject var viewModel: LuxuryItemViewModel
    let item: LuxuryItem
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
    @State private var existingImageURL: String?
    @State private var shouldRemoveImage: Bool = false
    #endif
    
    init(viewModel: LuxuryItemViewModel, item: LuxuryItem) {
        self.viewModel = viewModel
        self.item = item
    }
    
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
                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .cornerRadius(8)
                        } else if let urlString = existingImageURL,
                                  let remoteURL = URL(string: urlString),
                                  remoteURL.scheme?.hasPrefix("http") == true {
                            AsyncImage(url: remoteURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 180)
                                        .cornerRadius(8)
                                case .failure:
                                    placeholderView
                                case .empty:
                                    placeholderView
                                        .overlay(
                                            ProgressView()
                                        )
                                @unknown default:
                                    placeholderView
                                }
                            }
                        } else if let fallbackImage = legacyLocalImage() {
                            Image(uiImage: fallbackImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .cornerRadius(8)
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
                            Label(selectedImageData == nil && existingImageURL == nil ? "选择图片" : "更换图片", systemImage: "photo")
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    await MainActor.run {
                                        self.selectedImageData = data
                                        self.shouldRemoveImage = false
                                    }
                                }
                            }
                        }
                        
                        if existingImageURL != nil || selectedImageData != nil {
                            Button(role: .destructive) {
                                selectedImageData = nil
                                existingImageURL = nil
                                shouldRemoveImage = true
                            } label: {
                                Label("删除图片", systemImage: "trash")
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
            .navigationTitle("编辑收藏")
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
            .onAppear {
                loadItemData()
            }
        }
    }
    
    private func loadItemData() {
        name = item.name
        brand = item.brand
        category = item.category
        price = String(format: "%.2f", item.price)
        purchaseDate = item.purchaseDate
        description = item.description ?? ""
        #if os(iOS)
        existingImageURL = item.imageURL
        shouldRemoveImage = false
        #endif
    }
    
    private var isValid: Bool {
        !name.isEmpty && !brand.isEmpty && !price.isEmpty && Double(price) != nil
    }
    
    private func saveItem() {
        guard let priceValue = Double(price) else { return }
        
        let updatedItem = LuxuryItem(
            id: item.id,
            name: name,
            brand: brand,
            category: category,
            price: priceValue,
            purchaseDate: purchaseDate,
            description: description.isEmpty ? nil : description,
            imageURL: existingImageURL ?? item.imageURL
        )
        
        Task {
            #if os(iOS)
            let uploadData = selectedImageData.flatMap { ImageUploadHelper.prepareUploadData(from: $0) }
            await viewModel.updateItem(
                updatedItem,
                imageUploadData: uploadData,
                removeImage: shouldRemoveImage && uploadData == nil
            )
            #else
            await viewModel.updateItem(updatedItem)
            #endif
            dismiss()
        }
    }
    
    #if os(iOS)
    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 28))
                .foregroundColor(.secondary)
        }
        .frame(height: 180)
    }
    
    private func legacyLocalImage() -> UIImage? {
        guard let path = existingImageURL else { return nil }
        if path.hasPrefix("http") {
            return nil
        }
        let resolvedPath: String
        if path.hasPrefix("file://"), let url = URL(string: path) {
            resolvedPath = url.path
        } else {
            resolvedPath = path
        }
        guard FileManager.default.fileExists(atPath: resolvedPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: resolvedPath)) else {
            return nil
        }
        return UIImage(data: data)
    }
    #endif
}

#Preview {
    EditLuxuryItemView(
        viewModel: LuxuryItemViewModel(),
        item: LuxuryItem(
            name: "经典款手袋",
            brand: "Hermès",
            category: .bag,
            price: 50000,
            purchaseDate: Date(),
            description: "这是一款非常经典的奢侈品手袋"
        )
    )
}

