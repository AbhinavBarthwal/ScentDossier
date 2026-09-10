import Foundation

// MARK: - Essence History Entry

struct EssenceHistoryEntry: Codable, Identifiable {
    let id: UUID
    let name: String
    let birthDate: Date
    let lifePathNumber: Int
    let lifePathIsMaster: Bool
    let zodiacSign: String  // raw value
    let scentLeaning: String
    let lifePathDescription: String
    let dateSaved: Date
    
    var zodiac: ZodiacSign? {
        ZodiacSign(rawValue: zodiacSign)
    }
}

// MARK: - Essence History Store

class EssenceHistoryStore: ObservableObject {
    @Published var entries: [EssenceHistoryEntry] = []
    
    private let storageKey = "cosmicHistory_v2"
    
    init() {
        load()
    }
    
    func save(name: String, birthDate: Date, profile: EssenceProfile) {
        let entry = EssenceHistoryEntry(
            id: UUID(),
            name: name,
            birthDate: birthDate,
            lifePathNumber: profile.lifePathNumber,
            lifePathIsMaster: profile.lifePathIsmaster,
            zodiacSign: profile.zodiacSign.rawValue,
            scentLeaning: profile.scentLeaning,
            lifePathDescription: profile.lifePathTrait.description,
            dateSaved: Date()
        )
        
        // Remove existing entry for same name (case-insensitive) to avoid duplicates
        entries.removeAll { $0.name.lowercased() == name.lowercased() }
        entries.insert(entry, at: 0)
        persist()
    }
    
    func remove(_ entry: EssenceHistoryEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }
    
    func removeAll() {
        entries.removeAll()
        persist()
    }
    
    // MARK: - Persistence
    
    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([EssenceHistoryEntry].self, from: data) {
            entries = decoded
        }
    }
}
