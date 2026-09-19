import SwiftUI

/// `.stats` — the collapsible panel: two tiles on top, then full-width genre
/// bars and a decade histogram.
struct StatsPanel: View {
    let albums: [Album]

    private var genres: [(String, Int)] {
        var counts: [String: Int] = [:]
        for album in albums {
            for genre in album.genre { counts[genre, default: 0] += 1 }
        }
        return counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }

    private var decades: [(Int, Int)] {
        var counts: [Int: Int] = [:]
        for album in albums {
            guard let year = album.releaseYear else { continue }
            counts[year / 10 * 10, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    private var averageRating: String {
        let rated = albums.compactMap(\.rating)
        guard !rated.isEmpty else { return "—" }
        return String(format: "%.1f", Double(rated.reduce(0, +)) / Double(rated.count))
    }

    private var yearSpan: Int {
        let years = albums.compactMap(\.releaseYear)
        guard let oldest = years.min() else { return 0 }
        return Calendar.current.component(.year, from: Date()) - oldest
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                tile("Total Discs", sub: "spanning \(yearSpan) years of music") {
                    Text(String(format: "%03d", albums.count))
                        .font(Theme.serif(42))
                        .italic()
                        .foregroundStyle(Theme.ink0)
                }
                tile("Avg Rating", sub: "curated, not collected") {
                    HStack(alignment: .lastTextBaseline, spacing: 0) {
                        Text(averageRating)
                            .font(Theme.serif(42))
                            .italic()
                            .foregroundStyle(Theme.ink0)
                        Text(" / 5")
                            .font(Theme.serif(18))
                            .foregroundStyle(Theme.ink3)
                    }
                }
            }

            tile("Top Genres", sub: nil) {
                let top = Array(genres.prefix(5))
                let peak = top.first?.1 ?? 1
                VStack(spacing: 6) {
                    ForEach(top, id: \.0) { genre, count in
                        HStack(spacing: 8) {
                            Text(genre)
                                .font(Theme.mono(10))
                                .tracking(0.5)
                                .foregroundStyle(Theme.ink2)
                                .frame(width: 72, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Theme.ink0.opacity(0.08))
                                    Capsule()
                                        .fill(Theme.accent)
                                        .frame(width: geo.size.width * Double(count) / Double(peak))
                                }
                            }
                            .frame(height: 4)
                            Text("\(count)")
                                .font(Theme.mono(10))
                                .foregroundStyle(Theme.ink3)
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }
                .padding(.top, 10)
            }

            tile("By Decade", sub: nil) {
                let peak = decades.map(\.1).max() ?? 1
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(decades, id: \.0) { decade, count in
                        DecadeBar(
                            decade: decade,
                            count: count,
                            fraction: Double(count) / Double(peak)
                        )
                    }
                }
                .frame(height: 50)
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
        }
    }

    private func tile<Content: View>(
        _ label: String,
        sub: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            FieldLabel(text: label)
            content()
                .padding(.top, sub == nil ? 0 : 8)
            if let sub {
                Text(sub)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.ink3)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .glass(cornerRadius: 16)
    }
}

/// `.decade-bar` — gradient column with its decade label below.
private struct DecadeBar: View {
    let decade: Int
    let count: Int
    let fraction: Double

    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            UnevenRoundedRectangle(
                topLeadingRadius: 2, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 2
            )
            .fill(
                LinearGradient(
                    colors: hovering
                        ? [Theme.ink0, Theme.accent]
                        : [Theme.accent, Theme.frost1.opacity(0.25)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: max(3, 50 * fraction))
            Text("'\(String(String(decade).suffix(2)))")
                .font(Theme.mono(9))
                .tracking(0.5)
                .foregroundStyle(Theme.ink3)
                .padding(.top, 4)
                .frame(height: 16)
        }
        .frame(maxWidth: .infinity)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.2), value: hovering)
        .help("\(decade)s: \(count) discs")
    }
}
