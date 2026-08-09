import AVFoundation

enum CameraPermissionStatus {
    case authorized, denied, notDetermined
}

struct CameraPermissionService {
    static func currentStatus() -> CameraPermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .notDetermined: return .notDetermined
        default: return .denied
        }
    }

    static func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
