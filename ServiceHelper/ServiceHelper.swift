import Foundation
import AppKit
import os.log

class ServiceHelper: NSObject, ServiceHelperProtocol {
    private let log = OSLog(subsystem: "com.atcults.ServiceHelper", category: "Service")

    func getMenuItemData(with reply: @escaping ([String: Any]) -> Void) {
        let osqueryPaths = ["/usr/local/bin/osqueryi", "/usr/local/bin/osqueryctl"]
        let osqueryInstalled = osqueryPaths.allSatisfy { FileManager.default.fileExists(atPath: $0) }

        let wazuhInstalled = isWazuhInstalled()
        let wazuhRunning = isWazuhRunning()

        let gatekeeperEnabled = isGatekeeperEnabled()

        let menuItemData: [String: Any] = [
            "menuItems": [
                [
                    "text": "User Behavior Analytics",
                    "icon": "staroflife.shield",
                    "description": serviceStatusMessage(service: "osquery", isInstalled: osqueryInstalled),
                    "status": osqueryInstalled ? NSAlert.Style.informational.rawValue : NSAlert.Style.critical.rawValue
                ],
                [
                    "text": "Endpoint Detection and Response",
                    "icon": "lock.shield",
                    "description": wazuhInstalled ? (wazuhRunning ? "Wazuh is running." : "Wazuh is installed but not running.") : "Wazuh is not installed.",
                    "status": wazuhInstalled ? (wazuhRunning ? NSAlert.Style.informational.rawValue : NSAlert.Style.warning.rawValue) : NSAlert.Style.critical.rawValue
                ],
                [
                    "text": "End-Point Protection",
                    "icon": "shield.checkered",
                    "description": "Gatekeeper is \(gatekeeperEnabled ? "enabled" : "disabled").",
                    "status": gatekeeperEnabled ? NSAlert.Style.informational.rawValue : NSAlert.Style.critical.rawValue
                ]
            ]
        ]

        reply(menuItemData)
    }

    func serviceStatusMessage(service: String, isInstalled: Bool) -> String {
        return "\(service) is \(isInstalled ? "installed" : "not installed")."
    }

    func isWazuhInstalled() -> Bool {
        let wazuhDir = "/Library/Ossec/bin/"
        return FileManager.default.fileExists(atPath: wazuhDir)
    }

    func isWazuhRunning() -> Bool {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "/Library/Ossec/bin/wazuh-control status"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            os_log("Error reading Wazuh running status", log: log, type: .error)
            return false
        }

        let runningComponents = ["wazuh-modulesd is running...", "wazuh-logcollector is running...", "wazuh-syscheckd is running...", "wazuh-agentd is running...", "wazuh-execd is running..."]
        let isRunning = runningComponents.allSatisfy { output.contains($0) }

        if !isRunning {
            os_log("Wazuh is not running", log: log, type: .error)
        }

        return isRunning
    }

    func isGatekeeperEnabled() -> Bool {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "/bin/bash -c 'GateKeeper_Status=$(spctl --status) && echo \"<result>GK: $GateKeeper_Status</result>\"'"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            os_log("Error reading Gatekeeper status", log: log, type: .error)
            return false
        }

        let isEnabled = output.contains("<result>GK: assessments enabled</result>")
        if !isEnabled {
            os_log("Gatekeeper is not enabled", log: log, type: .error)
        }

        return isEnabled
    }
}
