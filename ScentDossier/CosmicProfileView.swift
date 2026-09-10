import SwiftUI

struct CosmicProfileView: View {
    @Binding var profile: UserProfile
    @Binding var currentStep: Int
    @ObservedObject var cosmicHistoryStore: CosmicHistoryStore
    
    @State private var showHistory = false
    
    private var isComplete: Bool {
        profile.birthDate != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            Text("COSMIC PROFILE")
                .font(.system(size: 13, weight: .medium))
                .tracking(3)
                .foregroundColor(DT.gold)
                .padding(.bottom, 8)
            
            Text("Your Numbers")
                .font(.system(size: 32, weight: .light, design: .serif))
                .foregroundColor(.white)
                .padding(.bottom, 6)
            
            Text("Your date of birth reveals a Life Path number\nthat shapes your scent identity.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            
            // Name
            VStack(spacing: 16) {
                TextField("Your name", text: $profile.name)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .submitLabel(.done)
                
                // DOB
                VStack(spacing: 8) {
                    Text("DATE OF BIRTH")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.6))
                    
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
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 32)
            
            // Confirmation
            if profile.birthDate != nil {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(DT.gold)
                    Text("Date of birth recorded")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 20)
            }
            
            Spacer()
            Spacer()
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Label("How this works", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DT.gold)
                
                VStack(alignment: .leading, spacing: 6) {
                    InfoBullet(text: "Your date of birth gives a Life Path number (1–9, 11, 22)")
                    InfoBullet(text: "This is the primary force shaping your scent profile")
                    InfoBullet(text: "Full cosmic reading revealed on the Results page")
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 28)
            
            // Navigation
            HStack {
                // History
                if !cosmicHistoryStore.entries.isEmpty {
                    Button {
                        showHistory = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 14))
                            Text("\(cosmicHistoryStore.entries.count)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .secondaryButton()
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { currentStep = 1 }
                } label: {
                    Text(isComplete ? "Continue" : "Skip")
                        .goldButton()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .scrollDismissesKeyboard(.immediately)
        .sheet(isPresented: $showHistory) {
            CosmicHistoryView(store: cosmicHistoryStore)
        }
    }
}
