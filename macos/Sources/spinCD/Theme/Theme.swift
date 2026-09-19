import AppKit
import SwiftUI

/// Colors, type and surface treatments ported 1:1 from the web registry's
/// stylesheet, so the native app reads as the same product.
enum Theme {
    // Snow / ice
    static let snow0 = Color(hex: "FFFFFF")
    static let snow1 = Color(hex: "F4F7FA")
    static let snow2 = Color(hex: "E8EEF4")
    static let snow3 = Color(hex: "D8E1EB")

    // Ink (navy text)
    static let ink0 = Color(hex: "1B2434")
    static let ink1 = Color(hex: "2D3B52")
    static let ink2 = Color(hex: "4A5878")
    static let ink3 = Color(hex: "7787A0")
    static let ink4 = Color(hex: "A6B1C4")

    // Frost accents
    static let frost0 = Color(hex: "6FA8B5")
    static let frost1 = Color(hex: "5E8CA8")
    static let frost2 = Color(hex: "4A6F94")
    static let frost3 = Color(hex: "3A5A82")

    static let auroraYellow = Color(hex: "C9A96A")
    static let auroraOrange = Color(hex: "C07B5C")
    static let auroraRed = Color(hex: "B05568")
    static let auroraGreen = Color(hex: "7FA37C")
    static let auroraPurple = Color(hex: "9B7CA3")

    static let accent = frost2
    static let accentSoft = Color(hex: "5E8CA8").opacity(0.12)

    static let glassBorder = ink0.opacity(0.08)
    static let glassBorderStrong = ink0.opacity(0.14)
    static let glassShadow = ink0.opacity(0.06)

    /// `--mono`: JetBrains Mono, falling back to SF Mono if registration failed.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        AppFonts.mono(size, weight)
    }

    /// `--serif`: Instrument Serif, falling back to New York.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        AppFonts.serif(size, weight)
    }
}

/// Registers the two bundled typefaces the web app loads from Google Fonts, so
/// the native app sets type identically.
enum AppFonts {
    private static let registered: (serif: Bool, mono: Bool) = {
        register()
        let families = Set(NSFontManager.shared.availableFontFamilies)
        return (families.contains("Instrument Serif"), families.contains("JetBrains Mono"))
    }()

    private static func register() {
        var urls: [URL] = []
        if let inFolder = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") {
            urls += inFolder
        }
        if let flat = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            urls += flat
        }
        guard !urls.isEmpty else { return }
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        registered.mono
            ? .custom("JetBrains Mono", fixedSize: size).weight(weight)
            : .system(size: size, weight: weight, design: .monospaced)
    }

    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        registered.serif
            ? .custom("Instrument Serif", fixedSize: size).weight(weight)
            : .system(size: size, weight: weight, design: .serif)
    }

    /// Called at launch so the first view already has the faces available.
    static func warmUp() {
        _ = registered
    }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else {
            self = .gray
            return
        }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }

    /// OKLCH -> sRGB, so generated cover art matches the CSS `oklch()` ramps.
    static func oklch(l: Double, c: Double, h: Double) -> Color {
        let hr = h * .pi / 180
        let a = c * cos(hr)
        let b = c * sin(hr)

        let lp = l + 0.3963377774 * a + 0.2158037573 * b
        let mp = l - 0.1055613458 * a - 0.0638541728 * b
        let sp = l - 0.0894841775 * a - 1.2914855480 * b

        let l3 = lp * lp * lp, m3 = mp * mp * mp, s3 = sp * sp * sp

        let r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
        let g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
        let bl = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

        func encode(_ x: Double) -> Double {
            let x = min(max(x, 0), 1)
            return x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1 / 2.4) - 0.055
        }
        return Color(.sRGB, red: encode(r), green: encode(g), blue: encode(bl))
    }
}

// MARK: - Background

