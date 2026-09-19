import SwiftUI

/// `.detail-rating` — five ★ glyphs, read-only in the detail view and
/// clickable in the editor.
struct StarRating: View {
    var value: Int
    var size: CGFloat = 14
    var onChange: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { n in
                Text("★")
                    .font(Theme.mono(size))
                    .foregroundStyle(n <= value ? Theme.auroraYellow : Theme.ink4.opacity(0.5))
                    .onTapGesture {
                        // Clicking the highest filled star clears the rating.
                        onChange?(value == n ? 0 : n)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(value) of 5")
    }
}

/// `.track-editor` — one row per track, return adds the next one.
struct TrackEditor: View {
    @Binding var tracks: [String]
    @FocusState private var focused: Int?

    private var rows: [String] { tracks.isEmpty ? [""] : tracks }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(rows.indices), id: \.self) { i in
                HStack(spacing: 6) {
                    Text(String(format: "%02d", i + 1))
                        .font(Theme.mono(11))
                        .tracking(1)
                        .foregroundStyle(Theme.ink3)
                        .frame(width: 32, alignment: .trailing)

                    FrostedTextField(
                        text: binding(for: i),
                        prompt: i == 0 ? "Track title — press Enter to add another" : "Track title",
                        fontSize: 12,
                        cornerRadius: 6,
                        verticalPadding: 7
                    )
                    .focused($focused, equals: i)
                    .onSubmit { insert(after: i) }
                    .onKeyPress(.delete) {
                        // Backspace on an empty row removes it, as on the web.
                        guard rows[i].isEmpty, rows.count > 1 else { return .ignored }
                        remove(at: i)
                        return .handled
                    }
                    .onKeyPress(.upArrow) {
                        guard i > 0 else { return .ignored }
                        focused = i - 1
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        guard i + 1 < rows.count else { return .ignored }
                        focused = i + 1
                        return .handled
                    }

                    RoundIconButton(glyph: "−", help: "Remove this track") { remove(at: i) }
                }
            }

            DashedButton(title: "+ Add track") { insert(after: rows.count - 1) }
                .padding(.top, 6)

            Text("enter ↵ adds · backspace on empty removes · ↑↓ to navigate")
                .font(Theme.mono(10))
                .tracking(0.5)
                .italic()
                .foregroundStyle(Theme.ink4)
                .padding(.top, 6)
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { index < tracks.count ? tracks[index] : "" },
            set: { newValue in
                if tracks.isEmpty { tracks = [""] }
                guard tracks.indices.contains(index) else { return }
                tracks[index] = newValue
            }
        )
    }

    private func insert(after index: Int) {
        if tracks.isEmpty { tracks = [""] }
        let target = min(max(index + 1, 0), tracks.count)
        tracks.insert("", at: target)
        focused = target
    }

    private func remove(at index: Int) {
        guard tracks.indices.contains(index) else { return }
        tracks.remove(at: index)
        if tracks.isEmpty { tracks = [""] }
        focused = max(0, index - 1)
    }
}

/// `.scan-uploader` — front / back / disc wells. Picking a file copies it into
/// the app's scan folder; the stored value is a path relative to that folder.
struct ScanSlots: View {
    @Binding var album: Album
    /// Side of one square well. The three of them plus 10pt gaps fill the
    /// editor's left column.
    var slotSide: CGFloat = 110
    @State private var importing: Face?
    @State private var importError: String?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Face.allCases) { face in
                slot(face)
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { importing != nil },
                set: { if !$0 { importing = nil } }
            ),
            allowedContentTypes: [.image]
        ) { result in
            let face = importing
            importing = nil
            guard let face else { return }
            do {
                let source = try result.get()
                album = album.settingScan(try ScanStore.importScan(from: source), for: face)
            } catch {
                importError = error.localizedDescription
            }
        }
        .alert("Could not import that image", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private func slot(_ face: Face) -> some View {
        ScanSlot(
            stored: album.scan(for: face),
            face: face,
            side: slotSide,
            onPick: { importing = face },
            onClear: {
                ScanStore.discardImported(album.scan(for: face))
                album = album.settingScan(nil, for: face)
            }
        )
    }
}

