import { useEffect, useState } from "react";
import type { CD, AppMode, Face } from "../types/cd";
import { FaceFlipper, ScanSlots, StarRating, TrackEditor } from "./atoms";

function fmtDate(s: string | undefined | null): string {
  if (!s) return "—";
  const d = new Date(s);
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

interface DetailProps {
  cd: CD;
  mode: AppMode;
  onClose: () => void;
  onSave: (cd: CD) => void;
  onDelete: (id: number) => void;
}

export function Detail({ cd, mode, onClose, onSave, onDelete }: DetailProps) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState<CD>(cd);
  const [face, setFace] = useState<Face>("front");

  useEffect(() => {
    setDraft(cd);
    setEditing(false);
    setFace("front");
  }, [cd?.id, cd]);

  const isAdmin = mode === "admin";
  const live = editing ? draft : cd;

  return (
    <div className="detail-overlay" onClick={onClose}>
      <div className="detail" onClick={e => e.stopPropagation()}>
        <button className="detail-close" onClick={onClose}>
          ✕
        </button>
        <div className="detail-grid">
          <div className="detail-jc-wrap">
            <FaceFlipper cd={live} face={face} />
            <div className="face-tabs">
              <button
                className={face === "front" ? "active" : ""}
                onClick={() => setFace("front")}
              >
                Front
              </button>
              <button
                className={face === "back" ? "active" : ""}
                onClick={() => setFace("back")}
              >
                Back
              </button>
              <button
                className={face === "disc" ? "active" : ""}
                onClick={() => setFace("disc")}
              >
                Disc
              </button>
            </div>
            {editing && (
              <div style={{ width: "100%", maxWidth: 360 }}>
                <div className="detail-section-title" style={{ marginTop: 6 }}>
                  Scans
                </div>
                <ScanSlots cd={draft} onChange={setDraft} />
              </div>
            )}
          </div>
          <div>
            <div className="detail-info-id">
              CD <span className="accent">#{String(cd.id).padStart(3, "0")}</span> · added{" "}
              {fmtDate(cd.added)}
            </div>
            {!editing ? (
              <>
                <h1 className="detail-title">{cd.title}</h1>
                <div className="detail-artist">{cd.artist}</div>
                <div className="detail-tags">
                  {cd.genre.map(g => (
                    <span key={g} className="detail-tag">
                      {g}
                    </span>
                  ))}
                </div>
                <div className="detail-meta-row">
                  <div>
                    <div className="label">Year</div>
                    <div className="value">{cd.year}</div>
                  </div>
                  <div>
                    <div className="label">Tracks</div>
                    <div className="value">{cd.tracks.length}</div>
                  </div>
                  <div>
                    <div className="label">Rating</div>
                    <StarRating value={cd.rating} readonly size={14} />
                  </div>
                </div>
                <div className="detail-section">
                  <div className="detail-section-title">Notes</div>
                  {cd.notes ? (
                    <div className="notes-text">"{cd.notes}"</div>
                  ) : (
                    <div className="notes-empty">// no notes yet</div>
                  )}
                </div>
                {isAdmin && (
                  <div className="edit-actions">
                    <button className="icon-btn" onClick={() => setEditing(true)}>
                      ✎ Edit
                    </button>
                    <button
                      className="icon-btn"
                      onClick={() => {
                        if (confirm("Remove this CD?")) onDelete(cd.id);
                      }}
                      style={{ color: "var(--aurora-red)" }}
                    >
                      ✕ Remove
                    </button>
                  </div>
                )}
              </>
            ) : (
              <>
                <div className="field-group">
                  <label>Title</label>
                  <input
                    value={draft.title}
                    onChange={e => setDraft({ ...draft, title: e.target.value })}
                  />
                </div>
                <div className="field-row">
                  <div className="field-group">
                    <label>Artist</label>
                    <input
                      value={draft.artist}
                      onChange={e => setDraft({ ...draft, artist: e.target.value })}
                    />
                  </div>
                  <div className="field-group">
                    <label>Year</label>
                    <input
                      type="number"
                      value={draft.year}
                      onChange={e => setDraft({ ...draft, year: +e.target.value })}
                    />
                  </div>
                </div>
                <div className="field-group">
                  <label>Genre (comma separated)</label>
                  <input
                    value={draft.genre.join(", ")}
                    onChange={e =>
                      setDraft({
                        ...draft,
                        genre: e.target.value
                          .split(",")
                          .map(s => s.trim())
                          .filter(Boolean),
                      })
                    }
                  />
                </div>
                <div className="field-group">
                  <label>Rating</label>
                  <StarRating
                    value={draft.rating}
                    onChange={n => setDraft({ ...draft, rating: n })}
                    size={20}
                  />
                </div>
                <div className="field-group">
                  <label>Notes</label>
                  <textarea
                    value={draft.notes}
                    onChange={e => setDraft({ ...draft, notes: e.target.value })}
                  />
                </div>
                <div className="field-group">
                  <label>Tracklist</label>
                  <TrackEditor
                    tracks={draft.tracks}
                    onChange={tracks => setDraft({ ...draft, tracks })}
                  />
                </div>
                <div className="edit-actions">
                  <button
                    className="icon-btn primary"
                    onClick={() => {
                      onSave({ ...draft, tracks: (draft.tracks || []).filter(Boolean) });
                      setEditing(false);
                    }}
                  >
                    Save changes
                  </button>
                  <button
                    className="icon-btn"
                    onClick={() => {
                      setDraft(cd);
                      setEditing(false);
                    }}
                  >
                    Cancel
                  </button>
                </div>
              </>
            )}
          </div>
        </div>

        {!editing && (
          <div className="detail-section">
            <div className="detail-section-title">Tracklist · {cd.tracks.length} tracks</div>
            <ol className="tracklist">
              {cd.tracks.map((t, i) => (
                <li key={i}>
                  <span className="num">{String(i + 1).padStart(2, "0")}</span>
                  <span>{t}</span>
                </li>
              ))}
            </ol>
          </div>
        )}
      </div>
    </div>
  );
}

