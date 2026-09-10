import Foundation
import SwiftUI
import Security

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    var quickReplies: [String]
    
    enum MessageRole {
        case user
        case assistant
        case system
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chat View Model

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""
    @Published var errorMessage: String?
    @Published var hasApiKey = false
    
    private var chatService: ChatService?
    private let historyStore: ScentHistoryStore
    private var profile: UserProfile
    private var traits: PersonalityTraits
    private var topFamilies: [String]
    private var recommendations: [Fragrance]
    
    private let apiKeyStorageKey = "groq_api_key"
    
    init(
        profile: UserProfile,
        traits: PersonalityTraits,
        topFamilies: [String],
        recommendations: [Fragrance],
        historyStore: ScentHistoryStore
    ) {
        self.profile = profile
        self.traits = traits
        self.topFamilies = topFamilies
        self.recommendations = recommendations
        self.historyStore = historyStore
        
        loadApiKey()
        addWelcomeMessage()
    }
    
    // MARK: - API Key Management
    
    func saveApiKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        KeychainHelper.save(key: apiKeyStorageKey, value: trimmed)
        chatService = ChatService(apiKey: trimmed)
        hasApiKey = true
        errorMessage = nil
    }
    
    func clearApiKey() {
        KeychainHelper.delete(key: apiKeyStorageKey)
        chatService = nil
        hasApiKey = false
    }
    
    private func loadApiKey() {
        if let key = KeychainHelper.load(key: apiKeyStorageKey) {
            chatService = ChatService(apiKey: key)
            hasApiKey = true
        }
    }
    
    // MARK: - Messaging
    
    func sendMessage(_ text: String? = nil) {
        let content = (text ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        inputText = ""
        
        let userMessage = ChatMessage(
            role: .user,
            content: content,
            timestamp: Date(),
            quickReplies: []
        )
        messages.append(userMessage)
        
        Task {
            await getResponse()
        }
    }
    
    func sendQuickReply(_ reply: String) {
        sendMessage(reply)
    }
    
    private func getResponse() async {
        guard let service = chatService else {
            errorMessage = "Please add your free Groq API key to start chatting."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let apiMessages = buildApiMessages()
            let response = try await service.send(messages: apiMessages)
            
            let (cleanedContent, quickReplies) = parseResponse(response)
            
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: cleanedContent,
                timestamp: Date(),
                quickReplies: quickReplies
            )
            messages.append(assistantMessage)
            
            // Check if the AI mentioned any notes to track
            extractAndStorePreferences(from: response)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - System Prompt Builder
    
    private func buildSystemPrompt() -> String {
        let familyNames = topFamilies.compactMap { id in
            allFamilies.first { $0.id == id }?.label
        }.joined(separator: ", ")
        
        let recsText = recommendations.prefix(5).map { frag in
            "- \(frag.name) by \(frag.house) (\(frag.family), ~$\(frag.priceUSD))"
        }.joined(separator: "\n")
        
        let historyContext = historyStore.contextSummary()
        
        return """
        You are the Scent Advisor for ScentDossier — a fragrance expert.
        
        RULES:
        - Keep answers SHORT: 2-3 sentences max. No essays.
        - Be direct. Answer the question, then stop.
        - When recommending, give the name, house, and ONE reason it fits them.
        - No fluff, no filler, no repeating what the user said.
        - Use simple everyday English.
        - End with ONE short follow-up question or suggestion chips.
        - Format chips like: [chips: Option A | Option B | Option C]
        - Never say you're an AI.
        - If the user has a essence profile (numerology + zodiac), you may reference it as a core part of their scent identity — Element, Essence Number, and Personality are the three primary forces that shape their fragrance profile. Climate and age are minor factors only.
        
        USER CONTEXT:
        - Climate: \(profile.climate.isEmpty ? "not set" : profile.climate)
        - Skin: \(profile.skin.isEmpty ? "not set" : profile.skin)
        - Work: \(profile.work.isEmpty ? "not set" : profile.work)
        - Style: \(profile.styling.isEmpty ? "not set" : profile.styling)
        - Season: \(profile.season.isEmpty ? "not set" : profile.season)
        - Occasion: \(profile.occasion.isEmpty ? "not set" : profile.occasion)
        - Budget: \(profile.budget == "any" ? "flexible" : "tier \(profile.budget)")
        - Gender pref: \(profile.genderPref == "any" ? "open" : profile.genderPref)
        - Boldness: \(String(format: "%.1f", traits.boldness)), Experimental: \(String(format: "%.1f", traits.experimental)), Warmth: \(String(format: "%.1f", traits.warmth))
        - Top families: \(familyNames)
        
        THEIR RECOMMENDATIONS:
        \(recsText)
        
        HISTORY: \(historyContext)
        """
    }
    
    private func buildApiMessages() -> [ChatService.Message] {
        var apiMessages: [ChatService.Message] = []
        
        // System prompt
        apiMessages.append(ChatService.Message(role: "system", content: buildSystemPrompt()))
        
        // Conversation history (last 20 messages to stay within token limits)
        let recentMessages = messages.suffix(20)
        for msg in recentMessages {
            let role: String
            switch msg.role {
            case .user: role = "user"
            case .assistant: role = "assistant"
            case .system: continue
            }
            apiMessages.append(ChatService.Message(role: role, content: msg.content))
        }
        
        return apiMessages
    }
    
    // MARK: - Response Parsing
    
    private func parseResponse(_ response: String) -> (String, [String]) {
        var content = response
        var quickReplies: [String] = []
        
        // Extract [chips: ...] pattern
        if let range = content.range(of: "\\[chips?:([^\\]]+)\\]", options: .regularExpression) {
            let chipsString = String(content[range])
            content = content.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parse chips
            let inner = chipsString
                .replacingOccurrences(of: "[chips:", with: "")
                .replacingOccurrences(of: "[chip:", with: "")
                .replacingOccurrences(of: "]", with: "")
            quickReplies = inner.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        // Default chips if none provided
        if quickReplies.isEmpty {
            quickReplies = generateDefaultChips()
        }
        
        return (content, quickReplies)
    }
    
    private func generateDefaultChips() -> [String] {
        let options: [[String]] = [
            ["Tell me more", "Something different", "Why this one?"],
            ["For a date night", "For the office", "Something unique"],
            ["Under $100", "More options", "What notes are in it?"],
            ["I tried it — loved it!", "Not for me", "What else?"],
        ]
        return options.randomElement() ?? ["Tell me more", "Something different"]
    }
    
    // MARK: - Preference Extraction
    
    private func extractAndStorePreferences(from response: String) {
        // Simple heuristic: if the AI mentions the user loves/hates a note,
        // we could parse it. For now, we rely on explicit user input.
        // This is a hook for future enhancement.
    }
    
    // MARK: - Welcome Message
    
    private func addWelcomeMessage() {
        let familyNames = topFamilies.compactMap { id in
            allFamilies.first { $0.id == id }?.label
        }
        
        let greeting: String
        if familyNames.isEmpty {
            greeting = "Hey! I'm your scent advisor. Tell me about fragrances you've worn, what you're looking for, or just ask me anything about perfume. I'm here to help you find your perfect match."
        } else {
            greeting = "Based on your profile, you lean toward \(familyNames.joined(separator: ", ")) fragrances. I can help you dive deeper — tell me about scents you've tried, ask about specific fragrances, or let me suggest something for a specific occasion."
        }
        
        let welcome = ChatMessage(
            role: .assistant,
            content: greeting,
            timestamp: Date(),
            quickReplies: [
                "What have I been missing?",
                "Suggest for a date night",
                "I want something unique"
            ]
        )
        messages.append(welcome)
    }
    
    // MARK: - Update Context
    
    func updateContext(profile: UserProfile, traits: PersonalityTraits, topFamilies: [String], recommendations: [Fragrance]) {
        self.profile = profile
        self.traits = traits
        self.topFamilies = topFamilies
        self.recommendations = recommendations
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        
        var newItem = query
        newItem[kSecValueData as String] = data
        SecItemAdd(newItem as CFDictionary, nil)
    }
    
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
