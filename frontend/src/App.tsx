import { useEffect, useMemo, useState } from "react";
import type { CD, ViewMode, AppMode } from "./types/cd";
import { SEED_CDS } from "./data/seed";
import { Stats } from "./components/Stats";
import { Carousel, GridView, ListView } from "./components/views";
import { Detail, AddNew, fmtDate } from "./components/Detail";

const STORAGE_KEY = "spincd-data-v2";

function loadCds(): CD[] {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) return JSON.parse(stored) as CD[];
  } catch {
    // ignore
  }
  return SEED_CDS;
}

function App() {
  const [cds, setCds] = useState<CD[]>(loadCds);
  const [view, setView] = useState<ViewMode>("carousel");
  const [query, setQuery] = useState("");
  const [genreFilter, setGenreFilter] = useState<string | null>(null);
  const [carouselIdx, setCarouselIdx] = useState(0);
  const [openId, setOpenId] = useState<number | null>(null);
  const [adding, setAdding] = useState(false);
  const [mode, setMode] = useState<AppMode>("admin");
  const [statsOpen, setStatsOpen] = useState(false);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(cds));
    } catch {
      // ignore
    }
  }, [cds]);

  const allGenres = useMemo(() => {
    const s = new Set<string>();
    cds.forEach(c => c.genre.forEach(g => s.add(g)));
    return Array.from(s).sort();
  }, [cds]);

  const filtered = useMemo(() => {
    let r = cds;
    if (query.trim()) {
      const q = query.toLowerCase();
      r = r.filter(
        c => c.title.toLowerCase().includes(q) || c.artist.toLowerCase().includes(q),
      );
    }
    if (genreFilter) r = r.filter(c => c.genre.includes(genreFilter));
    return r;
  }, [cds, query, genreFilter]);

  const [prevFilters, setPrevFilters] = useState({ query, genreFilter });
  if (prevFilters.query !== query || prevFilters.genreFilter !== genreFilter) {
    setPrevFilters({ query, genreFilter });
    setCarouselIdx(0);
  }

  const openCd = filtered.find(c => c.id === openId) || cds.find(c => c.id === openId);

  const saveCd = (updated: CD) =>
    setCds(prev => prev.map(c => (c.id === updated.id ? updated : c)));
  const addCd = (newCd: CD) => setCds(prev => [newCd, ...prev]);
  const deleteCd = (id: number) => {
    setCds(prev => prev.filter(c => c.id !== id));
    setOpenId(null);
  };

  return (
    <>
      <div className="app-bg" />
      <div className="shell">
        <div className="topbar">
          <div className="topbar-left">
            <div className="brand">
              <span className="brand-mark"></span>spinCD
            </div>
            <div className="crumb">
              <span className="dim">~/</span>
              <span className="accent">cd-registry</span>
              <span className="dim"> · {cds.length} discs</span>
              <span className="cursor"></span>
            </div>
          </div>
          <div className="topbar-right">
            <button
              className={"icon-btn" + (statsOpen ? " active" : "")}
              onClick={() => setStatsOpen(s => !s)}
            >
              ▦ Library stats {statsOpen ? "▴" : "▾"}
            </button>
            <div className="mode-toggle">
              <button
                className={mode === "public" ? "active" : ""}
                onClick={() => setMode("public")}
              >
                Public
              </button>
              <button
                className={mode === "admin" ? "active" : ""}
                onClick={() => setMode("admin")}
              >
                Admin
              </button>
            </div>
          </div>
        </div>

        <div className={"stats-panel" + (statsOpen ? " open" : "")}>
          <div className="stats-panel-inner">
            <Stats cds={cds} />
          </div>
        </div>

        <div className="toolbar">
          <div className="search">
            <span className="search-icon">⌕</span>
            <input
              placeholder="search artist or album…"
              value={query}
              onChange={e => setQuery(e.target.value)}
            />
            <span className="search-count">
              {String(filtered.length).padStart(3, "0")} /{" "}
              {String(cds.length).padStart(3, "0")}
            </span>
          </div>
          <div className="view-switch">
            <button
              className={view === "carousel" ? "active" : ""}
              onClick={() => setView("carousel")}
            >
              ◐ Carousel
            </button>
            <button
              className={view === "grid" ? "active" : ""}
              onClick={() => setView("grid")}
            >
              ▦ Grid
            </button>
            <button
              className={view === "list" ? "active" : ""}
              onClick={() => setView("list")}
            >
              ≡ List
            </button>
          </div>
        </div>

        <div className="genre-chips">
          <button
            className={"chip" + (!genreFilter ? " active" : "")}
            onClick={() => setGenreFilter(null)}
          >
            all
          </button>
          {allGenres.map(g => (
            <button
              key={g}
              className={"chip" + (genreFilter === g ? " active" : "")}
              onClick={() => setGenreFilter(genreFilter === g ? null : g)}
            >
              {g}
            </button>
          ))}
        </div>

        {view === "carousel" && (
          <Carousel
            cds={filtered}
            index={carouselIdx}
            setIndex={setCarouselIdx}
            onOpen={cd => setOpenId(cd.id)}
          />
        )}
        {view === "grid" && <GridView cds={filtered} onOpen={cd => setOpenId(cd.id)} />}
        {view === "list" && <ListView cds={filtered} onOpen={cd => setOpenId(cd.id)} />}

        <div className="footer">
          <div>
            spinCD · personal registry by{" "}
            <span className="accent">~/sean-michael</span>
          </div>
          <div>
            {cds.length} discs · last updated {fmtDate(new Date().toISOString())}
          </div>
        </div>
      </div>

      {mode === "admin" && (
        <button className="fab" onClick={() => setAdding(true)}>
          + New CD
        </button>
      )}

      {openCd && (
        <Detail
          cd={openCd}
          mode={mode}
          onClose={() => setOpenId(null)}
          onSave={saveCd}
          onDelete={deleteCd}
        />
      )}
      {adding && (
        <AddNew
          onClose={() => setAdding(false)}
          onAdd={addCd}
          nextId={Math.max(0, ...cds.map(c => c.id)) + 1}
        />
      )}
    </>
  );
}

export default App;
