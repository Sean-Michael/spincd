import SwiftUI

// MARK: - Buttons

/// `.icon-btn` — the small glass pill button used across the registry.
struct IconButton: View {
    enum Kind { case normal, primary, active }

    let title: String
    var kind: Kind = .normal
    var tint: Color?
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.mono(12))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 32)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        )
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }

    private var foreground: Color {
        if let tint { return hovering ? tint : tint.opacity(0.9) }
        switch kind {
        case .primary: return .white
        case .active: return Theme.snow0
        case .normal: return hovering ? Theme.accent : Theme.ink1
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return Theme.accent
        case .active: return Theme.ink0
        case .normal: return .white.opacity(hovering ? 1 : 0.7)
        }
    }

    private var border: Color {
        switch kind {
        case .primary: return .clear
        case .active: return Theme.ink0
        case .normal: return hovering ? Theme.accent : Theme.glassBorder
        }
    }
}

/// `.chip` — a genre filter pill.
struct GenreChip: View {
    let title: String
    let isActive: Bool
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.mono(10))
                .tracking(0.5)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? .white : (hovering ? Theme.accent : Theme.ink2))
        .background(isActive ? Theme.accent : .white.opacity(0.6), in: Capsule())
        .overlay(
            Capsule().strokeBorder(
                isActive || hovering ? Theme.accent : Theme.glassBorder,
                lineWidth: 1
            )
        )
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

/// `.mode-toggle` / `.face-tabs` — a pill-shaped segmented control.
struct PillToggle<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    var fontSize: CGFloat = 12
    var tracking: CGFloat = 0.5
    var horizontalPadding: CGFloat = 14
    var verticalPadding: CGFloat = 6
    var filled = true

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.value) { option in
                let isActive = option.value == selection
                Button {
                    selection = option.value
                } label: {
                    Text(option.label)
                        .font(Theme.mono(fontSize))
                        .tracking(tracking)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isActive ? (filled ? .white : Theme.accent) : Theme.ink2)
                .background(
                    isActive ? (filled ? Theme.accent : Theme.accentSoft) : .clear,
                    in: Capsule()
                )
            }
        }
        .padding(3)
        .background(Theme.ink0.opacity(0.05), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.glassBorder, lineWidth: 1))
    }
}

// MARK: - Topbar

/// `.topbar` — brand, path crumb, stats toggle and the admin/public switch.
struct Topbar: View {
    @Environment(LibraryStore.self) private var store
    @Binding var statsOpen: Bool

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 18) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 12, height: 12)
                        .shadow(color: Theme.frost1.opacity(0.6), radius: 6)
                    Text("spinCD")
                        .font(Theme.serif(26))
                        .italic()
                        .tracking(-0.5)
                        .foregroundStyle(Theme.ink0)
                }

                HStack(spacing: 0) {
                    Text("~/").foregroundStyle(Theme.ink4)
                    Text("cd-registry").foregroundStyle(Theme.accent)
                    Text(" · \(store.albums.count) discs").foregroundStyle(Theme.ink4)
                    BlinkingCursor()
                }
                .font(Theme.mono(13))
            }

            Spacer(minLength: 16)

            HStack(spacing: 10) {
                IconButton(
                    title: "▦ Library stats \(statsOpen ? "▴" : "▾")",
                    kind: statsOpen ? .active : .normal
                ) {
                    withAnimation(.timingCurve(0.6, 0.05, 0.2, 1, duration: 0.36)) {
                        statsOpen.toggle()
                    }
                }

                PillToggle(
                    options: [(AppMode.public_, "Public"), (AppMode.admin, "Admin")],
                    selection: Binding(get: { store.mode }, set: { store.mode = $0 })
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassStrong(cornerRadius: 14)
    }
}

/// The blinking block cursor at the end of the crumb.
private struct BlinkingCursor: View {
    @State private var on = true

    var body: some View {
        Rectangle()
            .fill(Theme.accent)
            .frame(width: 7, height: 14)
            .padding(.leading, 4)
            .opacity(on ? 1 : 0)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    Task { @MainActor in on.toggle() }
                }
            }
    }
}

