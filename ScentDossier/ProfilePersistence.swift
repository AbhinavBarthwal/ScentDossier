import Foundation

// MARK: - Saved Profile Bundle

/// Bundles all user data for local persistence as a single JSON file.
struct SavedProfile: Codable, Identifiable {
    let id: UUID
    let profile: CodableUserProfile
    let personalityAnswers: [PersonalityAnswer]
    let topFamilies: [String]
    let recommendations: [SavedFragrance]
    let savedAt: Date
    // Scent Profile Web data
    let elementName: String?       // e.g. "Fire"
    let zodiacName: String?        // e.g. "Aries"
    let lifePathNumber: Int?
    let essenceFamily: String?      // e.g. "spicy"
    let elementFamilies: [String]? // e.g. ["spicy", "oriental", "leather"]
    let signatureNotes: [String]?  // e.g. ["Black pepper", "Cinnamon", "Saffron"]
}

// MARK: - Codable User Profile

/// A Codable mirror of UserProfile for persistence.
struct CodableUserProfile: Codable {
    var name: String
    var climate: String
    var location: String
    var age: String
    var skin: String
    var styling: String
    var work: String
    var budget: String
    var genderPref: String
    var season: String
    var occasion: String
    var currency: String
    var birthDate: Date?
    var era: String
    var mood: String
    
    init(from profile: UserProfile) {
        self.name = profile.name
        self.climate = profile.climate
        self.location = profile.location
        self.age = profile.age
        self.skin = profile.skin
        self.styling = profile.styling
        self.work = profile.work
        self.budget = profile.budget
        self.genderPref = profile.genderPref
        self.season = profile.season
        self.occasion = profile.occasion
        self.currency = profile.currency
        self.birthDate = profile.birthDate
        self.era = profile.era
        self.mood = profile.mood
    }
    
    func toUserProfile() -> UserProfile {
        var p = UserProfile()
        p.name = name
        p.climate = climate
        p.location = location
        p.age = age
        p.skin = skin
        p.styling = styling
        p.work = work
        p.budget = budget
        p.genderPref = genderPref
        p.season = season
        p.occasion = occasion
        p.currency = currency
        p.birthDate = birthDate
        p.era = era
        p.mood = mood
        return p
    }
}

// MARK: - Personality Answer (Codable representation)

/// Stores a personality answer as axis + value (the UUID id is regenerated on load).
struct PersonalityAnswer: Codable {
    let questionId: String
    let label: String
    let axis: String
    let value: Double
}

// MARK: - Saved Fragrance (lightweight)

/// Stores just enough to identify a recommendation without the full catalog entry.
struct SavedFragrance: Codable {
    let name: String
    let house: String
    let family: String
}

// MARK: - Profile Persistence (supports multiple saved dossiers)

enum ProfilePersistence {
    
    private static let storageKey = "savedDossiers_v2"
    
    // MARK: - Save (appends to saved list)
    
    static func save(
        profile: UserProfile,
        answers: [String: QuestionOption],
        topFamilies: [String],
        recommendations: [Fragrance]
    ) {
        let codableProfile = CodableUserProfile(from: profile)
        
        let personalityAnswers: [PersonalityAnswer] = answers.map { (questionId, option) in
            PersonalityAnswer(
                questionId: questionId,
                label: option.label,
                axis: option.axis,
                value: option.value
            )
        }
        
        let savedFragrances = recommendations.map { f in
            SavedFragrance(name: f.name, house: f.house, family: f.family)
        }
        
        // Extract essence data if available
        var elementName: String?
        var zodiacName: String?
        var lifePathNumber: Int?
        var essenceFamily: String?
        var elementFamilies: [String]?
        var signatureNotes: [String]?
        
        if let birthDate = profile.birthDate {
            let essence = EssenceProfile.fromDate(birthDate)
            elementName = essence.zodiacSign.element
            zodiacName = essence.zodiacSign.displayName
            lifePathNumber = essence.lifePathNumber
            essenceFamily = essence.scentLeaning
            elementFamilies = essence.zodiacSign.elementScentProfile.families
            signatureNotes = essence.zodiacSign.elementScentProfile.signatureNotes
        }
        
        let bundle = SavedProfile(
            id: UUID(),
            profile: codableProfile,
            personalityAnswers: personalityAnswers,
            topFamilies: topFamilies,
            recommendations: savedFragrances,
            savedAt: Date(),
            elementName: elementName,
            zodiacName: zodiacName,
            lifePathNumber: lifePathNumber,
            essenceFamily: essenceFamily,
            elementFamilies: elementFamilies,
            signatureNotes: signatureNotes
        )
        
        var existing = loadAll()
        existing.insert(bundle, at: 0)
        persist(existing)
    }
    
    // MARK: - Load All
    
    static func loadAll() -> [SavedProfile] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SavedProfile].self, from: data)) ?? []
    }
    
    // MARK: - Load Latest (backward compat)
    
    static func load() -> SavedProfile? {
        loadAll().first
    }
    
    /// Converts saved personality answers back to the [String: QuestionOption] dictionary.
    static func restoreAnswers(from saved: [PersonalityAnswer]) -> [String: QuestionOption] {
        var answers: [String: QuestionOption] = [:]
        for answer in saved {
            let option = QuestionOption(label: answer.label, axis: answer.axis, value: answer.value)
            answers[answer.questionId] = option
        }
        return answers
    }
    
    // MARK: - Delete One
    
    static func delete(id: UUID) {
        var existing = loadAll()
        existing.removeAll { $0.id == id }
        persist(existing)
    }
    
    // MARK: - Clear All
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    // MARK: - Internal
    
    private static func persist(_ profiles: [SavedProfile]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
