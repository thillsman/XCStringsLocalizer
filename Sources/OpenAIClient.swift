import Foundation

// MARK: - OpenAI API Client

/// Client for communicating with the OpenAI API
class OpenAIClient {
    private let apiKey: String
    private let model: String
    private let session: URLSession
    private let appDescription: String?

    init(apiKey: String, model: String = "gpt-4o-mini", appDescription: String? = nil) {
        self.apiKey = apiKey
        self.model = model
        self.appDescription = appDescription
        self.session = URLSession.shared
    }

    /// Get the localized language name for a language code (e.g., "fr" -> "French")
    func languageName(for languageCode: String) -> String {
        // Use English locale for consistent API communication
        let englishLocale = Locale(identifier: "en")
        return englishLocale.localizedString(forLanguageCode: languageCode) ?? languageCode
    }

    /// Batch translate multiple strings to a target language (more efficient)
    func translateBatch(
        strings: [(key: String, text: String, context: String?)],
        targetLanguage: String
    ) async throws -> [String: String] {
        let targetLanguageName = languageName(for: targetLanguage)

        // Build the batch prompt
        var prompt = """
        Translate the following strings to \(targetLanguageName).

        IMPORTANT RULES:
        1. Preserve ALL placeholders exactly as they appear (e.g., %@, %d, %.0f, %1$@, {variable})
        2. Preserve formatting characters like \\n (newlines) and special characters
        3. Maintain the same tone and style
        4. If the text is a UI element, keep it concise
        5. Preserve capitalization style: if a string is lowercased and has no ending punctuation, keep it lowercased (don't make it a sentence)
        6. Return translations in the EXACT same JSON format, preserving the keys
        """

        if let appDesc = appDescription {
            prompt += "\n7. App context: \(appDesc)"
        }

        prompt += "\n\nStrings to translate (JSON format):\n"

        // Create JSON input
        var jsonInput: [String: Any] = [:]
        for (index, item) in strings.enumerated() {
            var entry: [String: String] = ["text": item.text]
            if let context = item.context {
                entry["context"] = context
            }
            jsonInput["string_\(index)"] = entry
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonInput, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            prompt += jsonString
        }

        prompt += """


        Return your translations in JSON format:
        {
          "string_0": "translated text here",
          "string_1": "translated text here",
          ...
        }

        Return ONLY the JSON, no explanations.
        """

        let request = ChatCompletionRequest(
            model: model,
            messages: [
                ChatMessage(role: "user", content: prompt)
            ],
            maxTokens: 4096
        )

        let response = try await sendRequest(request)
        guard let responseText = response.choices.first?.message.content else {
            throw OpenAIError.noResponse
        }

        // Parse the JSON response
        let cleaned = responseText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8),
              let translations = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else {
            throw OpenAIError.invalidResponse
        }

        // Map back to original keys
        var result: [String: String] = [:]
        for (index, item) in strings.enumerated() {
            if let translation = translations["string_\(index)"] {
                result[item.key] = translation
            }
        }

