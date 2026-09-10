import Foundation

// MARK: - Scoring Validation

enum ScoringValidationError: Error {
    case invalidBudget(String)
    case invalidFragranceLean(String)
}

// MARK: - Scoring Engine

struct ScoringEngine {
    
    static let validBudgets: Set<String> = ["1", "2", "3", "4"]
    static let validLeans: Set<String> = ["feminine", "masculine", "unisex"]
    
    /// Validates that the user profile has valid budget and fragrance lean values.
    /// Throws `ScoringValidationError` if either value is invalid.
    static func validateProfile(_ profile: UserProfile) throws {
        guard validBudgets.contains(profile.budget) else {
            throw ScoringValidationError.invalidBudget(profile.budget)
        }
        guard validLeans.contains(profile.genderPref) else {
            throw ScoringValidationError.invalidFragranceLean(profile.genderPref)
        }
    }
    
    static func scoreFamilies(profile: UserProfile, traits: PersonalityTraits, essenceProfile: EssenceProfile? = nil) -> [String: Double] {
        var s: [String: Double] = [:]
        for family in allFamilies {
            s[family.id] = 0
        }
        
        func add(_ key: String, _ amt: Double) {
            s[key, default: 0] += amt
        }
        
        // Climate
        switch profile.climate {
        case "hot":
            add("citrus", 3); add("aquatic", 3); add("fruity", 2); add("gourmand", -2); add("musk", 1); add("spicy", -1)
        case "cold":
            add("woody", 3); add("oriental", 3); add("gourmand", 2); add("leather", 2); add("spicy", 2)
        case "temperate":
            add("floral", 2); add("fougere", 2); add("fruity", 1); add("musk", 1); add("spicy", 1)
        case "humid":
            add("aquatic", 3); add("citrus", 2); add("fruity", 1); add("oriental", -2); add("gourmand", -1); add("spicy", -1)
        case "dry":
            add("woody", 2); add("oriental", 1); add("leather", 1); add("spicy", 2)
        default: break
        }
        
        // Skin type
        switch profile.skin {
        case "dry":
            add("oriental", 2); add("gourmand", 1); add("leather", 1)
        case "oily":
            add("citrus", 1); add("aquatic", 1); add("fruity", 1); add("fougere", 1)
        case "combination":
            add("floral", 1); add("fruity", 1); add("musk", 1)
        default: break
        }
        
        // Work style
        switch profile.work {
        case "corporate":
            add("woody", 2); add("fougere", 2); add("musk", 1); add("gourmand", -2)
        case "creative":
            add("oriental", 2); add("floral", 1); add("fruity", 1); add("leather", 1); add("spicy", 1)
        case "outdoor":
            add("aquatic", 2); add("citrus", 2); add("fruity", 1); add("fougere", 1)
        case "remote":
            add("gourmand", 2); add("floral", 1); add("fruity", 1); add("musk", 2); add("spicy", 1)
        case "social":
            add("floral", 2); add("fruity", 1); add("citrus", 1); add("musk", 1); add("spicy", 1)
        default: break
        }
        
        // Styling
        switch profile.styling {
        case "classic":
            add("woody", 2); add("fougere", 1); add("musk", 1)
        case "edgy":
            add("oriental", 2); add("leather", 2); add("spicy", 2)
        case "casual":
            add("citrus", 1); add("fruity", 2); add("aquatic", 1); add("musk", 1)
        case "romantic":
            add("floral", 3); add("fruity", 2); add("gourmand", 1); add("spicy", 1)
        case "minimalist":
            add("musk", 2); add("aquatic", 1); add("woody", 1)
        default: break
        }
        
        // Season preference
        switch profile.season {
        case "spring":
            add("floral", 2); add("fruity", 2); add("citrus", 1); add("fougere", 1)
        case "summer":
            add("citrus", 2); add("fruity", 2); add("aquatic", 2)
        case "autumn":
            add("woody", 2); add("oriental", 1); add("leather", 1); add("spicy", 2)
        case "winter":
            add("oriental", 2); add("gourmand", 2); add("leather", 1); add("spicy", 2)
        default: break
        }
        
        // Occasion
        switch profile.occasion {
        case "everyday":
            add("citrus", 1); add("fruity", 1); add("musk", 2); add("aquatic", 1)
        case "office":
            add("fougere", 2); add("woody", 1); add("musk", 1)
        case "evening":
            add("oriental", 2); add("leather", 1); add("gourmand", 1); add("spicy", 2)
        case "special":
            add("oriental", 2); add("floral", 1); add("fruity", 1); add("leather", 1); add("spicy", 1)
        default: break
        }
        
        // Personality traits (0–1 scales)
        add("oriental", traits.boldness * 3)
        add("leather", traits.boldness * 2)
        add("spicy", traits.boldness * 2)
        add("aquatic", (1 - traits.boldness) * 1.5)
        add("musk", (1 - traits.boldness) * 1.5)
        
        add("gourmand", traits.experimental * 1.5)
        add("fruity", traits.experimental * 1.5)
        add("leather", traits.experimental * 1)
        add("spicy", traits.experimental * 1)
        add("fougere", (1 - traits.experimental) * 1.5)
        add("woody", (1 - traits.experimental) * 1)
        
        add("floral", traits.extroversion * 1.5)
        add("fruity", traits.extroversion * 1)
        add("citrus", traits.extroversion * 1)
        add("woody", (1 - traits.extroversion) * 1)
        add("musk", (1 - traits.extroversion) * 1)
        
        add("gourmand", traits.warmth * 2)
        add("oriental", traits.warmth * 1.5)
        add("spicy", traits.warmth * 1.5)
        add("citrus", (1 - traits.warmth) * 1)
        add("fruity", (1 - traits.warmth) * 0.5)
        add("aquatic", (1 - traits.warmth) * 1)
        
        // Essence profile — now a core part of the Essence+Personality dimension (significant weight)
        if let essence = essenceProfile {
            add(essence.scentLeaning, 4.0)
            // Element-based scent profile boost
            let elementFamilies = essence.zodiacSign.elementScentProfile.families
            for familyId in elementFamilies {
                add(familyId, 3.0)
            }
        }
        
        return s
    }
    
