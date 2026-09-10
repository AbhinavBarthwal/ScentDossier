import Foundation

// MARK: - Recommendation Explanation Generator

enum RecommendationExplanationGenerator {
    
    // MARK: - Public Interface
    
    /// Generates a unique, rich narrative for each fragrance based on the user's full profile.
    /// Covers: what the perfume says about you, key notes, wardrobe pairing, occasion fit, and why it was matched.
    static func generate(
        for fragrance: Fragrance,
        scores: DimensionContributions,
        allFragrances: [Fragrance],
        traits: PersonalityTraits? = nil,
        profile: UserProfile? = nil
    ) -> RecommendationExplanation {
        let sections = [
            profileNarrative(fragrance: fragrance, traits: traits, profile: profile),
            keyNotesBreakdown(fragrance: fragrance),
            wardrobePairing(fragrance: fragrance, profile: profile),
            occasionFit(fragrance: fragrance, profile: profile),
            whyItWorks(fragrance: fragrance, scores: scores, traits: traits, profile: profile)
        ]
        
        let text = sections.filter { !$0.isEmpty }.joined(separator: " ")
        return RecommendationExplanation(text: text)
    }
    
    // MARK: - 1. Profile Narrative — What this perfume says about you
    
    private static func profileNarrative(fragrance: Fragrance, traits: PersonalityTraits?, profile: UserProfile?) -> String {
        let familyLabel = familyDisplayName(for: fragrance.family)
        let presenceWord = presenceAdjective(traits: traits)
        let moodWord = moodAdjective(profile: profile)
        
        // Build a unique opening sentence per fragrance family + personality combo
        switch fragrance.family {
        case "citrus":
            return "\(fragrance.name) speaks to your \(presenceWord) side — bright and direct, like someone who walks in and the room wakes up."
        case "floral":
            return "\(fragrance.name) captures a \(moodWord) elegance that mirrors your refined sensibility — not loud, but unforgettable."
        case "fruity":
            return "\(fragrance.name) reflects your \(presenceWord) energy — playful, approachable, the kind of scent that starts conversations."
        case "woody":
            return "\(fragrance.name) is grounded confidence in a bottle — it says you know exactly who you are without needing to announce it."
        case "oriental":
            return "\(fragrance.name) channels your \(moodWord) depth — rich, layered, magnetic. This is a scent that lingers in memory."
        case "aquatic":
            return "\(fragrance.name) is your \(presenceWord) breath of fresh air — clean lines, calm energy, effortlessly put-together."
        case "gourmand":
            return "\(fragrance.name) wraps your \(moodWord) warmth in something edible and irresistible — comfort made wearable."
        case "fougere":
            return "\(fragrance.name) is \(presenceWord) composure distilled — crisp, herbal, the kind of classic that never feels dated."
        case "leather":
            return "\(fragrance.name) carries your \(presenceWord) authority — dark, textured, and commanding without raising its voice."
        case "musk":
            return "\(fragrance.name) is your skin but better — intimate, \(moodWord), a scent discovered only up close."
        case "spicy":
            return "\(fragrance.name) carries your \(presenceWord) fire — warm, invigorating, the kind of scent that turns heads and quickens pulses."
        default:
            return "\(fragrance.name) by \(fragrance.house) is a \(familyLabel) fragrance that resonates with your profile."
        }
    }
    
    // MARK: - 2. Key Notes Breakdown
    
    private static func keyNotesBreakdown(fragrance: Fragrance) -> String {
        let topNotes = extractNotes(from: fragrance.topNotes)
        let heartNotes = extractNotes(from: fragrance.heartNotes)
        let baseNotes = extractNotes(from: fragrance.baseNotes)
        
        var parts: [String] = []
        
        if let first = topNotes.first {
            parts.append("It opens with \(first)")
            if topNotes.count > 1 {
                parts[0] += " and \(topNotes[1])"
            }
        }
        
        if let heart = heartNotes.first {
            parts.append("settles into a \(heart) heart")
        }
        
        if let base = baseNotes.first {
            parts.append("and dries down to \(base)")
            if baseNotes.count > 1 {
                parts[parts.count - 1] += " laced with \(baseNotes[1])"
            }
        }
        
        guard !parts.isEmpty else { return "" }
        return parts.joined(separator: ", ") + "."
    }
    
    // MARK: - 3. Wardrobe Pairing
    
