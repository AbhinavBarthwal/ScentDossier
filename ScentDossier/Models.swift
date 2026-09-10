import SwiftUI

// MARK: - Olfactory Family

struct OlfactoryFamily: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color
    let hexColor: String
    let description: String
    let icon: String
}

let allFamilies: [OlfactoryFamily] = [
    OlfactoryFamily(id: "citrus", label: "Citrus", color: Color(hex: "C6A24D"), hexColor: "C6A24D", description: "Bright, zesty, uplifting", icon: "sun.max"),
    OlfactoryFamily(id: "floral", label: "Floral", color: Color(hex: "B5647A"), hexColor: "B5647A", description: "Soft, romantic, blooming", icon: "leaf"),
    OlfactoryFamily(id: "fruity", label: "Fruity", color: Color(hex: "E07B5A"), hexColor: "E07B5A", description: "Juicy, playful, vibrant", icon: "applelogo"),
    OlfactoryFamily(id: "woody", label: "Woody", color: Color(hex: "8A6A45"), hexColor: "8A6A45", description: "Warm, grounded, timeless", icon: "tree"),
    OlfactoryFamily(id: "oriental", label: "Oriental", color: Color(hex: "8B3A46"), hexColor: "8B3A46", description: "Rich, sensual, statement", icon: "flame"),
    OlfactoryFamily(id: "aquatic", label: "Aquatic", color: Color(hex: "5E8B8A"), hexColor: "5E8B8A", description: "Clean, airy, effortless", icon: "drop"),
    OlfactoryFamily(id: "gourmand", label: "Gourmand", color: Color(hex: "A6693B"), hexColor: "A6693B", description: "Sweet, cozy, edible warmth", icon: "cup.and.saucer"),
    OlfactoryFamily(id: "fougere", label: "Fougère", color: Color(hex: "6F8767"), hexColor: "6F8767", description: "Herbal, crisp, classic", icon: "leaf.arrow.triangle.circlepath"),
    OlfactoryFamily(id: "leather", label: "Leather", color: Color(hex: "5C3D2E"), hexColor: "5C3D2E", description: "Dark, powerful, sensual", icon: "shield"),
    OlfactoryFamily(id: "musk", label: "Musk", color: Color(hex: "9B8B7E"), hexColor: "9B8B7E", description: "Skin-like, intimate, smooth", icon: "sparkle"),
    OlfactoryFamily(id: "spicy", label: "Spicy", color: Color(hex: "C44536"), hexColor: "C44536", description: "Fiery, warm, invigorating", icon: "flame.fill"),
]

// MARK: - Fragrance

struct Fragrance: Identifiable, Hashable, Codable {
    var id: String { "\(house)-\(name)" }
    let name: String
    let house: String
    let family: String
    let tier: Int  // 1 = Everyday ($25–60), 2 = Mid-range ($60–150), 3 = Premium ($150–300), 4 = Luxury/Niche ($300+)
    let priceUSD: Int  // approximate retail in USD
    let gender: String
    let topNotes: String
    let heartNotes: String
    let baseNotes: String
    let longevity: String
    let sillage: String
    let occasion: String
    let season: String
    let yearReleased: Int?
    let bottleShape: String?  // "round", "square", "stylish"
    let region: String?       // "global", "india", "dubai", etc. nil = global
    var score: Double = 0
    
    enum CodingKeys: String, CodingKey {
        case name, house, family, tier, priceUSD, gender
        case topNotes, heartNotes, baseNotes
        case longevity, sillage, occasion, season, yearReleased
        case bottleShape, region
    }
    
    // Hashable conformance (exclude score which is computed)
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(house)
    }
    
    static func == (lhs: Fragrance, rhs: Fragrance) -> Bool {
        lhs.name == rhs.name && lhs.house == rhs.house
    }
}

// MARK: - Catalog Wrapper (for JSON structure)

struct FragranceCatalog: Codable {
    let version: String
    let lastUpdated: String
    let totalEntries: Int
    let fragrances: [Fragrance]
}

