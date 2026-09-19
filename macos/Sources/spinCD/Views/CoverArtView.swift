import AppKit
import SwiftUI

/// A disc's artwork: the scanned image when there is one, otherwise the
/// generated cover derived from the album's hue and accent.
struct CoverView: View {
    let album: Album
    var face: Face = .front

    var body: some View {
        if let url = ScanStore.resolve(album.scan(for: face)) {
            ScanImageView(url: url, contentMode: .fill) {
                ProceduralCover(album: album, face: face)
            }
        } else {
            ProceduralCover(album: album, face: face)
        }
    }
}

/// Loads a scan off disk (or the network, for collections still on S3) and
/// falls back to the placeholder while loading or on failure.
struct ScanImageView<Placeholder: View>: View {
    let url: URL
    var contentMode: ContentMode = .fill
    @ViewBuilder var placeholder: Placeholder

    @State private var image: NSImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if failed {
                placeholder
            } else {
                placeholder.opacity(0.6)
            }
        }
        .task(id: url) {
            if let hit = ScanImageCache.shared.cached(url) {
                image = hit
                return
            }
            let loaded = await ScanImageCache.shared.image(at: url)
            image = loaded
            failed = loaded == nil
        }
    }
}

extension ScanImageView where Placeholder == Color {
    init(url: URL, contentMode: ContentMode = .fill) {
        self.init(url: url, contentMode: contentMode) { Theme.snow2 }
    }
}

// MARK: - Generated cover

/// The placeholder cover, drawn on a 300×300 grid to match the web registry's
/// SVG: a hue-derived gradient, a registration grid, one of four accent motifs
/// keyed off the catalog number, and typeset metadata.
struct ProceduralCover: View {
    let album: Album
    var face: Face = .front

    private var hue: Double { Double(album.hue ?? 200) }
    private var accent: Color { Color(hex: album.accent ?? "#5E8CA8") }
    private var isBack: Bool { face == .back }

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let s = min(size.width, size.height) / 300
            func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            // Background wash
            let top = isBack
                ? Color.oklch(l: 0.94, c: 0.02, h: hue)
                : Color.oklch(l: 0.78, c: 0.06, h: hue)
            let bottom = isBack
                ? Color.oklch(l: 0.86, c: 0.04, h: (hue + 30).truncatingRemainder(dividingBy: 360))
                : Color.oklch(l: 0.62, c: 0.09, h: (hue + 30).truncatingRemainder(dividingBy: 360))
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [top, bottom]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            // Registration grid
            var grid = Path()
            for y in [60.0, 240.0] {
                grid.move(to: p(0, y))
                grid.addLine(to: p(300, y))
            }
            for x in [60.0, 240.0] {
                grid.move(to: p(x, 0))
                grid.addLine(to: p(x, 300))
            }
            ctx.stroke(grid, with: .color(Theme.ink0.opacity(0.08)), lineWidth: s)

            if !isBack {
                drawMotif(ctx: ctx, s: s, p: p)
            }

            // Watermarked initials
            ctx.draw(
                Text(album.initials)
                    .font(Theme.serif(86 * s))
                    .italic()
                    .foregroundStyle(accent.opacity(isBack ? 0.10 : 0.22)),
                at: p(278, 112),
                anchor: .topTrailing
            )

            // Catalog line
            ctx.draw(
                Text("\(album.catalogNumber) · \(album.displayYear)")
                    .font(Theme.mono(10 * s, .medium))
                    .tracking(2 * s)
                    .foregroundStyle(Theme.ink0.opacity(0.6)),
                at: p(22, 32),
                anchor: .topLeading
            )

            if isBack {
                drawBackFace(ctx: ctx, s: s, p: p)
            }

