import SwiftUI

/// The web app's list column widths: 60px 2fr 1.3fr 70px 1.5fr 80px 36px, gap 18.
private struct ListColumns {
    let cover: CGFloat = 60
    let year: CGFloat = 70
    let rating: CGFloat = 80
    let arrow: CGFloat = 36
    let gap: CGFloat = 18
    let title: CGFloat
    let artist: CGFloat
    let genre: CGFloat

    init(width: CGFloat) {
        let fixed: CGFloat = 60 + 70 + 80 + 36 + 18 * 6
        let flexible = max(width - fixed, 240)
        title = flexible * 2 / 4.8
        artist = flexible * 1.3 / 4.8
        genre = flexible * 1.5 / 4.8
    }
}

/// `.list-view` — the registry as a glass table with sortable headers.
struct AlbumListView: View {
    let albums: [Album]
    var onOpen: (Album) -> Void

    @State private var sort: (key: SortKey, direction: SortDirection)?

    enum SortKey: String { case title, artist, releaseYear, genre, rating }
    enum SortDirection { case ascending, descending }

    var body: some View {
        GeometryReader { geo in
            let columns = ListColumns(width: geo.size.width - 36)

            ScrollView {
                LazyVStack(spacing: 0) {
                    header(columns)
                    ForEach(sorted) { album in
                        ListRow(album: album, columns: columns, onOpen: onOpen)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .glass(cornerRadius: 14)
        .overlay {
            if albums.isEmpty {
                Text("No matches. Try a different search.")
                    .font(Theme.mono(13))
                    .foregroundStyle(Theme.ink3)
            }
        }
    }

    // MARK: Header

    private func header(_ c: ListColumns) -> some View {
        HStack(spacing: c.gap) {
            Spacer().frame(width: c.cover)
            sortable(.title, "Title").frame(width: c.title, alignment: .leading)
            sortable(.artist, "Artist").frame(width: c.artist, alignment: .leading)
            sortable(.releaseYear, "Year").frame(width: c.year, alignment: .leading)
            sortable(.genre, "Genre").frame(width: c.genre, alignment: .leading)
            sortable(.rating, "Rating").frame(width: c.rating, alignment: .leading)
            Spacer().frame(width: c.arrow)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.glassBorder).frame(height: 1)
        }
    }

    private func sortable(_ key: SortKey, _ label: String) -> some View {
        SortableHeader(
            label: label,
            isActive: sort?.key == key,
            arrow: sort?.key == key ? (sort?.direction == .ascending ? " ▲" : " ▼") : ""
        ) {
            cycleSort(key)
        }
    }

    /// Ascending, then descending, then back to catalog order.
    private func cycleSort(_ key: SortKey) {
        if sort?.key != key {
            sort = (key, .ascending)
        } else if sort?.direction == .ascending {
            sort = (key, .descending)
        } else {
            sort = nil
        }
    }

    // MARK: Sorting

    private var sorted: [Album] {
        guard let sort else { return albums }
        var result = albums.sorted { compare($0, $1, by: sort.key) < 0 }
        guard sort.direction == .descending else { return result }

        // Reversed, but missing years and ratings still sort last.
        if sort.key == .releaseYear || sort.key == .rating {
            let missing = result.filter { value(of: $0, sort.key) == nil }
            let present = result.filter { value(of: $0, sort.key) != nil }.reversed()
            return Array(present) + missing
        }
        result.reverse()
        return result
    }

    private func value(of album: Album, _ key: SortKey) -> Int? {
        key == .releaseYear ? album.releaseYear : album.rating
    }

    private func compare(_ a: Album, _ b: Album, by key: SortKey) -> Int {
        switch key {
        case .title:
            a.title.localizedCaseInsensitiveCompare(b.title).rawValue
        case .artist:
            a.artist.localizedCaseInsensitiveCompare(b.artist).rawValue
        case .genre:
            (a.genre.first ?? "").localizedCaseInsensitiveCompare(b.genre.first ?? "").rawValue
        case .releaseYear, .rating:
            switch (value(of: a, key), value(of: b, key)) {
            case (nil, nil): 0
            case (nil, _): 1
            case (_, nil): -1
            case (let x?, let y?): x == y ? 0 : (x < y ? -1 : 1)
            }
        }
    }
}

private struct SortableHeader: View {
    let label: String
    let isActive: Bool
    let arrow: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(label.uppercased())
                Text(arrow).font(Theme.mono(9))
            }
            .font(Theme.mono(10))
            .tracking(2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive ? Theme.accent : (hovering ? Theme.ink1 : Theme.ink3))
        .onHover { hovering = $0 }
    }
}

private struct ListRow: View {
    let album: Album
    let columns: ListColumns
    var onOpen: (Album) -> Void
    @State private var hovering = false

    var body: some View {
        Button { onOpen(album) } label: {
            row
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(album.title) by \(album.artist)")
    }

    private var row: some View {
        HStack(spacing: columns.gap) {
            CoverView(album: album)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(Theme.ink0.opacity(0.08), lineWidth: 1)
                )
                .frame(width: columns.cover, alignment: .leading)

            Text(album.title)
                .font(Theme.serif(17))
                .italic()
                .foregroundStyle(Theme.ink0)
                .lineLimit(1)
                .frame(width: columns.title, alignment: .leading)

            Text(album.artist)
                .font(Theme.mono(12))
                .foregroundStyle(Theme.ink2)
                .lineLimit(1)
                .frame(width: columns.artist, alignment: .leading)

            Text(album.displayYear)
                .font(Theme.mono(11))
                .tracking(1)
                .foregroundStyle(Theme.ink3)
                .frame(width: columns.year, alignment: .leading)

            Text(album.genre.joined(separator: " · "))
                .font(Theme.mono(10))
                .tracking(0.5)
                .foregroundStyle(Theme.ink3)
                .lineLimit(1)
                .frame(width: columns.genre, alignment: .leading)

            StarRating(value: album.rating ?? 0, size: 11)
                .frame(width: columns.rating, alignment: .leading)

            Text("→")
                .font(Theme.mono(12))
                .foregroundStyle(Theme.ink3)
                .frame(width: columns.arrow, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(hovering ? Theme.frost1.opacity(0.08) : .clear)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.glassBorder).frame(height: 1)
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}