// MARK: - Catalog Loader
// Loads catalog from bundled catalog.json resource file.
// Structured as a separate JSON so it can be updated without touching app logic.

enum CatalogLoader {
    static var catalog: [Fragrance] = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let wrapper = try? JSONDecoder().decode(FragranceCatalog.self, from: data) else {
            print("⚠️ Failed to load catalog.json — falling back to empty catalog")
            return []
        }
        return wrapper.fragrances
    }()
}

// Global accessor for backward compatibility
var catalog: [Fragrance] { CatalogLoader.catalog }

// MARK: - Personality Question

struct PersonalityQuestion: Identifiable {
    let id: String
    let text: String
    let subtitle: String
    let options: [QuestionOption]
}

struct QuestionOption: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let axis: String
    let value: Double
}

let personalityQuestions: [PersonalityQuestion] = [
    PersonalityQuestion(
        id: "q1",
        text: "When you walk into a room, what happens?",
        subtitle: "Presence",
        options: [
            QuestionOption(label: "Heads turn", axis: "boldness", value: 1),
            QuestionOption(label: "A few people notice", axis: "boldness", value: 0.6),
            QuestionOption(label: "I arrive unnoticed — and I like it that way", axis: "boldness", value: 0.2),
        ]
    ),
    PersonalityQuestion(
        id: "q2",
        text: "Your ideal evening looks like…",
        subtitle: "Energy",
        options: [
            QuestionOption(label: "Just me, or one person I trust", axis: "extroversion", value: 0),
            QuestionOption(label: "A small dinner with close friends", axis: "extroversion", value: 0.4),
            QuestionOption(label: "A crowded room with music and strangers", axis: "extroversion", value: 1),
        ]
    ),
    PersonalityQuestion(
        id: "q3",
        text: "Which closet is yours?",
        subtitle: "Aesthetic",
        options: [
            QuestionOption(label: "Muted tones, clean lines, nothing loud", axis: "experimental", value: 0.2),
            QuestionOption(label: "Color, texture, things nobody else would wear", axis: "experimental", value: 0.9),
            QuestionOption(label: "All black. Always.", axis: "boldness", value: 0.8),
        ]
    ),
    PersonalityQuestion(
        id: "q4",
        text: "Something you've never tried before — your first instinct?",
        subtitle: "Openness",
        options: [
            QuestionOption(label: "I'd rather stick with what I know works", axis: "experimental", value: 0),
            QuestionOption(label: "Curious, but I'll research it first", axis: "experimental", value: 0.5),
            QuestionOption(label: "Already doing it", axis: "experimental", value: 1),
        ]
    ),
]

// MARK: - User Profile

struct UserProfile {
    var name: String = ""
    var climate: String = ""
    var location: String = ""
    var age: String = ""
    var skin: String = ""
    var styling: String = ""
    var work: String = ""
    var budget: String = ""
    var genderPref: String = ""
    var season: String = ""
    var occasion: String = ""
    var currency: String = "USD"
    
    // Essence profile (DOB-only numerology)
    var birthDate: Date?
    
    // Preferences
    var era: String = ""       // "classic", "new", "both"
    var mood: String = ""      // "energetic", "cool", "relaxed", "focused", "love"
    
    // Live weather data (fetched when city/country is entered)
    var currentWeather: WeatherData?
    
    var isComplete: Bool {
        !climate.isEmpty && !age.isEmpty && !skin.isEmpty && !styling.isEmpty && !work.isEmpty &&
        !budget.isEmpty && !genderPref.isEmpty && !mood.isEmpty && !era.isEmpty
    }
}

// MARK: - Element Scent Profile

/// Defines the scent personality for each zodiac element (Fire, Earth, Air, Water).
/// Used in the Profile Web to show how the user's element shapes their fragrance identity.
struct ElementScentProfile {
    let element: String
    let icon: String
    let color: String       // hex color
    let traits: [String]    // 2–3 personality keywords
    let scentCharacter: String  // what kind of perfumes suit this element
    let noteFocus: String       // which note layer dominates (top, heart, base, all)
    let families: [String]      // primary olfactory families
    let occasion: String        // best-fit occasion/context
    let signatureNotes: [String]  // fixed example notes for this element
}

