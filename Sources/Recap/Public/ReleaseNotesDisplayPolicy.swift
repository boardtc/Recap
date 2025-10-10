import Foundation

/// Determines whether to display a "What's New" banner based on
/// current/previous app versions and available release-note versions.
public struct ReleaseNotesDisplayPolicy {
    private let currentVersion: SemanticVersion
    private let previousVersion: SemanticVersion?
    private let releaseVersions: [SemanticVersion]

    public init(currentVersion: SemanticVersion, previousVersion: SemanticVersion?, releases: [SemanticVersion]) {
        self.currentVersion = currentVersion
        self.previousVersion = previousVersion
        self.releaseVersions = releases
    }

	/// Convenience initializer for String inputs. Prefer the `SemanticVersion` initializer when possible.
	public init(currentVersion: String, previousVersion: String?, releaseVersions: [String]) {
		let current = SemanticVersion(version: currentVersion)
		let previous = previousVersion.flatMap { SemanticVersion(version: $0) }
		let releases = releaseVersions.compactMap { SemanticVersion(version: $0) }
		self.init(currentVersion: current, previousVersion: previous, releases: releases)
	}

    /// Returns true if there are release notes for the current version,
    /// or any notes between the previous (exclusive) and current (inclusive).
    public var hasRelevantReleaseNotes: Bool {
		return self.hasReleaseNotes(from: self.previousVersion, to: self.currentVersion)
    }

    /// Returns true if major or minor has increased compared to the previous version.
    public var isNotableVersionIncrease: Bool {
        guard let previous = self.previousVersion else { return false }

		return self.currentVersion.major > previous.major || self.currentVersion.minor > previous.minor
    }

    /// Evaluate a trigger against the policy's versions and release notes,
	/// to determine if a Recap screen should be displayed.
    public func shouldTrigger(using trigger: Trigger) -> Bool {
        let hasNotesForCurrentVersion = self.releaseVersions.contains(where: { $0 == self.currentVersion })
		let previousVersion = self.previousVersion

		let hasNotesSincePreviousVersion = if let previousVersion {
			self.releaseVersions.contains(where: { $0 > previousVersion && $0 <= self.currentVersion })
		} else {
			self.releaseVersions.contains(where: { $0 <= self.currentVersion })
		}

		let meetsNotabilityRequirements = switch trigger.notability {
		case .any: true
		case .notableOnly: self.isNotableVersionIncrease
		}

		let meetsNotesRequirements = switch (trigger.notes, trigger.window) {
		case (.present, .current): hasNotesForCurrentVersion
		case (.present, .sincePrevious): hasNotesSincePreviousVersion
		case (.ignore, _): true
		}

        return meetsNotabilityRequirements && meetsNotesRequirements
    }
}

// MARK: Private

private extension ReleaseNotesDisplayPolicy {
    func hasReleaseNotes(from previous: SemanticVersion?, to current: SemanticVersion) -> Bool {
        let versions = self.releaseVersions

		guard !versions.isEmpty else { return false }

        if let previous {
            return versions.contains(where: { $0 >  previous && $0 <= current })
        } else {
            return versions.contains(where: { $0 <= current })
        }
    }
}
