import type { CD, Face } from "../types/cd";

interface CoverArtProps {
  cd: CD;
  size?: number;
  face?: Face;
}

export function CoverArt({ cd, face = "front" }: CoverArtProps) {
  const scanKey: keyof CD = face === "back" ? "scanBack" : "scanFront";
  const scanUrl = cd[scanKey] as string | null;
  if (scanUrl) {
    return (
      <img
        src={scanUrl}
        alt={`${cd.title} ${face}`}
        style={{ display: "block", width: "100%", height: "100%", objectFit: "cover" }}
      />
    );
  }

  const hue = cd.hue ?? 200;
  const id = `cv-${cd.id}-${face}`;
  const initials = (cd.title || "")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 3)
    .map(w => w[0])
    .join("")
    .toUpperCase();
  const isBack = face === "back";

  return (
    <svg
      viewBox="0 0 300 300"
      preserveAspectRatio="xMidYMid slice"
      style={{ display: "block", width: "100%", height: "100%" }}
    >
      <defs>
        <linearGradient id={`${id}-bg`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor={isBack ? `oklch(0.94 0.02 ${hue})` : `oklch(0.78 0.06 ${hue})`} />
          <stop offset="100%" stopColor={isBack ? `oklch(0.86 0.04 ${(hue + 30) % 360})` : `oklch(0.62 0.09 ${(hue + 30) % 360})`} />
        </linearGradient>
        <pattern id={`${id}-grain`} x="0" y="0" width="3" height="3" patternUnits="userSpaceOnUse">
          <rect width="3" height="3" fill="transparent" />
          <circle cx="1" cy="1" r="0.4" fill="rgba(27,36,52,0.06)" />
        </pattern>
      </defs>
      <rect x="0" y="0" width="300" height="300" fill={`url(#${id}-bg)`} />
      <g stroke="rgba(27,36,52,0.08)" strokeWidth="1">
        <line x1="0" y1="60" x2="300" y2="60" />
        <line x1="0" y1="240" x2="300" y2="240" />
        <line x1="60" y1="0" x2="60" y2="300" />
        <line x1="240" y1="0" x2="240" y2="300" />
      </g>
      <rect x="0" y="0" width="300" height="300" fill={`url(#${id}-grain)`} />
      {!isBack && cd.id % 4 === 0 && (
        <g opacity="0.55" stroke={cd.accent} fill="none" strokeWidth="1.4">
          <circle cx="150" cy="150" r="40" />
          <circle cx="150" cy="150" r="60" />
          <circle cx="150" cy="150" r="80" />
        </g>
      )}
      {!isBack && cd.id % 4 === 1 && (
        <g opacity="0.6" fill={cd.accent}>
          <rect x="60" y="220" width="180" height="2" />
          <rect x="60" y="60" width="2" height="160" />
        </g>
      )}
      {!isBack && cd.id % 4 === 2 && (
        <g opacity="0.6" stroke={cd.accent} fill="none" strokeWidth="1.4">
          <path d="M 40 200 Q 150 80 260 200" />
          <path d="M 40 220 Q 150 100 260 220" opacity="0.6" />
          <path d="M 40 240 Q 150 120 260 240" opacity="0.4" />
        </g>
      )}
      {!isBack && cd.id % 4 === 3 && (
        <g opacity="0.55" stroke={cd.accent} fill="none" strokeWidth="1.4">
          <polygon points="150,70 230,210 70,210" />
          <line x1="150" y1="70" x2="150" y2="210" />
        </g>
      )}
      <g fontFamily="'JetBrains Mono', monospace" fill="#1B2434">
        <text x="22" y="40" fontSize="10" letterSpacing="2" opacity="0.6">
          {String(cd.id).padStart(3, "0")} · {cd.year}
        </text>
      </g>
      <g fontFamily="'Instrument Serif', serif" fill="#1B2434">
        <text x="22" y="262" fontSize="22" fontStyle="italic">
          {cd.title.length > 22 ? cd.title.slice(0, 21) + "…" : cd.title}
        </text>
      </g>
      <g fontFamily="'JetBrains Mono', monospace" fill="#2D3B52">
        <text x="22" y="282" fontSize="9" letterSpacing="2" opacity="0.75">
          {cd.artist.toUpperCase()}
        </text>
      </g>
      <text
        x="278"
        y="140"
        textAnchor="end"
        fontFamily="'Instrument Serif', serif"
        fontSize="86"
        fill={cd.accent}
        opacity={isBack ? 0.1 : 0.22}
        fontStyle="italic"
      >
        {initials || "·"}
      </text>
      {isBack && (
        <g>
          <rect x="22" y="60" width="80" height="22" fill="#1B2434" opacity="0.85" />
          {Array.from({ length: 22 }).map((_, i) => (
            <rect
              key={i}
              x={26 + i * 3.2}
              y={62}
              width={i % 3 === 0 ? 1.6 : 0.8}
              height={18}
              fill="#fff"
            />
          ))}
          <text
            x="110"
            y="76"
            fontFamily="'JetBrains Mono',monospace"
            fontSize="9"
            fill="#1B2434"
            opacity="0.7"
            letterSpacing="1.5"
          >
            {String(cd.year)}-{String(cd.id).padStart(4, "0")}
          </text>
          <g
            fontFamily="'JetBrains Mono',monospace"
            fill="#1B2434"
            opacity="0.65"
            fontSize="8"
            letterSpacing="0.8"
          >
            {(cd.tracks || []).slice(0, 10).map((t, i) => (
              <text key={i} x="22" y={108 + i * 13}>
                {String(i + 1).padStart(2, "0")}.  {t.length > 32 ? t.slice(0, 30) + "…" : t}
              </text>
            ))}
            {(cd.tracks || []).length > 10 && (
              <text x="22" y={108 + 10 * 13} fontStyle="italic" opacity="0.5">
                +{cd.tracks.length - 10} more…
              </text>
            )}
          </g>
        </g>
      )}
    </svg>
  );
}

