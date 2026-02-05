import SwiftUI
import UIKit
import PhotosUI

/// Camera view for capturing menu photos
struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var capturedImage: UIImage?

    private enum PickerKind: Identifiable {
        case camera
        case library
        var id: String { self == .camera ? "camera" : "library" }
    }
    @State private var pickerKind: PickerKind? = nil

    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Camera icon
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 100))
                    .foregroundStyle(.secondary)
                
                Text("Capture Menu Photo")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Take a clear photo of the menu for best results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Camera button
                Button(action: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        pickerKind = .camera
                    } else {
                        alertMessage = "Camera is not available on this device."
                        showAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                
                // Photo library button
                Button(action: {
                    pickerKind = .library
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Library")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Scan Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $pickerKind) { kind in
                if kind == .camera {
                    ImagePicker(image: $capturedImage, sourceType: .camera)
                        .ignoresSafeArea()
                        .id("camera")
                } else {
                    PhotoLibraryPicker(image: $capturedImage)
                        .ignoresSafeArea()
                        .id("library")
                }
            }
            .onChange(of: capturedImage) { _, newImage in
                if newImage != nil {
                    dismiss()
                }
            }
            .alert("Unavailable", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
}

/// UIKit image picker wrapped for SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Modern Photos library picker (no camera) wrapped for SwiftUI
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker

        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.dismiss()
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                        self.parent.dismiss()
                    }
                }
            } else {
                parent.dismiss()
            }
        }
    }
}

#Preview {
    CameraView(capturedImage: .constant(nil))
}