interface AddNewProps {
  onClose: () => void;
  onAdd: (cd: CD) => void;
  nextId: number;
}

export function AddNew({ onClose, onAdd, nextId }: AddNewProps) {
  const [draft, setDraft] = useState<CD>({
    id: nextId,
    artist: "",
    title: "",
    year: new Date().getFullYear(),
    genre: [],
    hue: Math.floor(Math.random() * 360),
    accent: "#5E8CA8",
    added: new Date().toISOString().slice(0, 10),
    rating: 0,
    notes: "",
    tracks: [""],
    scanFront: null,
    scanBack: null,
    scanDisc: null,
  });

  const submit = () => {
    if (!draft.title.trim() || !draft.artist.trim()) {
      alert("Title and artist are required.");
      return;
    }
    onAdd({ ...draft, tracks: (draft.tracks || []).filter(Boolean) });
    onClose();
  };

  return (
    <div className="detail-overlay" onClick={onClose}>
      <div className="detail" onClick={e => e.stopPropagation()} style={{ maxWidth: 880 }}>
        <button className="detail-close" onClick={onClose}>
          ✕
        </button>
        <div className="detail-info-id">
          NEW ENTRY · #<span className="accent">{String(nextId).padStart(3, "0")}</span>
        </div>
        <h1 className="detail-title">Add a CD</h1>
        <div className="detail-artist">to your registry</div>
        <div className="detail-grid" style={{ marginTop: 24 }}>
          <div>
            <div className="detail-section-title" style={{ marginTop: 0 }}>
              Scans
            </div>
            <ScanSlots cd={draft} onChange={setDraft} />
            <div
              style={{
                fontFamily: "var(--mono)",
                fontSize: 11,
                color: "var(--ink-3)",
                marginTop: 12,
                lineHeight: 1.6,
              }}
            >
              // Drop in front cover, back cover, and disc face.
              <br />
              // No scan? A placeholder cover is generated for you.
            </div>
            <div style={{ marginTop: 18 }}>
              <div
                style={{
                  fontFamily: "var(--mono)",
                  fontSize: 10,
                  letterSpacing: 2,
                  color: "var(--ink-3)",
                  textTransform: "uppercase",
                  marginBottom: 6,
                }}
              >
                Cover hue (placeholder)
              </div>
              <input
                type="range"
                min="0"
                max="360"
                value={draft.hue}
                style={{ width: "100%" }}
                onChange={e => setDraft({ ...draft, hue: +e.target.value })}
              />
            </div>
          </div>
          <div>
            <div className="field-row">
              <div className="field-group">
                <label>Artist *</label>
                <input
                  value={draft.artist}
                  placeholder="e.g. Sigur Rós"
                  onChange={e => setDraft({ ...draft, artist: e.target.value })}
                />
              </div>
              <div className="field-group">
                <label>Year</label>
                <input
                  type="number"
                  value={draft.year}
                  onChange={e => setDraft({ ...draft, year: +e.target.value })}
                />
              </div>
            </div>
            <div className="field-group">
              <label>Title *</label>
              <input
                value={draft.title}
                placeholder="e.g. ( )"
                onChange={e => setDraft({ ...draft, title: e.target.value })}
              />
            </div>
            <div className="field-group">
              <label>Genre (comma separated)</label>
              <input
                placeholder="Post-Rock, Ambient"
                onChange={e =>
                  setDraft({
                    ...draft,
                    genre: e.target.value
                      .split(",")
                      .map(s => s.trim())
                      .filter(Boolean),
                  })
                }
              />
            </div>
            <div className="field-group">
              <label>Rating</label>
              <StarRating
                value={draft.rating}
                onChange={n => setDraft({ ...draft, rating: n })}
                size={22}
              />
            </div>
            <div className="field-group">
              <label>Notes</label>
              <textarea
                placeholder="A line or two on what this record means to you."
                onChange={e => setDraft({ ...draft, notes: e.target.value })}
              />
            </div>
            <div className="field-group">
              <label>Tracklist</label>
              <TrackEditor
                tracks={draft.tracks}
                onChange={tracks => setDraft({ ...draft, tracks })}
              />
            </div>
            <div className="edit-actions" style={{ marginTop: 24 }}>
              <button className="icon-btn primary" onClick={submit}>
                + Add to registry
              </button>
              <button className="icon-btn" onClick={onClose}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export { fmtDate };