    // MARK: - Weighted Multi-Factor Scoring Engine
    
    /// Computes weighted multi-factor scent family scores using personality traits, climate,
    /// work style, and age dimensions. Each dimension is scored independently, then multiplied
    /// by its effective weight. The final scores are normalized to a 0–100 scale.
    ///
    /// - Parameters:
    ///   - profile: The user's profile containing climate, work, birthDate, styling, and skin data
    ///   - traits: Personality traits (boldness, experimental, extroversion, warmth) on 0–1 scales
    ///   - essenceProfile: Optional essence profile for scent leaning refinement
    ///   - weights: Factor weights for each dimension (defaults sum to 1.0)
    /// - Returns: Dictionary mapping family IDs to normalized scores (0–100, highest = 100)
    static func weightedScoreFamilies(
        profile: UserProfile,
        traits: PersonalityTraits,
        essenceProfile: EssenceProfile? = nil,
        weights: FactorWeights = FactorWeights()
    ) -> [String: Double] {
        // Determine which dimensions are available
        let hasAge = profile.birthDate != nil
        let hasClimate = !profile.climate.isEmpty
        let hasWorkStyle = !profile.work.isEmpty
        // Personality traits are always present (default to 0.5)
        let hasPersonality = true
        
        // Get effective weights with redistribution for missing dimensions
        let effectiveWeights = weights.effective(
            hasPersonality: hasPersonality,
            hasClimate: hasClimate,
            hasWorkStyle: hasWorkStyle,
            hasAge: hasAge
        )
        
        // Initialize per-dimension score dictionaries
        var personalityScores: [String: Double] = [:]
        var climateScores: [String: Double] = [:]
        var workStyleScores: [String: Double] = [:]
        var ageScores: [String: Double] = [:]
        
        for family in allFamilies {
            personalityScores[family.id] = 0
            climateScores[family.id] = 0
            workStyleScores[family.id] = 0
            ageScores[family.id] = 0
        }
        
        // --- Personality Dimension ---
        // Boldness axis
        let adjustedBoldness = traits.boldness
        personalityScores["oriental", default: 0] += adjustedBoldness * 3
        personalityScores["leather", default: 0] += adjustedBoldness * 2
        personalityScores["spicy", default: 0] += adjustedBoldness * 2
        personalityScores["aquatic", default: 0] += (1 - adjustedBoldness) * 1.5
        personalityScores["musk", default: 0] += (1 - adjustedBoldness) * 1.5
        
        // Experimental axis
        personalityScores["gourmand", default: 0] += traits.experimental * 1.5
        personalityScores["fruity", default: 0] += traits.experimental * 1.5
        personalityScores["leather", default: 0] += traits.experimental * 1
        personalityScores["spicy", default: 0] += traits.experimental * 1
        personalityScores["fougere", default: 0] += (1 - traits.experimental) * 1.5
        personalityScores["woody", default: 0] += (1 - traits.experimental) * 1
        
        // Extroversion axis
        personalityScores["floral", default: 0] += traits.extroversion * 1.5
        personalityScores["fruity", default: 0] += traits.extroversion * 1
        personalityScores["citrus", default: 0] += traits.extroversion * 1
        personalityScores["spicy", default: 0] += traits.extroversion * 0.5
        personalityScores["woody", default: 0] += (1 - traits.extroversion) * 1
        personalityScores["musk", default: 0] += (1 - traits.extroversion) * 1
        
        // Warmth axis
        personalityScores["gourmand", default: 0] += traits.warmth * 2
        personalityScores["oriental", default: 0] += traits.warmth * 1.5
        personalityScores["spicy", default: 0] += traits.warmth * 1.5
        personalityScores["citrus", default: 0] += (1 - traits.warmth) * 1
        personalityScores["fruity", default: 0] += (1 - traits.warmth) * 0.5
        personalityScores["aquatic", default: 0] += (1 - traits.warmth) * 1
        
        // Essence profile — core signal in the merged Essence+Personality dimension
        // Increased to 4.0 to reflect its 45% combined weight with personality
        if let essence = essenceProfile {
            personalityScores[essence.scentLeaning, default: 0] += 4.0
            
            // Zodiac element adds a secondary boost
            let zodiacFamily = essence.zodiacSign.scentFamily
            if zodiacFamily != essence.scentLeaning {
                personalityScores[zodiacFamily, default: 0] += 2.0
            }
            
            // Element-based scent profile boost — ties zodiac element to specific families
            let elementFamilies = essence.zodiacSign.elementScentProfile.families
            for familyId in elementFamilies {
                personalityScores[familyId, default: 0] += 3.0
            }
        }
        
        // --- Styling Preference Scoring ---
        switch profile.styling {
        case "classic":
            personalityScores["woody", default: 0] += 2
            personalityScores["fougere", default: 0] += 1
            personalityScores["musk", default: 0] += 1
        case "edgy":
            personalityScores["oriental", default: 0] += 2
            personalityScores["leather", default: 0] += 2
        case "casual":
            personalityScores["citrus", default: 0] += 1
            personalityScores["fruity", default: 0] += 2
            personalityScores["aquatic", default: 0] += 1
            personalityScores["musk", default: 0] += 1
        case "romantic":
            personalityScores["floral", default: 0] += 3
            personalityScores["fruity", default: 0] += 2
            personalityScores["gourmand", default: 0] += 1
        case "minimalist":
            personalityScores["musk", default: 0] += 2
            personalityScores["aquatic", default: 0] += 1
            personalityScores["woody", default: 0] += 1
        default: break
        }
        
        // --- Climate Dimension ---
        if hasClimate {
            switch profile.climate {
            case "hot":
                climateScores["citrus", default: 0] += 3
                climateScores["aquatic", default: 0] += 3
                climateScores["fruity", default: 0] += 2
                climateScores["gourmand", default: 0] += -2
                climateScores["musk", default: 0] += 1
                climateScores["spicy", default: 0] += -1
            case "cold":
                climateScores["woody", default: 0] += 3
                climateScores["oriental", default: 0] += 3
                climateScores["gourmand", default: 0] += 2
                climateScores["leather", default: 0] += 2
                climateScores["spicy", default: 0] += 2
            case "temperate":
                climateScores["floral", default: 0] += 2
                climateScores["fougere", default: 0] += 2
                climateScores["fruity", default: 0] += 1
                climateScores["musk", default: 0] += 1
                climateScores["spicy", default: 0] += 1
            case "humid":
                climateScores["aquatic", default: 0] += 3
                climateScores["citrus", default: 0] += 2
                climateScores["fruity", default: 0] += 1
                climateScores["oriental", default: 0] += -2
                climateScores["gourmand", default: 0] += -1
                climateScores["spicy", default: 0] += -1
            case "dry":
                climateScores["woody", default: 0] += 2
                climateScores["oriental", default: 0] += 1
                climateScores["leather", default: 0] += 1
                climateScores["spicy", default: 0] += 2
            default: break
            }
            
            // --- Live Weather Adjustments (Humidity + Temperature) ---
            // High humidity amplifies top notes — boost top-note-forward families
            // Low humidity causes faster evaporation of top notes — favor base-heavy families
            if let weather = profile.currentWeather {
                // Humidity adjustments
                if weather.isHighHumidity {
                    // High humidity (>65%): top notes project stronger and last longer
                    climateScores["citrus", default: 0] += 3
                    climateScores["fruity", default: 0] += 2
                    climateScores["aquatic", default: 0] += 2
                    climateScores["floral", default: 0] += 1
                    // Heavy/dense scents feel cloying in high humidity
                    climateScores["oriental", default: 0] += -1
                    climateScores["gourmand", default: 0] += -1
                } else if weather.isLowHumidity {
                    // Low humidity (<40%): top notes vanish fast, base notes linger
                    climateScores["oriental", default: 0] += 2
                    climateScores["woody", default: 0] += 2
                    climateScores["leather", default: 0] += 1
                    climateScores["gourmand", default: 0] += 1
                    climateScores["musk", default: 0] += 1
                }
                // Moderate humidity (40–65%): no extra adjustment — base climate scoring is enough
                
                // Temperature fine-tuning (supplements the broad climate classification)
                if weather.temperature >= 35 {
                    // Extreme heat: strongly favor light, fresh scents
                    climateScores["citrus", default: 0] += 2
                    climateScores["aquatic", default: 0] += 2
                    climateScores["gourmand", default: 0] += -2
                    climateScores["leather", default: 0] += -1
                } else if weather.temperature <= 5 {
                    // Very cold: warm, enveloping scents shine
                    climateScores["oriental", default: 0] += 2
                    climateScores["gourmand", default: 0] += 2
                    climateScores["spicy", default: 0] += 1
                    climateScores["woody", default: 0] += 1
                }
            }
        }
        
        // --- Work Style Dimension ---
        if hasWorkStyle {
            switch profile.work {
            case "corporate":
                workStyleScores["woody", default: 0] += 2
                workStyleScores["fougere", default: 0] += 2
                workStyleScores["musk", default: 0] += 1
                workStyleScores["gourmand", default: 0] += -2
            case "creative":
                workStyleScores["oriental", default: 0] += 2
                workStyleScores["floral", default: 0] += 1
                workStyleScores["fruity", default: 0] += 1
                workStyleScores["leather", default: 0] += 1
                workStyleScores["spicy", default: 0] += 1
            case "outdoor":
                workStyleScores["aquatic", default: 0] += 2
                workStyleScores["citrus", default: 0] += 2
                workStyleScores["fruity", default: 0] += 1
                workStyleScores["fougere", default: 0] += 1
            case "remote":
                workStyleScores["gourmand", default: 0] += 2
                workStyleScores["floral", default: 0] += 1
                workStyleScores["fruity", default: 0] += 1
                workStyleScores["musk", default: 0] += 2
                workStyleScores["spicy", default: 0] += 1
            case "social":
                workStyleScores["floral", default: 0] += 2
                workStyleScores["fruity", default: 0] += 1
                workStyleScores["citrus", default: 0] += 1
                workStyleScores["musk", default: 0] += 1
                workStyleScores["spicy", default: 0] += 1
            default: break
            }
        }
        
        // --- Age Dimension ---
        if hasAge, let birthDate = profile.birthDate {
            let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
            let age = ageComponents.year ?? 0
            if age >= 18 && age <= 29 {
                // Young bracket: boost citrus, aquatic, fruity
                ageScores["citrus", default: 0] += 3
                ageScores["aquatic", default: 0] += 2
                ageScores["fruity", default: 0] += 2
                ageScores["spicy", default: 0] += 1
            } else if age >= 30 && age <= 45 {
                // Middle bracket: boost floral, fougere, woody
                ageScores["floral", default: 0] += 2
                ageScores["fougere", default: 0] += 2
                ageScores["woody", default: 0] += 3
                ageScores["spicy", default: 0] += 2
            } else if age >= 46 {
                // Mature bracket: boost oriental, leather, gourmand
                ageScores["oriental", default: 0] += 3
                ageScores["leather", default: 0] += 2
                ageScores["gourmand", default: 0] += 2
                ageScores["spicy", default: 0] += 2
            }
            // Ages < 18 get no age-based boost
        }
        
        // --- Combine dimensions with weights ---
        var finalScores: [String: Double] = [:]
        for family in allFamilies {
            let familyId = family.id
            let personalityContribution = (personalityScores[familyId] ?? 0) * effectiveWeights.personality
            let climateContribution = (climateScores[familyId] ?? 0) * effectiveWeights.climate
            let workStyleContribution = (workStyleScores[familyId] ?? 0) * effectiveWeights.workStyle
            let ageContribution = (ageScores[familyId] ?? 0) * effectiveWeights.age
            
            finalScores[familyId] = personalityContribution + climateContribution + workStyleContribution + ageContribution
        }
        
        // --- Normalize to 0–100 scale (highest = 100, others proportional) ---
        let maxScore = finalScores.values.max() ?? 0
        if maxScore > 0 {
            for (familyId, score) in finalScores {
                finalScores[familyId] = (score / maxScore) * 100.0
            }
        }
        
        // Clamp any negative values to 0 (can happen from negative climate penalties)
        for (familyId, score) in finalScores {
            if score < 0 {
                finalScores[familyId] = 0
            }
        }
        
        return finalScores
    }
    
