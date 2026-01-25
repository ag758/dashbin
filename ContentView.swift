import SwiftUI
import SwiftTerm

struct ContentView: View {
    @StateObject private var shelfViewModel = ShelfViewModel()
    
    var body: some View {
        HSplitView {
            // Left: Main Content (Terminal)
            TerminalViewWrapper(viewModel: shelfViewModel)
                .frame(minWidth: 400, minHeight: 300)
                .background(Color(red: 0.16, green: 0.16, blue: 0.18)) // Match terminal bg
            
            // Right: Sidebar (The Shelf)
            VStack(spacing: 0) {
                // Modern Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .leading) {
                        // Ghost Text (Autocomplete Suggestion)
                        if let suggestion = shelfViewModel.suggestedCommand, 
                           !shelfViewModel.searchText.isEmpty,
                           suggestion.lowercased().hasPrefix(shelfViewModel.searchText.lowercased()) {
                            
                            // Construct the ghost text with invisible prefix to assume perfect alignment
                            // This works best with Monospaced font
                            let prefix = String(suggestion.prefix(shelfViewModel.searchText.count))
                            let suffix = String(suggestion.dropFirst(shelfViewModel.searchText.count))
                            
                            (Text(prefix).foregroundColor(.clear) + Text(suffix).foregroundColor(.secondary.opacity(0.5)))
                                .font(.system(.body, design: .monospaced))
                                .allowsHitTesting(false)
                        }
                        
                        TextField("Search history...", text: $shelfViewModel.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .onKeyPress(.tab) {
                                if let suggestion = shelfViewModel.suggestedCommand {
                                    shelfViewModel.searchText = suggestion
                                    return .handled
                                }
                                return .ignored
                            }
                    }
                    
                    // Visual Hint for Autocomplete
                    if shelfViewModel.suggestedCommand != nil && !shelfViewModel.searchText.isEmpty {
                        Text("TAB")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                )
                .padding(12)
                .background(.regularMaterial)
                .zIndex(1) // Ensure it shadows content
                
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
                                        .padding(.horizontal, 8) // Add some horizontal breathing room
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: shelfViewModel.commands) { _ in
                        if shelfViewModel.searchText.isEmpty, let first = shelfViewModel.commands.first {
                            // Using ScrollView, scrollTo works similarly
                            withAnimation {
                                proxy.scrollTo(first.id, anchor: .top)
                            }
                        }
                    }
                }
                .clipped()
            }
            .frame(minWidth: 250, maxWidth: 350)
            .background(.regularMaterial)
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
                    Text(item.command)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundColor(.primary)
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
                                .foregroundColor(.blue)
                        case .none:
                            Text(item.timestamp, style: .time)
                                .foregroundColor(.secondary)
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
                Button(action: {
                    viewModel.triggerRun(item.command)
                    triggerFeedback(.executed)
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? Color.primary.opacity(0.05) : Color.clear)
        )
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