// MARK: - Essence Profile (DOB-only Numerology)

struct EssenceProfile {
    let lifePathNumber: Int
    let lifePathIsmaster: Bool
    let zodiacSign: ZodiacSign
    /// The combined scent-family leaning from numerology + zodiac
    let scentLeaning: String
    let lifePathTrait: NumerologyTrait
    
    /// Simplified initializer using only birth date (Life Path number only)
    static func fromDate(_ date: Date) -> EssenceProfile {
        let lifePathNum = ChaldeanNumerology.lifePathNumber(from: date)
        let zodiac = ZodiacSign.from(date: date)
        let lifePathTrait = ChaldeanNumerology.trait(for: lifePathNum)
        
        // Use life path as the sole numerology signal
        let zodiacFamily = zodiac.scentFamily
        let scentLeaning: String
        if lifePathTrait.scentFamily == zodiacFamily {
            scentLeaning = lifePathTrait.scentFamily
        } else {
            scentLeaning = lifePathTrait.scentFamily
        }
        
        return EssenceProfile(
            lifePathNumber: lifePathNum,
            lifePathIsmaster: lifePathNum == 11 || lifePathNum == 22,
            zodiacSign: zodiac,
            scentLeaning: scentLeaning,
            lifePathTrait: lifePathTrait
        )
    }
}

struct NumerologyTrait {
    let number: Int
    let isMaster: Bool
    let description: String
    let scentFamily: String
    let signatureNotes: [String]  // fixed example notes for this number
}

// MARK: - Chaldean Numerology

enum ChaldeanNumerology {
    /// Chaldean letter-to-number mapping (no letter maps to 9)
    static func letterValue(_ char: Character) -> Int {
        switch char.uppercased().first ?? " " {
        case "A", "I", "J", "Q", "Y": return 1
        case "B", "K", "R": return 2
        case "C", "G", "L", "S": return 3
        case "D", "M", "T": return 4
        case "E", "H", "N", "X": return 5
        case "U", "V", "W": return 6
        case "O", "Z": return 7
        case "F", "P": return 8
        default: return 0
        }
    }
    
    /// Reduce a number to single digit, preserving master numbers 11 and 22
    static func reduce(_ n: Int) -> Int {
        var value = n
        while value > 9 && value != 11 && value != 22 {
            value = digitSum(value)
        }
        return value
    }
    
    private static func digitSum(_ n: Int) -> Int {
        var sum = 0
        var val = n
        while val > 0 {
            sum += val % 10
            val /= 10
        }
        return sum
    }
    
    /// Life Path Number from birth date — uses only the birth DAY digit sum
    static func lifePathNumber(from date: Date) -> Int {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return reduce(day)
    }
    
