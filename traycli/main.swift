import Foundation

// Establish a connection to the XPC service
let serviceConnection = NSXPCConnection(serviceName: "com.atcults.ServiceHelper")
serviceConnection.remoteObjectInterface = NSXPCInterface(with: ServiceHelperProtocol.self)
serviceConnection.resume()

// Get the proxy object for the service
let serviceProxy = serviceConnection.remoteObjectProxy as? ServiceHelperProtocol

// Create a dispatch source for the SIGINT signal
let interruptSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)

// Schedule the timer to call the getMenuItemData method every second
let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    serviceProxy?.getMenuItemData { menuItemData in
        if let menuItems = menuItemData["menuItems"] as? [[String: Any]] {
            for item in menuItems {
                if let text = item["text"] as? String,
                   let description = item["description"] as? String {
                    print("\(text): \(description)")
                }
            }
        } else {
            print("Error: Invalid menu item data format")
        }
    }
}

// Set up the event handler for the SIGINT signal
interruptSource.setEventHandler {
    // Cancel the timer
    timer.invalidate()
    
    // Exit the program gracefully
    exit(0)
}

// Resume the interrupt source
interruptSource.resume()

// Run the main run loop
RunLoop.current.run()
