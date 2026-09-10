import Foundation

// MARK: - LLM Chat Service
// Uses Groq API (free, no credit card needed, OpenAI-compatible)
// Get your free key at: console.groq.com

actor ChatService {
    private let apiKey: String
    private let model = "openai/gpt-oss-20b"
    private let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int
    }
    
    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Msg: Codable {
                let content: String
            }
            let message: Msg
        }
        let choices: [Choice]
    }
    
    func send(messages: [Message]) async throws -> String {
        let request = ChatRequest(
            model: model,
            messages: messages,
            temperature: 0.7,
            max_tokens: 300
        )
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ChatError.apiError(httpResponse.statusCode, body)
        }
        
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw ChatError.emptyResponse
        }
        
        return content
    }
}

// MARK: - Errors

enum ChatError: LocalizedError {
    case networkError(String)
    case apiError(Int, String)
    case emptyResponse
    case noApiKey
    
    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .apiError(let code, _): return "API error (code \(code))"
        case .emptyResponse: return "Empty response from AI"
        case .noApiKey: return "No API key configured"
        }
    }
}
