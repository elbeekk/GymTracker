import AVFoundation
import Foundation

@MainActor
final class VoiceGuidanceCoordinator {
    private struct Announcement {
        let key: String
        let text: String
        let cooldown: TimeInterval
        let interruptsCurrentSpeech: Bool
    }

    private let configuration: AppConfiguration.VoiceGuidance
    private let synthesizer = AVSpeechSynthesizer()
    private var lastAnnouncementTimes: [String: Date] = [:]
    private var lastInterruptAt: Date?
    private var hasConfiguredAudioSession = false

    init(configuration: AppConfiguration.VoiceGuidance) {
        self.configuration = configuration
    }

    func handle(snapshot: WorkoutPipelineSnapshot, previousSnapshot: WorkoutPipelineSnapshot?) {
        guard configuration.isEnabled, let previousSnapshot else { return }
        guard let announcement = nextAnnouncement(for: snapshot, previousSnapshot: previousSnapshot) else { return }
        speak(announcement)
    }

    func announceSystemMessage(_ text: String, key: String, interrupt: Bool = true) {
        guard configuration.isEnabled else { return }
        speak(
            Announcement(
                key: key,
                text: text,
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: interrupt
            )
        )
    }

    func announceCoachingCue(_ text: String) {
        let normalized = spokenText(from: text)
        guard configuration.isEnabled, !normalized.isEmpty else { return }
        speak(
            Announcement(
                key: "coach-\(normalized.lowercased())",
                text: normalized,
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: true
            )
        )
    }

    private func nextAnnouncement(
        for snapshot: WorkoutPipelineSnapshot,
        previousSnapshot: WorkoutPipelineSnapshot
    ) -> Announcement? {
        if snapshot.repCounter.didCountRep, snapshot.repCounter.repCount != previousSnapshot.repCounter.repCount {
            return Announcement(
                key: "rep-\(snapshot.repCounter.repCount)",
                text: "Rep \(snapshot.repCounter.repCount)",
                cooldown: 0,
                interruptsCurrentSpeech: false
            )
        }

        if snapshot.trackingStatus == .lost, previousSnapshot.trackingStatus != .lost {
            return Announcement(
                key: "tracking-lost",
                text: snapshot.trackingMessage,
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: true
            )
        }

        if snapshot.trackingStatus == .reacquiring, previousSnapshot.trackingStatus != .reacquiring {
            return Announcement(
                key: "tracking-reacquiring",
                text: snapshot.trackingMessage,
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: true
            )
        }

        if
            !snapshot.visibilityAssessment.isGoodEnough,
            snapshot.visibilityAssessment.status != previousSnapshot.visibilityAssessment.status
        {
            return Announcement(
                key: "visibility-\(snapshot.visibilityAssessment.status.rawValue)",
                text: snapshot.visibilityAssessment.message,
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: true
            )
        }

        if snapshot.screen == .live, previousSnapshot.trackingStatus != .locked, snapshot.trackingStatus == .locked {
            return Announcement(
                key: "user-locked",
                text: "Locked on current user. Start the set when ready.",
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: true
            )
        }

        if
            snapshot.exerciseState.isStable,
            snapshot.exerciseState.displayName != previousSnapshot.exerciseState.displayName
        {
            let text = snapshot.exerciseState.isSupported
                ? "\(snapshot.exerciseState.displayName) recognized."
                : "\(snapshot.exerciseState.displayName) detected. Rep counting is not configured yet."

            return Announcement(
                key: "exercise-\(snapshot.exerciseState.displayName.lowercased())",
                text: text,
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: false
            )
        }

        if
            snapshot.screen == .calibration,
            let banner = snapshot.feedbackBanner,
            banner.text != previousSnapshot.feedbackBanner?.text
        {
            return Announcement(
                key: "calibration-\(banner.text.lowercased())",
                text: banner.text,
                cooldown: configuration.minimumRepeatInterval,
                interruptsCurrentSpeech: banner.style == .critical
            )
        }

        return nil
    }

    private func speak(_ announcement: Announcement) {
        let now = Date()
        if let lastTime = lastAnnouncementTimes[announcement.key], now.timeIntervalSince(lastTime) < announcement.cooldown {
            return
        }

        lastAnnouncementTimes[announcement.key] = now
        configureAudioSessionIfNeeded()

        if synthesizer.isSpeaking {
            guard announcement.interruptsCurrentSpeech else { return }

            if let lastInterruptAt, now.timeIntervalSince(lastInterruptAt) < configuration.minimumInterruptInterval {
                return
            }

            lastInterruptAt = now
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: spokenText(from: announcement.text))
        utterance.rate = configuration.speechRate
        utterance.prefersAssistiveTechnologySettings = true
        utterance.voice = preferredVoice()
        synthesizer.speak(utterance)
    }

    private func configureAudioSessionIfNeeded() {
        guard !hasConfiguredAudioSession else { return }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            hasConfiguredAudioSession = true
        } catch {
            hasConfiguredAudioSession = false
        }
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let language = Locale.preferredLanguages.first ?? "en-US"
        return AVSpeechSynthesisVoice(language: language)
    }

    private func spokenText(from rawText: String) -> String {
        rawText
            .replacingOccurrences(of: "—", with: ", ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