    private static func wardrobePairing(fragrance: Fragrance, profile: UserProfile?) -> String {
        let styling = profile?.styling ?? ""
        
        switch (fragrance.family, styling) {
        case ("citrus", "classic"):
            return "Pair it with a crisp white shirt and navy trousers — this scent was made for polished simplicity."
        case ("citrus", "casual"):
            return "Throw this on with a clean tee and chinos — it's weekend brunch energy in a spray."
        case ("citrus", "edgy"):
            return "Layer it over a structured jacket and dark denim — the freshness cuts through the edge perfectly."
        case ("citrus", _):
            return "It works beautifully with light, breathable fabrics and clean-cut silhouettes."
        case ("floral", "classic"):
            return "A silk blouse and tailored skirt make this scent sing — elegant without trying."
        case ("floral", "casual"):
            return "Even with a simple sundress, this scent adds a layer of effortless grace."
        case ("floral", "edgy"):
            return "Pair it with leather and lace — the contrast between softness and edge is magnetic."
        case ("floral", _):
            return "It pairs naturally with soft fabrics and romantic silhouettes."
        case ("woody", "corporate"):
            return "This is your power-meeting scent — pair it with a well-cut suit and it does half the talking."
        case ("woody", "classic"):
            return "A blazer and good leather shoes are all you need — this scent completes the picture."
        case ("woody", _):
            return "It grounds any outfit — from smart casual to evening wear."
        case ("oriental", _):
            return "Save this for your most considered outfits — deep tones, rich textures, statement pieces."
        case ("aquatic", _):
            return "Linen, cotton, open collars — this scent pairs with anything that breathes."
        case ("gourmand", _):
            return "Knitwear, cashmere, cozy layers — this scent turns comfort into an art form."
        case ("fougere", "corporate"):
            return "The perfect partner for tailored shirts and polished shoes — boardroom-ready."
        case ("fougere", _):
            return "It sits well with structured, clean-cut clothing — think pressed collars and sharp lines."
        case ("leather", _):
            return "This scent demands texture — suede, wool, dark materials that match its weight."
        case ("musk", _):
            return "The beauty of this scent is it works with anything — your outfit, your skin, it adapts."
        case ("spicy", _):
            return "Rich textures and warm tones in your wardrobe let this scent's fire sing — think deep reds, earthy knits, and bold accessories."
        default:
            return "A versatile scent that complements a wide range of wardrobe choices."
        }
    }
    
    // MARK: - 4. Occasion Fit
    
