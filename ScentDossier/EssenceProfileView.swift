import SwiftUI

struct EssenceProfileView: View {
    @Binding var profile: UserProfile
    @Binding var currentStep: Int
    @ObservedObject var essenceHistoryStore: EssenceHistoryStore
    
    @State private var showHistory = false
    
    private var isComplete: Bool {
        profile.birthDate != nil
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("ESSENCE PROFILE")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(3)
                    .foregroundColor(DT.gold)
                    .padding(.bottom, 8)
                
                Text("Your Numbers")
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .foregroundColor(.white)
                    .padding(.bottom, 6)
                
                Text("Your date of birth reveals a Life Path number — a fixed trait that shapes your scent identity.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                    .padding(.bottom, 32)
                
                // Input card
                VStack(spacing: 24) {
                    // Name
                    ProfileTextField(label: "Your Name", placeholder: "e.g. Paras", text: $profile.name)
                    
                    // DOB
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DATE OF BIRTH")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(.white.opacity(0.8))
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { profile.birthDate ?? Calendar.current.date(byAdding: .year, value: -25, to: Date())! },
                                set: { profile.birthDate = $0 }
                            ),
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(DT.gold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(DT.card)
                        .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous)
                                .stroke(DT.cardBorder, lineWidth: 1)
                        )
                    }
                }
                .padding(24)
                .background(DT.card)
                .clipShape(RoundedRectangle(cornerRadius: DT.radiusMD, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DT.radiusMD, style: .continuous)
                        .stroke(DT.cardBorder, lineWidth: 1)
                )
                
                // Confirmation
                if profile.birthDate != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(DT.gold)
                        Text("Date of birth recorded")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 16)
                }
                
                // History
                if !essenceHistoryStore.entries.isEmpty {
                    Button {
                        showHistory = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 13))
                            Text("Saved Profiles")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                            Text("\(essenceHistoryStore.entries.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(DT.gold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(DT.gold.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(DT.card)
                        .foregroundColor(.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous)
                                .stroke(DT.cardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.top, 16)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 12) {
                    Label("How this works", systemImage: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DT.gold)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        InfoBullet(text: "Your date of birth gives a Life Path number (1–9, 11, 22)")
                        InfoBullet(text: "This is the primary force shaping your scent profile")
                        InfoBullet(text: "Full essence reading revealed on the Results page")
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous))
                .padding(.top, 20)
                
                Spacer().frame(height: 40)
                
                // Navigation
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 1
                        }
                    } label: {
                        Text("Continue")
                            .goldButton()
                    }
                    .disabled(!isComplete)
                    .opacity(isComplete ? 1 : 0.4)
                }
                
                if !isComplete {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentStep = 1
                            }
                        } label: {
                            Text("Skip this step")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 10)
                        }
                        Spacer()
                    }
                }
                
                Spacer().frame(height: 60)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .scrollDismissesKeyboard(.immediately)
        .sheet(isPresented: $showHistory) {
            EssenceHistoryView(store: essenceHistoryStore)
        }
    }
}