// MARK: - Search + view switch

/// `.toolbar` — the search field and the three view buttons.
struct RegistryToolbar: View {
    @Environment(LibraryStore.self) private var store
    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text("⌕")
                        .font(Theme.mono(14))
                        .foregroundStyle(Theme.ink3)
                        .padding(.leading, 16)
                        .padding(.trailing, 12)

                    TextField(
                        "",
                        text: Binding(get: { store.query }, set: { store.query = $0 }),
                        prompt: Text("search artist or album…")
                            .font(Theme.mono(13))
                            .foregroundStyle(Theme.ink4)
                    )
                    .textFieldStyle(.plain)
                    .font(Theme.mono(13))
                    .foregroundStyle(Theme.ink0)
                    .focused($searchFocused)

                    Text("\(String(format: "%03d", store.filtered.count)) / \(String(format: "%03d", store.albums.count))")
                        .font(Theme.mono(11))
                        .tracking(1)
                        .foregroundStyle(Theme.ink3)
                        .padding(.trailing, 14)
                }
            }
            .frame(height: 42)
            .background(.white.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(searchFocused ? Theme.accent : Theme.glassBorder, lineWidth: 1)
            )
            .shadow(color: Theme.glassShadow, radius: 10, y: 6)
            .frame(minWidth: 280)

            HStack(spacing: 2) {
                ForEach(ViewMode.allCases) { mode in
                    let isActive = store.viewMode == mode
                    Button {
                        store.viewMode = mode
                    } label: {
                        Text("\(mode.glyph) \(mode.label)")
                            .font(Theme.mono(11))
                            .tracking(1)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isActive ? Theme.accent : Theme.ink2)
                    .background(
                        isActive ? Theme.accentSoft : .clear,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                }
            }
            .padding(3)
            .background(.white.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.glassBorder, lineWidth: 1)
            )
            .shadow(color: Theme.glassShadow, radius: 10, y: 6)
        }
        .onChange(of: store.focusSearchToken) { _, _ in searchFocused = true }
    }
}

/// `.genre-chips` — "all" plus one chip per genre, wrapping across lines.
struct GenreChipRow: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 6) {
            GenreChip(title: "all", isActive: store.genreFilter == nil) {
                store.genreFilter = nil
            }
            ForEach(store.genreCounts, id: \.genre) { entry in
                GenreChip(title: entry.genre, isActive: store.genreFilter == entry.genre) {
                    store.genreFilter = store.genreFilter == entry.genre ? nil : entry.genre
                }
            }
        }
    }
}

/// `.footer`
struct RegistryFooter: View {
    let count: Int

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.glassBorder)
                .frame(height: 1)
            HStack {
                HStack(spacing: 0) {
                    Text("spinCD · personal registry by ")
                    Text("~/sean-michael").foregroundStyle(Theme.accent)
                }
                Spacer()
                Text("\(count) discs · last updated \(Date().formatted(.dateTime.month(.abbreviated).day().year()))")
            }
            .font(Theme.mono(11))
            .tracking(1)
            .foregroundStyle(Theme.ink3)
            .padding(.vertical, 18)
        }
        .padding(.top, 40)
    }
}

/// `.detail-section-title` — a small caps label with a hairline running to the edge.
struct SectionTitle: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text(text.uppercased())
                .font(Theme.mono(10))
                .tracking(3)
                .foregroundStyle(Theme.ink3)
            Rectangle()
                .fill(Theme.glassBorder)
                .frame(height: 1)
        }
    }
}

/// Uppercase mono caption used above fields and stat tiles.
struct FieldLabel: View {
    let text: String
    var size: CGFloat = 10
    var trackingValue: CGFloat = 2

    var body: some View {
        Text(text.uppercased())
            .font(Theme.mono(size))
            .tracking(trackingValue)
            .foregroundStyle(Theme.ink3)
    }
}

// MARK: - Flow layout

/// Wraps subviews onto as many lines as needed — the chip row's `flex-wrap`.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