    /// Computes per-dimension contribution values for a specific scent family.
    /// Uses the same scoring logic as `weightedScoreFamilies` but returns individual
    /// dimension scores for use in recommendation explanations.
    static func dimensionContributions(
        for familyId: String,
        profile: UserProfile,
        traits: PersonalityTraits,
        essenceProfile: EssenceProfile? = nil,
        weights: FactorWeights = FactorWeights()
    ) -> DimensionContributions {
        let hasAge = profile.birthDate != nil
        let hasClimate = !profile.climate.isEmpty
        let hasWorkStyle = !profile.work.isEmpty
        let hasPersonality = true
        
        let effectiveWeights = weights.effective(
            hasPersonality: hasPersonality,
            hasClimate: hasClimate,
            hasWorkStyle: hasWorkStyle,
            hasAge: hasAge
        )
        
        // --- Personality ---
        var personalityScore: Double = 0
        
        let adjustedBoldness = traits.boldness
        
        // Boldness axis
        switch familyId {
        case "oriental": personalityScore += adjustedBoldness * 3
        case "leather": personalityScore += adjustedBoldness * 2
        case "spicy": personalityScore += adjustedBoldness * 2
        case "aquatic": personalityScore += (1 - adjustedBoldness) * 1.5
        case "musk": personalityScore += (1 - adjustedBoldness) * 1.5
        default: break
        }
        
        // Experimental axis
        switch familyId {
        case "gourmand": personalityScore += traits.experimental * 1.5
        case "fruity": personalityScore += traits.experimental * 1.5
        case "leather": personalityScore += traits.experimental * 1
        case "spicy": personalityScore += traits.experimental * 1
        case "fougere": personalityScore += (1 - traits.experimental) * 1.5
        case "woody": personalityScore += (1 - traits.experimental) * 1
        default: break
        }
        
        // Extroversion axis
        switch familyId {
        case "floral": personalityScore += traits.extroversion * 1.5
        case "fruity": personalityScore += traits.extroversion * 1
        case "citrus": personalityScore += traits.extroversion * 1
        case "spicy": personalityScore += traits.extroversion * 0.5
        case "woody": personalityScore += (1 - traits.extroversion) * 1
        case "musk": personalityScore += (1 - traits.extroversion) * 1
        default: break
        }
        
        // Warmth axis
        switch familyId {
        case "gourmand": personalityScore += traits.warmth * 2
        case "oriental": personalityScore += traits.warmth * 1.5
        case "spicy": personalityScore += traits.warmth * 1.5
        case "citrus": personalityScore += (1 - traits.warmth) * 1
        case "fruity": personalityScore += (1 - traits.warmth) * 0.5
        case "aquatic": personalityScore += (1 - traits.warmth) * 1
        default: break
        }
        
        // Essence — core signal in merged Essence+Personality dimension
        if let essence = essenceProfile {
            if essence.scentLeaning == familyId {
                personalityScore += 4.0
            }
            if essence.zodiacSign.scentFamily == familyId && essence.zodiacSign.scentFamily != essence.scentLeaning {
                personalityScore += 2.0
            }
            // Element-based scent profile boost
            let elementFamilies = essence.zodiacSign.elementScentProfile.families
            if elementFamilies.contains(familyId) {
                personalityScore += 3.0
            }
        }
        
        // Styling preference
        switch profile.styling {
        case "classic":
            switch familyId {
            case "woody": personalityScore += 2
            case "fougere": personalityScore += 1
            case "musk": personalityScore += 1
            default: break
            }
        case "edgy":
            switch familyId {
            case "oriental": personalityScore += 2
            case "leather": personalityScore += 2
            default: break
            }
        case "casual":
            switch familyId {
            case "citrus": personalityScore += 1
            case "fruity": personalityScore += 2
            case "aquatic": personalityScore += 1
            case "musk": personalityScore += 1
            default: break
            }
        case "romantic":
            switch familyId {
            case "floral": personalityScore += 3
            case "fruity": personalityScore += 2
            case "gourmand": personalityScore += 1
            default: break
            }
        case "minimalist":
            switch familyId {
            case "musk": personalityScore += 2
            case "aquatic": personalityScore += 1
            case "woody": personalityScore += 1
            default: break
            }
        default: break
        }
        
        // --- Climate ---
        var climateScore: Double = 0
        if hasClimate {
            switch profile.climate {
            case "hot":
                switch familyId {
                case "citrus": climateScore += 3
                case "aquatic": climateScore += 3
                case "fruity": climateScore += 2
                case "gourmand": climateScore += -2
                case "musk": climateScore += 1
                case "spicy": climateScore += -1
                default: break
                }
            case "cold":
                switch familyId {
                case "woody": climateScore += 3
                case "oriental": climateScore += 3
                case "gourmand": climateScore += 2
                case "leather": climateScore += 2
                case "spicy": climateScore += 2
                default: break
                }
            case "temperate":
                switch familyId {
                case "floral": climateScore += 2
                case "fougere": climateScore += 2
                case "fruity": climateScore += 1
                case "musk": climateScore += 1
                case "spicy": climateScore += 1
                default: break
                }
            case "humid":
                switch familyId {
                case "aquatic": climateScore += 3
                case "citrus": climateScore += 2
                case "fruity": climateScore += 1
                case "oriental": climateScore += -2
                case "gourmand": climateScore += -1
                case "spicy": climateScore += -1
                default: break
                }
            case "dry":
                switch familyId {
                case "woody": climateScore += 2
                case "oriental": climateScore += 1
                case "leather": climateScore += 1
                case "spicy": climateScore += 2
                default: break
                }
            default: break
            }
            
            // Live weather adjustments (same logic as weightedScoreFamilies)
            if let weather = profile.currentWeather {
                if weather.isHighHumidity {
                    switch familyId {
                    case "citrus": climateScore += 3
                    case "fruity": climateScore += 2
                    case "aquatic": climateScore += 2
                    case "floral": climateScore += 1
                    case "oriental": climateScore += -1
                    case "gourmand": climateScore += -1
                    default: break
                    }
                } else if weather.isLowHumidity {
                    switch familyId {
                    case "oriental": climateScore += 2
                    case "woody": climateScore += 2
                    case "leather": climateScore += 1
                    case "gourmand": climateScore += 1
                    case "musk": climateScore += 1
                    default: break
                    }
                }
                
                if weather.temperature >= 35 {
                    switch familyId {
                    case "citrus": climateScore += 2
                    case "aquatic": climateScore += 2
                    case "gourmand": climateScore += -2
                    case "leather": climateScore += -1
                    default: break
                    }
                } else if weather.temperature <= 5 {
                    switch familyId {
                    case "oriental": climateScore += 2
                    case "gourmand": climateScore += 2
                    case "spicy": climateScore += 1
                    case "woody": climateScore += 1
                    default: break
                    }
                }
            }
        }
        
        // --- Work Style ---
        var workStyleScore: Double = 0
        if hasWorkStyle {
            switch profile.work {
            case "corporate":
                switch familyId {
                case "woody": workStyleScore += 2
                case "fougere": workStyleScore += 2
                case "musk": workStyleScore += 1
                case "gourmand": workStyleScore += -2
                default: break
                }
            case "creative":
                switch familyId {
                case "oriental": workStyleScore += 2
                case "floral": workStyleScore += 1
                case "fruity": workStyleScore += 1
                case "leather": workStyleScore += 1
                case "spicy": workStyleScore += 1
                default: break
                }
            case "outdoor":
                switch familyId {
                case "aquatic": workStyleScore += 2
                case "citrus": workStyleScore += 2
                case "fruity": workStyleScore += 1
                case "fougere": workStyleScore += 1
                default: break
                }
            case "remote":
                switch familyId {
                case "gourmand": workStyleScore += 2
                case "floral": workStyleScore += 1
                case "fruity": workStyleScore += 1
                case "musk": workStyleScore += 2
                case "spicy": workStyleScore += 1
                default: break
                }
            case "social":
                switch familyId {
                case "floral": workStyleScore += 2
                case "fruity": workStyleScore += 1
                case "citrus": workStyleScore += 1
                case "musk": workStyleScore += 1
                case "spicy": workStyleScore += 1
                default: break
                }
            default: break
            }
        }
        
        // --- Age ---
        var ageScore: Double = 0
        if hasAge, let birthDate = profile.birthDate {
            let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
            let age = ageComponents.year ?? 0
            if age >= 18 && age <= 29 {
                switch familyId {
                case "citrus": ageScore += 3
                case "aquatic": ageScore += 2
                case "fruity": ageScore += 2
                case "spicy": ageScore += 1
                default: break
                }
            } else if age >= 30 && age <= 45 {
                switch familyId {
                case "floral": ageScore += 2
                case "fougere": ageScore += 2
                case "woody": ageScore += 3
                case "spicy": ageScore += 2
                default: break
                }
            } else if age >= 46 {
                switch familyId {
                case "oriental": ageScore += 3
                case "leather": ageScore += 2
                case "gourmand": ageScore += 2
                case "spicy": ageScore += 2
                default: break
                }
            }
        }
        
        // Apply weights
        let weightedPersonality = personalityScore * effectiveWeights.personality
        let weightedClimate = climateScore * effectiveWeights.climate
        let weightedWorkStyle = workStyleScore * effectiveWeights.workStyle
        let weightedAge = ageScore * effectiveWeights.age
        
        return DimensionContributions(
            personality: weightedPersonality,
            climate: weightedClimate,
            workStyle: weightedWorkStyle,
            age: weightedAge
        )
    }
    
