import SwiftUI

// MARK: - Chat View

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @State private var showApiKeySheet = false
    @FocusState private var isInputFocused: Bool
    
    init(
        profile: UserProfile,
        traits: PersonalityTraits,
        topFamilies: [String],
        recommendations: [Fragrance],
        historyStore: ScentHistoryStore
    ) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(
            profile: profile,
            traits: traits,
            topFamilies: topFamilies,
            recommendations: recommendations,
            historyStore: historyStore
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message) { reply in
                                viewModel.sendQuickReply(reply)
                            }
                            .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            TypingIndicator()
                                .id("typing")
                        }
                        
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    isInputFocused = false
                }
                .onChange(of: viewModel.messages.count) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        if viewModel.isLoading {
                            proxy.scrollTo("typing", anchor: .bottom)
                        } else if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input bar
            if viewModel.hasApiKey {
                inputBar
            } else {
                apiKeyPrompt
            }
        }
        .background(DT.ink.ignoresSafeArea())
        .sheet(isPresented: $showApiKeySheet) {
            ApiKeySheet(viewModel: viewModel, isPresented: $showApiKeySheet)
        }
    }
    
    // MARK: - Header
    
    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SCENT ADVISOR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(DT.gold)
                
                Text("Your personal fragrance consultant")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button {
                showApiKeySheet = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DT.ink.opacity(0.95))
    }
    
    // MARK: - Input Bar
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about fragrances…", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DT.card)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)
            
            Button {
                viewModel.sendMessage()
                isInputFocused = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty ? DT.inkSoft : DT.gold)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DT.ink.opacity(0.98))
    }
    
    // MARK: - API Key Prompt
    
    private var apiKeyPrompt: some View {
        VStack(spacing: 12) {
            Text("To chat with the Scent Advisor, add your free Groq API key.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Add API Key") {
                showApiKeySheet = true
            }
            .goldButton()
        }
        .padding(20)
        .background(DT.ink.opacity(0.98))
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let onQuickReply: (String) -> Void
    
    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
            HStack {
                if message.role == .user { Spacer(minLength: 60) }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(message.role == .user ? DT.ink : DT.parchment)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.role == .user
                    ? AnyShapeStyle(DT.parchment)
                    : AnyShapeStyle(DT.inkSoft.opacity(0.5))
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
                if message.role == .assistant { Spacer(minLength: 40) }
            }
            
            // Quick reply chips
            if message.role == .assistant && !message.quickReplies.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(message.quickReplies, id: \.self) { reply in
                            Button {
                                onQuickReply(reply)
                            } label: {
                                Text(reply)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(DT.gold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(DT.inkSoft.opacity(0.4))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(DT.gold.opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                    .padding(.leading, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(DT.gold.opacity(0.6))
                    .frame(width: 7, height: 7)
                    .offset(y: index == Int(dotOffset) ? -4 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(DT.inkSoft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                dotOffset = 2
            }
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 12))
                .foregroundColor(DT.rose)
            
            Text(message)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DT.rose.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - API Key Sheet

struct ApiKeySheet: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var isPresented: Bool
    @State private var keyInput = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                DT.ink.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    Text("Groq API Key")
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Groq offers a free API — no credit card needed. Your key is stored securely in the device Keychain and never leaves your device.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API KEY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(DT.gold)
                        
                        SecureField("gsk_...", text: $keyInput)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(DT.inkSoft.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: DT.radiusSM))
                    }
                    
                    Button {
                        viewModel.saveApiKey(keyInput)
                        isPresented = false
                    } label: {
                        Text("Save Key")
                            .frame(maxWidth: .infinity)
                            .goldButton()
                    }
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    if viewModel.hasApiKey {
                        Button {
                            viewModel.clearApiKey()
                            keyInput = ""
                        } label: {
                            Text("Remove Saved Key")
                                .font(.system(size: 13))
                                .foregroundColor(DT.rose)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HOW TO GET A FREE KEY")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(DT.gold)
                        
                        Text("1. Go to console.groq.com\n2. Sign up (free, no credit card)\n3. Go to API Keys section\n4. Create a new key\n5. Paste it above")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                    }
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .foregroundColor(DT.gold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

