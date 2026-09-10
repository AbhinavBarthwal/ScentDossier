import SwiftUI

struct PersonalityView: View {
    @Binding var answers: [String: QuestionOption]
    @Binding var currentStep: Int
    
    @State private var activeIndex = 0
    
    private var questions: [PersonalityQuestion] { personalityQuestions }
    
    var isComplete: Bool {
        answers.count == questions.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 10) {
                ForEach(0..<questions.count, id: \.self) { i in
                    Circle()
                        .fill(answers[questions[i].id] != nil ? DT.gold : Color.white.opacity(0.1))
                        .frame(width: 8, height: 8)
                        .scaleEffect(i == activeIndex ? 1.4 : 1.0)
                        .animation(.easeInOut(duration: 0.25), value: activeIndex)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                activeIndex = i
                            }
                        }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Subtitle label
            Text(questions[activeIndex].subtitle.uppercased())
                .font(.system(size: 13, weight: .medium))
                .tracking(3)
                .foregroundColor(DT.gold)
                .padding(.bottom, 4)
                .id("sub-\(activeIndex)")
                .transition(.opacity)
            
            // Counter
            Text("\(activeIndex + 1) of \(questions.count)")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.35))
                .padding(.bottom, 24)
            
            Spacer()
            
            // Question — centered, large, dramatic
            Text(questions[activeIndex].text)
                .font(.system(size: 30, weight: .light, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 28)
                .id("q-\(activeIndex)")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 40)),
                    removal: .opacity.combined(with: .offset(x: -40))
                ))
            
            Spacer()
            
            // Options — full-width, stacked at the bottom
            VStack(spacing: 8) {
                ForEach(questions[activeIndex].options) { option in
                    let isSelected = answers[questions[activeIndex].id]?.id == option.id
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            answers[questions[activeIndex].id] = option
                        }
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Text(option.label)
                                .font(.system(size: 17, weight: isSelected ? .medium : .regular))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(DT.gold)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .id("opts-\(activeIndex)")
            .transition(.opacity)
            
            Spacer().frame(height: 28)
            
            // Navigation
            HStack {
                // Back: go to previous question or previous step
                Button {
                    if activeIndex > 0 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            activeIndex -= 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 1
                        }
                    }
                } label: {
                    Text(activeIndex > 0 ? "Previous" : "Back")
                        .secondaryButton()
                }
                
                Spacer()
                
                // Continue: next question or next step
                Button {
                    if activeIndex < questions.count - 1 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            activeIndex += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = 3
                        }
                    }
                } label: {
                    Text(activeIndex == questions.count - 1 ? "See Results" : "Next")
                        .goldButton()
                }
                .disabled(activeIndex == questions.count - 1 && !isComplete)
                .opacity(activeIndex == questions.count - 1 && !isComplete ? 0.4 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .animation(.easeInOut(duration: 0.35), value: activeIndex)
    }
}