    static func topFamilies(scores: [String: Double], count: Int = 3) -> [String] {
        return scores
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map { $0.key }
    }
    
    /// Returns exactly 2 families: primary (highest score) and secondary (second-highest).
    /// Uses alphabetical family ID as tiebreaker for second place.
    static func topTwoFamilies(scores: [String: Double]) -> (primary: String, secondary: String) {
        let sorted = scores.sorted { lhs, rhs in
            if lhs.value != rhs.value {
                return lhs.value > rhs.value
            }
            return lhs.key < rhs.key  // Alphabetical tiebreaker
        }
        
        let primary = sorted.first?.key ?? "woody"
        let secondary = sorted.dropFirst().first?.key ?? "floral"
        return (primary: primary, secondary: secondary)
    }
    
    static func matchCatalog(scores: [String: Double], profile: UserProfile) throws -> [Fragrance] {
        // Validate budget and fragrance lean before filtering
        try validateProfile(profile)
        
        var ranked = catalog.map { fragrance -> Fragrance in
            var f = fragrance
            f.score = scores[f.family] ?? 0
            return f
        }
        
        // Filter by budget (strict — no "any" fallback)
        let maxTier = Int(profile.budget) ?? 4
        ranked = ranked.filter { $0.tier <= maxTier }
        
        // Filter by gender preference (strict — no "any" fallback)
        ranked = ranked.filter { $0.gender == "unisex" || $0.gender == profile.genderPref }
        
        // Filter by era preference — thresholds based on user's birth year
        // Classic = released before (birthYear - 5 to 10 year gap), i.e. before (birthYear - 5)
        // New = released from birthYear onwards
        // Both = no filter
        if let birthDate = profile.birthDate {
            let birthYear = Calendar.current.component(.year, from: birthDate)
            let classicCutoff = birthYear - 5   // e.g. born 2004 → classic = before 1999
            let newCutoff = birthYear            // e.g. born 2004 → new = 2004 onwards
            
            switch profile.era {
            case "classic":
                ranked = ranked.filter { ($0.yearReleased ?? 2000) <= classicCutoff }
            case "new":
                ranked = ranked.filter { ($0.yearReleased ?? 2020) >= newCutoff }
            default:
                break // "both" or empty — no filter
            }
        } else {
            // No DOB — fall back to fixed thresholds
            switch profile.era {
            case "classic":
                ranked = ranked.filter { ($0.yearReleased ?? 2000) < 2010 }
            case "new":
                ranked = ranked.filter { ($0.yearReleased ?? 2020) >= 2015 }
            default:
                break
            }
        }
        
        // === LAYER 1: Brand Selection (Price + Country) ===
        let detectedCountry = CountryDetector.detect(from: profile.location)
        
        ranked = ranked.filter { fragrance in
            let region = fragrance.region ?? "global"
            return region == "global" || region == detectedCountry
        }
        
        for i in ranked.indices {
            if let region = ranked[i].region, region != "global", region == detectedCountry {
                ranked[i].score += 12
            }
        }
        
        // === LAYER 2: Perfume Selection ===
        
        // Mood-based score boost
        for i in ranked.indices {
            ranked[i].score += moodBoost(for: ranked[i], mood: profile.mood)
        }
        
        // Bottle shape boost
        let inferredShape = BottleShapeInference.infer(styling: profile.styling, work: profile.work)
        for i in ranked.indices {
            ranked[i].score += bottleShapeBoost(
                fragranceShape: ranked[i].bottleShape,
                preferredShape: inferredShape
            )
        }
        
        // --- First 5: Profile + Scent Profile (personality, work, styling, mood, age) ---
        var profileRanked = ranked
        profileRanked.sort { $0.score > $1.score }
        let top5 = Array(profileRanked.prefix(5))
        let top5Ids = Set(top5.map { $0.id })
        
        // --- Next 3: Climate-focused picks (not already in top 5) ---
        let climateFamilies = topClimateFamilies(climate: profile.climate)
        var climateRanked = ranked.filter { !top5Ids.contains($0.id) }
        // Re-score emphasizing climate family match
        for i in climateRanked.indices {
            if climateFamilies.contains(climateRanked[i].family) {
                climateRanked[i].score += 20 // strong climate-family boost
            }
        }
        climateRanked.sort { $0.score > $1.score }
        let climateTop3 = Array(climateRanked.prefix(3))
        
        return top5 + climateTop3
    }
    