    /// Generates a unique occasion sentence per fragrance using the fragrance's own occasion field,
    /// season, family, sillage, longevity, and the user's occasion/mood preferences.
    private static func occasionFit(fragrance: Fragrance, profile: UserProfile?) -> String {
        let userOccasion = profile?.occasion ?? ""
        let mood = profile?.mood ?? ""
        let fOccasion = fragrance.occasion.lowercased()
        let fSeason = fragrance.season.lowercased()
        let fSillage = fragrance.sillage.lowercased()
        let fLongevity = fragrance.longevity
        
        // Build a unique sentence from the fragrance's actual data
        var parts: [String] = []
        
        // Occasion-specific opening — uses the fragrance's occasion field directly
        if fOccasion.contains("everyday") && fOccasion.contains("office") {
            parts.append("From your morning commute to a late meeting, \(fragrance.name) holds its composure all day")
        } else if fOccasion.contains("everyday") || fOccasion.contains("casual") {
            if fOccasion.contains("casual") && mood == "relaxed" {
                parts.append("A laid-back companion for slow weekends and easy errands")
            } else if mood == "energetic" {
                parts.append("\(fragrance.name) keeps pace with your energy — spray it before heading out the door")
            } else {
                parts.append("Wear \(fragrance.name) on repeat — it's the kind of scent that becomes your daily handshake")
            }
        } else if fOccasion.contains("evening") && fOccasion.contains("night") {
            parts.append("This one wakes up after dark — \(fragrance.name) is built for dinner tables and dimmed lights")
        } else if fOccasion.contains("evening") || fOccasion.contains("date") {
            if mood == "love" {
                parts.append("Close-quarters and candlelight — \(fragrance.name) was designed for moments you want remembered")
            } else {
                parts.append("When the sun sets, \(fragrance.name) steps forward — evening energy in every spray")
            }
        } else if fOccasion.contains("office") || fOccasion.contains("formal") {
            if userOccasion == "office" {
                parts.append("\(fragrance.name) reads the room perfectly — professional enough for 9 AM, interesting enough to be noticed at lunch")
            } else {
                parts.append("Structured and respectful of shared space, \(fragrance.name) leaves the right impression without overstepping")
            }
        } else if fOccasion.contains("special") || fOccasion.contains("grand") || fOccasion.contains("festive") {
            parts.append("Save \(fragrance.name) for the events circled on your calendar — it carries the weight of the occasion")
        } else if fOccasion.contains("resort") || fOccasion.contains("day") {
            parts.append("\(fragrance.name) belongs in sunlight and open air — the kind of scent that feels like a getaway")
        } else if fOccasion.contains("cozy") {
            parts.append("Wrap yourself in \(fragrance.name) on a quiet evening in — it turns a room into a retreat")
        } else {
            parts.append("\(fragrance.name) adapts to wherever your day takes you")
        }
        
        // Season texture — adds uniqueness per fragrance
        if fSeason.contains("year-round") {
            parts.append("and it holds up in any season")
        } else if fSeason.contains("summer") && fSeason.contains("spring") {
            parts.append("with its peak in the warmer months when lighter scents shine")
        } else if fSeason.contains("summer") {
            parts.append("— at its best when the heat rises")
        } else if fSeason.contains("winter") && fSeason.contains("autumn") {
            parts.append("and it comes alive in cooler air when warmth is welcome")
        } else if fSeason.contains("autumn") {
            parts.append("— it has that crisp autumn character that matches the season's shift")
        } else if fSeason.contains("winter") {
            parts.append("best worn when layers pile on and nights draw in")
        } else if fSeason.contains("monsoon") {
            parts.append("with a character that feels especially right when the air turns heavy and wet")
        } else if fSeason.contains("spring") {
            parts.append("— it carries the optimism of spring mornings")
        }
        
        // Sillage/longevity specificity
        if fSillage.contains("intimate") {
            parts.append("— worn close to the skin, discovered only by those who lean in.")
        } else if fSillage.contains("beast") || fSillage.contains("strong") {
            parts.append("— with \(fLongevity) of wear, this one announces itself and stays.")
        } else if fSillage.contains("moderate") {
            parts.append("— it projects enough to be noticed and fades gracefully over \(fLongevity).")
        } else {
            parts.append(".")
        }
        
        return parts.joined(separator: " ")
    }
    
    // MARK: - 5. Why It Works (includes wardrobe + scent profile)
    
    private static func whyItWorks(fragrance: Fragrance, scores: DimensionContributions, traits: PersonalityTraits?, profile: UserProfile?) -> String {
        var parts: [String] = []
        
        // Scent profile connection
        let familyLabel = familyDisplayName(for: fragrance.family)
        if let topFamilyIds = topScoredFamilies(scores: scores, familyId: fragrance.family) {
            parts.append("Your scent profile leans \(topFamilyIds) — \(familyLabel) sits right in that space.")
        }
        
        // Wardrobe connection
        if let styling = profile?.styling, !styling.isEmpty {
            let wardrobeLink = wardrobeConnection(family: fragrance.family, styling: styling)
            if !wardrobeLink.isEmpty {
                parts.append(wardrobeLink)
            }
        }
        
        // Dimension reasons
        var reasons: [String] = []
        
        if scores.climate > 0, let climate = profile?.climate, !climate.isEmpty {
            reasons.append("your \(climateAdjective(climate)) climate")
        }
        if scores.personality > 0, let traits = traits {
            reasons.append("your \(dominantTraitLabel(traits)) personality")
        }
        if scores.workStyle > 0, let work = profile?.work, !work.isEmpty {
            reasons.append("your \(workAdjective(work)) lifestyle")
        }
        if scores.age > 0 {
            reasons.append("your life stage")
        }
        
        if !reasons.isEmpty {
            let last = reasons.count > 1 ? reasons.removeLast() : nil
            var sentence = "Matched because of \(reasons.joined(separator: ", "))"
            if let last = last {
                sentence += ", and \(last)"
            }
            parts.append(sentence + ".")
        }
        
        return parts.isEmpty ? "A strong overall match for your complete profile." : parts.joined(separator: " ")
    }
    