            // Title and artist
            let title = album.title.count > 22
                ? album.title.prefix(21) + "…"
                : album.title[...]
            ctx.draw(
                Text(String(title))
                    .font(Theme.serif(22 * s))
                    .italic()
                    .foregroundStyle(Theme.ink0),
                at: p(22, 264),
                anchor: .bottomLeading
            )
            ctx.draw(
                Text(album.artist.uppercased())
                    .font(Theme.mono(9 * s, .medium))
                    .tracking(2 * s)
                    .foregroundStyle(Theme.ink1.opacity(0.75)),
                at: p(22, 284),
                anchor: .bottomLeading
            )
        }
        .background(Theme.snow2)
        .drawingGroup()
    }

    /// One of four accent motifs, chosen by catalog number like the SVG did.
    private func drawMotif(ctx: GraphicsContext, s: Double, p: (Double, Double) -> CGPoint) {
        let stroke = GraphicsContext.Shading.color(accent.opacity(0.55))
        let width = 1.4 * s

        switch Int(album.id ?? 0) % 4 {
        case 0:
            var path = Path()
            for r in [40.0, 60.0, 80.0] {
                path.addEllipse(in: CGRect(
                    x: (150 - r) * s, y: (150 - r) * s, width: 2 * r * s, height: 2 * r * s
                ))
            }
            ctx.stroke(path, with: stroke, lineWidth: width)
        case 1:
            var path = Path()
            path.addRect(CGRect(x: 60 * s, y: 220 * s, width: 180 * s, height: 2 * s))
            path.addRect(CGRect(x: 60 * s, y: 60 * s, width: 2 * s, height: 160 * s))
            ctx.fill(path, with: .color(accent.opacity(0.6)))
        case 2:
            for (i, offset) in [0.0, 20.0, 40.0].enumerated() {
                var path = Path()
                path.move(to: p(40, 200 + offset))
                path.addQuadCurve(to: p(260, 200 + offset), control: p(150, 80 + offset))
                ctx.stroke(
                    path,
                    with: .color(accent.opacity(0.6 - Double(i) * 0.12)),
                    lineWidth: width
                )
            }
        default:
            var path = Path()
            path.move(to: p(150, 70))
            path.addLine(to: p(230, 210))
            path.addLine(to: p(70, 210))
            path.closeSubpath()
            path.move(to: p(150, 70))
            path.addLine(to: p(150, 210))
            ctx.stroke(path, with: stroke, lineWidth: width)
        }
    }

    /// The back of the case: barcode, catalog code and the first ten tracks.
    private func drawBackFace(ctx: GraphicsContext, s: Double, p: (Double, Double) -> CGPoint) {
        ctx.fill(
            Path(CGRect(x: 22 * s, y: 60 * s, width: 80 * s, height: 22 * s)),
            with: .color(Theme.ink0.opacity(0.85))
        )
        var bars = Path()
        for i in 0..<22 {
            bars.addRect(CGRect(
                x: (26 + Double(i) * 3.2) * s,
                y: 62 * s,
                width: (i % 3 == 0 ? 1.6 : 0.8) * s,
                height: 18 * s
            ))
        }
        ctx.fill(bars, with: .color(.white))

        ctx.draw(
            Text("\(album.releaseYear.map(String.init) ?? "----")-\(String(format: "%04d", album.id ?? 0))")
                .font(Theme.mono(9 * s))
                .tracking(1.5 * s)
                .foregroundStyle(Theme.ink0.opacity(0.7)),
            at: p(110, 66),
            anchor: .topLeading
        )

        for (i, track) in album.tracks.prefix(10).enumerated() {
            let name = track.count > 32 ? track.prefix(30) + "…" : track[...]
            ctx.draw(
                Text("\(String(format: "%02d", i + 1)).  \(String(name))")
                    .font(Theme.mono(8 * s))
                    .foregroundStyle(Theme.ink0.opacity(0.65)),
                at: p(22, 100 + Double(i) * 13),
                anchor: .topLeading
            )
        }
        if album.tracks.count > 10 {
            ctx.draw(
                Text("+\(album.tracks.count - 10) more…")
                    .font(Theme.mono(8 * s))
                    .italic()
                    .foregroundStyle(Theme.ink0.opacity(0.5)),
                at: p(22, 100 + 10 * 13),
                anchor: .topLeading
            )
        }
    }
}

// MARK: - Disc

/// The disc face: a pressed-CD look with a rainbow sheen tinted by the album hue.
struct DiscView: View {
    let album: Album

