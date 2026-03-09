import Recap
import SwiftUI

struct ContentView: View {
	@Environment(\.isMacCatalystEnvironment) private var isMacCatalystEnvironment
	@Environment(\.openWindow) private var openWindow

	@State private var isPresentingRecapScreen = false

	var body: some View {
		VStack {
			self.showReleasesButton
		}
		.sheet(isPresented: $isPresentingRecapScreen, content: {
			self.recapScreen
		})
		.task({
			guard !self.isMacCatalystEnvironment else { return }

			try? await Task.sleep(for: .seconds(0.5))
			self.presentRecapScreen()
		})
	}
}

private extension ContentView {
	@ViewBuilder
    var showReleasesButton: some View {
		Button(action: {
			self.presentRecapScreen()
		}, label: {
			Label("Show What's New", systemImage: "sparkles")
				.frame(maxWidth: .infinity)
		})
		.padding(.vertical, self.isMacCatalystEnvironment ? 128.0 : 0.0)
    }

    var recapScreen: some View {
        DemoRecapScreen()
    }
}

// MARK: ContentView

private extension ContentView {
	func presentRecapScreen() {
		if self.isMacCatalystEnvironment {
			self.openWindow(id: DemoWindow.recap.id, value: DemoWindow.recap)
		} else {
			self.isPresentingRecapScreen = true
		}
	}
}
