import SwiftUI

// MARK: - Scent Wheel (Interactive Olfactive Web)
// A radial chart mapping each olfactory family to a spoke.
// Tapping a spoke reveals how that family connects to the user's profile.

struct ScentWheelView: View {
    let scores: [String: Double]
    let animate: Bool
    var profile: UserProfile? = nil
    var traits: PersonalityTraits? = nil
    var contributionsForFamily: ((String) -> DimensionContributions)? = nil
    
    @State private var progress: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var selectedFamily: String? = nil
    
    private let families = allFamilies
    
    var body: some View {
        VStack(spacing: 0) {
            // The wheel
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let center = CGPoint(x: size / 2, y: size / 2)
                let rMax = size * 0.38
                let rMin = size * 0.08
                let maxScore = max(1, scores.values.max() ?? 1)
                
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [DT.gold.opacity(0.08), .clear],
                                center: .center,
                                startRadius: rMin,
                                endRadius: rMax + 40
                            )
                        )
                        .frame(width: size, height: size)
                        .opacity(glowOpacity)
                    
                    // Concentric guide rings
                    ForEach([0.33, 0.66, 1.0], id: \.self) { fraction in
                        Circle()
                            .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                            .frame(
                                width: (rMin + (rMax - rMin) * fraction) * 2,
                                height: (rMin + (rMax - rMin) * fraction) * 2
                            )
                            .position(center)
                    }
                    