    /// Returns the top scent families that match a given climate.
    private static func topClimateFamilies(climate: String) -> Set<String> {
        switch climate {
        case "hot": return ["citrus", "aquatic", "fruity"]
        case "cold": return ["woody", "oriental", "gourmand"]
        case "temperate": return ["floral", "fougere", "musk"]
        case "humid": return ["aquatic", "citrus"]
        case "dry": return ["woody", "oriental", "leather"]
        default: return []
        }
    }
    
    /// Returns a score boost for a fragrance based on the user's mood preference.
    private static func moodBoost(for fragrance: Fragrance, mood: String) -> Double {
        switch mood {
        case "energetic":
            switch fragrance.family {
            case "citrus": return 15
            case "fruity": return 10
            case "aquatic": return 8
            case "fougere": return 5
            case "spicy": return 8
            default: return 0
            }
        case "cool":
            switch fragrance.family {
            case "aquatic": return 15
            case "citrus": return 10
            case "musk": return 8
            case "fougere": return 5
            default: return 0
            }
        case "relaxed":
            switch fragrance.family {
            case "woody": return 15
            case "musk": return 12
            case "gourmand": return 10
            case "floral": return 5
            default: return 0
            }
        case "focused":
            switch fragrance.family {
            case "woody": return 15
            case "fougere": return 12
            case "citrus": return 8
            case "musk": return 5
            case "spicy": return 5
            default: return 0
            }
        case "love":
            switch fragrance.family {
            case "floral": return 15
            case "oriental": return 12
            case "gourmand": return 10
            case "fruity": return 5
            case "spicy": return 8
            default: return 0
            }
        default:
            return 0
        }
    }
    