    /// Trait description and scent-family leaning for each number
    static func trait(for number: Int) -> NumerologyTrait {
        let isMaster = number == 11 || number == 22
        switch number {
        case 1:
            return NumerologyTrait(number: 1, isMaster: false, description: "Independent, pioneering, charismatic", scentFamily: "woody", signatureNotes: ["Cedar", "Vetiver", "Sandalwood"])
        case 2:
            return NumerologyTrait(number: 2, isMaster: false, description: "Nurturing, emotional, attached", scentFamily: "floral", signatureNotes: ["Rose", "Peony", "Jasmine"])
        case 3:
            return NumerologyTrait(number: 3, isMaster: false, description: "Optimistic, knowledgeable, goal oriented", scentFamily: "fruity", signatureNotes: ["Peach", "Pear", "Raspberry"])
        case 4:
            return NumerologyTrait(number: 4, isMaster: false, description: "Logical, organized, ambitious", scentFamily: "fougere", signatureNotes: ["Lavender", "Oakmoss", "Coumarin"])
        case 5:
            return NumerologyTrait(number: 5, isMaster: false, description: "Adventurous, dynamic, communicators", scentFamily: "spicy", signatureNotes: ["Pink pepper", "Cardamom", "Ginger"])
        case 6:
            return NumerologyTrait(number: 6, isMaster: false, description: "Creative, worldly, compassionate", scentFamily: "gourmand", signatureNotes: ["Vanilla", "Tonka bean", "Caramel"])
        case 7:
            return NumerologyTrait(number: 7, isMaster: false, description: "Introspective, mystical, analytical", scentFamily: "oriental", signatureNotes: ["Incense", "Amber", "Myrrh"])
        case 8:
            return NumerologyTrait(number: 8, isMaster: false, description: "Disciplined, balanced, hard working", scentFamily: "leather", signatureNotes: ["Suede", "Birch tar", "Oud"])
        case 9:
            return NumerologyTrait(number: 9, isMaster: false, description: "Humanitarian, passion driven, task masters", scentFamily: "spicy", signatureNotes: ["Saffron", "Cinnamon", "Black pepper"])
        case 11:
            return NumerologyTrait(number: 11, isMaster: true, description: "Visionary, leadership, emotional", scentFamily: "oriental", signatureNotes: ["Frankincense", "Amber", "Oud"])
        case 22:
            return NumerologyTrait(number: 22, isMaster: true, description: "Master builder, ambitious dreamer, transformative", scentFamily: "leather", signatureNotes: ["Leather accord", "Tobacco", "Dark wood"])
        default:
            return NumerologyTrait(number: number, isMaster: false, description: "Balanced", scentFamily: "musk", signatureNotes: ["White musk", "Amber"])
        }
    }
}

// MARK: - Zodiac

