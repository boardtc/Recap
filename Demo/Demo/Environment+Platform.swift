import SwiftUI

extension EnvironmentValues {
	var isMacCatalystEnvironment: Bool {
		#if targetEnvironment(macCatalyst)
		true
		#else
		false
		#endif
	}
}
