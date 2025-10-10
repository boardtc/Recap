import Recap
import Testing

@Suite("ReleaseNotesDisplayPolicy.Trigger")
struct ReleaseNotesDisplayPolicyTriggerTests {
	@Test
	func testCurrentVersionNotesTriggers() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: SemanticVersion(version: "5.0"),
			previousVersion: SemanticVersion(version: "4.9"),
			releases: [SemanticVersion(version: "5.0")]
		)
		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.current)

		#expect(policy.shouldTrigger(using: trigger))
	}

	@Test
	func testCurrentVersionWithoutNotesDoesNotTrigger() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "5.1",
			previousVersion: "5.0",
			releaseVersions: ["5.0"]
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.current)

		#expect(!policy.shouldTrigger(using: trigger))
	}

	@Test
	func testSincePreviousWithSkippedMinorNotesExistTriggers() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: SemanticVersion(version: "6.1"),
			previousVersion: SemanticVersion(version: "5.9"),
			releases: [SemanticVersion(version: "6.0")]
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.sincePrevious)

		#expect(policy.shouldTrigger(using: trigger))
	}

	@Test
	func testSincePreviousAlreadySeenDoesNotTrigger() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "6.1",
			previousVersion: "6.0",
			releaseVersions: ["6.0"]
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.sincePrevious)

		#expect(!policy.shouldTrigger(using: trigger))
	}

	@Test
	func testCurrentNotableOnlyWithNotesTriggers() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: SemanticVersion(version: "6.0"),
			previousVersion: SemanticVersion(version: "5.9"),
			releases: [SemanticVersion(version: "6.0")]
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.current)
			.notability(.notableOnly)

		#expect(policy.shouldTrigger(using: trigger))
	}

	@Test
	func testSincePreviousNotableOnlyWithNotesTriggers() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "7.1",
			previousVersion: "6.9",
			releaseVersions: ["7.0"]
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.sincePrevious)
			.notability(.notableOnly)

		#expect(policy.shouldTrigger(using: trigger))
	}

	@Test
	func testPatchOnlyNotableOnlyDoesNotTrigger() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "5.0.1",
			previousVersion: "5.0",
			releaseVersions: ["5.0.1"]
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.current)
			.notability(.notableOnly)

		#expect(!policy.shouldTrigger(using: trigger))
	}

	@Test
	func testEmptyReleasesNeverTrigger() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "5.0",
			previousVersion: "4.9",
			releaseVersions: []
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.sincePrevious)

		#expect(!policy.shouldTrigger(using: trigger))
	}

	@Test
	func testIgnoringNotesRequirementAllowsTriggerOnNotableWithoutNotes() {
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: SemanticVersion(version: "6.0"),
			previousVersion: SemanticVersion(version: "5.9"),
			releases: []
		)

		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.current)
			.notability(.notableOnly)
			.ignoringReleaseNotesRequirement()

		#expect(policy.shouldTrigger(using: trigger))
	}

	// MARK: Multiple release lists (realistic scenarios)

	@Test
	func testSincePreviousWithManyReleasesTriggersWhenIntermediateHasNotes() {
		// User jumped from 4.0 to 4.1.1; 4.1 has notes in the list.
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "4.1.1",
			previousVersion: "4.0",
			releaseVersions: ["5.0", "4.1", "4.0", "3.0", "2.0", "1.0"]
		)
		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.sincePrevious)
			.notability(.notableOnly)
		#expect(policy.shouldTrigger(using: trigger))
	}

	@Test
	func testSincePreviousAlreadySeenMinorDoesNotTriggerWithManyReleases() {
		// User already launched 4.1; now on 4.1.2 (patch). No notable bump; should not trigger.
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "4.1.2",
			previousVersion: "4.1",
			releaseVersions: ["5.0", "4.1", "4.0", "3.0", "2.0", "1.0"]
		)
		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.sincePrevious)
			.notability(.notableOnly)
		#expect(!policy.shouldTrigger(using: trigger))
	}

	@Test
	func testLargeSkipAcrossManyReleasesTriggers() {
		// User jumped from 3.0 to 5.0.1; multiple prior versions have notes.
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "5.0.1",
			previousVersion: "3.0",
			releaseVersions: ["5.0", "4.1", "4.0", "3.0", "2.0", "1.0"]
		)
		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.sincePrevious)
			.notability(.notableOnly)
		#expect(policy.shouldTrigger(using: trigger))
	}

	@Test
	func testCurrentWindowRequiresExactCurrentEvenWithManyReleases() {
		// Current is 5.0.1; list has 5.0 but not 5.0.1 -> .current should not trigger.
		let policy = ReleaseNotesDisplayPolicy(
			currentVersion: "5.0.1",
			previousVersion: "5.0",
			releaseVersions: ["5.0", "4.1", "4.0", "3.0", "2.0", "1.0"]
		)
		let trigger = ReleaseNotesDisplayPolicy.Trigger
			.updateWindow(.current)
		#expect(!policy.shouldTrigger(using: trigger))

		// Now include exact current in releases -> should trigger.
		let policyWithExact = ReleaseNotesDisplayPolicy(
			currentVersion: "5.0.1",
			previousVersion: "5.0",
			releaseVersions: ["5.0.1", "5.0", "4.1", "4.0", "3.0", "2.0", "1.0"]
		)
		#expect(policyWithExact.shouldTrigger(using: trigger))
	}
}