    /// Returns a human-readable label for the user's dominant scent families.
    private static func topScoredFamilies(scores: DimensionContributions, familyId: String) -> String? {
        let total = scores.personality + scores.climate + scores.workStyle + scores.age
        guard total > 0 else { return nil }
        let familyLabel = familyDisplayName(for: familyId)
        return familyLabel
    }
    
    /// Returns a wardrobe-to-scent-family connection sentence.
    private static func wardrobeConnection(family: String, styling: String) -> String {
        switch (family, styling) {
        case ("citrus", "classic"): return "Your polished wardrobe pairs naturally with citrus freshness."
        case ("citrus", "casual"): return "Citrus and casual wear are a perfect duo — effortless and clean."
        case ("citrus", "edgy"): return "The brightness of citrus cuts through your edgy aesthetic perfectly."
        case ("floral", "classic"): return "Florals and your classic style share the same refined DNA."
        case ("floral", "casual"): return "Soft florals add grace to your relaxed look."
        case ("floral", "edgy"): return "Florals against your edgy wardrobe create an unexpected contrast."
        case ("woody", "classic"): return "Woody scents and your polished style are a natural pair — both timeless."
        case ("woody", "casual"): return "Woody warmth grounds your casual aesthetic beautifully."
        case ("woody", "edgy"): return "Dark woods match the depth in your wardrobe choices."
        case ("oriental", _): return "Oriental richness matches the bold statement your wardrobe makes."
        case ("aquatic", _): return "Aquatic freshness complements your clean, breathable style."
        case ("gourmand", _): return "Gourmand warmth adds a cozy layer to your overall look."
        case ("fougere", "classic"), ("fougere", "corporate"): return "Fougère is the scent equivalent of your sharp, structured wardrobe."
        case ("fougere", _): return "Fougère's crisp character works with your put-together style."
        case ("leather", _): return "Leather scents carry the same weight as your boldest outfit."
        case ("musk", _): return "Musk works like a second skin — invisible but essential, like your best basics."
        case ("spicy", _): return "Spicy scents carry the same warmth and intensity your look projects — bold and unforgettable."
        default: return ""
        }
    }
    
    // MARK: - Helpers
    
    private static func presenceAdjective(traits: PersonalityTraits?) -> String {
        guard let traits = traits else { return "distinct" }
        let dominant = [
            (traits.boldness, "bold"),
            (1 - traits.boldness, "understated"),
            (traits.extroversion, "radiant"),
            (1 - traits.extroversion, "quietly confident"),
        ].max(by: { abs($0.0 - 0.5) < abs($1.0 - 0.5) })
        return dominant?.1 ?? "distinct"
    }
    
    private static func moodAdjective(profile: UserProfile?) -> String {
        switch profile?.mood {
        case "energetic": return "vibrant"
        case "cool": return "cool"
        case "relaxed": return "serene"
        case "focused": return "sharp"
        case "love": return "romantic"
        default: return "refined"
        }
    }
    
    private static func climateAdjective(_ climate: String) -> String {
        switch climate {
        case "hot": return "warm"
        case "cold": return "cool"
        case "temperate": return "mild"
        case "humid": return "humid"
        case "dry": return "dry"
        default: return climate
        }
    }
    
    private static func workAdjective(_ work: String) -> String {
        switch work {
        case "corporate": return "polished"
        case "creative": return "creative"
        case "outdoor": return "active"
        case "remote": return "relaxed"
        case "social": return "social"
        default: return "dynamic"
        }
    }
    
    private static func dominantTraitLabel(_ traits: PersonalityTraits) -> String {
        let traitPairs: [(Double, String)] = [
            (traits.boldness, traits.boldness >= 0.5 ? "bold" : "subtle"),
            (traits.warmth, traits.warmth >= 0.5 ? "warm" : "cool"),
            (traits.experimental, traits.experimental >= 0.5 ? "adventurous" : "classic"),
            (traits.extroversion, traits.extroversion >= 0.5 ? "outgoing" : "introspective"),
        ]
        let sorted = traitPairs.sorted { abs($0.0 - 0.5) > abs($1.0 - 0.5) }
        return sorted.first?.1 ?? "unique"
    }
    
    private static func extractNotes(from notesString: String) -> [String] {
        notesString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
    }
    
    private static func familyDisplayName(for familyId: String) -> String {
        allFamilies.first(where: { $0.id == familyId })?.label.lowercased() ?? familyId
    }
}
