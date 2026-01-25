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
                // Search Bar
                TextField("Search commands...", text: $shelfViewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(8)
                
                ScrollViewReader { proxy in
                    List(shelfViewModel.filteredCommands) { item in
                        CommandRowView(item: item, viewModel: shelfViewModel)
                            .id(item.id) // Important for scrolling
                    }
                    .listStyle(.plain) // Cleaner look for side panel
                    .onChange(of: shelfViewModel.commands) { _ in
                        // Scroll to top when new commands arrive
                        // Only scroll if we are not actively searching (or if the new command matches)
                        if shelfViewModel.searchText.isEmpty, let first = shelfViewModel.commands.first {
                            withAnimation {
                                proxy.scrollTo(first.id, anchor: .top)
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 200, maxWidth: 300)
            .background(.thinMaterial)
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
    
    var body: some View {
        HStack {
            // Clickable Area (Text + Spacer)
            HStack {
                VStack(alignment: .leading) {
                    Text(item.command)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Group {
                        switch feedbackState {
                        case .copied:
                            Label("Copied!", systemImage: "checkmark")
                                .foregroundColor(.green)
                        case .executed:
                            Label("Executed!", systemImage: "play.circle.fill")
                                .foregroundColor(.blue)
                        case .none:
                            Text(item.timestamp, style: .time)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                    .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.2), value: feedbackState)
                
                Spacer()
            }
            .contentShape(Rectangle()) // Make the text+spacer area tappable
            .onTapGesture {
                // Clicking row just copies to clipboard
                viewModel.copyCommand(item.command)
                triggerFeedback(.copied)
            }
            
            // Run Button
            Button(action: {
                viewModel.triggerRun(item.command)
                triggerFeedback(.executed)
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(.accentColor)
                    .padding(8) // Add some touch target padding
            }
            .buttonStyle(.borderless)
            .help("Run command immediately")
        }
        .padding(.vertical, 4)
    }
    
    private func triggerFeedback(_ state: FeedbackState) {
        withAnimation {
            feedbackState = state
        }
        
        // Reset after delay
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
