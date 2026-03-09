import SwiftUI

/// A View to display your app's releases.
///
/// This screen presents a horizontally paged view of releases, allowing users to swipe through
/// different versions of the app and view their respective features and changes.
///
/// The `RecapScreen` uses environment values to customize its appearance,
/// including background style, color scheme, page indicator colors, and dismiss button style.
///
/// Usage:
/// ```swift
/// let releases = [
///     Release(version: AppVersion(version: "1.0.0"), title: "Initial Release", features: [...]),
///     Release(version: AppVersion(version: "1.1.0"), title: "Feature Update", features: [...])
/// ]
///
/// RecapScreen(releases: releases)
/// ```
///
/// - Note: The releases are displayed in reverse chronological order, with the most recent release shown first.
public struct RecapScreen<LeadingView: View, TrailingView: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.backgroundStyle) private var backgroundStyle
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.recapScreenStartIndex) private var startIndex
    @Environment(\.recapScreenSelectedPageIndicatorColor) private var selectedPageIndicatorColor
    @Environment(\.recapScreenDeselectedPageIndicatorColor) private var deselectedPageIndicatorColor
    @Environment(\.recapScreenDismissButtonStyle) private var dismissButtonStyle
    @Environment(\.recapScreenDismissButtonTitle) private var dismissButtonTitle
    @Environment(\.recapScreenDismissButtonVisibility) private var dismissButtonVisibility
    @Environment(\.recapScreenDismissAction) private var dismissAction
    @Environment(\.recapScreenPaginationStyle) private var paginationStyle

    @State private var originalSelectedPageIndicatorColor: UIColor?
    @State private var originalDeselectedPageIndicatorColor: UIColor?
    @State private var selectedIndex = 0

    private let releases: [Release]
    private let leadingView: LeadingView
    private let trailingView: TrailingView

    public init(releases: [Release], @ViewBuilder leadingView: () -> LeadingView, @ViewBuilder trailingView: () -> TrailingView) {
        self.releases = releases
        self.leadingView = leadingView()
        self.trailingView = trailingView()
    }

    public var body: some View {
        VStack(spacing: 0.0) {
            TabView(selection: $selectedIndex) {
                self.leadingView
                    .tag(self.tabIndex(from: .leadingView))

                ForEach(Array(self.displayedReleases.enumerated()), id: \.element.id) { index, release in
                    ReleaseView(release: release)
                        .padding(.bottom, 32.0)
                        .tag(self.releasePageIndex(for: index))
                }

                self.trailingView
                    .tag(self.tabIndex(from: .trailingView))
            }
            .tabViewStyle(.page(indexDisplayMode: self.usesDefaultPaginationControls ? .always : .never))
            .background(self.derivedBackgroundStyle)

            if self.showsFooter {
                VStack(spacing: 0.0) {
                    if self.usesButtonPaginationControls {
                        self.paginationControls
                    }

                    if self.showsDismissButton {
                        self.dismissButton
                    }
                }
                .background(self.derivedBackgroundStyle)
            }
        }
        .onAppear(perform: {
			self.selectedIndex = self.tabIndex(from: self.startIndex)

            self.setupAppearanceChanges()
        })
        .onDisappear(perform: {
            self.teardownAppearanceChanges()
        })
    }
}

// MARK: Convenience Initializers

public extension RecapScreen where LeadingView == EmptyView {
    init(releases: [Release], @ViewBuilder trailingView: () -> TrailingView) {
        self.releases = releases
        self.leadingView = EmptyView()
        self.trailingView = trailingView()
    }
}

public extension RecapScreen where TrailingView == EmptyView {
    init(releases: [Release], @ViewBuilder leadingView: () -> LeadingView) {
        self.releases = releases
        self.leadingView = leadingView()
        self.trailingView = EmptyView()
    }
}

public extension RecapScreen where LeadingView == EmptyView, TrailingView == EmptyView {
    init(releases: [Release]) {
        self.releases = releases
        self.leadingView = EmptyView()
        self.trailingView = EmptyView()
    }
}

// MARK: Private

private extension RecapScreen {
	var paginationControls: some View {
		HStack(spacing: 16.0) {
			self.paginationButton(
				title: LocalizedStringResource(
					"RECAP.SCREEN.PAGINATION.BUTTON.PREVIOUS",
					bundle: .atURL(Bundle.module.bundleURL)
				),
				systemImage: "arrow.left",
				direction: .previous
			)
			.frame(maxWidth: .infinity, alignment: .leading)

			self.pageIndicators

			self.paginationButton(
				title: LocalizedStringResource(
					"RECAP.SCREEN.PAGINATION.BUTTON.NEXT",
					bundle: .atURL(Bundle.module.bundleURL)
				),
				systemImage: "arrow.right",
				direction: .next
			)
			.frame(maxWidth: .infinity, alignment: .trailing)
		}
		.padding(.top, 24.0)
		.padding(.horizontal, 32.0)
		.foregroundStyle(.primary)
		.withBottomPaddingIfNoSafeArea(when: !self.showsDismissButton)
	}

	var pageIndicators: some View {
		HStack(spacing: 10.0) {
			ForEach(Array(0..<self.pageCount), id: \.self) { index in
				Button(action: {
					withAnimation {
						self.selectedIndex = index
					}
				}, label: {
					Circle()
						.fill(index == self.selectedIndex ? self.selectedPageIndicatorColor : self.deselectedPageIndicatorColor)
						.frame(width: 8.0, height: 8.0)
				})
				.buttonStyle(.plain)
			}
		}
	}

