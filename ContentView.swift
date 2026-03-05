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
}

struct ContentView: View {
    @StateObject private var shelfViewModel = ShelfViewModel()
    @StateObject private var themeManager = ThemeManager()
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var showingThemePicker = false
    
    var body: some View {
        ZStack {
            // MARK: - Mesh Gradient Aura Background
            themeManager.base
                .ignoresSafeArea()
            
            // Aura blobs — soft radial glows behind the interface
            Canvas { context, size in
                let aura1Color = SwiftUI.Color(hex: themeManager.current.aura1)
                let aura2Color = SwiftUI.Color(hex: themeManager.current.aura2)
                let aura3Color = SwiftUI.Color(hex: themeManager.current.aura3)
                
                // Aura 1 (top-left)
                let c1 = CGPoint(x: size.width * 0.15, y: size.height * 0.2)
                let g1 = Gradient(colors: [aura1Color.opacity(0.08), SwiftUI.Color.clear])
                context.fill(
                    Path(ellipseIn: CGRect(x: c1.x - 200, y: c1.y - 200, width: 400, height: 400)),
                    with: .radialGradient(g1, center: c1, startRadius: 0, endRadius: 200)
                )
                
                // Aura 2 (bottom-right)
                let c2 = CGPoint(x: size.width * 0.85, y: size.height * 0.75)
                let g2 = Gradient(colors: [aura2Color.opacity(0.06), SwiftUI.Color.clear])
                context.fill(
                    Path(ellipseIn: CGRect(x: c2.x - 250, y: c2.y - 250, width: 500, height: 500)),
                    with: .radialGradient(g2, center: c2, startRadius: 0, endRadius: 250)
                )
                
                // Aura 3 (center-bottom)
                let c3 = CGPoint(x: size.width * 0.5, y: size.height * 0.9)
                let g3 = Gradient(colors: [aura3Color.opacity(0.04), SwiftUI.Color.clear])
                context.fill(
                    Path(ellipseIn: CGRect(x: c3.x - 180, y: c3.y - 180, width: 360, height: 360)),
                    with: .radialGradient(g3, center: c3, startRadius: 0, endRadius: 180)
                )
            }
            .ignoresSafeArea()
            .blur(radius: 60)
            
            // MARK: - Main Layout
            HSplitView {
                // Left: Main Content (Terminal) — Glass Panel
                ZStack {
                    // Rounded background fills the container
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(themeManager.terminalBg)
                    
                    // Terminal with inner padding so text clears rounded corners
                    TerminalViewWrapper(viewModel: shelfViewModel, themeManager: themeManager)
                        .padding(6)
                }
                .frame(minWidth: 400, minHeight: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(themeManager.border, lineWidth: 1)
                )
                
                // Right: Sidebar (The Shelf) — Glass Surface
                VStack(spacing: 0) {
                    // Search Bar Area (Glass)
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.textMuted)
                            
                            ZStack(alignment: .leading) {
                                if let suggestion = shelfViewModel.suggestedCommand, 
                                   !shelfViewModel.searchText.isEmpty,
                                   suggestion.lowercased().hasPrefix(shelfViewModel.searchText.lowercased()) {
                                    
                                    let prefix = String(suggestion.prefix(shelfViewModel.searchText.count))
                                    let suffix = String(suggestion.dropFirst(shelfViewModel.searchText.count))
                                    
                                    // Use non-breaking spaces to preserve whitespace width
                                    let displayPrefix = prefix.replacingOccurrences(of: " ", with: "\u{00a0}")
                                    let displaySuffix = suffix.replacingOccurrences(of: " ", with: "\u{00a0}")
                                    
                                    (Text(displayPrefix).foregroundColor(SwiftUI.Color.clear) + Text(displaySuffix).foregroundColor(themeManager.textPrimary.opacity(0.25)))
                                        .font(.system(.body, design: .monospaced))
                                        .allowsHitTesting(false)
                                }
                                
                                TextField("Search history...", text: $shelfViewModel.searchText)
                                    .textFieldStyle(.plain)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(themeManager.textPrimary.opacity(0.9))
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
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundColor(themeManager.accent.opacity(0.8))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(themeManager.accent.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .stroke(themeManager.accent.opacity(0.2), lineWidth: 0.5)
                                    )
                            }
                            
                            Button(action: {
                                showingNewFolderAlert = true
                            }) {
                                Image(systemName: "folder.badge.plus")
                                    .foregroundColor(themeManager.textMuted)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 4)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(themeManager.current.isLight 
                                    ? themeManager.base.opacity(0.5) 
                                    : SwiftUI.Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(themeManager.border.opacity(0.6), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    }
                    
                    // Subtle separator
                    Rectangle()
                        .fill(themeManager.border.opacity(0.4))
                        .frame(height: 0.5)
                        .padding(.horizontal, 12)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                if !shelfViewModel.filteredFolders.isEmpty {
                                    ForEach(shelfViewModel.filteredFolders) { folder in
                                        FolderView(folder: folder, viewModel: shelfViewModel, themeManager: themeManager)
                                    }
                                    Rectangle()
                                        .fill(themeManager.border.opacity(0.3))
                                        .frame(height: 0.5)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                }
                                
                                if shelfViewModel.filteredCommands.isEmpty && (shelfViewModel.searchText.isEmpty || shelfViewModel.filteredFolders.isEmpty) {
                                    VStack(spacing: 12) {
                                        Spacer().frame(height: 40)
                                        Image(systemName: "clock")
                                            .font(.largeTitle)
                                            .foregroundColor(themeManager.textMuted.opacity(0.3))
                                        Text(shelfViewModel.searchText.isEmpty ? "No history found" : "No results found")
                                            .font(.system(.callout, design: .monospaced))
                                            .foregroundColor(themeManager.textMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    ForEach(shelfViewModel.filteredCommands) { item in
                                        CommandRowView(item: item, viewModel: shelfViewModel, themeManager: themeManager)
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
                    
                    // MARK: - Bottom Bar with Settings Gear
                    Rectangle()
                        .fill(themeManager.border.opacity(0.4))
                        .frame(height: 0.5)
                        .padding(.horizontal, 12)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingThemePicker.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(themeManager.textMuted)
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(showingThemePicker 
                                            ? themeManager.accent.opacity(0.12) 
                                            : SwiftUI.Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(showingThemePicker 
                                            ? themeManager.accent.opacity(0.25) 
                                            : SwiftUI.Color.clear, lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingThemePicker, arrowEdge: .bottom) {
                            ThemePickerView(themeManager: themeManager)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(minWidth: 250, maxWidth: 350)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(themeManager.border, lineWidth: 1)
                )
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(themeManager.surface.opacity(0.85))
                )
                .padding(.trailing, 4)
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
            }
            .padding(.horizontal, 8)
            .padding(.top, 36)  // Account for transparent title bar
            .padding(.bottom, 8)
        }
        .environmentObject(themeManager)
    }
}

// MARK: - Theme Picker Popover

struct ThemePickerView: View {
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Theme")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 4)
            
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(AppTheme.allThemes) { theme in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.current = theme
                            }
                        }) {
                            HStack(spacing: 10) {
                                // Color preview swatch
                                HStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(SwiftUI.Color(hex: theme.base))
                                        .frame(width: 14, height: 14)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(SwiftUI.Color(hex: theme.accent))
                                        .frame(width: 14, height: 14)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(SwiftUI.Color(hex: theme.accentSecondary))
                                        .frame(width: 14, height: 14)
                                }
                                .padding(3)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(SwiftUI.Color(hex: theme.surface))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                                
                                Text(theme.name)
                                    .font(.system(size: 13, weight: .medium))
                                
                                Spacer()
                                
                                if themeManager.current.id == theme.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(themeManager.current.id == theme.id 
                                        ? Color.accentColor.opacity(0.1) 
                                        : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 380)
        }
        .padding(8)
        .frame(width: 240)
    }
}


struct CommandRowView: View {
    let item: CommandItem
    @ObservedObject var viewModel: ShelfViewModel
    @ObservedObject var themeManager: ThemeManager
    var folderId: UUID? = nil
    
    enum FeedbackState {
        case none
        case copied
        case executed
    }
    @State private var feedbackState: FeedbackState = .none
    @State private var isHovering = false
    
    @State private var isEditing = false
    @State private var editedCommand = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isEditing {
                        TextField("Command", text: $editedCommand, axis: .vertical)
                            .font(.system(.body, design: .monospaced))
                            .textFieldStyle(.plain)
                            .foregroundColor(themeManager.textPrimary)
                            .focused($isFocused)
                            .autocorrectionDisabled()
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(themeManager.base.opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(themeManager.accentSecondary.opacity(0.3), lineWidth: 0.5)
                            )
                            .onChange(of: editedCommand) {
                                let fixed = editedCommand
                                    .replacingOccurrences(of: "\u{201C}", with: "\"")
                                    .replacingOccurrences(of: "\u{201D}", with: "\"")
                                    .replacingOccurrences(of: "\u{2018}", with: "'")
                                    .replacingOccurrences(of: "\u{2019}", with: "'")
                                    .replacingOccurrences(of: "\u{2014}", with: "--")
                                if fixed != editedCommand {
                                    editedCommand = fixed
                                }
                            }
                            .onSubmit {
                                submitEdit()
                            }
                            .onExitCommand {
                                isEditing = false
                            }
                            .onChange(of: isFocused) {
                                if !isFocused && isEditing {
                                    submitEdit()
                                }
                            }
                    } else {
                        Text(item.command)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(themeManager.textPrimary.opacity(0.85))
                    }
                    Spacer()
                }
                
                if feedbackState != .none {
                    HStack {
                        Group {
                            if feedbackState == .copied {
                                Label("Copied", systemImage: "checkmark")
                                    .foregroundColor(themeManager.success)
                            } else if feedbackState == .executed {
                                Label("Running", systemImage: "play.fill")
                                    .foregroundColor(themeManager.info)
                            }
                        }
                        .font(.caption2)
                        .transition(.opacity)
                        
                        Spacer()
                    }
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
            HStack(spacing: 6) {
                Button(action: {
                    editedCommand = item.command
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isEditing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isFocused = true
                        }
                    }
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.textMuted.opacity(0.5))
                }
                .buttonStyle(.plain)
                if let folderId = folderId {
                    Button(action: {
                        withAnimation {
                            viewModel.removeCommandFromFolder(commandId: item.id, folderId: folderId)
                        }
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.textMuted.opacity(0.5))
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
                        Text(Image(systemName: "plus.circle.fill"))
                            .font(.title2)
                            .foregroundColor(themeManager.textMuted.opacity(0.5))
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    
                    Button(action: {
                        withAnimation {
                            viewModel.deleteCommand(id: item.id)
                        }
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.textMuted.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    viewModel.triggerRun(item.command)
                    triggerFeedback(.executed)
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.accent.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .opacity(isHovering ? 1 : 0)
            .allowsHitTesting(isHovering)
        }
        .padding(4)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovering 
                    ? (themeManager.current.isLight ? themeManager.base.opacity(0.5) : SwiftUI.Color.white.opacity(0.06)) 
                    : SwiftUI.Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isHovering ? themeManager.border.opacity(0.5) : SwiftUI.Color.clear, lineWidth: 0.5)
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
    
    private func submitEdit() {
        if editedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            isEditing = false
            return
        }
        viewModel.editCommand(id: item.id, newCommand: editedCommand, folderId: folderId)
        isEditing = false
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
    @ObservedObject var themeManager: ThemeManager
    @State private var isExpanded: Bool = false
    @State private var isHovering = false
    @State private var showingDeleteAlert = false
    
    @State private var isEditing = false
    @State private var editedName = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("\(folder.commands.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(themeManager.accent.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(themeManager.accent.opacity(0.08))
                    )
                
                Image(systemName: "folder.fill")
                    .foregroundColor(themeManager.accentTertiary.opacity(0.5))
                    .font(.system(size: 13))
                    
                if isEditing {
                    TextField("Folder Name", text: $editedName)
                        .font(.system(.body, weight: .semibold))
                        .foregroundColor(themeManager.textPrimary)
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
                        .autocorrectionDisabled()
                        .onChange(of: editedName) {
                            let fixed = editedName
                                .replacingOccurrences(of: "\u{201C}", with: "\"")
                                .replacingOccurrences(of: "\u{201D}", with: "\"")
                                .replacingOccurrences(of: "\u{2018}", with: "'")
                                .replacingOccurrences(of: "\u{2019}", with: "'")
                            if fixed != editedName {
                                editedName = fixed
                            }
                        }
                } else {
                    Text(folder.name)
                        .font(.system(.body, weight: .semibold))
                        .foregroundColor(themeManager.textPrimary.opacity(0.9))
                }
                Spacer()
                
                HStack(spacing: 6) {
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
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.textMuted)
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovering ? 1 : 0)
                        .allowsHitTesting(isHovering)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(themeManager.textMuted.opacity(0.5))
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovering 
                        ? (themeManager.current.isLight ? themeManager.base.opacity(0.5) : SwiftUI.Color.white.opacity(0.05)) 
                        : (isExpanded 
                            ? (themeManager.current.isLight ? themeManager.base.opacity(0.3) : SwiftUI.Color.white.opacity(0.03)) 
                            : SwiftUI.Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isHovering ? themeManager.border.opacity(0.4) : SwiftUI.Color.clear, lineWidth: 0.5)
            )
            .onHover { hover in
                isHovering = hover
            }
            .onTapGesture {
                if !isEditing {
                    if viewModel.searchText.isEmpty {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    }
                }
            }
            
            let isActivelySearching = !viewModel.searchText.isEmpty
            if isExpanded || isActivelySearching {
                VStack(spacing: 0) {
                    if isActivelySearching && folder.commands.isEmpty {
                        Text("No matching commands")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(themeManager.textMuted.opacity(0.6))
                            .padding(.vertical, 8)
                            .padding(.leading, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(folder.commands) { item in
                            CommandRowView(item: item, viewModel: viewModel, themeManager: themeManager, folderId: folder.id)
                                .padding(.horizontal, 8)
                        }
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
