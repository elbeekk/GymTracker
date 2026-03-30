import Foundation

struct AnthropicCoachService: Sendable {
    enum CoachError: Error {
        case invalidResponse
        case requestFailed(statusCode: Int, message: String)
    }

    nonisolated init() {}

    nonisolated
    func generateCue(
        prompt: String,
        configuration: AppConfiguration.Anthropic,
        apiKey: String
    ) async throws -> String {
        var request = URLRequest(url: configuration.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(configuration.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(
            MessageRequest(
                model: configuration.model,
                system: systemPrompt,
                max_tokens: configuration.maxTokens,
                temperature: configuration.temperature,
                messages: [
                    Message(role: "user", content: [MessageContent(text: prompt)])
                ]
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoachError.invalidResponse
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            let message = (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data).error.message)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw CoachError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        let decoded = try JSONDecoder().decode(MessageResponse.self, from: data)
        let text = decoded.content
            .compactMap(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw CoachError.invalidResponse
        }

        return text
    }

    private var systemPrompt: String {
        """
        You are a live gym form coach.
        Return one short spoken correction only.
        Never mention rep counting, invalid reps, range of motion, metrics, analysis, or tracking.
        Start with an action verb.
        Name a body part.
        Use plain gym language.
        Maximum 7 words.
        No punctuation.
        """
    }
}

private struct MessageRequest: Encodable {
    let model: String
    let system: String
    let max_tokens: Int
    let temperature: Double
    let messages: [Message]
}

private struct Message: Encodable {
    let role: String
    let content: [MessageContent]
}

private struct MessageContent: Encodable {
    let type = "text"
    let text: String
}

private struct MessageResponse: Decodable {
    let content: [ResponseContent]
}

private struct ResponseContent: Decodable {
    let type: String
    let text: String?
}

private struct APIErrorEnvelope: Decodable {
    let error: APIErrorPayload
}

private struct APIErrorPayload: Decodable {
    let message: String
}
