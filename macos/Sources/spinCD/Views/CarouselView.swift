import SwiftUI

/// `.carousel` — cover-flow browsing. 320pt cards, neighbours rotated 22° and
/// pushed 200pt aside, arrow keys / drag / scroll to move, click to open.
struct CarouselView: View {
    let albums: [Album]
    var onOpen: (Album) -> Void

    @Binding var index: Int
    @State private var dragX: CGFloat = 0
    @FocusState private var focused: Bool

    private var count: Int { albums.count }
    private var current: Album? { albums.indices.contains(index) ? albums[index] : albums.first }

    var body: some View {
        if albums.isEmpty {
            Text("No matches. Try a different search.")
                .font(Theme.mono(13))
                .foregroundStyle(Theme.ink3)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else {
            ZStack {
                ForEach(visible(), id: \.album.id) { slot in
                    card(slot)
                }

                // Centered disc's title and artist, 90pt below the cover.
                if let album = current {
                    VStack(spacing: 10) {
                        Text(album.title)
                            .font(Theme.serif(22))
                            .italic()
                            .foregroundStyle(Theme.ink0)
                            .multilineTextAlignment(.center)
                            .lineSpacing(-2)
                        Text(album.artist.uppercased() + (album.releaseYear.map { " · \($0)" } ?? ""))
                            .font(Theme.mono(11))
                            .tracking(2)
                            .foregroundStyle(Theme.ink2)
                    }
                    .frame(width: 520)
                    .offset(y: 258)
                    .id(album.id)
                    .transition(.opacity)
                }

                HStack {
                    navButton("‹") { step(-1) }
                    Spacer()
                    navButton("›") { step(1) }
                }
                .padding(.horizontal, 60)

                Text("\(String(format: "%03d", min(index + 1, count)))  /  \(String(format: "%03d", count))")
                    .font(Theme.mono(10))
                    .tracking(2)
                    .foregroundStyle(Theme.ink3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.6), in: Capsule())
                    .overlay(Capsule().strokeBorder(Theme.glassBorder, lineWidth: 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.trailing, 24)
                    .padding(.bottom, 14)
            }
            .frame(height: 600)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { dragX = $0.translation.width }
                    .onEnded { value in
                        if abs(value.translation.width) > 60 {
                            step(value.translation.width < 0 ? 1 : -1)
                        }
                        dragX = 0
                    }
            )
            .onScrollWheel { delta in step(delta > 0 ? 1 : -1) }
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
            .onKeyPress(.leftArrow) { step(-1); return .handled }
            .onKeyPress(.rightArrow) { step(1); return .handled }
            .onKeyPress(.return) {
                if let album = current { onOpen(album) }
                return .handled
            }
            .onAppear { focused = true }
            .onChange(of: albums.count) { _, _ in
                if index >= count { index = max(0, count - 1) }
            }
        }
    }

    private func navButton(_ glyph: String, action: @escaping () -> Void) -> some View {
        NavCircle(glyph: glyph, action: action)
    }

    private struct Slot: Equatable {
        let album: Album
        let offset: Int
    }

    /// The seven discs around the centre; everything else is off stage.
    private func visible() -> [Slot] {
        albums.indices.compactMap { i in
            var offset = i - index
            if offset > count / 2 { offset -= count }
            if offset < -count / 2 { offset += count }
            guard abs(offset) <= 3 else { return nil }
            return Slot(album: albums[i], offset: offset)
        }
    }

    private func card(_ slot: Slot) -> some View {
        CarouselCard(
            album: slot.album,
            offset: Double(slot.offset),
            dragX: slot.offset == 0 ? dragX : 0,
            animatedValue: index,
            onTap: {
                if slot.offset == 0 {
                    onOpen(slot.album)
                } else {
                    move(to: index + slot.offset)
                }
            }
        )
    }

    private func wrap(_ i: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((i % count) + count) % count
    }

    private func step(_ delta: Int) {
        move(to: index + delta)
    }

    private func move(to target: Int) {
        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.6)) {
            index = wrap(target)
        }
    }
}

/// `.carousel-card` — one 320pt cover, placed and rotated by its distance
/// from the centre of the stack.
private struct CarouselCard: View {
    let album: Album
    let offset: Double
    let dragX: CGFloat
    let animatedValue: Int
    let onTap: () -> Void

    private var distance: Double { abs(offset) }
    private var isCenter: Bool { offset == 0 }

    var body: some View {
        cover
            .scaleEffect(isCenter ? 1.05 : 0.85 - distance * 0.05)
            .rotation3DEffect(
                .degrees(offset * -22),
                axis: (x: 0, y: 1, z: 0),
                perspective: 1 / 5.6
            )
            .offset(x: offset * 200 + dragX * 0.35)
            .opacity(distance > 2 ? 0 : 1 - distance * 0.25)
            .blur(radius: distance * 1.5)
            .zIndex(100 - distance)
            .onTapGesture(perform: onTap)
            .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.6), value: animatedValue)
    }

    private var cover: some View {
        CoverView(album: album)
            .frame(width: 320, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Theme.ink0.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Theme.ink0.opacity(0.18), radius: 20, y: 22)
    }
}

/// `.carousel-nav` — the 44pt round glass arrow buttons.
private struct NavCircle: View {
    let glyph: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(glyph)
                .font(Theme.mono(18))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .foregroundStyle(hovering ? Theme.accent : Theme.ink1)
        .background(.white.opacity(0.78), in: Circle())
        .overlay(
            Circle().strokeBorder(
                hovering ? Theme.accent : Theme.glassBorderStrong,
                lineWidth: 1
            )
        )
        .shadow(color: Theme.glassShadow, radius: 10, y: 6)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
        .zIndex(200)
    }
}

/// Trackpad and mouse-wheel scrolling over an arbitrary view.
private struct ScrollWheelReader: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = WheelView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? WheelView)?.onScroll = onScroll
    }

    private final class WheelView: NSView {
        var onScroll: ((CGFloat) -> Void)?
        private var accumulated: CGFloat = 0

        override func scrollWheel(with event: NSEvent) {
            // Horizontal flicks move the carousel; vertical ones scroll the page.
            guard abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else {
                super.scrollWheel(with: event)
                return
            }
            accumulated += event.scrollingDeltaX
            if abs(accumulated) > 24 {
                onScroll?(accumulated < 0 ? 1 : -1)
                accumulated = 0
            }
        }
    }
}

extension View {
    func onScrollWheel(_ action: @escaping (CGFloat) -> Void) -> some View {
        overlay(ScrollWheelReader(onScroll: action).allowsHitTesting(false))
    }
}
