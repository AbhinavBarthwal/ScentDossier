import SwiftUI

struct SavedDossiersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dossiers: [SavedProfile] = []
    @State private var expandedId: UUID?
    
    var body: some View {
        NavigationStack {
            ZStack {
                DT.ink.ignoresSafeArea()
                
                if dossiers.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(dossiers) { dossier in
                                DossierCard(
                                    dossier: dossier,
                                    isExpanded: expandedId == dossier.id,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            expandedId = expandedId == dossier.id ? nil : dossier.id
                                        }
                                    },
                                    onDelete: {
                                        withAnimation {
                                            ProfilePersistence.delete(id: dossier.id)
                                            dossiers = ProfilePersistence.loadAll()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Saved Dossiers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(DT.gold)
                }
                if !dossiers.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            withAnimation {
                                ProfilePersistence.clear()
                                dossiers = []
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundColor(DT.rose)
                    }
                }
            }
            .toolbarBackground(DT.ink, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            dossiers = ProfilePersistence.loadAll()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(.white.opacity(0.5))
            Text("No saved dossiers yet")
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.white.opacity(0.5))
            Text("Complete your profile and tap Save Dossier on the results page")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Dossier Card

struct DossierCard: View {
    let dossier: SavedProfile
    let isExpanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var displayName: String {
        dossier.profile.name.isEmpty ? "Unnamed" : dossier.profile.name
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dossier.savedAt)
    }
    
    private var zodiacSymbol: String {
        guard let date = dossier.profile.birthDate else { return "" }
        return ZodiacSign.from(date: date).symbol
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 14) {
                // Zodiac badge
                if !zodiacSymbol.isEmpty {
                    Text(zodiacSymbol)
                        .font(.system(size: 22))
                        .frame(width: 40, height: 40)
                        .background(DT.gold.opacity(0.1))
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                        .foregroundColor(DT.parchment)
                    
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.35))
                }
                
                Spacer()
                
                // Top families dots
                HStack(spacing: 4) {
                    ForEach(dossier.topFamilies.prefix(3), id: \.self) { familyId in
                        if let family = allFamilies.first(where: { $0.id == familyId }) {
                            Circle()
                                .fill(family.color)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(18)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 1)
                    
                    // Scent Profile Web
                    if let element = dossier.elementName {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SCENT PROFILE WEB")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(DT.gold)
                            
                            HStack(spacing: 8) {
                                Text("①")
                                    .font(.system(size: 14))
                                    .foregroundColor(DT.gold)
                                Text("\(element) Element")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                if let zodiac = dossier.zodiacName {
                                    Text("· \(zodiac)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            if let lp = dossier.lifePathNumber {
                                HStack(spacing: 8) {
                                    Text("②")
                                        .font(.system(size: 14))
                                        .foregroundColor(DT.gold)
                                    Text("Life Path \(lp)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    if let family = dossier.essenceFamily,
                                       let fam = allFamilies.first(where: { $0.id == family }) {
                                        HStack(spacing: 4) {
                                            Circle().fill(fam.color).frame(width: 6, height: 6)
                                            Text(fam.label)
                                                .font(.system(size: 13))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                            }
                            
                            if let notes = dossier.signatureNotes, !notes.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "leaf")
                                        .font(.system(size: 11))
                                        .foregroundColor(DT.gold)
                                    Text(notes.joined(separator: " · "))
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    
                    // Top families
                    HStack(spacing: 8) {
                        ForEach(dossier.topFamilies.prefix(3), id: \.self) { familyId in
                            if let family = allFamilies.first(where: { $0.id == familyId }) {
                                HStack(spacing: 5) {
                                    Circle().fill(family.color).frame(width: 6, height: 6)
                                    Text(family.label)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(family.color.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Profile summary
                    if !dossier.profile.location.isEmpty {
                        DetailLabel(icon: "mappin", text: dossier.profile.location)
                    }
                    if !dossier.profile.climate.isEmpty {
                        DetailLabel(icon: "cloud.sun", text: dossier.profile.climate.capitalized)
                    }
                    if !dossier.profile.mood.isEmpty {
                        DetailLabel(icon: "heart", text: "Mood: \(dossier.profile.mood.capitalized)")
                    }
                    
                    // Recommendations preview
                    if !dossier.recommendations.isEmpty {
                        Text("RECOMMENDATIONS")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(DT.gold)
                            .padding(.top, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(dossier.recommendations.prefix(5).enumerated()), id: \.offset) { i, frag in
                                HStack(spacing: 8) {
                                    Text("#\(i + 1)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(DT.gold)
                                        .frame(width: 20)
                                    
                                    if let family = allFamilies.first(where: { $0.id == frag.family }) {
                                        Circle().fill(family.color).frame(width: 6, height: 6)
                                    }
                                    
                                    Text("\(frag.name)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(DT.parchment)
                                    
                                    Text("— \(frag.house)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Delete
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text("Delete")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(DT.rose)
                            .padding(.vertical, 8)
                        }
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusMD, style: .continuous)
                .stroke(isExpanded ? DT.gold.opacity(0.3) : DT.cardBorder, lineWidth: 1)
        )
        .onTapGesture { onTap() }
    }
}

// MARK: - Detail Label

private struct DetailLabel: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 16)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
