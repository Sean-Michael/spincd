import { useRef } from "react";
import type { Album, Face } from "../types/album";
import { CoverArt, Disc } from "./CoverArt";

interface StarRatingProps {
  value: number;
  onChange?: (n: number) => void;
  readonly?: boolean;
  size?: number;
}

export function StarRating({ value, onChange, readonly = false, size = 14 }: StarRatingProps) {
  return (
    <span className="detail-rating" style={{ fontSize: size }}>
      {[1, 2, 3, 4, 5].map(n => (
        <span
          key={n}
          className={"star " + (n <= value ? "" : "empty")}
          style={{ cursor: readonly ? "default" : "pointer", fontSize: size }}
          onClick={() => !readonly && onChange && onChange(n)}
        >
          ★
        </span>
      ))}
    </span>
  );
}

function fileToDataURL(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const r = new FileReader();
    r.onload = () => resolve(r.result as string);
    r.onerror = reject;
    r.readAsDataURL(file);
  });
}

interface TrackEditorProps {
  tracks: string[];
  onChange: (tracks: string[]) => void;
}

export function TrackEditor({ tracks, onChange }: TrackEditorProps) {
  const list = tracks && tracks.length ? tracks : [""];
  const inputsRef = useRef<Record<number, HTMLInputElement | null>>({});

  const update = (i: number, val: string) => {
    const next = [...list];
    next[i] = val;
    onChange(next);
  };
  const insertAfter = (i: number) => {
    const next = [...list];
    next.splice(i + 1, 0, "");
    onChange(next);
    setTimeout(() => {
      const el = inputsRef.current[i + 1];
      if (el) el.focus();
    }, 10);
  };
  const removeAt = (i: number) => {
    if (list.length <= 1) {
      onChange([""]);
      return;
    }
    const next = list.filter((_, idx) => idx !== i);
    onChange(next);
    setTimeout(() => {
      const el = inputsRef.current[Math.max(0, i - 1)];
      if (el) el.focus();
    }, 10);
  };

  return (
    <div className="track-editor">
      {list.map((t, i) => (
        <div key={i} className="track-row">
          <span className="track-num">{String(i + 1).padStart(2, "0")}</span>
          <input
            ref={el => {
              inputsRef.current[i] = el;
            }}
            value={t}
            placeholder={i === 0 ? "Track title — press Enter to add another" : "Track title"}
            onChange={e => update(i, e.target.value)}
            onKeyDown={e => {
              if (e.key === "Enter") {
                e.preventDefault();
                insertAfter(i);
              } else if (e.key === "Backspace" && t === "" && list.length > 1) {
                e.preventDefault();
                removeAt(i);
              } else if (e.key === "ArrowDown") {
                const el = inputsRef.current[i + 1];
                if (el) {
                  e.preventDefault();
                  el.focus();
                }
              } else if (e.key === "ArrowUp") {
                const el = inputsRef.current[i - 1];
                if (el) {
                  e.preventDefault();
                  el.focus();
                }
              }
            }}
          />
          <button type="button" className="track-remove" title="Remove" onClick={() => removeAt(i)}>
            −
          </button>
        </div>
      ))}
      <button type="button" className="track-add" onClick={() => insertAfter(list.length - 1)}>
        + Add track
      </button>
      <div className="track-hint">enter ↵ adds · backspace on empty removes · ↑↓ to navigate</div>
    </div>
  );
}

interface ScanSlotsProps {
  cd: Album;
  onChange: (cd: Album) => void;
}

type ScanKey = "scan_front" | "scan_back" | "scan_disc";

export function ScanSlots({ cd, onChange }: ScanSlotsProps) {
  const onPick = async (key: ScanKey, file: File | undefined) => {
    if (!file) return;
    const url = await fileToDataURL(file);
    onChange({ ...cd, [key]: url });
  };

  const slot = (key: ScanKey, label: string) => {
    const value = cd[key];
    return (
      <label className={"scan-slot " + (value ? "has-img" : "")}>
        {value && (
          <button
            type="button"
            className="scan-clear"
            onClick={e => {
              e.preventDefault();
              onChange({ ...cd, [key]: null });
            }}
          >
            ✕
          </button>
        )}
        {value ? (
          <img src={value} alt={label} />
        ) : (
          <div className="scan-empty">
            ＋ Upload
            <br />
            {label}
          </div>
        )}
        <div className="scan-label">{label}</div>
        <input
          type="file"
          accept="image/*"
          style={{ display: "none" }}
          onChange={e => onPick(key, e.target.files?.[0])}
        />
      </label>
    );
  };

  return (
    <div className="scan-uploader">
      {slot("scan_front", "Front")}
      {slot("scan_back", "Back")}
      {slot("scan_disc", "Disc")}
    </div>
  );
}

interface FaceFlipperProps {
  cd: Album;
  face: Face;
}

export function FaceFlipper({ cd, face }: FaceFlipperProps) {
  return (
    <div className={"face-flipper show-" + face}>
      <div className="face face-front">
        <CoverArt cd={cd} face="front" />
      </div>
      <div className="face face-back">
        <CoverArt cd={cd} face="back" />
      </div>
      <div className="face face-disc">
        {cd.scan_disc ? (
          <img
            src={cd.scan_disc}
            alt="disc"
            style={{ width: "100%", height: "100%", objectFit: "contain", borderRadius: "50%" }}
          />
        ) : (
          <Disc cd={cd} size={340} />
        )}
      </div>
    </div>
  );
}
