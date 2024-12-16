import SwiftUI
import PhotosUI

struct ImagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(selection: $photosPickerItem,
                           matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.primary)
                        
                        Text("Select Image")
                            .titleStyle()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onChange(of: photosPickerItem) { _ in
                    Task {
                        if let data = try? await photosPickerItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Choose Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                }
            }
        }
    }
} 