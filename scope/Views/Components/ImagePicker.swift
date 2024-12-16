import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var note: HealthNote
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var captions: [String] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    PhotosPicker(selection: $selectedItems, matching: .images) {
                        Label("Select Images", systemImage: "photo.on.rectangle.angled")
                    }
                }
                
                if !selectedImages.isEmpty {
                    Section("Selected Images") {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            HStack {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                    .cornerRadius(8)
                                
                                TextField("Caption (optional)", text: $captions[index])
                                    .transparentTextField()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Images")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addImages()
                    }
                    .disabled(selectedImages.isEmpty)
                }
            }
            .onChange(of: selectedItems) { _ in
                loadImages()
            }
        }
    }
    
    private func loadImages() {
        Task {
            selectedImages = []
            captions = []
            
            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        selectedImages.append(image)
                        captions.append("")
                    }
                }
            }
        }
    }
    
    private func addImages() {
        for (index, image) in selectedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let caption = captions[index].isEmpty ? nil : captions[index]
                let imageData = HealthNote.ImageData(
                    id: UUID().uuidString,
                    imageData: imageData,
                    caption: caption
                )
                note.images.append(imageData)
            }
        }
        dismiss()
    }
} 