enum ZodiacSign: String, CaseIterable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var element: String {
        switch self {
        case .aries, .leo, .sagittarius: return "Fire"
        case .taurus, .virgo, .capricorn: return "Earth"
        case .gemini, .libra, .aquarius: return "Air"
        case .cancer, .scorpio, .pisces: return "Water"
        }
    }
    
    /// Element-based scent personality: defines the fragrance character for each zodiac element.
    var elementScentProfile: ElementScentProfile {
        switch element {
        case "Fire":
            return ElementScentProfile(
                element: "Fire",
                icon: "flame.fill",
                color: "C44536",
                traits: ["Bold", "Energetic", "Spontaneous"],
                scentCharacter: "Heavy, statement perfumes with commanding top notes",
                noteFocus: "Top notes — first impression, immediate impact",
                families: ["spicy", "oriental", "leather"],
                occasion: "Night out, first dates, high-energy events",
                signatureNotes: ["Black pepper", "Cinnamon", "Saffron", "Oud", "Tobacco"]
            )
        case "Earth":
            return ElementScentProfile(
                element: "Earth",
                icon: "mountain.2.fill",
                color: "8A6A45",
                traits: ["Practical", "Luxury-worthy", "Customized"],
                scentCharacter: "Refined base-heavy perfumes that reward patience",
                noteFocus: "Base notes — lasting presence, skin-close signature",
                families: ["woody", "gourmand", "musk"],
                occasion: "Evening events, special occasions, curated experiences",
                signatureNotes: ["Sandalwood", "Vetiver", "Vanilla", "Amber", "Tonka bean"]
            )
        case "Air":
            return ElementScentProfile(
                element: "Air",
                icon: "wind",
                color: "5E8B8A",
                traits: ["Logical", "Balanced", "Justified"],
                scentCharacter: "Well-structured perfumes with harmony across all note layers",
                noteFocus: "All three layers — balanced top, heart, and base",
                families: ["fougere", "citrus", "floral"],
                occasion: "Wardrobe-aligned, work-ready, versatile daily wear",
                signatureNotes: ["Bergamot", "Lavender", "Jasmine", "Cedar", "White musk"]
            )
        case "Water":
            return ElementScentProfile(
                element: "Water",
                icon: "drop.fill",
                color: "4A7C8A",
                traits: ["Fresh", "Herbal", "Memory-driven"],
                scentCharacter: "Intimate, aquatic scents that evoke emotion and closeness",
                noteFocus: "Top notes — discovered by those near you, close-range presence",
                families: ["aquatic", "fruity", "floral"],
                occasion: "Close friends, intimate settings, personal rituals",
                signatureNotes: ["Sea salt", "Green tea", "Lotus", "Cucumber", "White iris"]
            )
        default:
            return ElementScentProfile(
                element: element,
                icon: "sparkle",
                color: "9B8B7E",
                traits: ["Balanced"],
                scentCharacter: "A balanced scent profile",
                noteFocus: "All layers",
                families: ["musk"],
                occasion: "Everyday",
                signatureNotes: ["Musk", "Amber"]
            )
        }
    }
    
    var rulingPlanet: String {
        switch self {
        case .aries: return "Mars"
        case .taurus: return "Venus"
        case .gemini: return "Mercury"
        case .cancer: return "Moon"
        case .leo: return "Sun"
        case .virgo: return "Mercury"
        case .libra: return "Venus"
        case .scorpio: return "Pluto"
        case .sagittarius: return "Jupiter"
        case .capricorn: return "Saturn"
        case .aquarius: return "Uranus"
        case .pisces: return "Neptune"
        }
    }
    
    var traitKeywords: [String] {
        switch self {
        case .aries: return ["bold", "energetic", "direct"]
        case .taurus: return ["sensual", "grounded", "luxurious"]
        case .gemini: return ["curious", "versatile", "witty"]
        case .cancer: return ["nurturing", "intuitive", "cozy"]
        case .leo: return ["dramatic", "confident", "warm"]
        case .virgo: return ["refined", "precise", "understated"]
        case .libra: return ["elegant", "harmonious", "charming"]
        case .scorpio: return ["intense", "magnetic", "deep"]
        case .sagittarius: return ["adventurous", "optimistic", "free"]
        case .capricorn: return ["ambitious", "classic", "structured"]
        case .aquarius: return ["unconventional", "original", "cool"]
        case .pisces: return ["dreamy", "ethereal", "romantic"]
        }
    }
    
    var scentFamily: String {
        switch self {
        case .aries: return "spicy"
        case .taurus: return "floral"
        case .gemini: return "citrus"
        case .cancer: return "gourmand"
        case .leo: return "spicy"
        case .virgo: return "fougere"
        case .libra: return "floral"
        case .scorpio: return "leather"
        case .sagittarius: return "woody"
        case .capricorn: return "woody"
        case .aquarius: return "aquatic"
        case .pisces: return "aquatic"
        }
    }
    
    var symbol: String {
        switch self {
        case .aries: return "♈︎"
        case .taurus: return "♉︎"
        case .gemini: return "♊︎"
        case .cancer: return "♋︎"
        case .leo: return "♌︎"
        case .virgo: return "♍︎"
        case .libra: return "♎︎"
        case .scorpio: return "♏︎"
        case .sagittarius: return "♐︎"
        case .capricorn: return "♑︎"
        case .aquarius: return "♒︎"
        case .pisces: return "♓︎"
        }
    }
    
    static func from(date: Date) -> ZodiacSign {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        switch (month, day) {
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...20): return .gemini
        case (6, 21...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...22): return .libra
        case (10, 23...31), (11, 1...21): return .scorpio
        case (11, 22...30), (12, 1...21): return .sagittarius
        case (12, 22...31), (1, 1...19): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        case (2, 19...29), (3, 1...20): return .pisces
        default: return .capricorn // Dec 22–31 fallback
        }
    }
}

// MARK: - Essence Profile Builder

// MARK: - Personality Traits

struct PersonalityTraits {
    var boldness: Double = 0.5
    var experimental: Double = 0.5
    var extroversion: Double = 0.5
    var warmth: Double = 0.5
}

// MARK: - Currency Support

struct CurrencyInfo: Identifiable, Hashable {
    let id: String  // code e.g. "USD"
    let symbol: String
    let name: String
    let rateFromUSD: Double  // multiply USD by this to get local price
}