interface DiscProps {
  cd: CD;
  size?: number;
}

export function Disc({ cd, size = 240 }: DiscProps) {
  const hue = cd.hue ?? 200;
  return (
    <div className="disc" style={{ width: size, height: size }}>
      <svg viewBox="0 0 240 240" width={size} height={size} style={{ display: "block" }}>
        <defs>
          <radialGradient id={`d-${cd.id}-base`} cx="50%" cy="50%" r="50%">
            <stop offset="0%" stopColor="#fafcff" stopOpacity="1" />
            <stop offset="40%" stopColor="#e6ecf3" stopOpacity="1" />
            <stop offset="100%" stopColor="#a6b1c4" stopOpacity="1" />
          </radialGradient>
          <linearGradient id={`d-${cd.id}-rainbow`} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor={`oklch(0.85 0.13 ${hue})`} stopOpacity="0.55" />
            <stop offset="25%" stopColor={`oklch(0.85 0.13 ${(hue + 60) % 360})`} stopOpacity="0.4" />
            <stop offset="50%" stopColor={`oklch(0.85 0.13 ${(hue + 120) % 360})`} stopOpacity="0.25" />
            <stop offset="75%" stopColor={`oklch(0.85 0.13 ${(hue + 200) % 360})`} stopOpacity="0.4" />
            <stop offset="100%" stopColor={`oklch(0.85 0.13 ${(hue + 300) % 360})`} stopOpacity="0.55" />
          </linearGradient>
          <linearGradient id={`d-${cd.id}-shine`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#fff" stopOpacity="0.7" />
            <stop offset="50%" stopColor="#fff" stopOpacity="0" />
            <stop offset="100%" stopColor="#fff" stopOpacity="0.2" />
          </linearGradient>
        </defs>
        <circle cx="120" cy="120" r="119" fill={`url(#d-${cd.id}-base)`} />
        <circle cx="120" cy="120" r="119" fill={`url(#d-${cd.id}-rainbow)`} />
        <circle cx="120" cy="120" r="119" fill={`url(#d-${cd.id}-shine)`} opacity="0.6" />
        {Array.from({ length: 24 }).map((_, i) => (
          <circle
            key={i}
            cx="120"
            cy="120"
            r={40 + i * 3.2}
            fill="none"
            stroke="rgba(27,36,52,0.06)"
            strokeWidth="0.5"
          />
        ))}
        <circle cx="120" cy="120" r="42" fill={cd.accent} fillOpacity="0.25" />
        <circle cx="120" cy="120" r="42" fill="#fff" fillOpacity="0.85" />
        <circle cx="120" cy="120" r="42" fill="none" stroke={cd.accent} strokeOpacity="0.4" />
        <text
          x="120"
          y="115"
          textAnchor="middle"
          fontFamily="'JetBrains Mono', monospace"
          fontSize="6"
          fill="#1B2434"
          letterSpacing="1.5"
          opacity="0.7"
        >
          {cd.artist.toUpperCase().slice(0, 24)}
        </text>
        <text
          x="120"
          y="128"
          textAnchor="middle"
          fontFamily="'Instrument Serif', serif"
          fontSize="9"
          fill="#1B2434"
          fontStyle="italic"
        >
          {cd.title.length > 18 ? cd.title.slice(0, 17) + "…" : cd.title}
        </text>
        <circle cx="120" cy="120" r="9" fill="#cfd8e3" />
        <circle cx="120" cy="120" r="9" fill="none" stroke="rgba(27,36,52,0.3)" strokeWidth="0.5" />
        <ellipse cx="80" cy="80" rx="50" ry="20" fill="#fff" opacity="0.3" transform="rotate(-30 80 80)" />
      </svg>
    </div>
  );
}
