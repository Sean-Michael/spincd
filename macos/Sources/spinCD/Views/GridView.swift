import SwiftUI

/// `.grid-view` — a wall of covers, metadata set beneath each one.
struct AlbumGridView: View {
    let albums: [Album]
    var onOpen: (Album) -> Void

    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 22)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 22) {
            ForEach(albums) { album in
                GridCard(album: album, onOpen: onOpen)
            }
        }
        .padding(.bottom, 32)
    }
}

private struct GridCard: View {
    let album: Album
    var onOpen: (Album) -> Void
    @State private var hovering = false

    var body: some View {
        Button { onOpen(album) } label: {
            card
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(album.title) by \(album.artist)")
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            // A hard square driven by the column width, with the scan cropped to
            // fill it — `aspect-ratio: 1/1` plus `object-fit: cover` on the web.
            // Letting the cover size itself would give each non-square scan its
            // own height and stagger the whole row.
            Rectangle()
                .fill(.white)
                .aspectRatio(1, contentMode: .fit)
                .overlay { CoverView(album: album) }
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Theme.ink0.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Theme.ink0.opacity(0.14), radius: 12, y: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(Theme.serif(17))
                    .italic()
                    .foregroundStyle(Theme.ink0)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(album.artist.uppercased() + (album.releaseYear.map { " · \($0)" } ?? ""))
                    .font(Theme.mono(10))
                    .tracking(1.5)
                    .foregroundStyle(Theme.ink3)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .offset(y: hovering ? -4 : 0)
        .animation(.easeOut(duration: 0.2), value: hovering)
        .onHover { hovering = $0 }
    }
}
