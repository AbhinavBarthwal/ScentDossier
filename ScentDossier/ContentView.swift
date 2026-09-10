import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentStep = 0
    @State private var profile = UserProfile()
    @State private var answers: [String: QuestionOption] = [:]
    @State private var showOnboarding = true
    @State private var showSavedDossiers = false
    @StateObject private var historyStore = ScentHistoryStore()
    @StateObject private var essenceHistoryStore = EssenceHistoryStore()
    
    private var traits: PersonalityTraits {
        ScoringEngine.computeTraits(from: answers)
    }
    
    private var essenceProfile: EssenceProfile? {
        guard let date = profile.birthDate else { return nil }
        return EssenceProfile.fromDate(date)
    }
    
    private var scores: [String: Double] {
        guard !profile.budget.isEmpty, !profile.genderPref.isEmpty else {
            return [:]
        }
        return ScoringEngine.weightedScoreFamilies(
            profile: profile,
            traits: traits,
            essenceProfile: essenceProfile
        )
    }
    
    private var topFamilyPair: [String] {
        guard !scores.isEmpty else { return [] }
        return ScoringEngine.topFamilies(scores: scores, count: 3)
    }
    
    private var recommendations: [Fragrance] {
        (try? ScoringEngine.matchCatalog(scores: scores, profile: profile)) ?? []
    }
    
    private let stepLabels = ["Essence", "Profile", "Personality", "Dossier", "Advisor"]
    
    var body: some View {
        ZStack {
            // Background
            DT.ink.ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .transition(.opacity)
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background && currentStep >= 3 {
                saveProfile()
            }
        }
        .onChange(of: currentStep) { _, newStep in
            if newStep == 3 {
                saveProfile()
            }
        }
    }
    
    private func saveProfile() {
        ProfilePersistence.save(
            profile: profile,
            answers: answers,
            topFamilies: topFamilyPair,
            recommendations: recommendations
        )
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Top bar
            headerBar
            
            // Step indicator
            stepIndicator
            
            // Content
            TabView(selection: $currentStep) {
                EssenceProfileView(profile: $profile, currentStep: $currentStep, essenceHistoryStore: essenceHistoryStore)
                    .tag(0)
                
                ProfileView(profile: $profile, currentStep: $currentStep)
                    .tag(1)
                
                PersonalityView(answers: $answers, currentStep: $currentStep)
                    .tag(2)
                
                ResultsView(
                    scores: scores,
                    topFamilies: topFamilyPair,
                    recommendations: recommendations,
                    traits: traits,
                    profile: profile,
                    essenceProfile: essenceProfile,
                    contributionsForFamily: { familyId in
                        self.contributionsForFamily(familyId)
                    }
                ) {
                    resetAll()
                } onOpenAdvisor: {
                    withAnimation { currentStep = 4 }
                }
                .tag(3)
                
                ChatView(
                    profile: profile,
                    traits: traits,
                    topFamilies: topFamilyPair,
                    recommendations: recommendations,
                    historyStore: historyStore
                )
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
    }
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("SCENT DOSSIER")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(3)
                    .foregroundColor(DT.gold)
                
                Text("Find your signature")
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Saved dossiers button
            Button {
                showSavedDossiers = true
            } label: {
                Image(systemName: "archivebox")
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .sheet(isPresented: $showSavedDossiers) {
            SavedDossiersView()
        }
    }
    
    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepLabels.count, id: \.self) { i in
                VStack(spacing: 6) {
                    Capsule()
                        .fill(i <= currentStep ? DT.gold : Color.white.opacity(0.08))
                        .frame(height: 3)
                    
                    Text(stepLabels[i])
                        .font(.system(size: 11, weight: i == currentStep ? .semibold : .regular))
                        .foregroundColor(i == currentStep ? DT.gold : Color.white.opacity(0.6))
                        .textCase(.uppercase)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private func resetAll() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentStep = 0
            profile = UserProfile()
            answers = [:]
        }
        ProfilePersistence.clear()
    }
    
    private func contributionsForFamily(_ familyId: String) -> DimensionContributions {
        ScoringEngine.dimensionContributions(
            for: familyId,
            profile: profile,
            traits: traits,
            essenceProfile: essenceProfile
        )
    }
}
