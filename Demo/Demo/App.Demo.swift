import UIKit
import SwiftUI

@main
struct DemoApp: App {
    @UIApplicationDelegateAdaptor(DemoAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if targetEnvironment(macCatalyst) || os(macOS)
		.defaultSize(width: 400.0, height: 400.0)
		.windowResizability(.contentSize)
        #endif

		#if targetEnvironment(macCatalyst)
        WindowGroup(id: DemoWindow.recap.id, for: DemoWindow.self) { _ in
            DemoRecapScreen(isRunningInMacCatalystEnvironment: true)
        }
		.defaultSize(width: 800.0, height: 800.0)
        .windowResizability(.contentMinSize)
		#endif
    }
}

// MARK: DemoWindow

enum DemoWindow: String, Codable, Hashable {
	case recap

	var id: String {
		"Recap-Demo-Window.\(self.rawValue)"
	}
}

// MARK: DemoAppDelegate

private final class DemoAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = connectingSceneSession.configuration
        sceneConfiguration.delegateClass = DemoSceneDelegate.self
        return sceneConfiguration
    }
}

// MARK: DemoSceneDelegate

final class DemoSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        #if targetEnvironment(macCatalyst)
        if let windowScene = scene as? UIWindowScene, let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .hidden
        }
        #endif
    }
}
