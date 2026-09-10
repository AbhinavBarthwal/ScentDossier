import SwiftUI
import CoreLocation

// MARK: - Profile Step Definition

private struct ProfileStep: Identifiable {
    let id: Int
    let question: String
    let subtitle: String
}

private let profileSteps: [ProfileStep] = [
    ProfileStep(id: 0, question: "Where do you live?", subtitle: "Location"),
    ProfileStep(id: 1, question: "How would you describe your skin?", subtitle: "Skin"),
    ProfileStep(id: 2, question: "What's your personal style?", subtitle: "Aesthetic"),
    ProfileStep(id: 3, question: "What does a typical workday look like?", subtitle: "Lifestyle"),
    ProfileStep(id: 4, question: "When will you wear this fragrance most?", subtitle: "Occasion"),
    ProfileStep(id: 5, question: "How much are you willing to invest?", subtitle: "Budget"),
    ProfileStep(id: 6, question: "Which direction should your fragrance lean?", subtitle: "Character"),
    ProfileStep(id: 7, question: "Vintage house or modern release?", subtitle: "Era"),
    ProfileStep(id: 8, question: "What mood do you want to carry?", subtitle: "Mood"),
]

// MARK: - Profile View (step-by-step, conversational)

struct ProfileView: View {
    @Binding var profile: UserProfile
    @Binding var currentStep: Int
    
    @State private var activeStep = 0
    
    // Climate inference
    @State private var isInferringClimate = false
    @State private var climateInferenceTask: Task<Void, Never>?
    @State private var showManualClimatePicker = false
    @State private var resolvedLocationName: String = ""
    
    private var eraOptions: [(String, String)] {
        if let birthDate = profile.birthDate {
            let birthYear = Calendar.current.component(.year, from: birthDate)
            let classicCutoff = birthYear - 5
            return [
                ("classic", "Classic (before \(classicCutoff))"),
                ("new", "New (\(birthYear) onwards)"),
                ("both", "Both"),
            ]
        }
        return [
            ("classic", "Classic (older releases)"),
            ("new", "New (recent releases)"),
            ("both", "Both"),
        ]
    }
    
    private var canContinueToNext: Bool {
        switch activeStep {
        case 0: return !profile.location.isEmpty && !profile.climate.isEmpty
        case 1: return !profile.skin.isEmpty
        case 2: return !profile.styling.isEmpty
        case 3: return !profile.work.isEmpty
        case 4: return !profile.occasion.isEmpty
        case 5: return !profile.budget.isEmpty
        case 6: return !profile.genderPref.isEmpty
        case 7: return !profile.era.isEmpty
        case 8: return !profile.mood.isEmpty
        default: return false
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 4) {
                ForEach(0..<profileSteps.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= activeStep ? DT.gold : Color.white.opacity(0.08))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Subtitle
            Text(profileSteps[activeStep].subtitle.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(3)
                .foregroundColor(DT.gold)
                .padding(.bottom, 4)
                .id("psub-\(activeStep)")
                .transition(.opacity)
            
            // Counter
            Text("\(activeStep + 1) of \(profileSteps.count)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 20)
            
            // Question
            Text(profileSteps[activeStep].question)
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
                .id("pq-\(activeStep)")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 40)),
                    removal: .opacity.combined(with: .offset(x: -40))
                ))
            
            // Answer area
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    answerContent
                        .padding(.horizontal, 20)
                        .id("pans-\(activeStep)")
                        .transition(.opacity)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            
            Spacer().frame(height: 12)
            
            // Navigation
            HStack {
                Button {
                    if activeStep > 0 {
                        withAnimation(.easeInOut(duration: 0.35)) { activeStep -= 1 }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) { currentStep = 0 }
                    }
                } label: {
                    Text(activeStep > 0 ? "Previous" : "Back")
                        .secondaryButton()
                }
                
                Spacer()
                