/// The alpine snow backdrop: white wash at the top, two colour blooms, a
/// snowfield ridge along the bottom, and a scatter of sparkles.
struct AlpineBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "D9E3EE"), location: 0),
                        .init(color: Color(hex: "B8C8DA"), location: 0.6),
                        .init(color: Color(hex: "95A8BD"), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // radial-gradient(ellipse 120% 60% at 50% -10%, white, transparent)
                bloom(.white.opacity(0.95), at: CGPoint(x: w * 0.5, y: -h * 0.1),
                      radii: CGSize(width: w * 1.2, height: h * 0.6))
                bloom(Color(hex: "8FBCBB").opacity(0.25), at: CGPoint(x: w * 0.15, y: h * 0.2),
                      radii: CGSize(width: w * 0.6, height: h * 0.4))
                bloom(Color(hex: "B4C8E1").opacity(0.45), at: CGPoint(x: w * 0.85, y: h * 0.3),
                      radii: CGSize(width: w * 0.6, height: h * 0.4))

                RidgeShape()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.55),
                                .init(color: Color(hex: "788AA2").opacity(0.35), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RidgeShape().fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.7),
                                    .init(color: .white.opacity(0.5), location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    )
                    .opacity(0.7)

                Sparkles()
                    .opacity(0.8)
            }
        }
        .ignoresSafeArea()
    }

    /// One elliptical colour wash. The gradient reaches full transparency exactly
    /// at the rectangle's bounds, so there is no visible edge.
    private func bloom(_ color: Color, at center: CGPoint, radii: CGSize) -> some View {
        Rectangle()
            .fill(
                EllipticalGradient(
                    stops: [
                        .init(color: color, location: 0),
                        .init(color: color.opacity(0), location: 1),
                    ],
                    center: .center,
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.5
                )
            )
            .frame(width: radii.width * 2, height: radii.height * 2)
            .position(center)
    }
}

/// The snowfield silhouette masked into the lower half of the backdrop.
private struct RidgeShape: Shape {
    /// The stylesheet's mask polygon, normalized to 0...1.
    private static let points: [CGPoint] = [
        CGPoint(x: 0, y: 0.65), CGPoint(x: 0.067, y: 0.525), CGPoint(x: 0.133, y: 0.625),
        CGPoint(x: 0.2, y: 0.45), CGPoint(x: 0.283, y: 0.55), CGPoint(x: 0.367, y: 0.35),
        CGPoint(x: 0.45, y: 0.5), CGPoint(x: 0.533, y: 0.4), CGPoint(x: 0.617, y: 0.55),
        CGPoint(x: 0.7, y: 0.45), CGPoint(x: 0.8, y: 0.6), CGPoint(x: 0.9, y: 0.5),
        CGPoint(x: 1, y: 0.65),
    ]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let band = rect.height * 0.55
        let top = rect.maxY - band
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for pt in Self.points {
            p.addLine(to: CGPoint(x: rect.minX + pt.x * rect.width, y: top + pt.y * band))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The faint snow specks the stylesheet paints with tiny radial gradients.
private struct Sparkles: View {
    private static let specks: [(x: Double, y: Double, r: Double, o: Double)] = [
        (0.20, 0.30, 2.0, 0.7), (0.70, 0.60, 1.5, 0.5), (0.40, 0.80, 2.0, 0.6),
        (0.85, 0.25, 1.0, 0.6), (0.10, 0.70, 1.5, 0.5), (0.60, 0.15, 2.0, 0.6),
        (0.30, 0.50, 1.0, 0.4),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(Self.specks.enumerated()), id: \.offset) { _, speck in
                Circle()
                    .fill(.white.opacity(speck.o))
                    .frame(width: speck.r * 3, height: speck.r * 3)
                    .blur(radius: speck.r)
                    .position(x: geo.size.width * speck.x, y: geo.size.height * speck.y)
            }
        }
    }
}

// MARK: - Surfaces

/// `.glass` — the frosted panel used for cards, rows and stat tiles.
struct GlassPanel: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.55
    var borderStrong = false

    func body(content: Content) -> some View {
        content
            .background(.white.opacity(opacity))
            .background(.ultraThinMaterial.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        borderStrong ? Theme.glassBorderStrong : Theme.glassBorder,
                        lineWidth: 1
                    )
            )
            .shadow(color: Theme.glassShadow, radius: 10, y: 6)
    }
}

extension View {
    func glass(
        cornerRadius: CGFloat = 16,
        opacity: Double = 0.55,
        borderStrong: Bool = false
    ) -> some View {
        modifier(GlassPanel(cornerRadius: cornerRadius, opacity: opacity, borderStrong: borderStrong))
    }

    /// `--glass-bg-strong`
    func glassStrong(cornerRadius: CGFloat = 14) -> some View {
        glass(cornerRadius: cornerRadius, opacity: 0.78)
    }
}