    /// Returns a score boost when the fragrance's bottle shape matches the inferred preference.
    private static func bottleShapeBoost(fragranceShape: String?, preferredShape: String) -> Double {
        guard let shape = fragranceShape else { return 0 }
        if shape == preferredShape { return 8 }
        // Partial match — adjacent shapes
        switch (preferredShape, shape) {
        case ("round", "stylish"), ("stylish", "round"): return 3
        case ("square", "stylish"), ("stylish", "square"): return 3
        default: return 0
        }
    }
}

// MARK: - Bottle Shape Inference

/// Infers a bottle shape preference from the user's styling and work profile.
/// Round → soft, approachable, romantic presence
/// Square → structured, confident, professional presence
/// Stylish → creative, bold, expressive presence
enum BottleShapeInference {
    static func infer(styling: String, work: String) -> String {
        // Scoring: accumulate votes for each shape
        var round = 0, square = 0, stylish = 0
        
        switch styling {
        case "classic":    square += 2
        case "casual":     round += 2
        case "edgy":       stylish += 2
        case "minimalist": square += 1; round += 1
        case "romantic":   round += 2
        default: break
        }
        
        switch work {
        case "corporate":  square += 2
        case "creative":   stylish += 2
        case "outdoor":    round += 1; stylish += 1
        case "remote":     round += 2
        case "social":     stylish += 1; round += 1
        default: break
        }
        
        let max = Swift.max(round, square, stylish)
        if max == square { return "square" }
        if max == stylish { return "stylish" }
        return "round"
    }
}

