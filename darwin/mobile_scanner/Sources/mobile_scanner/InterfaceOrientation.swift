#if os(iOS)
import UIKit

/// Resolve the host interface, including apps that do not use UIScene.
/// Read on the main thread, alongside the scanner's other UIKit access.
func scannerInterfaceOrientation() -> UIInterfaceOrientation {
    if #available(iOS 13.0, *) {
        let application = UIApplication.shared
        if let scene = application.windows.first(where: { $0.isKeyWindow })?.windowScene,
           scene.interfaceOrientation != .unknown {
            return scene.interfaceOrientation
        }
        if let scene = application.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           scene.interfaceOrientation != .unknown {
            return scene.interfaceOrientation
        }
    }
    // Legacy AppDelegate hosts have no connected scenes. This still describes
    // the interface when rotation is locked, unlike UIDevice.orientation.
    return UIApplication.shared.statusBarOrientation
}
/// Device notifications can precede the interface rotation. Legacy hosts also
/// publish a status-bar notification after their interface has rotated.
func observeScannerInterfaceOrientation(_ action: @escaping () -> Void) -> [NSObjectProtocol] {
    return [UIDevice.orientationDidChangeNotification,
            UIApplication.didChangeStatusBarOrientationNotification].map { name in
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
            DispatchQueue.main.async(execute: action)
        }
    }
}
#endif
