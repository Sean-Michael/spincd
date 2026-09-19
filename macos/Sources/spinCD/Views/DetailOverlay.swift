import SwiftUI

/// `.detail-overlay` + `.detail` — the disc modal, floating over a blurred
/// backdrop exactly as the web registry presents it.
struct DetailOverlay: View {
    let albumID: Int64
    var onClose: () -> Void

    @Environment(LibraryStore.self) private var store

    @State private var face: Face = .front
    @State private var editing = false
    @State private var confirmingDelete = false
    @State private var appeared = false

    private var album: Album? { store.album(id: albumID) }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "B4C4D7").opacity(0.55)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            ScrollView {
                Group {
                    if let album {
                        if editing {
                            AlbumEditor(album: album, heading: "Edit disc") { edited in
                                store.save(edited)
                                editing = false
                            } onCancel: {
                                editing = false
                            }
                        } else {
                            panel(album)
                        }
                    }
                }
                .padding(36)
                .frame(maxWidth: 1100)
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
        .onChange(of: album == nil) { _, gone in
            if gone { onClose() }
        }
        .onKeyPress(.escape) {
            onClose()
            return .handled
        }
        .confirmationDialog(
            "Remove “\(album?.title ?? "")” from the registry?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Remove disc", role: .destructive) {
                if let id = album?.id { store.delete(id: id) }
                onClose()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes the record from your local database. Imported scans stay on disk.")
        }
    }

    // MARK: - Read-only panel

    private func panel(_ album: Album) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 40) {
                faceColumn(album)
                    .frame(maxWidth: .infinity)
                info(album)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // `.detail-section` — tracklist
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Tracklist · \(album.tracks.count) tracks")
                if album.tracks.isEmpty {
                    Text("// no tracks recorded")
                        .font(Theme.mono(12))
                        .italic()
                        .foregroundStyle(Theme.ink3)
                } else {
                    TrackColumns(tracks: album.tracks)
                }
            }
            .padding(.top, 28)
        }
        .overlay(alignment: .topTrailing) {
            CloseButton(action: onClose)
                .offset(x: 16, y: -16)
        }
    }

    /// `.detail-jc-wrap` — the case faces plus the front/back/disc tabs.
    private func faceColumn(_ album: Album) -> some View {
        VStack(spacing: 18) {
            ZStack {
                switch face {
                case .front, .back:
                    CoverView(album: album, face: face)
                        .frame(width: 360, height: 360)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Theme.ink0.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Theme.ink0.opacity(0.25), radius: 25, y: 30)
                case .disc:
                    DiscFace(album: album)
                        .frame(width: 360, height: 360)
                }
            }
            .frame(width: 360, height: 360)
            .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.45), value: face)

            PillToggle(
                options: Face.allCases.map { ($0, $0.label) },
                selection: $face,
                fontSize: 11,
                tracking: 1.5,
                horizontalPadding: 16,
                verticalPadding: 7
            )
        }
        .padding(.vertical, 12)
    }

    private func info(_ album: Album) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("CD ")
                Text("#\(album.catalogNumber)").foregroundStyle(Theme.accent)
                Text(" · added \(Self.formatted(album.added))")
            }
            .font(Theme.mono(11))
            .tracking(3)
            .foregroundStyle(Theme.ink3)

            Text(album.title)
                .font(Theme.serif(48))
                .italic()
                .tracking(-1)
                .foregroundStyle(Theme.ink0)
                .lineSpacing(-6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
                .textSelection(.enabled)

            Text(album.artist.uppercased())
                .font(Theme.mono(13))
                .tracking(2)
                .foregroundStyle(Theme.ink2)
                .padding(.top, 6)
                .textSelection(.enabled)

            if !album.genre.isEmpty {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(album.genre, id: \.self) { genre in
                        Text(genre)
                            .font(Theme.mono(10))
                            .tracking(1)
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 5)
                            .background(Theme.accentSoft, in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.frost1.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.top, 18)
            }

            // `.detail-meta-row`
            HStack(alignment: .top, spacing: 24) {
                metaColumn("Year") {
                    Text(album.displayYear).font(Theme.mono(12)).foregroundStyle(Theme.ink1)
                }
                metaColumn("Tracks") {
                    Text("\(album.tracks.count)").font(Theme.mono(12)).foregroundStyle(Theme.ink1)
                }
                metaColumn("Rating") {
                    StarRating(value: album.rating ?? 0, size: 16)
                }
            }
            .padding(.top, 24)

            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Notes")
                if let notes = album.notes, !notes.isEmpty {
                    Text("“\(notes)”")
                        .font(Theme.serif(18))
                        .italic()
                        .foregroundStyle(Theme.ink1)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                } else {
                    Text("// no notes yet")
                        .font(Theme.mono(12))
                        .italic()
                        .foregroundStyle(Theme.ink3)
                }
            }
            .padding(.top, 28)

            if store.mode.isAdmin {
                HStack(spacing: 8) {
                    IconButton(title: "✎ Edit") { editing = true }
                    IconButton(title: "✕ Remove", tint: Theme.auroraRed) { confirmingDelete = true }
                }
                .padding(.top, 18)
            }
        }
    }

    private func metaColumn<V: View>(_ label: String, _ value: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FieldLabel(text: label, size: 9, trackingValue: 2)
            value()
        }
    }

    static func formatted(_ iso: String?) -> String {
        guard let iso, !iso.isEmpty else { return "—" }
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: iso) else { return iso }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
}

/// `.tracklist` — two columns, dashed rules, mono numbering.
struct TrackColumns: View {
    let tracks: [String]

    var body: some View {
        let half = (tracks.count + 1) / 2
        HStack(alignment: .top, spacing: 24) {
            column(Array(tracks.enumerated().prefix(half)))
            column(Array(tracks.enumerated().dropFirst(half)))
        }
    }

    private func column(_ entries: [(offset: Int, element: String)]) -> some View {
        VStack(spacing: 0) {
            ForEach(entries, id: \.offset) { entry in
                HStack(spacing: 12) {
                    Text(String(format: "%02d", entry.offset + 1))
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.ink3)
                        .frame(width: 22, alignment: .leading)
                    Text(entry.element)
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.ink1)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    DashedRule()
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The dashed hairline under each tracklist row.
private struct DashedRule: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(
                Theme.ink0.opacity(0.06),
                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
            )
        }
        .frame(height: 1)
    }
}

/// `.detail-close`
struct CloseButton: View {
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text("✕")
                .font(Theme.mono(14))
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .foregroundStyle(hovering ? Theme.auroraRed : Theme.ink1)
        .background(.white.opacity(0.7), in: Circle())
        .overlay(
            Circle().strokeBorder(hovering ? Theme.auroraRed : Theme.glassBorder, lineWidth: 1)
        )
        .onHover { hovering = $0 }
        .keyboardShortcut(.cancelAction)
        .help("Close")
    }
}