	var dismissButton: some View {
		Button(action: {
			dismissAction?() ?? dismiss()
		}, label: {
			HStack {
				Spacer(minLength: 0.0)

				Text(self.dismissButtonTitle)
					.font(.system(.title3, weight: .bold))
					.padding(8.0)
					.padding(.vertical, 4.0)
					.padding(.horizontal, 16.0)
					.foregroundStyle(dismissButtonStyle.foregroundStyle)

				Spacer(minLength: 0.0)
			}
			.contentShape(.rect(cornerRadius: 16.0))
		})
		.buttonStyle(.borderless)
		.frame(maxWidth: .infinity)
		.background(self.dismissButtonStyle.backgroundStyle)
		.versionSpecificClipShape()
		.padding(.horizontal, 40.0)
		.padding(.top, self.usesButtonPaginationControls ? 16.0 : 0.0)
		.foregroundStyle(.primary)
		.withBottomPaddingIfNoSafeArea()
	}

    var displayedReleases: [Release] {
        self.releases.reversed()
    }

    var hasLeadingPage: Bool {
        LeadingView.self != EmptyView.self
    }

    var hasTrailingPage: Bool {
        TrailingView.self != EmptyView.self
    }

    var pageCount: Int {
        self.displayedReleases.count
            + (self.hasLeadingPage ? 1 : 0)
            + (self.hasTrailingPage ? 1 : 0)
    }

    var hasMultiplePages: Bool {
        self.pageCount > 1
    }

    var usesDefaultPaginationControls: Bool {
        self.paginationStyle == .default && self.hasMultiplePages
    }

    var usesButtonPaginationControls: Bool {
        self.paginationStyle == .buttons && self.hasMultiplePages
    }

    var showsDismissButton: Bool {
        self.dismissButtonVisibility == .visible
    }

    var showsFooter: Bool {
        self.usesButtonPaginationControls || self.showsDismissButton
    }

	var leadingPageIndex: Int {
		0
	}

	var trailingPageIndex: Int {
		self.pageCount - 1
	}

    var derivedBackgroundStyle: AnyShapeStyle {
        if let backgroundStyle {
            backgroundStyle
        } else {
            AnyShapeStyle(self.colorScheme == .dark ? Color.black : Color.white)
        }
    }

	func canPaginate(in direction: PaginationDirection) -> Bool {
		switch direction {
		case .previous: self.selectedIndex > 0
		case .next: self.selectedIndex < (self.pageCount - 1)
		}
	}

	func tabIndex(from startIndex: RecapScreenStartIndex) -> Int {
		switch startIndex {
		case .leadingView:
			return 0

		case .trailingView:
			return max(self.trailingPageIndex, 0)

		case .release(let index):
			let clampedIndex = min(max(index, 0), max(self.displayedReleases.count - 1, 0))

			return self.releasePageIndex(for: clampedIndex)
		}
	}


	func releasePageIndex(for releaseIndex: Int) -> Int {
		releaseIndex + (self.hasLeadingPage ? 1 : 0)
	}

    func setupAppearanceChanges() {
#if canImport(UIKit)
        self.originalSelectedPageIndicatorColor = UIPageControl.appearance().currentPageIndicatorTintColor
        self.originalDeselectedPageIndicatorColor = UIPageControl.appearance().pageIndicatorTintColor

        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(self.selectedPageIndicatorColor)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(self.deselectedPageIndicatorColor)
#endif
    }

    func teardownAppearanceChanges() {
#if canImport(UIKit)
        UIPageControl.appearance().currentPageIndicatorTintColor = self.originalSelectedPageIndicatorColor
        UIPageControl.appearance().pageIndicatorTintColor = self.originalDeselectedPageIndicatorColor
#endif
    }

	@ViewBuilder
    func paginationButton(title: LocalizedStringResource, systemImage: String, direction: PaginationDirection) -> some View {
        let isEnabled = self.canPaginate(in: direction)

        Button(action: {
            self.paginate(in: direction)
        }, label: {
            HStack(spacing: 8.0) {
                if direction == .previous {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .lineLimit(1)

                if direction == .next {
                    Image(systemName: systemImage)
                }
            }
            .font(.system(.title3, weight: .semibold))
            .contentShape(.rect)
            .opacity(isEnabled ? 1.0 : 0.35)
        })
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    func paginate(in direction: PaginationDirection) {
        guard self.canPaginate(in: direction) else { return }

        withAnimation {
            switch direction {
            case .previous: self.selectedIndex -= 1
            case .next: self.selectedIndex += 1
            }
        }
    }
}

// MARK: PaginationDirection

private enum PaginationDirection {
    case previous
    case next
}

// MARK: Safe Area Insets

private extension View {
	@ViewBuilder
	func versionSpecificClipShape() -> some View {
		if #available(iOS 26.0, *) {
			self.clipShape(.capsule)
		} else {
			self.clipShape(.rect(cornerRadius: 16.0))
		}
	}

    var hasSafeAreaForBottomPadding: Bool {
		#if os(macOS) || targetEnvironment(macCatalyst)
        return false
		#else
        if UIDevice.current.userInterfaceIdiom == .pad {
            // On iPad, we don't display fullscreen so the home bar isn't relevant.
            return false
        } else {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            let mainScene = windowScenes.first(where: { $0.screen == .main })
            let mainWindow = (mainScene?.keyWindow ?? mainScene?.windows.first)
            return (mainWindow?.safeAreaInsets.bottom ?? 0.0) > 0.0
        }
		#endif
    }

    @ViewBuilder
    func withBottomPaddingIfNoSafeArea(when shouldApply: Bool = true) -> some View {
        if !shouldApply || hasSafeAreaForBottomPadding {
            self
        } else {
            self.padding(.bottom, 24.0)
        }
    }
}
