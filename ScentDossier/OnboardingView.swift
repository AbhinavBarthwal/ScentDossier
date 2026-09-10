import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [(title: String, subtitle: String, icon: String)] = [
        ("Scent Dossier", "A curated fragrance profiling experience", "wind"),
        ("Your Profile", "Climate, lifestyle, and aesthetic — the raw materials of your scent identity", "person.crop.circle"),
        ("Personality", "Quick questions to find your scent personality", "brain.head.profile"),
        ("Your Wheel", "A living radial chart — your unique scent fingerprint", "circle.hexagongrid"),
    ]
    
    var body: some View {
        ZStack {
            DT.ink.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                Image(systemName: pages[currentPage].icon)
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(DT.gold.gradient)
                    .frame(height: 64)
                    .padding(.bottom, 40)
                    .id(currentPage)
                    .transition(.opacity)
                
                // Title
                Text(pages[currentPage].title)
                    .font(.system(size: 34, weight: .light, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .id("title-\(currentPage)")
                    .transition(.opacity)
                
                // Subtitle
                Text(pages[currentPage].subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 44)
                    .padding(.top, 16)
                    .id("sub-\(currentPage)")
                    .transition(.opacity)
                
                Spacer()
                Spacer()
                
                // Page dots
                HStack(spacing: 10) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? DT.gold : Color.white.opacity(0.15))
                            .frame(width: i == currentPage ? 20 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 40)
                
                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showOnboarding = false
                        }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Begin")
                        .goldButton()
                }
                .padding(.bottom, 16)
                
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation {
                            showOnboarding = false
                        }
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                    }
                }
                
                Spacer().frame(height: 36)
            }
        }
    }
}