                    // Spoke lines
                    ForEach(0..<families.count, id: \.self) { i in
                        let angle = angleFor(index: i)
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: pointAt(center: center, radius: rMax, angle: angle))
                        }
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                    }
                    
                    // Filled polygon
                    Path { path in
                        for (i, family) in families.enumerated() {
                            let angle = angleFor(index: i)
                            let val = max(0, scores[family.id] ?? 0)
                            let r = rMin + (rMax - rMin) * (val / maxScore) * progress
                            let point = pointAt(center: center, radius: r, angle: angle)
                            if i == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [DT.gold.opacity(0.3), DT.rose.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    
                    // Polygon stroke
                    Path { path in
                        for (i, family) in families.enumerated() {
                            let angle = angleFor(index: i)
                            let val = max(0, scores[family.id] ?? 0)
                            let r = rMin + (rMax - rMin) * (val / maxScore) * progress
                            let point = pointAt(center: center, radius: r, angle: angle)
                            if i == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(DT.gold, lineWidth: 2)
                    
                    // Data points + tappable labels
                    ForEach(0..<families.count, id: \.self) { i in
                        let family = families[i]
                        let angle = angleFor(index: i)
                        let val = max(0, scores[family.id] ?? 0)
                        let r = rMin + (rMax - rMin) * (val / maxScore) * progress
                        let point = pointAt(center: center, radius: r, angle: angle)
                        let labelR = rMax + 24
                        let labelPoint = pointAt(center: center, radius: labelR, angle: angle)
                        let isSelected = selectedFamily == family.id
                        
                        // Node circle
                        Circle()
                            .fill(family.color)
                            .frame(width: isSelected ? 20 : 14, height: isSelected ? 20 : 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: isSelected ? 2 : 1.5)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                            )
                            .shadow(color: family.color.opacity(isSelected ? 0.9 : 0.6), radius: isSelected ? 8 : 5)
                            .position(point)
                            .animation(.easeInOut(duration: 0.2), value: isSelected)
                        
                        // Tappable label
                        Text(family.label)
                            .font(.system(size: isSelected ? 13 : 11, weight: isSelected ? .bold : .semibold, design: .monospaced))
                            .foregroundColor(isSelected ? DT.gold : DT.inkSoft)
                            .position(labelPoint)
                            .animation(.easeInOut(duration: 0.2), value: isSelected)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if selectedFamily == family.id {
                                        selectedFamily = nil
                                    } else {
                                        selectedFamily = family.id
                                    }
                                }
                            }
                        
                        // Score percentage near the node
                        if isSelected {
                            let scorePercent = Int((scores[family.id] ?? 0).rounded())
                            Text("\(scorePercent)%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(DT.gold)
                                .position(pointAt(center: center, radius: r + 16, angle: angle))
                                .transition(.opacity)
                        }
                    }
                }
                .frame(width: size, height: size)
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Family Profile Card (shown when a spoke is tapped)
            if let familyId = selectedFamily,
               let family = allFamilies.first(where: { $0.id == familyId }) {
                FamilyProfileCard(
                    family: family,
                    score: scores[familyId] ?? 0,
                    profile: profile,
                    traits: traits,
                    contributions: contributionsForFamily?(familyId)
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .padding(.top, 8)
            }
        }
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 1.2)) {
                    progress = 1
                }
                withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                    glowOpacity = 1
                }
            } else {
                progress = 1
                glowOpacity = 1
            }
        }
    }
    
    private func angleFor(index: Int) -> Double {
        (Double.pi * 2.0 * Double(index)) / Double(families.count) - Double.pi / 2.0
    }
    
    private func pointAt(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

// MARK: - Family Profile Card

/// Shows how a specific olfactive family connects to the user's profile.
/// Displayed when the user taps a spoke on the scent wheel.
struct FamilyProfileCard: View {
    let family: OlfactoryFamily
    let score: Double
    let profile: UserProfile?
    let traits: PersonalityTraits?
    let contributions: DimensionContributions?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Family header
            HStack(spacing: 10) {
                Circle()
                    .fill(family.color)
                    .frame(width: 12, height: 12)
                
                Text(family.label)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(score.rounded()))% match")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(DT.gold)
            }
            
            Text(family.description)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            
            Divider().background(DT.parchmentDim)
            
            // Profile connection breakdown
            Text("YOUR PROFILE CONNECTION")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundColor(DT.goldDeep)
            
            if let contributions = contributions {
                // Dimension bars showing what drove this family's score
                ProfileDimensionBar(label: "Essence + Personality", value: contributions.personality, icon: "sparkles")
                ProfileDimensionBar(label: "Climate", value: contributions.climate, icon: "cloud.sun")
                ProfileDimensionBar(label: "Lifestyle", value: contributions.workStyle, icon: "briefcase")
                ProfileDimensionBar(label: "Life Stage", value: contributions.age, icon: "calendar")
            }
            
            // Profile-specific narrative
            Text(profileNarrative)
                .font(.system(size: 11.5))
                .foregroundColor(.white)
                .lineSpacing(2)
                .padding(.top, 4)
        }
        .padding(16)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusMD)
                .stroke(family.color.opacity(0.4), lineWidth: 1)
        )
    }
    
    private var profileNarrative: String {
        let climateWord = profile?.climate.isEmpty == false ? profile!.climate : "your climate"
        let workWord = profile?.work.isEmpty == false ? workLabel(profile!.work) : "your lifestyle"
        let moodWord = profile?.mood.isEmpty == false ? profile!.mood : "your mood"
        
        switch family.id {
        case "citrus":
            return "Your \(climateWord) environment and \(moodWord) mood pull you toward bright, energizing scents. Citrus families thrive in \(workWord) settings where freshness keeps you sharp."
        case "floral":
            return "There's a romantic thread in your profile — your styling choices and \(moodWord) energy create a natural affinity for soft, blooming florals that feel effortlessly elegant."
        case "fruity":
            return "Your \(moodWord) vibe and social energy make fruity scents a natural fit. They're playful, approachable, and match the youthful current running through your profile."
        case "woody":
            return "Grounded and confident — your \(workWord) lifestyle and \(climateWord) surroundings both point to woody scents. They carry the same quiet authority your profile suggests."
        case "oriental":
            return "Your profile has depth — \(moodWord) mood combined with your styling choices creates a magnetic pull toward rich, layered oriental fragrances that linger and intrigue."
        case "aquatic":
            return "Clean and effortless — your \(climateWord) climate and \(moodWord) energy align perfectly with aquatic scents. They mirror the easy, put-together quality in your profile."
        case "gourmand":
            return "There's a warmth in your profile — your \(moodWord) mood and comfort-forward choices create an irresistible pull toward sweet, cozy gourmand fragrances."
        case "fougere":
            return "Classic and composed — your \(workWord) lifestyle and structured approach make fougère a natural companion. It's the scent equivalent of a well-pressed shirt."
        case "leather":
            return "Your profile carries weight — the combination of your \(moodWord) mood and bold choices points to leather's dark, commanding character."
        case "musk":
            return "Intimate and understated — your profile suggests someone who prefers closeness over broadcast. Musks work right at skin level, discovered only up close."
        case "spicy":
            return "There's fire in your profile — your \(moodWord) mood and bold personality create a magnetic pull toward warm, invigorating spicy fragrances that command attention and leave an impression."
        default:
            return "This family resonates with multiple dimensions of your profile."
        }
    }
    
    private func workLabel(_ work: String) -> String {
        switch work {
        case "corporate": return "polished"
        case "creative": return "creative"
        case "outdoor": return "active"
        case "remote": return "relaxed"
        case "social": return "social"
        default: return work
        }
    }
}

