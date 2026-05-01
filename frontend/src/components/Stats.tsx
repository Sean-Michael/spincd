import { useMemo } from "react";
import type { Album } from "../types/album";

interface StatsProps {
  cds: Album[];
}

export function Stats({ cds }: StatsProps) {
  const total = cds.length;

  const genres = useMemo(() => {
    const m: Record<string, number> = {};
    cds.forEach(c => c.genre.forEach(g => { m[g] = (m[g] || 0) + 1; }));
    return Object.entries(m).sort((a, b) => b[1] - a[1]);
  }, [cds]);

  const decades = useMemo(() => {
    const m: Record<string, number> = {};
    cds.forEach(c => {
      if (c.release_year == null) return;
      const d = Math.floor(c.release_year / 10) * 10;
      m[d] = (m[d] || 0) + 1;
    });
    return Object.entries(m).sort((a, b) => Number(a[0]) - Number(b[0]));
  }, [cds]);

  const maxDecade = Math.max(1, ...decades.map(([, n]) => n));
  const rated = cds.filter(c => c.rating != null);
  const avgRating = rated.length
    ? (rated.reduce((s, c) => s + (c.rating ?? 0), 0) / rated.length).toFixed(1)
    : "—";
  const years = cds.map(c => c.release_year).filter((y): y is number => y != null);
  const oldestYear = years.length ? Math.min(...years) : new Date().getFullYear();
  const yearSpan = new Date().getFullYear() - oldestYear;

  return (
    <div className="stats">
      <div className="glass stat">
        <div className="stat-label">Total Discs</div>
        <div className="stat-value">{String(total).padStart(3, "0")}</div>
        <div className="stat-sub">spanning {yearSpan} years of music</div>
      </div>
      <div className="glass stat">
        <div className="stat-label">Avg Rating</div>
        <div className="stat-value">
          {avgRating}
          <span style={{ fontSize: 18, color: "var(--ink-3)" }}> / 5</span>
        </div>
        <div className="stat-sub">curated, not collected</div>
      </div>
      <div className="glass stat" style={{ gridColumn: "span 2" }}>
        <div className="stat-label">Top Genres</div>
        <div className="stat-bars">
          {genres.slice(0, 5).map(([g, n]) => (
            <div key={g} className="stat-bar">
              <span className="stat-bar-label">{g}</span>
              <span className="stat-bar-track">
                <span
                  className="stat-bar-fill"
                  style={{ width: (n / genres[0][1] * 100) + "%" }}
                />
              </span>
              <span className="stat-bar-count">{n}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="glass stat" style={{ gridColumn: "span 2" }}>
        <div className="stat-label">By Decade</div>
        <div className="decade-row">
          {decades.map(([d, n]) => (
            <div
              key={d}
              className="decade-bar"
              data-label={"'" + String(Number(d)).slice(2)}
              style={{ height: (n / maxDecade * 100) + "%" }}
              title={`${d}s: ${n} discs`}
            />
          ))}
        </div>
        <div style={{ height: 18 }} />
      </div>
    </div>
  );
}