// Approximate exchange rates (static, for display purposes)
// NOTE: These are approximate and should be updated periodically
let supportedCurrencies: [CurrencyInfo] = [
    CurrencyInfo(id: "USD", symbol: "$", name: "US Dollar", rateFromUSD: 1.0),
    CurrencyInfo(id: "EUR", symbol: "€", name: "Euro", rateFromUSD: 0.92),
    CurrencyInfo(id: "GBP", symbol: "£", name: "British Pound", rateFromUSD: 0.79),
    CurrencyInfo(id: "INR", symbol: "₹", name: "Indian Rupee", rateFromUSD: 83.5),
    CurrencyInfo(id: "JPY", symbol: "¥", name: "Japanese Yen", rateFromUSD: 149.0),
    CurrencyInfo(id: "CNY", symbol: "¥", name: "Chinese Yuan", rateFromUSD: 7.25),
    CurrencyInfo(id: "AUD", symbol: "A$", name: "Australian Dollar", rateFromUSD: 1.53),
    CurrencyInfo(id: "CAD", symbol: "C$", name: "Canadian Dollar", rateFromUSD: 1.36),
    CurrencyInfo(id: "CHF", symbol: "Fr", name: "Swiss Franc", rateFromUSD: 0.88),
    CurrencyInfo(id: "AED", symbol: "د.إ", name: "UAE Dirham", rateFromUSD: 3.67),
    CurrencyInfo(id: "SAR", symbol: "﷼", name: "Saudi Riyal", rateFromUSD: 3.75),
    CurrencyInfo(id: "SGD", symbol: "S$", name: "Singapore Dollar", rateFromUSD: 1.34),
    CurrencyInfo(id: "HKD", symbol: "HK$", name: "Hong Kong Dollar", rateFromUSD: 7.82),
    CurrencyInfo(id: "KRW", symbol: "₩", name: "South Korean Won", rateFromUSD: 1320.0),
    CurrencyInfo(id: "BRL", symbol: "R$", name: "Brazilian Real", rateFromUSD: 4.97),
    CurrencyInfo(id: "MXN", symbol: "MX$", name: "Mexican Peso", rateFromUSD: 17.15),
    CurrencyInfo(id: "ZAR", symbol: "R", name: "South African Rand", rateFromUSD: 18.6),
    CurrencyInfo(id: "SEK", symbol: "kr", name: "Swedish Krona", rateFromUSD: 10.45),
    CurrencyInfo(id: "NOK", symbol: "kr", name: "Norwegian Krone", rateFromUSD: 10.7),
    CurrencyInfo(id: "DKK", symbol: "kr", name: "Danish Krone", rateFromUSD: 6.88),
    CurrencyInfo(id: "PLN", symbol: "zł", name: "Polish Zloty", rateFromUSD: 4.02),
    CurrencyInfo(id: "THB", symbol: "฿", name: "Thai Baht", rateFromUSD: 35.5),
    CurrencyInfo(id: "MYR", symbol: "RM", name: "Malaysian Ringgit", rateFromUSD: 4.65),
    CurrencyInfo(id: "PHP", symbol: "₱", name: "Philippine Peso", rateFromUSD: 56.0),
    CurrencyInfo(id: "IDR", symbol: "Rp", name: "Indonesian Rupiah", rateFromUSD: 15700.0),
    CurrencyInfo(id: "TRY", symbol: "₺", name: "Turkish Lira", rateFromUSD: 32.0),
    CurrencyInfo(id: "RUB", symbol: "₽", name: "Russian Ruble", rateFromUSD: 92.0),
    CurrencyInfo(id: "NGN", symbol: "₦", name: "Nigerian Naira", rateFromUSD: 1550.0),
    CurrencyInfo(id: "EGP", symbol: "E£", name: "Egyptian Pound", rateFromUSD: 48.5),
    CurrencyInfo(id: "PKR", symbol: "₨", name: "Pakistani Rupee", rateFromUSD: 278.0),
    CurrencyInfo(id: "NZD", symbol: "NZ$", name: "New Zealand Dollar", rateFromUSD: 1.65),
]