// MARK: - Country Detection

/// Detects the user's country from the location string for regional brand matching.
enum CountryDetector {
    private static let countryKeywords: [(country: String, keywords: [String])] = [
        ("india", ["india", "mumbai", "delhi", "bangalore", "bengaluru", "chennai", "kolkata", "hyderabad", "pune", "ahmedabad", "jaipur", "lucknow", "kochi", "goa", "chandigarh", "noida", "gurgaon", "gurugram"]),
        ("dubai", ["dubai", "abu dhabi", "sharjah", "uae", "emirates", "ajman", "ras al", "fujairah", "al ain"]),
    ]
    
    static func detect(from location: String) -> String {
        let lower = location.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return "global" }
        
        for (country, keywords) in countryKeywords {
            for keyword in keywords {
                if lower.contains(keyword) {
                    return country
                }
            }
        }
        return "global"
    }
}

// MARK: - Trait Computation (extension of ScoringEngine)

extension ScoringEngine {
    static func computeTraits(from answers: [String: QuestionOption]) -> PersonalityTraits {
        var axes: [String: [Double]] = [
            "boldness": [],
            "experimental": [],
            "extroversion": [],
            "warmth": []
        ]
        
        for (_, option) in answers {
            axes[option.axis, default: []].append(option.value)
        }
        
        func avg(_ arr: [Double]) -> Double {
            arr.isEmpty ? 0.5 : arr.reduce(0, +) / Double(arr.count)
        }
        
        return PersonalityTraits(
            boldness: avg(axes["boldness"] ?? []),
            experimental: avg(axes["experimental"] ?? []),
            extroversion: avg(axes["extroversion"] ?? []),
            warmth: avg(axes["warmth"] ?? [])
        )
    }
}
