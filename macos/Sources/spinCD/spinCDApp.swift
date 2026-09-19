import SwiftUI

@main
struct spinCDApp: App {
    @State private var startup: Result<LibraryStore, Error>

    init() {
        AppFonts.warmUp()
        do {
            try AppPaths.ensureDirectories()
            startup = .success(LibraryStore(database: try AppDatabase.onDisk()))
        } catch {
            startup = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch startup {
                case .success(let store):
                    RootView().environment(store)
                case .failure(let error):
                    DatabaseFailureView(error: error)
                }
            }
            .frame(minWidth: 1000, minHeight: 700)
            .preferredColorScheme(.light)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1500, height: 1000)
        .commands { SpinCommands() }

        Settings {
            SettingsView()
        }
    }
}

/// Menu-bar commands, acting on the focused window through the scene values
/// `RootView` publishes.
private struct SpinCommands: Commands {
    @FocusedValue(\.newAlbumAction) private var newAlbum
    @FocusedValue(\.statsToggleAction) private var toggleStats
    @FocusedValue(\.findAction) private var find

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New CD") { newAlbum?() }
                .keyboardShortcut("n")
                .disabled(newAlbum == nil)
        }

        CommandGroup(after: .textEditing) {
            Button("Find") { find?() }
                .keyboardShortcut("f")
                .disabled(find == nil)
        }

        CommandGroup(after: .sidebar) {
            Button("Library Stats") { toggleStats?() }
                .keyboardShortcut("i")
                .disabled(toggleStats == nil)
            Divider()
            ViewModeCommands()
        }

        CommandGroup(after: .saveItem) {
            Button("Reveal Database in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([AppPaths.databaseURL])
            }
            Button("Reveal Imported Scans in Finder") {
                try? AppPaths.ensureDirectories()
                NSWorkspace.shared.activateFileViewerSelecting([AppPaths.importedScans])
            }
        }
    }
}

/// ⌘1 / ⌘2 / ⌘3 switch the browsing view.
private struct ViewModeCommands: View {
    @FocusedValue(\.viewModeAction) private var setViewMode

    var body: some View {
        ForEach(Array(ViewMode.allCases.enumerated()), id: \.element) { index, mode in
            Button(mode.label) { setViewMode?(mode) }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")))
                .disabled(setViewMode == nil)
        }
    }
}

// MARK: - Focused actions

private struct NewAlbumActionKey: FocusedValueKey { typealias Value = () -> Void }
private struct StatsToggleActionKey: FocusedValueKey { typealias Value = () -> Void }
private struct FindActionKey: FocusedValueKey { typealias Value = () -> Void }
private struct ViewModeActionKey: FocusedValueKey { typealias Value = (ViewMode) -> Void }

extension FocusedValues {
    var newAlbumAction: (() -> Void)? {
        get { self[NewAlbumActionKey.self] }
        set { self[NewAlbumActionKey.self] = newValue }
    }

    var statsToggleAction: (() -> Void)? {
        get { self[StatsToggleActionKey.self] }
        set { self[StatsToggleActionKey.self] = newValue }
    }

    var findAction: (() -> Void)? {
        get { self[FindActionKey.self] }
        set { self[FindActionKey.self] = newValue }
    }

    var viewModeAction: ((ViewMode) -> Void)? {
        get { self[ViewModeActionKey.self] }
        set { self[ViewModeActionKey.self] = newValue }
    }
}

// MARK: - Fallbacks and settings

struct DatabaseFailureView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 10) {
            Text("spinCD could not open its database")
                .font(Theme.serif(24))
                .italic()
            Text(error.localizedDescription)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.ink2)
                .multilineTextAlignment(.center)
            Text(AppPaths.databaseURL.path)
                .font(Theme.mono(10))
                .foregroundStyle(Theme.ink3)
                .textSelection(.enabled)
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 300)
        .background(AlpineBackground())
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Storage") {
                LabeledContent("Database") {
                    Text(AppPaths.databaseURL.path)
                        .font(Theme.mono(10))
                        .textSelection(.enabled)
                }
                LabeledContent("Imported scans") {
                    Text(AppPaths.importedScans.path)
                        .font(Theme.mono(10))
                        .textSelection(.enabled)
                }
                LabeledContent("Bundled scans") {
                    Text(AppPaths.bundledScans?.path ?? AppPaths.repositoryScans?.path ?? "none found")
                        .font(Theme.mono(10))
                        .textSelection(.enabled)
                }
            }
            Section {
                Button("Reveal Database in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([AppPaths.databaseURL])
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 280)
    }
}
