import SwiftUI

struct ResultsView: View {
    let scores: [String: Double]
    let topFamilies: [String]
    let recommendations: [Fragrance]
    let traits: PersonalityTraits
    let profile: UserProfile
    var essenceProfile: EssenceProfile? = nil
    let contributionsForFamily: (String) -> DimensionContributions
    let onReset: () -> Void
    var onOpenAdvisor: (() -> Void)? = nil
    
    @State private var showWheel = false
    @State private var expandedCard: String?
    @State private var showSaveConfirmation = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header with name
                Text("YOUR DOSSIER")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(DT.gold)
                    .padding(.bottom, 6)
                
                if !profile.name.isEmpty {
                    Text(profile.name)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                }
                
                Text("Scent Profile")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 24)
                
                // === SCENT WHEEL ===
                VStack(spacing: 16) {
                    ScentWheelView(
                        scores: scores,
                        animate: true,
                        profile: profile,
                        traits: traits,
                        contributionsForFamily: contributionsForFamily
                    )
                    .frame(minHeight: 320)
                    .padding(.horizontal, 8)
                    
                    // Top families summary
                    Text("YOUR OLFACTORY SIGNATURE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(.black.opacity(0.7))
                    
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(Array(topFamilies.enumerated()), id: \.element) { index, familyId in
                            if let family = allFamilies.first(where: { $0.id == familyId }) {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(family.color)
                                        .frame(
                                            width: index == 0 ? 16 : (index == 1 ? 12 : 8),
                                            height: index == 0 ? 16 : (index == 1 ? 12 : 8)
                                        )
                                    Text(family.label)
                                        .font(.system(
                                            size: index == 0 ? 14 : (index == 1 ? 12 : 11),
                                            weight: index == 0 ? .bold : (index == 1 ? .semibold : .regular)
                                        ))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(family.description)
                                        .font(.system(size: 10))
                                        .foregroundColor(.black.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .top)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: DT.radiusLG))
                .padding(.bottom, 24)
                
                // === PROFILE WEB ===
                ProfileWebView(
                    profile: profile,
                    traits: traits,
                    scores: scores,
                    essenceProfile: essenceProfile
                )
                .padding(.bottom, 24)
                
                // === TRAIT BARS ===
                VStack(alignment: .leading, spacing: 16) {
                    Text("ESSENCE + PERSONALITY AXIS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(DT.gold)
                    
                    TraitBar(label: "Boldness", value: traits.boldness, leftLabel: "Subtle", rightLabel: "Statement")
                    TraitBar(label: "Experimental", value: traits.experimental, leftLabel: "Classic", rightLabel: "Avant-garde")
                    TraitBar(label: "Extroversion", value: traits.extroversion, leftLabel: "Introspective", rightLabel: "Radiating")
                    TraitBar(label: "Warmth", value: traits.warmth, leftLabel: "Cool / Fresh", rightLabel: "Warm / Enveloping")
                }
                .padding(20)
                .background(DT.ink.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: DT.radiusMD)
                        .stroke(DT.goldDeep.opacity(0.3), lineWidth: 0.5)
                )
                .padding(.bottom, 28)
                
                // === ESSENCE PROFILE ===
                if let essence = essenceProfile {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ESSENCE SIGNATURE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(DT.gold)
                        
                        Text("Your essence reading — revealed here for the first time.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 12) {
                            // Life Path
                            VStack(spacing: 4) {
                                Text("\(essence.lifePathNumber)")
                                    .font(.system(size: 22, weight: .semibold, design: .serif))
                                    .foregroundColor(.white)
                                Text("Life Path")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                if essence.lifePathIsmaster {
                                    Text("MASTER")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .tracking(0.5)
                                        .foregroundColor(DT.gold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Zodiac
                            VStack(spacing: 4) {
                                Text(essence.zodiacSign.symbol)
                                    .font(.system(size: 22))
                                Text(essence.zodiacSign.displayName)
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(essence.zodiacSign.element)
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(DT.parchmentDim.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Trait details
                        VStack(alignment: .leading, spacing: 6) {
                            Text(essence.lifePathTrait.description)
                                .font(.system(size: 11.5))
                                .foregroundColor(.white.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("\(essence.zodiacSign.displayName) · \(essence.zodiacSign.rulingPlanet) · \(essence.zodiacSign.traitKeywords.joined(separator: ", "))")
                                .font(.system(size: 11))
                                .foregroundColor(DT.parchmentDim.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let family = allFamilies.first(where: { $0.id == essence.scentLeaning }) {
                                HStack(spacing: 6) {
                                    Text("Essence leaning →")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(DT.parchmentDim.opacity(0.6))
                                    Circle()
                                        .fill(family.color)
                                        .frame(width: 7, height: 7)
                                    Text(family.label)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer(minLength: 0)
                                }
                                .padding(.top, 4)
                            }
                            
                            // Show zodiac secondary signal if different
                            let zodiacFamily = essence.zodiacSign.scentFamily
                            if zodiacFamily != essence.scentLeaning,
                               let zFamily = allFamilies.first(where: { $0.id == zodiacFamily }) {
                                HStack(spacing: 6) {
                                    Text("Zodiac signal →")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(DT.parchmentDim.opacity(0.6))
                                    Circle()
                                        .fill(zFamily.color)
                                        .frame(width: 7, height: 7)
                                    Text(zFamily.label)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        
                        // Weight indicator
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "gauge.with.dots.needle.50percent")
                                .font(.system(size: 11))
                                .foregroundColor(DT.gold)
                            Text("Element + Essence + Personality = your core scent identity")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(DT.gold)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(DT.ink.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: DT.radiusMD)
                            .stroke(DT.goldDeep.opacity(0.3), lineWidth: 0.5)
                    )
                    .padding(.bottom, 28)
                }
                
                // === RECOMMENDATIONS ===
                Text("CURATED FOR YOU")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(DT.gold)
                    .padding(.bottom, 4)
                
                Text("\(recommendations.count) fragrances matched to your profile")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 16)
                
                if recommendations.isEmpty {
                    EmptyStateCard()
                } else {
                    // First 5: Profile + Scent Profile matches
                    ForEach(Array(recommendations.prefix(5).enumerated()), id: \.element.id) { index, fragrance in
                        FragranceCard(
                            fragrance: fragrance,
                            rank: index + 1,
                            isExpanded: expandedCard == fragrance.id,
                            traits: traits,
                            profile: profile,
                            dimensionContributions: contributionsForFamily(fragrance.family),
                            allFragrances: recommendations,
                            blendFamilies: Array(topFamilies.prefix(2))
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedCard = expandedCard == fragrance.id ? nil : fragrance.id
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    
                    // Climate picks separator
                    if recommendations.count > 5 {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(DT.goldDeep.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("CLIMATE PICKS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(DT.gold)
                                .fixedSize()
                            
                            RoundedRectangle(cornerRadius: 1)
                                .fill(DT.goldDeep.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 12)
                        
                        Text(profile.climate.isEmpty ? "Based on your climate" : "Based on your \(profile.climate) climate")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.bottom, 12)
                        
                        ForEach(Array(recommendations.dropFirst(5).enumerated()), id: \.element.id) { index, fragrance in
                            FragranceCard(
                                fragrance: fragrance,
                                rank: index + 6,
                                isExpanded: expandedCard == fragrance.id,
                                traits: traits,
                                profile: profile,
                                dimensionContributions: contributionsForFamily(fragrance.family),
                                allFragrances: recommendations,
                                blendFamilies: Array(topFamilies.prefix(2))
                            ) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    expandedCard = expandedCard == fragrance.id ? nil : fragrance.id
                                }
                            }
                            .padding(.bottom, 12)
                        }
                    }
                }
                
                Spacer().frame(height: 36)
                
                // Save Dossier
                HStack {
                    Spacer()
                    Button {
                        ProfilePersistence.save(
                            profile: profile,
                            answers: [:],
                            topFamilies: topFamilies,
                            recommendations: recommendations
                        )
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSaveConfirmation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showSaveConfirmation = false }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showSaveConfirmation ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .font(.system(size: 14))
                            Text(showSaveConfirmation ? "Saved!" : "Save Dossier")
                        }
                        .frame(maxWidth: .infinity)
                        .goldButton()
                    }
                    Spacer()
                }
                .padding(.bottom, 12)
                
                // Chat Advisor button
                HStack {
                    Spacer()
                    Button {
                        onOpenAdvisor?()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.text.bubble.right")
                                .font(.system(size: 14))
                            Text("Ask Scent Advisor")
                        }
                        .frame(maxWidth: .infinity)
                        .goldButton()
                    }
                    Spacer()
                }
                .padding(.bottom, 12)
                
                // Reset
                HStack {
                    Spacer()
                    Button {
                        onReset()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("Start Over")
                        }
                        .secondaryButton()
                    }
                    Spacer()
                }
                
                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
}

// MARK: - Trait Bar

struct TraitBar: View {
    let label: String
    let value: Double
    let leftLabel: String
    let rightLabel: String
    
    @State private var animatedValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundColor(.white.opacity(0.7))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DT.inkSoft.opacity(0.4))
                        .frame(height: 4)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [DT.gold.opacity(0.6), DT.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * animatedValue, height: 4)
                    
                    // Indicator dot
                    Circle()
                        .fill(DT.gold)
                        .frame(width: 10, height: 10)
                        .shadow(color: DT.gold.opacity(0.4), radius: 3)
                        .offset(x: geo.size.width * animatedValue - 5)
                }
            }
            .frame(height: 10)
            
            HStack {
                Text(leftLabel)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(DT.parchmentDim.opacity(0.6))
                Spacer()
                Text(rightLabel)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(DT.parchmentDim.opacity(0.6))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedValue = value
            }
        }
    }
}

// MARK: - Fragrance Card

struct FragranceCard: View {
    let fragrance: Fragrance
    let rank: Int
    let isExpanded: Bool
    let traits: PersonalityTraits
    let profile: UserProfile
    let dimensionContributions: DimensionContributions
    let allFragrances: [Fragrance]
    var blendFamilies: [String] = []
    let onTap: () -> Void
    
    private var family: OlfactoryFamily? {
        allFamilies.first { $0.id == fragrance.family }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                // Rank + color bar
                VStack(spacing: 4) {
                    Text("#\(rank)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(DT.gold)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(family?.color ?? DT.inkSoft)
                        .frame(width: 4, height: 40)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(fragrance.house)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(DT.goldDeep)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Spacer(minLength: 8)
                        
                        Text(String(repeating: "$", count: fragrance.tier))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.black.opacity(0.7))
                        Text("~\(CurrencyConverter.convert(usd: fragrance.priceUSD, to: profile.currency))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.black.opacity(0.7))
                            .lineLimit(1)
                            .fixedSize()
                    }
                    
                    Text(fragrance.name)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    
                    HStack(spacing: 8) {
                        FamilyTag(text: family?.label ?? "", color: family?.color ?? DT.inkSoft)
                        Text("·")
                            .foregroundColor(.black.opacity(0.5))
                        Text(fragrance.longevity)
                            .font(.system(size: 11))
                            .foregroundColor(.black.opacity(0.7))
                            .lineLimit(1)
                        Text("·")
                            .foregroundColor(.black.opacity(0.5))
                        Text(fragrance.sillage)
                            .font(.system(size: 11))
                            .foregroundColor(.black.opacity(0.7))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    
                    // Blend families label
                    if blendFamilies.count >= 2 {
                        let blendLabels = blendFamilies.compactMap { id in
                            allFamilies.first(where: { $0.id == id })?.label
                        }
                        if blendLabels.count >= 2 {
                            Text("Your blend: \(blendLabels[0]) + \(blendLabels[1])")
                                .font(.system(size: 10))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                    
                    // Bottle shape + region badges
                    HStack(spacing: 8) {
                        if let shape = fragrance.bottleShape {
                            HStack(spacing: 4) {
                                Image(systemName: bottleShapeIcon(shape))
                                    .font(.system(size: 9))
                                    .foregroundColor(DT.goldDeep)
                                Text(shape.capitalized)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DT.gold.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        if let region = fragrance.region, region != "global" {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(DT.goldDeep)
                                Text(regionDisplayName(region))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DT.gold.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
            .padding(16)
            
            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(Color.black.opacity(0.15))
                    
                    // Note pyramid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE PYRAMID")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(.black.opacity(0.7))
                        
                        NoteRow(label: "Top", notes: fragrance.topNotes, icon: "arrow.up")
                        NoteRow(label: "Heart", notes: fragrance.heartNotes, icon: "heart")
                        NoteRow(label: "Base", notes: fragrance.baseNotes, icon: "arrow.down")
                    }
                    
                    // Occasion + Season
                    HStack(spacing: 16) {
                        DetailChip(icon: "calendar", text: fragrance.season)
                        DetailChip(icon: "sparkles", text: fragrance.occasion)
                    }
                    
                    // Why this match
                    Text("Why this works for you")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(DT.goldDeep)
                        .padding(.top, 4)
                    
                    Text(whyText)
                        .font(.system(size: 12.5))
                        .foregroundColor(.black.opacity(0.7))
                        .lineSpacing(2)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusMD)
                .stroke(isExpanded ? DT.gold.opacity(0.4) : .clear, lineWidth: 1)
        )
        .onTapGesture { onTap() }
    }
    
    private var whyText: String {
        RecommendationExplanationGenerator.generate(
            for: fragrance,
            scores: dimensionContributions,
            allFragrances: allFragrances,
            traits: traits,
            profile: profile
        ).text
    }
    
    private func bottleShapeIcon(_ shape: String) -> String {
        switch shape {
        case "round": return "circle"
        case "square": return "square"
        case "stylish": return "star"
        default: return "circle"
        }
    }
    
    private func regionDisplayName(_ region: String) -> String {
        switch region {
        case "india": return "Local · India"
        case "dubai": return "Local · Dubai"
        default: return region.capitalized
        }
    }
}

// MARK: - Supporting Views

struct FamilyTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.black.opacity(0.7))
        }
    }
}

struct NoteRow: View {
    let label: String
    let notes: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(DT.goldDeep)
                .frame(width: 14)
            
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.black.opacity(0.7))
                .frame(width: 36, alignment: .leading)
            
            Text(notes)
                .font(.system(size: 12.5))
                .foregroundColor(.black)
        }
    }
}

struct DetailChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(DT.goldDeep)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.black.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM))
    }
}

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wind")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.7))
            Text("No matches within those filters")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Text("Try widening your budget or fragrance preference")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
    }
}