    private var hue: Double { Double(album.hue ?? 200) }
    private var accent: Color { Color(hex: album.accent ?? "#5E8CA8") }

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let side = min(size.width, size.height)
            let s = side / 240
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            func circle(_ radius: Double) -> Path {
                Path(ellipseIn: CGRect(
                    x: center.x - radius * s, y: center.y - radius * s,
                    width: 2 * radius * s, height: 2 * radius * s
                ))
            }

            let disc = circle(119)
            ctx.fill(
                disc,
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: Color(hex: "FAFCFF"), location: 0),
                        .init(color: Color(hex: "E6ECF3"), location: 0.4),
                        .init(color: Color(hex: "A6B1C4"), location: 1),
                    ]),
                    center: center,
                    startRadius: 0,
                    endRadius: side / 2
                )
            )
            ctx.fill(
                disc,
                with: .conicGradient(
                    Gradient(stops: (0...6).map { i in
                        let step = Double(i) / 6
                        return .init(
                            color: Color.oklch(
                                l: 0.85, c: 0.13,
                                h: (hue + step * 360).truncatingRemainder(dividingBy: 360)
                            ).opacity(0.45),
                            location: step
                        )
                    }),
                    center: center
                )
            )
            ctx.fill(
                disc,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(0.45), location: 0),
                        .init(color: .white.opacity(0), location: 0.5),
                        .init(color: .white.opacity(0.14), location: 1),
                    ]),
                    startPoint: CGPoint(x: center.x, y: center.y - side / 2),
                    endPoint: CGPoint(x: center.x, y: center.y + side / 2)
                )
            )

            // Pressed data rings
            var rings = Path()
            for i in 0..<24 {
                rings.addPath(circle(40 + Double(i) * 3.2))
            }
            ctx.stroke(rings, with: .color(Theme.ink0.opacity(0.06)), lineWidth: 0.5 * s)

            // Hub
            ctx.fill(circle(42), with: .color(accent.opacity(0.25)))
            ctx.fill(circle(42), with: .color(.white.opacity(0.85)))
            ctx.stroke(circle(42), with: .color(accent.opacity(0.4)), lineWidth: s)

            ctx.draw(
                Text(album.artist.uppercased().prefix(24))
                    .font(Theme.mono(6 * s, .medium))
                    .tracking(1.5 * s)
                    .foregroundStyle(Theme.ink0.opacity(0.7)),
                at: CGPoint(x: center.x, y: center.y - 8 * s),
                anchor: .center
            )
            ctx.draw(
                Text(album.title.count > 18 ? album.title.prefix(17) + "…" : album.title[...])
                    .font(Theme.serif(9 * s))
                    .italic()
                    .foregroundStyle(Theme.ink0),
                at: CGPoint(x: center.x, y: center.y + 5 * s),
                anchor: .center
            )

            ctx.fill(circle(9), with: .color(Color(hex: "CFD8E3")))
            ctx.stroke(circle(9), with: .color(Theme.ink0.opacity(0.3)), lineWidth: 0.5 * s)

            // Specular sweep
            var sheen = Path(ellipseIn: CGRect(
                x: -50 * s, y: -20 * s, width: 100 * s, height: 40 * s
            ))
            sheen = sheen.applying(
                CGAffineTransform(rotationAngle: -.pi / 6)
                    .concatenating(CGAffineTransform(
                        translationX: center.x - 40 * s, y: center.y - 40 * s
                    ))
            )
            ctx.clip(to: disc)
            ctx.fill(sheen, with: .color(.white.opacity(0.3)))
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(Circle())
        .shadow(color: Theme.ink0.opacity(0.25), radius: 18, y: 8)
    }
}

/// The disc face in the detail modal: the scanned disc if present, else the
/// generated one. A scan is cropped to a circle, as `border-radius: 50%` does
/// on the web, so the scanner bed around the disc is hidden.
struct DiscFace: View {
    let album: Album

    var body: some View {
        if let url = ScanStore.resolve(album.scanDisc) {
            ScanImageView(url: url, contentMode: .fill) { DiscView(album: album) }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(Circle())
                .shadow(color: Theme.ink0.opacity(0.3), radius: 12, y: 14)
        } else {
            DiscView(album: album)
        }
    }
}
