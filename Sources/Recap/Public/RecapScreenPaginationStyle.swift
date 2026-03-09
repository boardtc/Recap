/// Controls how pagination is presented on the `RecapScreen`.
public enum RecapScreenPaginationStyle: Sendable, Equatable {
    /// Uses the platform-appropriate pagination presentation.
    ///
    /// On Mac Catalyst, Recap displays previous/next buttons and automatically compacts them to icon-only controls when space is tight.
    /// On other platforms, Recap uses the system page control.
    case automatic

    /// Always shows previous/next buttons with text labels.
    case labeled

    /// Always shows previous/next buttons as icon-only controls.
    case compact
}
