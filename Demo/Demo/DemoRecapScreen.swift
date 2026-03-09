import Recap
import SwiftUI

struct DemoRecapScreen: View {
	@Environment(\.isMacCatalystEnvironment) private var isMacCatalystEnvironment

	var body: some View {
		// Optionally you can add a `leadingView` and `trailingView` to your RecapScreen.
		// If you do, you may also wish to specify the start index of your RecapScreen
		// by using the `.recapScreenStartIndex()` modifier, which takes three parameters:
		// .leadingView, .trailingView, and `.release(Int)`, specifying the index of the release you wish to display.
		RecapScreen(releases: .releases)
			.recapScreenDismissButtonStyle(Color.pink, Color.white)
			.recapScreenIconFillMode(.gradient)
			.recapScreenTitleStyle(.foreground)
			.recapScreenPageIndicatorColors(
				selected: Color.pink,
				deselected: Color.gray
			)
			.recapScreenPaginationStyle(self.isMacCatalystEnvironment ? .labeled : .automatic)
			.recapScreenDismissButtonVisibility(self.isMacCatalystEnvironment ? .hidden : .visible)
	}
}

// MARK: [Release]

private extension [Release] {
	static var releases: [Release] {
		ReleasesParser(fileName: "Releases").releases
	}
}
