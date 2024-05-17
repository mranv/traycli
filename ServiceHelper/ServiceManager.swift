

import Foundation

class ServiceManager {
    static let shared = ServiceManager()
    private var timer: Timer?
    private let serviceHelper = ServiceHelper()

    private init() {
        startCheckingServices()
    }

    private func startCheckingServices() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkServices()
        }
    }

    private func checkServices() {
        serviceHelper.getMenuItemData { [weak self] menuItemData in
            self?.handleMenuItemData(menuItemData)
        }
    }

    private func handleMenuItemData(_ menuItemData: [String: Any]) {
        print("Menu Item Data: \(menuItemData)")
        // Additional handling logic can be added here
    }
}
