import Foundation
import UIKit
import AVFoundation

/// Service for handling camera permissions and utilities
class CameraService {
    static let shared = CameraService()
    
    private init() {}
    
    /// Check if camera is available
    var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// Check camera authorization status
    var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// Request camera permission
    func requestCameraPermission() async -> Bool {
        let status = authorizationStatus
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    /// Compress image for upload
    func compressImage(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        var compression: CGFloat = 1.0
        let maxBytes = maxSizeKB * 1024
        
        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        // Reduce compression until size is acceptable
        while imageData.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            }
        }
        
        return imageData
    }
    
    /// Resize image to a maximum dimension while maintaining aspect ratio
    func resizeImage(_ image: UIImage, maxDimension: CGFloat = 1920) -> UIImage {
        let size = image.size
        
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
