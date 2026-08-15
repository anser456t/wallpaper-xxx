import UIKit
import Photos

/// Thin wrapper around the Photos save API that surfaces permission and
/// write errors back through a Swift `Result` instead of an Obj-C selector.
enum PhotoLibrarySaver {
    static func save(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }, completionHandler: { success, error in
                        DispatchQueue.main.async {
                            if success {
                                completion(.success(()))
                            } else {
                                completion(.failure(error ?? PhotoSaveError.unknown))
                            }
                        }
                    })
                case .denied, .restricted:
                    completion(.failure(PhotoSaveError.permissionDenied))
                case .notDetermined:
                    completion(.failure(PhotoSaveError.permissionDenied))
                @unknown default:
                    completion(.failure(PhotoSaveError.unknown))
                }
            }
        }
    }

    enum PhotoSaveError: LocalizedError {
        case permissionDenied
        case unknown

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Photos access was denied. Enable it in Settings to save wallpapers directly."
            case .unknown:
                return "The wallpaper couldn't be saved to Photos."
            }
        }
    }
}
