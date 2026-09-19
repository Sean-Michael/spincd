import SwiftUI

/// `.shell` — the whole registry in one window: topbar, collapsible stats,
/// search + view switch, genre chips, the active view, and the footer. The
/// disc modal and the "+ New CD" button float above it.
struct RootView: View {
    @Environment(LibraryStore.self) private var store

    @State private var statsOpen = false
    @State private var openAlbumID: Int64?
    @State private var addingAlbum = false
    @State private var carouselIndex = 0

    var body: some View {
        ZStack {
            AlpineBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Topbar(statsOpen: $statsOpen)
                        .padding(.bottom, 24)

                    if statsOpen {
                        StatsPanel(albums: store.albums)
                            .padding(22)
                            .glass(cornerRadius: 18)
                            .shadow(color: Theme.ink0.opacity(0.1), radius: 20, y: 12)
                            .padding(.bottom, 28)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    RegistryToolbar()
                        .padding(.bottom, 18)

                    GenreChipRow()
                        .padding(.bottom, 22)

                    content

                    RegistryFooter(count: store.albums.count)
                }
                .frame(maxWidth: 1480)
                .padding(.horizontal, 32)
                .padding(.top, 34)
                .padding(.bottom, 80)
                .frame(maxWidth: .infinity)
            }
            .scrollContentBackground(.hidden)

            if store.mode.isAdmin {
                FloatingAddButton { addingAlbum = true }
            }

            if let openAlbumID {
                DetailOverlay(albumID: openAlbumID) { self.openAlbumID = nil }
                    .environment(store)
                    .zIndex(100)
            }

            if addingAlbum {
                NewAlbumOverlay(
                    nextCatalogNumber: (store.albums.compactMap(\.id).max() ?? 0) + 1,
                    onAdd: { album in
                        store.add(album)
                        addingAlbum = false
                    },
                    onClose: { addingAlbum = false }
                )
                .zIndex(110)
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { store.actionError != nil },
                set: { if !$0 { store.actionError = nil } }
            )
        ) {
            Button("OK") { store.actionError = nil }
        } message: {
            Text(store.actionError ?? "")
        }
        .focusedSceneValue(\.newAlbumAction) { addingAlbum = true }
        .focusedSceneValue(\.statsToggleAction) {
            withAnimation(.timingCurve(0.6, 0.05, 0.2, 1, duration: 0.36)) { statsOpen.toggle() }
        }
        .focusedSceneValue(\.findAction) { store.focusSearch() }
        .onChange(of: store.query) { _, _ in carouselIndex = 0 }
        .onChange(of: store.genreFilter) { _, _ in carouselIndex = 0 }
    }

    @ViewBuilder
    private var content: some View {
        if let error = store.loadError {
            VStack(spacing: 8) {
                Text("could not read the local database")
                    .font(Theme.mono(13))
                    .foregroundStyle(Theme.auroraRed)
                Text(error)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.ink3)
                Text(AppPaths.databaseURL.path)
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.ink4)
                    .textSelection(.enabled)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(80)
        } else {
            switch store.viewMode {
            case .carousel:
                CarouselView(
                    albums: store.filtered,
                    onOpen: { openAlbumID = $0.id },
                    index: $carouselIndex
                )
                .padding(.horizontal, -32)
                .padding(.bottom, 60)
            case .grid:
                AlbumGridView(albums: store.filtered) { openAlbumID = $0.id }
            case .list:
                AlbumListView(albums: store.filtered) { openAlbumID = $0.id }
                    .frame(height: max(240, CGFloat(store.filtered.count) * 69 + 48))
                    .padding(.bottom, 32)
            }
        }
    }
}

/// `.fab` — the fixed "+ New CD" pill, bottom right.
private struct FloatingAddButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text("+ New CD")
                .font(Theme.mono(12, .semibold))
                .tracking(2)
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .background(Theme.accent, in: Capsule())
        .shadow(color: Theme.frost1.opacity(0.35), radius: 15, y: 14)
        .offset(y: hovering ? -2 : 0)
        .brightness(hovering ? 0.05 : 0)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(28)
        .keyboardShortcut("n")
        .help("Add a disc to the registry")
    }
}

/// The create-disc modal, styled like the detail overlay.
private struct NewAlbumOverlay: View {
    let nextCatalogNumber: Int64
    var onAdd: (Album) -> Void
    var onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "B4C4D7").opacity(0.55)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            ScrollView {
                AlbumEditor(
                    album: draft,
                    heading: "New entry",
                    catalogHint: nextCatalogNumber,
                    onSave: onAdd,
                    onCancel: onClose
                )
                    .padding(36)
                    .frame(maxWidth: 880)
                    .glass(cornerRadius: 22, opacity: 0.78, borderStrong: true)
                    .shadow(color: Theme.ink0.opacity(0.18), radius: 40, y: 30)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 60)
                    .frame(maxWidth: .infinity)
            }
            .scrollContentBackground(.hidden)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.35)) { appeared = true }
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
    }

    private var draft: Album {
        var album = Album.draft()
        album.tracks = [""]
        return album
    }
}