private struct ScanSlot: View {
    let stored: String?
    let face: Face
    let side: CGFloat
    let onPick: () -> Void
    let onClear: () -> Void

    @State private var hovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottom) {
                if let url = ScanStore.resolve(stored) {
                    ScanImageView(url: url, contentMode: .fill)
                } else {
                    VStack(spacing: 2) {
                        Text("＋ Upload")
                        Text(face.label)
                    }
                    .font(Theme.mono(10))
                    .tracking(1)
                    .foregroundStyle(Theme.ink3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Text(face.label.uppercased())
                    .font(Theme.mono(9))
                    .tracking(2)
                    .foregroundStyle(Theme.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.85))
            }
            .frame(width: side, height: side)
            .background(.white.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        hovering ? Theme.accent : Theme.glassBorderStrong,
                        style: StrokeStyle(lineWidth: 1, dash: stored == nil ? [4, 3] : [])
                    )
            )
            .onHover { hovering = $0 }
            .onTapGesture(perform: onPick)

            if stored != nil {
                Button(action: onClear) {
                    Text("✕")
                        .font(Theme.mono(11))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.ink2)
                .background(.white.opacity(0.9), in: Circle())
                .overlay(Circle().strokeBorder(Theme.glassBorder, lineWidth: 1))
                .padding(4)
                .help("Remove this scan")
            }
        }
    }
}

// MARK: - Field primitives

/// `.field-group input` — a white, hairline-bordered text field.
struct FrostedTextField: View {
    @Binding var text: String
    var prompt: String = ""
    var fontSize: CGFloat = 13
    var cornerRadius: CGFloat = 8
    var verticalPadding: CGFloat = 10
    var serif = false

    @FocusState private var focused: Bool

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(prompt)
                .font(serif ? Theme.serif(fontSize) : Theme.mono(fontSize))
                .foregroundStyle(Theme.ink4)
        )
        .textFieldStyle(.plain)
        .font(serif ? Theme.serif(fontSize) : Theme.mono(fontSize))
        .italic(serif)
        .foregroundStyle(Theme.ink0)
        .focused($focused)
        .padding(.horizontal, 12)
        .padding(.vertical, verticalPadding)
        .background(.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(focused ? Theme.accent : Theme.glassBorder, lineWidth: 1)
        )
    }
}

/// `.field-group textarea`
struct FrostedTextArea: View {
    @Binding var text: String
    var prompt: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextEditor(text: $text)
            .font(Theme.serif(15))
            .italic()
            .foregroundStyle(Theme.ink0)
            .scrollContentBackground(.hidden)
            .focused($focused)
            .frame(minHeight: 80)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(.white.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(focused ? Theme.accent : Theme.glassBorder, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(prompt)
                        .font(Theme.serif(15))
                        .italic()
                        .foregroundStyle(Theme.ink4)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// `.track-remove`
struct RoundIconButton: View {
    let glyph: String
    var help: String = ""
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(glyph)
                .font(Theme.mono(14))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .foregroundStyle(hovering ? Theme.auroraRed : Theme.ink3)
        .overlay(
            Circle().strokeBorder(hovering ? Theme.auroraRed : Theme.glassBorder, lineWidth: 1)
        )
        .onHover { hovering = $0 }
        .help(help)
    }
}

/// `.track-add`
struct DashedButton: View {
    let title: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.mono(11))
                .tracking(1)
                .frame(maxWidth: .infinity)
                .padding(8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(hovering ? Theme.accent : Theme.ink2)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    hovering ? Theme.accent : Theme.glassBorderStrong,
                    style: StrokeStyle(lineWidth: 1, dash: hovering ? [] : [4, 3])
                )
        )
        .onHover { hovering = $0 }
    }
}
