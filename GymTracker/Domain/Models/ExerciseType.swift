import Foundation

enum ExerciseType: String, CaseIterable, Codable, Sendable {
    case squat
    case pushUp
    case lunge
    case shoulderPress
    case bicepCurl
    case unknown

    init(rawLabel: String) {
        let normalized = ExerciseType.normalizedLabelKey(from: rawLabel)

        switch normalized {
        case "squat", "squats":
            self = .squat
        case "pushup", "pushups", "push-up", "push-ups":
            self = .pushUp
        case "lunge", "lunges":
            self = .lunge
        case "shoulderpress", "overheadpress":
            self = .shoulderPress
        case "bicepcurl", "bicepcurls", "curl", "curls", "barbellbicepscurl", "hammercurl":
            self = .bicepCurl
        default:
            self = .unknown
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .squat:
            "Squat"
        case .pushUp:
            "Push-Up"
        case .lunge:
            "Lunge"
        case .shoulderPress:
            "Shoulder Press"
        case .bicepCurl:
            "Bicep Curl"
        case .unknown:
            "Recognizing..."
        }
    }

    nonisolated static func normalizedLabelKey(from rawLabel: String) -> String {
        rawLabel
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    nonisolated static func displayName(forRawLabel rawLabel: String) -> String {
        let trimmed = rawLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return unknown.displayName }

        let normalizedSpacing = trimmed
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return normalizedSpacing.capitalized
    }
}
