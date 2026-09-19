import SwiftUI

/// The add / edit form inside the disc modal. `onSave` hands back the edited
/// disc, which the caller either inserts or updates.
struct AlbumEditor: View {
    let heading: String
    /// The id a new disc will be given, previewed in the header.
    var catalogHint: Int64?
    var onSave: (Album) -> Void
    var onCancel: () -> Void

    @State private var album: Album
    @State private var genreText: String
    @State private var yearText: String
    @State private var notesText: String
    @State private var face: Face = .front
    @State private var validationMessage: String?

    private var isNew: Bool { album.id == nil }

    private static let leftColumnWidth: CGFloat = 380

    init(
        album: Album,
        heading: String,
        catalogHint: Int64? = nil,
        onSave: @escaping (Album) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.heading = heading
        self.catalogHint = catalogHint
        self.onSave = onSave
        self.onCancel = onCancel
        _album = State(initialValue: album)
        _genreText = State(initialValue: album.genre.joined(separator: ", "))
        _yearText = State(initialValue: album.releaseYear.map(String.init) ?? "")
        _notesText = State(initialValue: album.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            HStack(alignment: .top, spacing: 40) {
                leftColumn
                    .frame(width: Self.leftColumnWidth)
                VStack(alignment: .leading, spacing: 16) {
                    fields
                    actions
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, isNew ? 24 : 12)
        }
        .overlay(alignment: .topTrailing) {
            CloseButton(action: onCancel).offset(x: 16, y: -16)
        }
    }

    /// `.edit-actions`
    private var actions: some View {
        HStack(spacing: 8) {
            IconButton(title: isNew ? "+ Add to registry" : "Save changes", kind: .primary) {
                submit()
            }
            IconButton(title: "Cancel", action: onCancel)
            if let validationMessage {
                Text(validationMessage)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.auroraRed)
                    .padding(.leading, 6)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if isNew {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("NEW ENTRY · #")
                    Text(String(format: "%03d", catalogHint ?? 1)).foregroundStyle(Theme.accent)
                }
                .font(Theme.mono(11))
                .tracking(3)
                .foregroundStyle(Theme.ink3)

                Text("Add a CD")
                    .font(Theme.serif(48))
                    .italic()
                    .tracking(-1)
                    .foregroundStyle(Theme.ink0)
                    .padding(.top, 12)

                Text("TO YOUR REGISTRY")
                    .font(Theme.mono(13))
                    .tracking(2)
                    .foregroundStyle(Theme.ink2)
                    .padding(.top, 6)
            }
        } else {
            HStack(spacing: 0) {
                Text("CD ")
                Text("#\(album.catalogNumber)").foregroundStyle(Theme.accent)
                Text(" · \(heading.uppercased())")
            }
            .font(Theme.mono(11))
            .tracking(3)
            .foregroundStyle(Theme.ink3)
        }
    }

    // MARK: - Left column

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !isNew {
                VStack(spacing: 18) {
                    ZStack {
                        switch face {
                        case .front, .back:
                            CoverView(album: album, face: face)
                                .frame(width: 360, height: 360)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .shadow(color: Theme.ink0.opacity(0.25), radius: 22, y: 26)
                        case .disc:
                            DiscFace(album: album).frame(width: 360, height: 360)
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
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "Scans")
                ScanSlots(album: $album, slotSide: (Self.leftColumnWidth - 20) / 3)
                Text("// Drop in front cover, back cover, and disc face.\n// No scan? A placeholder cover is generated for you.")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.ink3)
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(text: "Cover hue (placeholder)")
                Slider(
                    value: Binding(
                        get: { Double(album.hue ?? 200) },
                        set: { album.hue = Int($0) }
                    ),
                    in: 0...360
                )
                .tint(Theme.accent)
            }
        }
    }

    // MARK: - Fields

    private var fields: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isNew {
                HStack(alignment: .top, spacing: 12) {
                    field("Artist *") {
                        FrostedTextField(text: $album.artist, prompt: "e.g. Sigur Rós")
                    }
                    field("Year") {
                        FrostedTextField(text: $yearText, prompt: "1999")
                            .onChange(of: yearText) { _, new in
                                album.releaseYear = Int(new.filter(\.isNumber))
                            }
                    }
                }
                field("Title *") {
                    FrostedTextField(text: $album.title, prompt: "e.g. ( )")
                }
            } else {
                field("Title") {
                    FrostedTextField(text: $album.title)
                }
                HStack(alignment: .top, spacing: 12) {
                    field("Artist") {
                        FrostedTextField(text: $album.artist)
                    }
                    field("Year") {
                        FrostedTextField(text: $yearText)
                            .onChange(of: yearText) { _, new in
                                album.releaseYear = Int(new.filter(\.isNumber))
                            }
                    }
                }
            }

            field("Genre (comma separated)") {
                FrostedTextField(text: $genreText, prompt: "Post-Rock, Ambient")
                    .onChange(of: genreText) { _, new in
                        album.genre = new
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }
            }

            field("Rating") {
                StarRating(value: album.rating ?? 0, size: 20) { album.rating = $0 }
            }

            field("Notes") {
                FrostedTextArea(
                    text: $notesText,
                    prompt: "A line or two on what this record means to you."
                )
                .onChange(of: notesText) { _, new in
                    album.notes = new.isEmpty ? nil : new
                }
            }

            field("Tracklist") {
                TrackEditor(tracks: $album.tracks)
            }
        }
    }

    private func field<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel(text: label)
            content()
        }
    }

    // MARK: - Submit

    private func submit() {
        var cleaned = album
        cleaned.title = cleaned.title.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned.artist = cleaned.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned.tracks = cleaned.tracks
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleaned.title.isEmpty, !cleaned.artist.isEmpty else {
            validationMessage = "Title and artist are required."
            return
        }
        validationMessage = nil
        onSave(cleaned)
    }
}
