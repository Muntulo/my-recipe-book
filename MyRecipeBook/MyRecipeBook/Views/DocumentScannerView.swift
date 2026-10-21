import SwiftUI
import VisionKit

/// Wraps VisionKit's `VNDocumentCameraViewController` so a recipe clipping can be scanned
/// with the camera. Present this only when a camera is available (see `isAvailable`).
///
/// On the simulator there is no camera, and on a real device the scanner requires an
/// `NSCameraUsageDescription` string. If the camera is denied the OS dismisses the
/// controller; `onCancel` runs and the user falls back to the photo library — no crash.
struct DocumentScannerView: UIViewControllerRepresentable {
    /// Returns the first scanned page as a `UIImage`.
    let onScan: (UIImage) -> Void
    /// Called when the scan is cancelled or fails.
    let onCancel: () -> Void

    /// True when the device has a camera available for the document scanner.
    static var isAvailable: Bool {
        VNDocumentCameraViewController.isSupported
            && UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: (UIImage) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }
            onScan(scan.imageOfPage(at: 0))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            onCancel()
        }
    }
}
