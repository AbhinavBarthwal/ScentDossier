import SwiftUI

/// Displays the Life Path personality trait derived from the user's date of birth.
/// Hidden when `essenceProfile` is nil (DOB not set).
struct PersonalityTraitsCard: View {
    let essenceProfile: EssenceProfile?

    var body: some View {
        if let essence = essenceProfile {
            traitContent(essence)
        }
    }

    // MARK: - Trait Content

    @ViewBuilder
    private func traitContent(_ essence: EssenceProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("NUMEROLOGY TRAIT")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(DT.gold)

            // Life Path trait row
            traitRow(
                number: essence.lifePathTrait.number,
                label: "Life Path",
                description: essence.lifePathTrait.description,
                scentFamily: essence.lifePathTrait.scentFamily,
                isMaster: essence.lifePathTrait.isMaster,
                dotColor: DT.gold
            )
        }
        .padding(20)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: DT.radiusMD)
                .stroke(DT.gold.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Single Trait Row

    @ViewBuilder
    private func traitRow(
        number: Int,
        label: String,
        description: String,
        scentFamily: String,
        isMaster: Bool,
        dotColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Number badge
            VStack(spacing: 4) {
                Text("\(number)")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundColor(.white)

                if isMaster {
                    Text("MASTER")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(DT.gold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DT.gold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            .frame(width: 52)
            .padding(.vertical, 8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM))

            // Trait details
            VStack(alignment: .leading, spacing: 6) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(.white.opacity(0.7))

                // Trait phrase
                HStack(spacing: 6) {
                    Circle().fill(dotColor).frame(width: 5, height: 5)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }

                // Linked scent family
                if let family = allFamilies.first(where: { $0.id == scentFamily }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(family.color)
                            .frame(width: 8, height: 8)
                        Text(family.label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}
