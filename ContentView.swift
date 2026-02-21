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
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
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
                            
                            Button(action: {
                                showingNewFolderAlert = true
                            }) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 4)
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
                                if !shelfViewModel.folders.isEmpty {
                                    ForEach(shelfViewModel.folders) { folder in
                                        FolderView(folder: folder, viewModel: shelfViewModel)
                                    }
                                    Divider().padding(.vertical, 8)
                                }
                                
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
                .alert("New Folder", isPresented: $showingNewFolderAlert) {
                    TextField("Folder Name", text: $newFolderName)
                    Button("Cancel", role: .cancel) {
                        newFolderName = ""
                    }
                    Button("Create") {
                        shelfViewModel.createFolder(name: newFolderName)
                        newFolderName = ""
                    }
                } message: {
                    Text("Enter a name for the new folder.")
                }
                .background(SwiftUI.Color(red: 0.07, green: 0.07, blue: 0.07)) // Dark Spotify-style Sidebar
            }
        }
    }
}

struct CommandRowView: View {
    let item: CommandItem
    @ObservedObject var viewModel: ShelfViewModel
    var folderId: UUID? = nil
    
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
            HStack(spacing: 8) {
                if let folderId = folderId {
                    Button(action: {
                        withAnimation {
                            viewModel.removeCommandFromFolder(commandId: item.id, folderId: folderId)
                        }
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title) // Larger icon
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                } else {
                    Menu {
                        if viewModel.folders.isEmpty {
                            Text("No folders available")
                        } else {
                            ForEach(viewModel.folders) { folder in
                                Button(folder.name) {
                                    viewModel.addCommandToFolder(item, folderId: folder.id)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
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
                }

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
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
        }
        .padding(4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovering ? SwiftUI.Color.white.opacity(0.1) : SwiftUI.Color.clear)
        )
        .contextMenu {
            if let folderId = folderId {
                Button(role: .destructive) {
                    withAnimation {
                        viewModel.removeCommandFromFolder(commandId: item.id, folderId: folderId)
                    }
                } label: {
                    Label("Remove from Folder", systemImage: "minus.circle")
                }
            } else {
                Button(role: .destructive) {
                    withAnimation {
                        viewModel.deleteCommand(id: item.id)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            Button {
                viewModel.copyCommand(item.command)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        .onHover { hover in
            isHovering = hover
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


struct FolderView: View {
    let folder: CommandFolder
    @ObservedObject var viewModel: ShelfViewModel
    @State private var isExpanded: Bool = false
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    
    @State private var isEditing = false
    @State private var editedName = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.white.opacity(0.5))
                    
                if isEditing {
                    TextField("Folder Name", text: $editedName)
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit {
                            submitRename()
                        }
                        .onExitCommand {
                            isEditing = false
                        }
                        .onChange(of: isFocused) {
                            if !isFocused && isEditing {
                                submitRename()
                            }
                        }
                } else {
                    Text(folder.name)
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(folder.commands.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.trailing, 2)
                        
                    if !isEditing {
                        Button(action: {
                            editedName = folder.name
                            withAnimation {
                                isEditing = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isFocused = true
                                }
                            }
                        }) {
                            Image(systemName: "pencil")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovering ? 1 : 0)
                        .allowsHitTesting(isHovering)
                    }
                        
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovering ? 1 : 0)
                    .allowsHitTesting(isHovering)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? SwiftUI.Color.white.opacity(0.1) : (isExpanded ? SwiftUI.Color.white.opacity(0.05) : SwiftUI.Color.clear))
            )
            .onHover { hover in
                isHovering = hover
            }
            .onTapGesture {
                if !isEditing {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }
            }
            
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(folder.commands) { item in
                        CommandRowView(item: item, viewModel: viewModel, folderId: folder.id)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.leading, 8)
                .padding(.top, 4)
                .clipped()
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 4)
        .alert("Delete Folder", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    viewModel.deleteFolder(id: folder.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this folder? All commands inside will be removed.")
        }
    }
    
    private func submitRename() {
        if editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            isEditing = false
            return
        }
        viewModel.renameFolder(id: folder.id, newName: editedName)
        isEditing = false
    }
}
