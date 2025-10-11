public extension RecapDisplayPolicy {
    /// A fluent, composable description of when to surface release notes
    /// given the current and previous app versions and the available
    /// release-note versions.
    ///
    /// Build a trigger by chaining together three parts:
    /// 1) An update window describing which versions to match (e.g. only the
    ///    current version, or anything since the previous version).
    /// 2) A notability requirement (any vs notable-only, where notable is a
    ///    major/minor bump compared to the previous version).
    /// 3) A notes requirement (require release notes to be present in the
    ///    selected window, or ignore notes entirely).
    ///
    /// Evaluate with `RecapDisplayPolicy.shouldTrigger(using:)`.
    ///
    /// Examples:
    /// - Only if current version has notes (default behavior requires notes):
    ///   `Trigger.updateWindow(.current)`
    /// - If any notes exist in (previous, current]:
    ///   `Trigger.updateWindow(.sincePrevious)`
    /// - Notable-only and must have notes since previous:
    ///   `Trigger.updateWindow(.sincePrevious).notability(.notableOnly)`
    /// - Ignore notes requirement entirely:
    ///   `Trigger.updateWindow(.current).ignoringReleaseNotesRequirement()`
    struct Trigger {
		let window: UpdateWindow
		var notability = UpdateNotability.any
		var notes = NotesRequirement.present

		private init(window: UpdateWindow) { self.window = window }

		/// Start a trigger chain by selecting the update window to evaluate.
		public static func updateWindow(_ window: UpdateWindow) -> Trigger {
			Trigger(window: window)
		}

		/// Restrict the trigger to only notable (major/minor) changes, or allow any change.
		public func notability(_ notability: UpdateNotability) -> Trigger {
			var trigger = self;
			trigger.notability = notability;
			return trigger
		}

		/// Ignore the requirement that release notes must be present for the selected window.
		/// By default, triggers require release notes to be present in the matched window.
		public func ignoringReleaseNotesRequirement() -> Trigger {
			var trigger = self;
			trigger.notes = .ignore;
			return trigger
		}
	}
}

// MARK: RecapDisplayPolicy.UpdateWindow, RecapDisplayPolicy.UpdateNotability, RecapDisplayPolicy.NotesRequirement

public extension RecapDisplayPolicy {
	/// Defines the version range in which to evaluate release notes.
	///
	/// - current: Only the current app version must have release notes.
	/// - sincePrevious: Any version in (previous, current] may have release notes.
	enum UpdateWindow {
		case current
		case sincePrevious
	}

	/// Controls whether there must be a "notable" (major/minor) change in between to trigger.
	///
	/// - any: Do not require a major/minor bump; patch‑level changes are allowed.
	/// - notableOnly: Require a major or minor version increase compared to the previous version.
	enum UpdateNotability {
		case any
		case notableOnly
	}

	/// Requires release notes to be present in the selected window, or ignores notes entirely.
	///
	/// - present: Release notes must be present (window‑aware).
	/// - ignore: Do not require release notes (useful for custom behaviors).
	enum NotesRequirement {
		case present
		case ignore
	}
}

