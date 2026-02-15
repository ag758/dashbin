import SwiftUI
import SwiftTerm

extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    static let dashbinPrimary = SwiftUI.Color(hex: "172884")
    static let dashbinAccent = SwiftUI.Color(hex: "00F5FF")
}

struct ContentView: View {
    @StateObject private var shelfViewModel = ShelfViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            //SwiftUI.Color.dashbinPrimary
                //.frame(height: 24)
            
            HSplitView {
                // Left: Main Content (Terminal)
                TerminalViewWrapper(viewModel: shelfViewModel)
                    .frame(minWidth: 400, minHeight: 300)
                    .background(SwiftUI.Color(red: 0.16, green: 0.16, blue: 0.18)) // Match terminal bg
                
                // Right: Sidebar (The Shelf)
                VStack(spacing: 0) {
                    // Search Bar Area (Themed)
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            ZStack(alignment: .leading) {
                                if let suggestion = shelfViewModel.suggestedCommand, 
                                   !shelfViewModel.searchText.isEmpty,
                                   suggestion.lowercased().hasPrefix(shelfViewModel.searchText.lowercased()) {
                                    
                                    let prefix = String(suggestion.prefix(shelfViewModel.searchText.count))
                                    let suffix = String(suggestion.dropFirst(shelfViewModel.searchText.count))
                                    
                                    // Use non-breaking spaces to preserve whitespace width
                                    let displayPrefix = prefix.replacingOccurrences(of: " ", with: "\u{00a0}")
                                    let displaySuffix = suffix.replacingOccurrences(of: " ", with: "\u{00a0}")
                                    
                                    (Text(displayPrefix).foregroundColor(SwiftUI.Color.clear) + Text(displaySuffix).foregroundColor(SwiftUI.Color.white.opacity(0.4)))
                                        .font(.system(.body, design: .monospaced))
                                        .allowsHitTesting(false)
                                }
                                
                                TextField("Search history...", text: $shelfViewModel.searchText)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white)
                                    .onKeyPress(.tab) {
                                        if let suggestion = shelfViewModel.suggestedCommand {
                                            shelfViewModel.searchText = suggestion
                                            return .handled
                                        }
                                        return .ignored
                                    }
                            }
                            
                            if shelfViewModel.suggestedCommand != nil && !shelfViewModel.searchText.isEmpty {
                                Text("TAB")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(SwiftUI.Color.white.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(10)
                        .background(SwiftUI.Color.black.opacity(0.15))
                        .cornerRadius(8)
                        .padding(12)
                    }
                    .background(SwiftUI.Color.dashbinPrimary)
                    
                    Divider()

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if shelfViewModel.filteredCommands.isEmpty {
                                    VStack(spacing: 12) {
                                        Spacer().frame(height: 40)
                                        Image(systemName: "clock")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary.opacity(0.3))
                                        Text("No history found")
                                            .font(.callout)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    ForEach(shelfViewModel.filteredCommands) { item in
                                        CommandRowView(item: item, viewModel: shelfViewModel)
                                            .id(item.id)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 8)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .clipped()
                }
                .frame(minWidth: 250, maxWidth: 350)
                .background(SwiftUI.Color(red: 0.07, green: 0.07, blue: 0.07)) // Dark Spotify-style Sidebar
            }
        }
    }
}

struct CommandRowView: View {
    let item: CommandItem
    @ObservedObject var viewModel: ShelfViewModel
    
    enum FeedbackState {
        case none
        case copied
        case executed
    }
    @State private var feedbackState: FeedbackState = .none
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if item.isPinned == true {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.dashbinAccent)
                            .rotationEffect(.degrees(45))
                    }
                    Text(item.command)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack {
                    Group {
                        switch feedbackState {
                        case .copied:
                            Label("Copied", systemImage: "checkmark")
                                .foregroundColor(.green)
                        case .executed:
                            Label("Running", systemImage: "play.fill")
                                .foregroundColor(.white)
                        case .none:
                            Text(item.timestamp, style: .time)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .font(.caption2)
                    .transition(.opacity)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle()) 
            .onTapGesture {
                viewModel.copyCommand(item.command)
                triggerFeedback(.copied)
            }
            
            // Actions (Visible on Hover)
            if isHovering {
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                             viewModel.togglePin(id: item.id)
                        }
                    }) {
                        Image(systemName: "pin.circle.fill")
                            .font(.title) // Larger icon
                            .foregroundColor((item.isPinned ?? false) ? .dashbinAccent : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation {
                            viewModel.deleteCommand(id: item.id)
                        }
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title) // Larger icon
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        viewModel.triggerRun(item.command)
                        triggerFeedback(.executed)
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title) // Larger icon
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? SwiftUI.Color.white.opacity(0.1) : SwiftUI.Color.clear)
        )
        .contextMenu {
            Button {
                withAnimation {
                    viewModel.togglePin(id: item.id)
                }
            } label: {
                Label((item.isPinned ?? false) ? "Unpin" : "Pin", systemImage: "pin")
            }
            
            Button(role: .destructive) {
                withAnimation {
                    viewModel.deleteCommand(id: item.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                viewModel.copyCommand(item.command)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hover
            }
        }
    }
    
    private func triggerFeedback(_ state: FeedbackState) {
        withAnimation {
            feedbackState = state
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                feedbackState = .none
            }
        }
    }
}

#Preview {
    ContentView()
}
