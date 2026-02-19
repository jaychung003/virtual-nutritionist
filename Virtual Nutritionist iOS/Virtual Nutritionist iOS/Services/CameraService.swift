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
    
    /// Compress image for upload using binary search for fast convergence
    func compressImage(_ image: UIImage, maxSizeKB: Int = 1024) -> Data? {
        let maxBytes = maxSizeKB * 1024

        // Try target quality first — often good enough in one shot
        guard let firstTry = image.jpegData(compressionQuality: 0.6) else { return nil }
        if firstTry.count <= maxBytes { return firstTry }

        // Binary search: converge in ~4 iterations instead of up to 9
        var lo: CGFloat = 0.1
        var hi: CGFloat = 0.6
        var best = firstTry

        for _ in 0..<4 {
            let mid = (lo + hi) / 2
            guard let data = image.jpegData(compressionQuality: mid) else { break }
            if data.count <= maxBytes {
                best = data
                lo = mid
            } else {
                hi = mid
            }
        }

        return best
    }
    
    /// Resize image to a maximum dimension while maintaining aspect ratio
    func resizeImage(_ image: UIImage, maxDimension: CGFloat = 1280) -> UIImage {
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