enum CurrencyConverter {
    static func convert(usd: Int, to currencyCode: String) -> String {
        guard let currency = supportedCurrencies.first(where: { $0.id == currencyCode }) else {
            return "$\(usd)"
        }
        let converted = Double(usd) * currency.rateFromUSD
        // Format based on magnitude
        if converted >= 10000 {
            let rounded = Int(converted / 100) * 100  // round to nearest 100
            return "\(currency.symbol)\(formatNumber(rounded))"
        } else if converted >= 1000 {
            let rounded = Int(converted / 10) * 10  // round to nearest 10
            return "\(currency.symbol)\(formatNumber(rounded))"
        } else {
            return "\(currency.symbol)\(Int(converted.rounded()))"
        }
    }
    
    static func budgetRange(tier: Int, currencyCode: String) -> String {
        guard let currency = supportedCurrencies.first(where: { $0.id == currencyCode }) else {
            return tierRangeUSD(tier)
        }
        let ranges: [(Int, Int)] = [(25, 60), (60, 150), (150, 300), (300, 600)]
        guard tier >= 1 && tier <= 4 else { return "" }
        let (low, high) = ranges[tier - 1]
        let lowConverted = Int((Double(low) * currency.rateFromUSD).rounded())
        let highConverted = Int((Double(high) * currency.rateFromUSD).rounded())
        
        if tier == 4 {
            return "\(currency.symbol)\(formatNumber(lowConverted))+"
        }
        return "\(currency.symbol)\(formatNumber(lowConverted))–\(formatNumber(highConverted))"
    }
    
    private static func tierRangeUSD(_ tier: Int) -> String {
        switch tier {
        case 1: return "$25–60"
        case 2: return "$60–150"
        case 3: return "$150–300"
        case 4: return "$300+"
        default: return ""
        }
    }
    
    private static func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}


// MARK: - Climate Classification

enum ClimateClassification: String, CaseIterable, Codable {
    case hot, cold, temperate, humid, dry
}

// MARK: - Factor Weights

struct FactorWeights {
    var personality: Double = 0.90  // Combined: Element + Essence Number + Personality (the 3 core dimensions)
    var climate: Double = 0.05     // Minor nudge only
    var workStyle: Double = 0.03   // Minor nudge only
    var age: Double = 0.02         // Minor nudge only
    
    /// Redistributes missing dimensions' weight equally among present dimensions.
    /// At least one dimension must be present.
    func effective(
        hasPersonality: Bool = true,
        hasClimate: Bool = true,
        hasWorkStyle: Bool = true,
        hasAge: Bool = true
    ) -> FactorWeights {
        let dimensions: [(present: Bool, weight: Double)] = [
            (hasPersonality, personality),
            (hasClimate, climate),
            (hasWorkStyle, workStyle),
            (hasAge, age)
        ]
        
        let presentCount = dimensions.filter(\.present).count
        guard presentCount > 0 else { return self }
        
        let absentWeight = dimensions.filter { !$0.present }.reduce(0.0) { $0 + $1.weight }
        let redistribution = absentWeight / Double(presentCount)
        
        return FactorWeights(
            personality: hasPersonality ? personality + redistribution : 0.0,
            climate: hasClimate ? climate + redistribution : 0.0,
            workStyle: hasWorkStyle ? workStyle + redistribution : 0.0,
            age: hasAge ? age + redistribution : 0.0
        )
    }
}

// MARK: - Scoring Output Models

struct FamilyScore {
    let familyId: String
    let rawScore: Double
    let normalizedScore: Double  // 0–100 where max = 100
    let dimensionContributions: DimensionContributions
}

struct DimensionContributions {
    let personality: Double
    let climate: Double
    let workStyle: Double
    let age: Double
}

// MARK: - Recommendation Explanation

struct RecommendationExplanation {
    let text: String  // 1–3 sentences, plain language, no scores
}
