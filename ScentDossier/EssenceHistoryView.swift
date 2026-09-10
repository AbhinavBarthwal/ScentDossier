import SwiftUI

struct EssenceHistoryView: View {
    @ObservedObject var store: EssenceHistoryStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DT.ink.ignoresSafeArea()
                
                if store.entries.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(store.entries) { entry in
                                EssenceHistoryCard(entry: entry) {
                                    withAnimation {
                                        store.remove(entry)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Saved Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(DT.gold)
                }
                if !store.entries.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear All") {
                            withAnimation { store.removeAll() }
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
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.7))
            Text("No saved profiles yet")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.7))
            Text("Save an essence profile to see it here")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - History Card

struct EssenceHistoryCard: View {
    let entry: EssenceHistoryEntry
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: entry.dateSaved)
    }
    
    private var formattedBirthDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: entry.birthDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                // Zodiac symbol
                if let zodiac = entry.zodiac {
                    Text(zodiac.symbol)
                        .font(.system(size: 24))
                        .frame(width: 36, height: 36)
                        .background(DT.gold.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Name and date
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("Saved \(formattedDate)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                // Life Path badge
                VStack(spacing: 2) {
                    Text("\(entry.lifePathNumber)")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                    Text("LP")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider().background(DT.parchmentDim)
                    
                    DetailRow(label: "Born", value: formattedBirthDate)
                    
                    if let zodiac = entry.zodiac {
                        DetailRow(label: "Sign", value: "\(zodiac.displayName) · \(zodiac.element) · \(zodiac.rulingPlanet)")
                        DetailRow(label: "Traits", value: zodiac.traitKeywords.joined(separator: ", "))
                    }
                    
                    DetailRow(label: "Life Path \(entry.lifePathNumber)\(entry.lifePathIsMaster ? " ✦" : "")", value: entry.lifePathDescription)
                    
                    if let family = allFamilies.first(where: { $0.id == entry.scentLeaning }) {
                        HStack(spacing: 6) {
                            Text("Scent leaning:")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                            Circle()
                                .fill(family.color)
                                .frame(width: 7, height: 7)
                            Text(family.label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                    
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text("Remove")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(DT.rose)
                        }
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusMD)
                .stroke(isExpanded ? DT.gold.opacity(0.4) : .clear, lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(DT.goldDeep)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.system(size: 12.5))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
