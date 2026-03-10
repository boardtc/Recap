# Recap

#### A "What's New" Screen, with a few tricks up it's sleeve.

![Screenshots of Plinky's Recap Integration](Images/plinky-screens.png)

### What’s New? Nm, what’s new witchu?

- **Flexible release history**: Unlike most What's New Screen libraries, Recap can display multiple releases, showcasing your app's entire feature history.

- **No code, no problems**: Powered by a simple Markdown file, stored locally or loaded remotely.

- **Built-in customization**: Presents a beautiful, standardized interface out of the box, while offering full customization to match any app's design language.

- **Semantic versioning support**: Simple logic to help decide when to display your What's New Screen.

### Getting Started

Setting up a screen to display your app's releases is simple:
1. Create a markdown file with your releases (we'll cover the format later).
2. Add two lines of code.

```swift
// Initialize releases from a markdown file in your app's bundle
extension [Release] {
    static var appReleases: [Release] {
        ReleasesParser(fileName: "Releases").releases
    }
}

// Create and display the RecapScreen
RecapScreen(releases: .appReleases)
```

That's all you need to get started!

### Creating Releases

Your releases are defined in a simple markdown file, with a very simple spec:
```markdown
# Version Number: [String] (Supports arbitrary number formats such as 1, 1.0, or 1.0.0)
## Release Title: [String]
### Semantic Version Change Type: [Major | Minor | Patch]

- title: [String] (Feature Title)
- description: [String] (Feature Description)
- symbol: [String] (SF Symbol Identifier)
- color: [String] (Hex Color Code or System Color Name)
```

> [!NOTE]
> For a full list of supported System Color Names, see `Sources/Recap/Internal/Color+SystemNames.swift`.

#### Example Releases file

```markdown
# 1.1
## New Features ❤️
### Minor

- title: Super Cool Feature #1
- description: You won't believe how this works
- symbol: sparkles
- color: cyan

- title: Super Cool Feature #2
- description: You will believe how this one works though
- symbol: text.magnifyingglass
- color: blue

- title: Super Cool Feature #3
- description: This feature is for the nerds in the house
- symbol: apple.terminal.on.rectangle
- color: orange

# 1.0.1
## Bug Fixes! 🐛
### Patch

- title: Welcome to some bug fixes!
- description: My bad y'all…
- symbol: ladybug.circle
- color: #FFC933

# 1.0
## Introducing Recap 🥳
### Major

- title: Welcome to Recap
- description: It's live! 🥰
- symbol: party.popper
- color: #F72585
```

With just a few lines of markdown we've built a Releases screen that has three pages, with a consistent look and feel.

![Screenshots of our demo Recap Integration](Images/demo-screens.png)

### Customize Your Release Screen

Recap provides various modifiers to tailor the Releases screen to your app's visual identity:

```swift
// Available customization modifiers
func recapScreenStartIndex(_ startIndex: RecapScreenStartIndex) -> some View
func recapScreenTitleStyle(_ style: some ShapeStyle) -> some View
func recapScreenDismissButtonStyle(_ style: some ShapeStyle) -> some View
func recapScreenDismissButtonStyle(_ backgroundStyle: some ShapeStyle, _ foregroundStyle: some ShapeStyle) -> some View
func recapScreenDismissButtonTitle(_ title: LocalizedStringResource) -> some View
func recapScreenDismissButtonVisibility(_ visibility: RecapScreenDismissButtonVisibility) -> some View
func recapScreenIconFillMode(_ style: IconFillMode) -> some View
func recapScreenIconAlignment(_ alignment: VerticalAlignment) -> some View
func recapScreenPageIndicatorColors(selected: Color, deselected: Color) -> some View
func recapScreenPaginationStyle(_ style: RecapScreenPaginationStyle) -> some View
func recapScreenBackground(_ style: AnyShapeStyle?) -> some View
func recapScreenBackground(_ color: Color) -> some View
func recapScreenPadding(_ insets: EdgeInsets) -> some View
func recapScreenHeaderSpacing(_ spacing: CGFloat) -> some View
func recapScreenItemSpacing(_ spacing: CGFloat) -> some View
func recapScreenDismissAction(_ dismissAction: (() -> Void)?) -> some View
```

Example usage:

```swift
RecapScreen(releases: .appReleases)
    .recapScreenTitleStyle(LinearGradient(colors: [.purple, .pink, .orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
    .recapScreenDismissButtonStyle(Color.pink, Color.white)
    .recapScreenDismissButtonVisibility(.hidden)
    .recapScreenIconFillMode(.gradient)
    .recapScreenPaginationStyle(.automatic)
    .recapScreenPageIndicatorColors(
        selected: Color.pink,
        deselected: Color.gray
    )
```

Pagination styles:

- `.automatic`: uses the system page control on iPhone and iPad, and adaptive previous/next buttons on Mac Catalyst
- `.labeled`: always shows previous/next buttons with text labels
- `.compact`: always shows previous/next buttons as icon-only controls

RecapScreen also supports leading and trailing views:

```swift
RecapScreen(
    releases: .plinkyReleases
    leadingView: {
        UpcomingRoadmapView()
    }, trailingView: {
        SupportView()
    }
)
.recapScreenStartIndex(.release())
// Alternatively: .recapScreenStartIndex(.leadingView) or .recapScreenStartIndex(.trailingView)
```

In my app [Plinky](https://plinky.app), I use the leading view to display the app's upcoming roadmap ahead of the most recent features, and the trailing view displays a support screen for people to reach out to me after browsing the feature list.

### Display Policies

`RecapDisplayPolicy` and `RecapDisplayPolicy.Trigger` provide a handy way to define when your Recap screen should display. It encapsulates the most common strategies people choose for displaying a What's New screen, for example "when there's a new version that has release notes" or "if there are any release notes since the last version the user launched". It achieves this with a composable fluent syntax, and the rest is handled for you.

Below is a simplified example of how you can present a Recap screen. In this case we will display our screen when there are release notes for any version since the last launch, and the update is notable (major/minor).

```swift
func presentRecapScreen() {
    let currentVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
    let previousVersion = UserDefaults.standard.string(forKey: "previouslyLaunchedVersion")

    // Versions of your app that have release notes
    let releaseVersions: [SemanticVersion] = [Release].appReleases.map(\.version.semanticVersion)

	// Create a RecapDisplayPolicy based on the app's current version, the previously launched version, and your release notes.
    let policy = RecapDisplayPolicy(
        currentVersion: SemanticVersion(version: currentVersion),
        previousVersion: previousVersion.map(SemanticVersion.init(version:)),
        releases: releaseVersions
    )

	// A Trigger that shows the release notes for notable versions 
	// for a user who hasn't seen opened the app since the last version with release notes. 
    let trigger = RecapDisplayPolicy.Trigger
        .updateWindow(.sincePrevious)
        .notability(.notableOnly)

	// An alternative example trigger that always shows release notes for any new version.
    // let trigger = RecapDisplayPolicy.Trigger
    //     .updateWindow(.current)
    //     .notability(.any)
    //     .ignoringReleaseNotesRequirement()

    if policy.shouldTrigger(using: trigger) {
		// Present a RecapScreen in your app in a contextually relevant manner. 
		let recapScreen = RecapScreen(releases: .appReleases)
        self.router.present(recapScreen)
    }

    // Persist version state for next launch
    UserDefaults.standard.set(currentVersion, forKey: "previouslyLaunchedVersion")
}
```

### Semantic Versioning

Recap includes a `SemanticVersion` type to represent and compare versions using the standard `major.minor.patch` scheme. It powers the display policy described below and can be used directly anywhere version comparisons are needed.

Examples:
- `SemanticVersion(version: "1.2.3")`
- Compare with `==`, `<`, `>` to implement custom logic

### Demo

Try Recap with [the demo project](https://github.com/mergesort/Recap/tree/main/Demo) to see if it fits your app's needs. 📱

### Requirements

- iOS 17.0+
- Xcode 14+

### Installation

#### Swift Package Manager

The [Swift Package Manager](https://www.swift.org/package-manager) is a tool for automating the distribution of Swift code and is integrated into the Swift build system.

Once you have your Swift package set up, adding Recap as a dependency is as easy as adding it to the dependencies value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/mergesort/Recap/", from: Version(2, 0, 0))
]
```

#### Manually

If you prefer not to use SPM, you can integrate Recap into your project manually by copying the files in.

---

### About me

Hi, I'm [Joe](http://fabisevi.ch) everywhere on the web, but especially on [Threads](https://threads.net/@mergesort).

### License

See the [license](LICENSE) for more information about how you can use Recap.

### Sponsorship

Recap is a labor of love to help developers build better apps, making it easier for you to unlock your creativity and make something amazing for your yourself and your users. If you find Recap valuable I would really appreciate it if you'd consider helping [sponsor my open source work](https://github.com/sponsors/mergesort), so I can continue to work on projects like Recap to help developers like yourself.