                Button {
                    if activeStep < profileSteps.count - 1 {
                        withAnimation(.easeInOut(duration: 0.35)) { activeStep += 1 }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) { currentStep = 2 }
                    }
                } label: {
                    Text(activeStep == profileSteps.count - 1 ? "Continue" : "Next")
                        .goldButton()
                }
                .disabled(!canContinueToNext)
                .opacity(canContinueToNext ? 1 : 0.4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .animation(.easeInOut(duration: 0.35), value: activeStep)
        .onChange(of: profile.location) { _, newValue in
            triggerClimateInference(for: newValue)
        }
    }
    
    // MARK: - Answer Content (per step)
    
    @ViewBuilder
    private var answerContent: some View {
        switch activeStep {
        case 0:
            locationStep
        case 1:
            pickerStep(selection: $profile.skin, options: [
                ("oily", "Oily"),
                ("dry", "Dry"),
                ("combination", "Combination"),
            ])
        case 2:
            pickerStep(selection: $profile.styling, options: [
                ("classic", "Classic / Polished"),
                ("casual", "Casual / Relaxed"),
                ("edgy", "Edgy / Statement"),
                ("minimalist", "Minimalist / Clean"),
            ])
        case 3:
            pickerStep(selection: $profile.work, options: [
                ("corporate", "Corporate / Formal"),
                ("creative", "Creative / Expressive"),
                ("outdoor", "Outdoor / Active"),
                ("remote", "Remote / Low-key"),
            ])
        case 4:
            pickerStep(selection: $profile.occasion, options: [
                ("everyday", "Everyday"),
                ("office", "Office / Work"),
                ("evening", "Evening / Night Out"),
                ("special", "Special Occasion"),
            ])
        case 5:
            budgetStep
        case 6:
            pickerStep(selection: $profile.genderPref, options: [
                ("feminine", "Feminine-leaning"),
                ("masculine", "Masculine-leaning"),
                ("unisex", "Unisex only"),
            ])
        case 7:
            pickerStep(selection: $profile.era, options: eraOptions)
        case 8:
            pickerStep(selection: $profile.mood, options: [
                ("energetic", "Energetic"),
                ("cool", "Feel Cool"),
                ("relaxed", "Relaxed"),
                ("focused", "Focused"),
                ("love", "Love"),
            ])
        default:
            EmptyView()
        }
    }
    
    // MARK: - Location Step (text field + climate)
    
    private var locationStep: some View {
        VStack(spacing: 16) {
            TextField("e.g. Mumbai, India", text: $profile.location)
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
            
            // Climate status
            if isInferringClimate {
                HStack(spacing: 10) {
                    ProgressView().tint(.white).scaleEffect(0.8)
                    Text("Detecting climate…")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else if !profile.climate.isEmpty && !showManualClimatePicker {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: climateIcon(for: profile.climate))
                            .font(.system(size: 16))
                            .foregroundColor(DT.gold)
                        Text(profile.climate.capitalized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        if !resolvedLocationName.isEmpty {
                            Text("· \(resolvedLocationName)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                    
                    // Temperature & Humidity
                    if let weather = profile.currentWeather {
                        HStack(spacing: 16) {
                            HStack(spacing: 5) {
                                Image(systemName: "thermometer.medium")
                                    .font(.system(size: 13))
                                    .foregroundColor(DT.gold.opacity(0.8))
                                Text("\(Int(weather.temperature.rounded()))°C / \(Int(weather.temperatureF.rounded()))°F")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            
                            HStack(spacing: 5) {
                                Image(systemName: "humidity.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(DT.gold.opacity(0.8))
                                Text("\(weather.humidity)%")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if showManualClimatePicker {
                pickerStep(selection: $profile.climate, options: [
                    ("hot", "Hot / Tropical"),
                    ("cold", "Cold / Winter-heavy"),
                    ("temperate", "Mild / Temperate"),
                    ("humid", "Humid / Rainy"),
                    ("dry", "Dry / Arid"),
                ])
            }
        }
    }
    
    // MARK: - Budget Step (with currency)
    
    private var budgetStep: some View {
        VStack(spacing: 16) {
            pickerStep(selection: $profile.budget, options: [
                ("1", "$ Everyday (\(CurrencyConverter.budgetRange(tier: 1, currencyCode: profile.currency)))"),
                ("2", "$$ Mid-range (\(CurrencyConverter.budgetRange(tier: 2, currencyCode: profile.currency)))"),
                ("3", "$$$ Premium (\(CurrencyConverter.budgetRange(tier: 3, currencyCode: profile.currency)))"),
                ("4", "$$$$ Luxury (\(CurrencyConverter.budgetRange(tier: 4, currencyCode: profile.currency)))"),
            ])
            
            // Inline currency toggle
            HStack(spacing: 8) {
                Text("Currency:")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                
                Menu {
                    ForEach(supportedCurrencies) { currency in
                        Button {
                            profile.currency = currency.id
                        } label: {
                            HStack {
                                Text("\(currency.symbol) \(currency.id)")
                                if profile.currency == currency.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let c = supportedCurrencies.first(where: { $0.id == profile.currency }) {
                            Text("\(c.symbol) \(c.id)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    // MARK: - Generic Picker Step
    
    private func pickerStep(selection: Binding<String>, options: [(String, String)]) -> some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.0) { (value, title) in
                let isSelected = selection.wrappedValue == value
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection.wrappedValue = value
                    }
                } label: {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: isSelected ? .medium : .regular))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DT.gold)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Climate Inference
    
    private func triggerClimateInference(for location: String) {
        climateInferenceTask?.cancel()
        showManualClimatePicker = false
        resolvedLocationName = ""
        
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 && trimmed.count <= 100 else {
            isInferringClimate = false
            profile.climate = ""
            return
        }
        
        isInferringClimate = true
        climateInferenceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            
            do {
                let result = try await ClimateInferenceService().inferClimateWithGeocoding(from: trimmed)
                guard !Task.isCancelled else { return }
                profile.climate = result.climate.rawValue
                profile.currentWeather = result.weather
                resolvedLocationName = result.resolvedLocationName
                isInferringClimate = false
                showManualClimatePicker = false
            } catch {
                guard !Task.isCancelled else { return }
                isInferringClimate = false
                showManualClimatePicker = true
            }
        }
    }
    
    private func climateIcon(for climate: String) -> String {
        switch climate {
        case "hot": return "sun.max.fill"
        case "cold": return "snowflake"
        case "temperate": return "cloud.sun.fill"
        case "humid": return "humidity.fill"
        case "dry": return "wind"
        default: return "thermometer.medium"
        }
    }
}

// MARK: - Reusable Form Components (kept for other views)

struct ProfilePicker: View {
    let label: String
    @Binding var selection: String
    let options: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color.white.opacity(0.8))
            
            VStack(spacing: 6) {
                ForEach(options, id: \.0) { (value, title) in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = value
                        }
                    } label: {
                        HStack {
                            Text(title)
                                .font(.system(size: 17))
                                .foregroundColor(selection == value ? .white : .white.opacity(0.75))
                            Spacer()
                            if selection == value {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(DT.gold)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(selection == value ? Color.white.opacity(0.1) : DT.card)
                        .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous)
                                .stroke(selection == value ? Color.white.opacity(0.3) : DT.cardBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

struct ProfileTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color.white.opacity(0.8))
            
            TextField(placeholder, text: $text)
                .font(.system(size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(DT.card)
                .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DT.radiusSM, style: .continuous)
                        .stroke(isFocused ? Color.white.opacity(0.4) : DT.cardBorder, lineWidth: 1)
                )
                .keyboardType(keyboardType)
                .submitLabel(.done)
                .onSubmit { isFocused = false }
                .focused($isFocused)
        }
    }
}
