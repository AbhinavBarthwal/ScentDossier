import Foundation

// MARK: - Scent History
// Stores user's fragrance experiences locally (loved, disliked, tried)

struct ScentEntry: Codable, Identifiable, Hashable {
    var id: String { name + "-" + house }
    let name: String
    let house: String
    let rating: ScentRating
    let notes: String  // user's personal notes
    let dateAdded: Date
}

enum ScentRating: String, Codable, CaseIterable {
    case loved = "loved"
    case liked = "liked"
    case neutral = "neutral"
    case disliked = "disliked"
    
    var emoji: String {
        switch self {
        case .loved: return "❤️"
        case .liked: return "👍"
        case .neutral: return "😐"
        case .disliked: return "👎"
        }
    }
    
    var label: String {
        switch self {
        case .loved: return "Loved"
        case .liked: return "Liked"
        case .neutral: return "Neutral"
        case .disliked: return "Disliked"
        }
    }
}

// MARK: - Note Preferences

struct NotePreferences: Codable {
    var loved: [String]   // notes user loves (e.g., "vanilla", "sandalwood")
    var disliked: [String] // notes user dislikes (e.g., "patchouli", "oud")
    
    static var empty: NotePreferences {
        NotePreferences(loved: [], disliked: [])
    }
}

// MARK: - History Store

class ScentHistoryStore: ObservableObject {
    @Published var entries: [ScentEntry] = []
    @Published var notePreferences: NotePreferences = .empty
    
    private let entriesKey = "scentHistory_entries"
    private let prefsKey = "scentHistory_notePrefs"
    
    init() {
        load()
    }
    
    func addEntry(_ entry: ScentEntry) {
        // Remove existing entry for same fragrance if any
        entries.removeAll { $0.id == entry.id }
        entries.insert(entry, at: 0)
        save()
    }
    
    func removeEntry(_ entry: ScentEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }
    
    func addLovedNote(_ note: String) {
        let cleaned = note.lowercased().trimmingCharacters(in: .whitespaces)
        if !notePreferences.loved.contains(cleaned) {
            notePreferences.loved.append(cleaned)
            notePreferences.disliked.removeAll { $0 == cleaned }
            save()
        }
    }
    
    func addDislikedNote(_ note: String) {
        let cleaned = note.lowercased().trimmingCharacters(in: .whitespaces)
        if !notePreferences.disliked.contains(cleaned) {
            notePreferences.disliked.append(cleaned)
            notePreferences.loved.removeAll { $0 == cleaned }
            save()
        }
    }
    
    func removeNotePreference(_ note: String) {
        let cleaned = note.lowercased().trimmingCharacters(in: .whitespaces)
        notePreferences.loved.removeAll { $0 == cleaned }
        notePreferences.disliked.removeAll { $0 == cleaned }
        save()
    }
    
    // Summary for the LLM context
    func contextSummary() -> String {
        var parts: [String] = []
        
        let loved = entries.filter { $0.rating == .loved }
        let disliked = entries.filter { $0.rating == .disliked }
        
        if !loved.isEmpty {
            parts.append("Fragrances they LOVE: \(loved.map { "\($0.name) by \($0.house)" }.joined(separator: ", "))")
        }
        if !disliked.isEmpty {
            parts.append("Fragrances they DISLIKE: \(disliked.map { "\($0.name) by \($0.house)" }.joined(separator: ", "))")
        }
        if !notePreferences.loved.isEmpty {
            parts.append("Notes they enjoy: \(notePreferences.loved.joined(separator: ", "))")
        }
        if !notePreferences.disliked.isEmpty {
            parts.append("Notes they avoid: \(notePreferences.disliked.joined(separator: ", "))")
        }
        
        return parts.isEmpty ? "No scent history yet." : parts.joined(separator: "\n")
    }
    
    // MARK: - Persistence
    
    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
        if let data = try? JSONEncoder().encode(notePreferences) {
            UserDefaults.standard.set(data, forKey: prefsKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([ScentEntry].self, from: data) {
            entries = decoded
        }
        if let data = UserDefaults.standard.data(forKey: prefsKey),
           let decoded = try? JSONDecoder().decode(NotePreferences.self, from: data) {
            notePreferences = decoded
        }
    }
}