// MARK: - Profile Dimension Bar

struct ProfileDimensionBar: View {
    let label: String
    let value: Double
    let icon: String
    
    // Normalize to 0-1 range for display (max contribution ~15)
    private var normalizedValue: Double {
        min(1.0, max(0, value / 15.0))
    }
    
    private var isActive: Bool {
        value > 0.1
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(isActive ? DT.goldDeep : DT.inkSoft.opacity(0.4))
                .frame(width: 16)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(isActive ? DT.ink : DT.inkSoft.opacity(0.5))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 92, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DT.parchmentDim.opacity(0.3))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isActive ? DT.gold : DT.inkSoft.opacity(0.2))
                        .frame(width: geo.size.width * normalizedValue, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Profile Web Section

/// The Scent Profile Web — 3 core dimensions that shape the user's fragrance identity:
/// 1. Element (from Zodiac) — the elemental scent archetype
/// 2. Essence Number (Life Path numerology) — the numerological scent leaning
/// 3. Personality (quiz traits) — the behavioural scent axis
struct ProfileWebView: View {
    let profile: UserProfile
    let traits: PersonalityTraits
    let scores: [String: Double]
    var essenceProfile: EssenceProfile? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCENT PROFILE WEB")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(DT.gold)
            
            Text("Three forces shape your scent identity")
                .font(.system(size: 12))
                .foregroundColor(DT.parchmentDim)
                .padding(.bottom, 4)
            
            // === 1. ELEMENT (from Zodiac) — Primary ===
            if let essence = essenceProfile {
                let elementProfile = essence.zodiacSign.elementScentProfile
                
                ElementWebCard(
                    rank: 1,
                    label: "\(elementProfile.element) Element",
                    sublabel: "\(essence.zodiacSign.displayName) · \(essence.zodiacSign.symbol)",
                    icon: elementProfile.icon,
                    accentColorHex: elementProfile.color,
                    traits: elementProfile.traits,
                    scentCharacter: elementProfile.scentCharacter,
                    noteFocus: elementProfile.noteFocus,
                    occasion: elementProfile.occasion,
                    familyIds: elementProfile.families,
                    signatureNotes: elementProfile.signatureNotes
                )
                
                // === 2. ESSENCE NUMBER (Life Path) — Secondary ===
                EssenceNumberWebCard(
                    rank: 2,
                    lifePathNumber: essence.lifePathNumber,
                    isMaster: essence.lifePathIsmaster,
                    trait: essence.lifePathTrait
                )
            }
            
            // === 3. PERSONALITY (quiz traits) — Tertiary ===
            PersonalityWebCard(
                rank: 3,
                traits: traits,
                scores: scores
            )
        }
        .padding(20)
        .background(DT.ink.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusMD)
                .stroke(DT.goldDeep.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Element Web Card (Dimension 1 — FIXED, does not change with questionnaire)

struct ElementWebCard: View {
    let rank: Int
    let label: String
    let sublabel: String
    let icon: String
    let accentColorHex: String
    let traits: [String]
    let scentCharacter: String
    let noteFocus: String
    let occasion: String
    let familyIds: [String]
    let signatureNotes: [String]
    
    private var accentColor: Color { Color(hex: accentColorHex) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(spacing: 8) {
                Text("\(rank)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(DT.gold)
                    .frame(width: 18, height: 18)
                    .background(DT.gold.opacity(0.15))
                    .clipShape(Circle())
                
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(accentColor)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(label.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(DT.parchment)
                    Text(sublabel)
                        .font(.system(size: 10))
                        .foregroundColor(DT.parchmentDim)
                }
                
                Spacer()
            }
            
            // Traits
            FlowLayout(spacing: 6) {
                ForEach(traits, id: \.self) { trait in
                    Text(trait)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
            // Scent character
            Text(scentCharacter)
                .font(.system(size: 12))
                .foregroundColor(DT.parchment)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Note focus
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 9))
                    .foregroundColor(DT.gold)
                Text(noteFocus)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(DT.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            
            // Signature Notes (FIXED — from element, never changes)
            HStack(spacing: 6) {
                Image(systemName: "leaf")
                    .font(.system(size: 9))
                    .foregroundColor(DT.gold)
                
                FlowLayout(spacing: 5) {
                    ForEach(signatureNotes, id: \.self) { note in
                        Text(note)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DT.parchment)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(accentColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            
            // Occasion
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9))
                    .foregroundColor(DT.gold)
                Text(occasion)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(DT.parchmentDim)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            
            // Connected families (FIXED — from element, no dynamic scores)
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 9))
                    .foregroundColor(DT.inkSoft.opacity(0.5))
                
                FlowLayout(spacing: 6) {
                    ForEach(familyIds, id: \.self) { familyId in
                        if let family = allFamilies.first(where: { $0.id == familyId }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(family.color)
                                    .frame(width: 6, height: 6)
                                Text(family.label)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DT.parchment)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(family.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusSM)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Essence Number Web Card (Dimension 2 — FIXED, does not change with questionnaire)

struct EssenceNumberWebCard: View {
    let rank: Int
    let lifePathNumber: Int
    let isMaster: Bool
    let trait: NumerologyTrait
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Text("\(rank)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(DT.gold)
                    .frame(width: 18, height: 18)
                    .background(DT.gold.opacity(0.15))
                    .clipShape(Circle())
                
                Image(systemName: "number.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(DT.goldDeep)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("ESSENCE NUMBER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(DT.parchment)
                    Text("Life Path \(lifePathNumber)\(isMaster ? " · Master Number" : "")")
                        .font(.system(size: 10))
                        .foregroundColor(DT.parchmentDim)
                }
                
                Spacer()
                
                // Large number display
                Text("\(lifePathNumber)")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(DT.gold)
            }
            
            // Trait description
            Text(trait.description)
                .font(.system(size: 12))
                .foregroundColor(DT.parchment)
            
            // Signature Notes (FIXED — from essence number, never changes)
            HStack(spacing: 6) {
                Image(systemName: "leaf")
                    .font(.system(size: 9))
                    .foregroundColor(DT.gold)
                
                FlowLayout(spacing: 5) {
                    ForEach(trait.signatureNotes, id: \.self) { note in
                        Text(note)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DT.parchment)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(DT.gold.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            
            // Connected family (FIXED — from essence number, no dynamic scores)
            if let family = allFamilies.first(where: { $0.id == trait.scentFamily }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 9))
                        .foregroundColor(DT.inkSoft.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(family.color)
                            .frame(width: 6, height: 6)
                        Text(family.label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DT.parchment)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(family.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(14)
        .background(DT.gold.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusSM)
                .stroke(DT.gold.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Personality Web Card (Dimension 3)

struct PersonalityWebCard: View {
    let rank: Int
    let traits: PersonalityTraits
    let scores: [String: Double]
    
    private var dominantAxis: (label: String, families: [String]) {
        let axes: [(distance: Double, label: String, families: [String])] = [
            (abs(traits.boldness - 0.5), traits.boldness >= 0.5 ? "Bold" : "Subtle",
             traits.boldness >= 0.5 ? ["oriental", "leather", "spicy"] : ["aquatic", "musk"]),
            (abs(traits.warmth - 0.5), traits.warmth >= 0.5 ? "Warm" : "Cool",
             traits.warmth >= 0.5 ? ["gourmand", "oriental", "spicy"] : ["citrus", "aquatic"]),
            (abs(traits.experimental - 0.5), traits.experimental >= 0.5 ? "Adventurous" : "Classic",
             traits.experimental >= 0.5 ? ["gourmand", "fruity", "leather", "spicy"] : ["fougere", "woody"]),
            (abs(traits.extroversion - 0.5), traits.extroversion >= 0.5 ? "Outgoing" : "Introspective",
             traits.extroversion >= 0.5 ? ["floral", "fruity", "citrus"] : ["woody", "musk"]),
        ]
        return axes.max(by: { $0.distance < $1.distance }).map { ($0.label, $0.families) } ?? ("Balanced", ["musk"])
    }
    
    private var traitSummary: String {
        var parts: [String] = []
        if traits.boldness >= 0.6 { parts.append("Bold") }
        else if traits.boldness <= 0.4 { parts.append("Subtle") }
        if traits.warmth >= 0.6 { parts.append("Warm") }
        else if traits.warmth <= 0.4 { parts.append("Cool") }
        if traits.experimental >= 0.6 { parts.append("Adventurous") }
        else if traits.experimental <= 0.4 { parts.append("Classic") }
        if traits.extroversion >= 0.6 { parts.append("Outgoing") }
        else if traits.extroversion <= 0.4 { parts.append("Introspective") }
        if parts.isEmpty { parts.append("Balanced") }
        return parts.prefix(3).joined(separator: " · ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Text("\(rank)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(DT.gold)
                    .frame(width: 18, height: 18)
                    .background(DT.gold.opacity(0.15))
                    .clipShape(Circle())
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 13))
                    .foregroundColor(DT.rose)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("PERSONALITY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(DT.parchment)
                    Text("Dominant: \(dominantAxis.label)")
                        .font(.system(size: 10))
                        .foregroundColor(DT.parchmentDim)
                }
                
                Spacer()
            }
            
            // Trait summary chips
            Text(traitSummary)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DT.parchment)
            
            // Mini trait bars
            HStack(spacing: 12) {
                MiniTraitIndicator(label: "Bold", value: traits.boldness)
                MiniTraitIndicator(label: "Warm", value: traits.warmth)
                MiniTraitIndicator(label: "Open", value: traits.experimental)
                MiniTraitIndicator(label: "Social", value: traits.extroversion)
            }
            
            // Connected families
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 9))
                    .foregroundColor(DT.inkSoft.opacity(0.5))
                
                FlowLayout(spacing: 6) {
                    ForEach(dominantAxis.families, id: \.self) { familyId in
                        if let family = allFamilies.first(where: { $0.id == familyId }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(family.color)
                                    .frame(width: 6, height: 6)
                                Text(family.label)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DT.parchment)
                                if let score = scores[familyId], score > 0 {
                                    Text("\(Int(score.rounded()))%")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(DT.gold)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(family.color.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(DT.rose.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusSM)
                .stroke(DT.rose.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Mini Trait Indicator

struct MiniTraitIndicator: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 3) {
            // Vertical bar
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DT.inkSoft.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DT.gold)
                        .frame(height: geo.size.height * value)
                }
            }
            .frame(width: 6, height: 24)
            
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(DT.parchmentDim)
        }
    }
}

// MARK: - Flow Layout (horizontal wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }
        
        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

// MARK: - Mini Wheel (for card previews)

struct MiniScentWheel: View {
    let scores: [String: Double]
    
    var body: some View {
        ScentWheelView(scores: scores, animate: false)
            .frame(width: 80, height: 80)
    }
}