        return result
    }

    /// Analyze existing translations and suggest improvements
    func analyzeBatch(
        translations: [(key: String, original: String, translation: String, context: String?)],
        targetLanguage: String
    ) async throws -> [TranslationSuggestion] {
        let targetLanguageName = languageName(for: targetLanguage)

        // Build the analysis prompt
        var prompt = """
        You are analyzing existing translations from English to \(targetLanguageName).
        For each translation provided, evaluate if there is a SIGNIFICANTLY better alternative.

        IMPORTANT RULES:
        1. Only suggest improvements if you have HIGH confidence (4 or 5 out of 5)
        2. Preserve ALL placeholders exactly (e.g., %@, %d, %.0f, %1$@, {variable})
        3. Preserve formatting characters like \\n
        4. Consider: naturalness, cultural appropriateness, tone, and UI context
        5. Preserve capitalization style: if a string is lowercased and has no ending punctuation, keep it lowercased (don't make it a sentence)
        6. If the current translation is good enough, set confidence to 1-3 (will be filtered out)
        """

        if let appDesc = appDescription {
            prompt += "\n7. App context: \(appDesc)"
        }

        prompt += "\n\nTranslations to analyze (JSON format):\n"

        // Create JSON input
        var jsonInput: [String: Any] = [:]
        for (index, item) in translations.enumerated() {
            var entry: [String: String] = [
                "original": item.original,
                "translation": item.translation
            ]
            if let context = item.context {
                entry["context"] = context
            }
            jsonInput["string_\(index)"] = entry
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonInput, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            prompt += jsonString
        }

        prompt += """


        Return your analysis in JSON format:
        {
          "string_0": {
            "suggested": "improved translation (or same if no improvement needed)",
            "confidence": 1-5,
            "reasoning": "brief explanation"
          },
          "string_1": { ... },
          ...
        }

        Return ONLY the JSON, no explanations.
        """

        let request = ChatCompletionRequest(
            model: model,
            messages: [
                ChatMessage(role: "user", content: prompt)
            ],
            maxTokens: 4096,
            temperature: 0.3  // Lower temperature for more consistent analysis
        )

        let response = try await sendRequest(request)
        guard let responseText = response.choices.first?.message.content else {
            throw OpenAIError.noResponse
        }

        // Parse the JSON response
        let cleaned = responseText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8),
              let analysisDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: [String: Any]] else {
            throw OpenAIError.invalidResponse
        }

        // Build suggestions array, filtering by confidence >= 4 and different translations
        var suggestions: [TranslationSuggestion] = []
        for (index, item) in translations.enumerated() {
            if let analysis = analysisDict["string_\(index)"],
               let suggested = analysis["suggested"] as? String,
               let confidence = analysis["confidence"] as? Int,
               let reasoning = analysis["reasoning"] as? String,
               confidence >= 4,  // Only include high-confidence suggestions
               suggested != item.translation {  // Only include actual changes

                suggestions.append(TranslationSuggestion(
                    key: item.key,
                    language: targetLanguage,
                    currentTranslation: item.translation,
                    suggestedTranslation: suggested,
                    confidence: confidence,
                    reasoning: reasoning
                ))
            }
        }

        return suggestions
    }

    /// Translate text to a target language (single string - less efficient, use batch when possible)
    func translate(
        text: String,
        targetLanguage: String,
        context: String? = nil
    ) async throws -> String {
        let targetLanguageName = languageName(for: targetLanguage)

        var prompt = """
        Translate the following text to \(targetLanguageName).

        IMPORTANT RULES:
        1. Preserve ALL placeholders exactly as they appear (e.g., %@, %d, %.0f, %1$@, {variable})
        2. Preserve formatting characters like \\n (newlines) and special characters
        3. Maintain the same tone and style
        4. If the text is a UI element, keep it concise
        5. Preserve capitalization style: if a string is lowercased and has no ending punctuation, keep it lowercased (don't make it a sentence)
        6. Return ONLY the translated text, no explanations or additional content
        """

        if let appDesc = appDescription {
            prompt += "\n7. App context: \(appDesc)"
        }

        if let context = context {
            prompt += "\n8. String context: \(context)"
        }

        prompt += "\n\nText to translate: \(text)"

        let request = ChatCompletionRequest(
            model: model,
            messages: [
                ChatMessage(role: "user", content: prompt)
            ],
            maxTokens: 1024
        )

        let response = try await sendRequest(request)
        guard let translatedText = response.choices.first?.message.content else {
            throw OpenAIError.noResponse
        }

        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sendRequest(_ request: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw OpenAIError.apiError(errorResponse.error.message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ChatCompletionResponse.self, from: data)
    }
}

// MARK: - OpenAI API Models

struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int?
    let temperature: Double?

    init(model: String, messages: [ChatMessage], maxTokens: Int? = nil, temperature: Double? = nil) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]

    struct Choice: Codable {
        let index: Int
        let message: ChatMessage
        let finishReason: String?
    }
}

struct OpenAIErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
        let type: String
        let code: String?
    }
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case noResponse
    case invalidResponse
    case httpError(Int)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from OpenAI API"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
