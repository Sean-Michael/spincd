import { useEffect, useRef, useState } from "react";
import type { CD } from "../types/cd";
import { CoverArt } from "./CoverArt";

interface ViewProps {
  cds: CD[];
  onOpen: (cd: CD) => void;
}

interface CarouselProps extends ViewProps {
  index: number;
  setIndex: (n: number | ((prev: number) => number)) => void;
}

export function Carousel({ cds, index, setIndex, onOpen }: CarouselProps) {
  const total = cds.length;
  const wrap = (i: number) => total === 0 ? 0 : ((i % total) + total) % total;
  const dragStart = useRef<number | null>(null);
  const [dragX, setDragX] = useState(0);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      if (target && (target.tagName === "INPUT" || target.tagName === "TEXTAREA")) return;
      if (e.key === "ArrowLeft") setIndex((i: number) => wrap(i - 1));
      if (e.key === "ArrowRight") setIndex((i: number) => wrap(i + 1));
      if (e.key === "Enter" && cds[index]) onOpen(cds[index]);
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index, cds]);

  if (total === 0) {
    return (
      <div className="carousel" style={{ height: 300 }}>
        <div
          style={{
            textAlign: "center",
            paddingTop: 120,
            color: "var(--ink-3)",
            fontFamily: "var(--mono)",
          }}
        >
          No matches. Try a different search.
        </div>
      </div>
    );
  }

  return (
    <div
      className="carousel"
      onMouseDown={e => {
        dragStart.current = e.clientX;
      }}
      onMouseMove={e => {
        if (dragStart.current != null) setDragX(e.clientX - dragStart.current);
      }}
      onMouseUp={() => {
        if (Math.abs(dragX) > 60) setIndex((i: number) => wrap(i + (dragX < 0 ? 1 : -1)));
        dragStart.current = null;
        setDragX(0);
      }}
      onMouseLeave={() => {
        dragStart.current = null;
        setDragX(0);
      }}
    >
      <div className="carousel-track">
        {cds.map((cd, i) => {
          let offset = i - index;
          if (offset > total / 2) offset -= total;
          if (offset < -total / 2) offset += total;
          if (Math.abs(offset) > 3) return null;
          const isCenter = offset === 0;
          const x = offset * 200;
          const rot = offset * -22;
          const z = isCenter ? 200 : -Math.abs(offset) * 100;
          const scale = isCenter ? 1.05 : 0.85 - Math.abs(offset) * 0.05;
          const opacity = Math.abs(offset) > 2 ? 0 : 1 - Math.abs(offset) * 0.25;
          const blur = isCenter ? 0 : Math.abs(offset) * 1.5;
          return (
            <div
              key={cd.id}
              className={"carousel-card" + (isCenter ? " center" : "")}
              style={{
                transform: `translateX(${x}px) translateZ(${z}px) rotateY(${rot}deg) scale(${scale})`,
                opacity,
                filter: `blur(${blur}px)`,
                zIndex: 100 - Math.abs(offset),
              }}
              onClick={() => (isCenter ? onOpen(cd) : setIndex(i))}
            >
              <div className="card-cover">
                <CoverArt cd={cd} face="front" />
              </div>
              <div className="card-meta">
                <div className="meta-title">{cd.title}</div>
                <div className="meta-artist">
                  {cd.artist} · {cd.year}
                </div>
              </div>
            </div>
          );
        })}
      </div>
      <button className="carousel-nav prev" onClick={() => setIndex((i: number) => wrap(i - 1))}>
        ‹
      </button>
      <button className="carousel-nav next" onClick={() => setIndex((i: number) => wrap(i + 1))}>
        ›
      </button>
      <div className="carousel-counter">
        <b>{String(index + 1).padStart(3, "0")}</b> / {String(total).padStart(3, "0")}
      </div>
    </div>
  );
}

export function GridView({ cds, onOpen }: ViewProps) {
  return (
    <div className="grid-view">
      {cds.map(cd => (
        <div key={cd.id} className="grid-card" onClick={() => onOpen(cd)}>
          <div className="gc-cover">
            <CoverArt cd={cd} face="front" />
          </div>
          <div className="gc-meta">
            <div className="gc-title">{cd.title}</div>
            <div className="gc-artist">
              {cd.artist} · {cd.year}
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

export function ListView({ cds, onOpen }: ViewProps) {
  return (
    <div className="list-view glass">
      <div className="list-row head">
        <span></span>
        <span>Title</span>
        <span>Artist</span>
        <span>Year</span>
        <span>Genre</span>
        <span>Rating</span>
        <span></span>
      </div>
      {cds.map(cd => (
        <div key={cd.id} className="list-row" onClick={() => onOpen(cd)}>
          <div className="lr-cover">
            <CoverArt cd={cd} face="front" />
          </div>
          <div className="lr-title">{cd.title}</div>
          <div className="lr-artist">{cd.artist}</div>
          <div className="lr-year">{cd.year}</div>
          <div className="lr-genre">{cd.genre.join(" · ")}</div>
          <div className="lr-rating">
            {"★".repeat(cd.rating)}
            <span style={{ color: "var(--ink-4)", opacity: 0.4 }}>{"★".repeat(5 - cd.rating)}</span>
          </div>
          <div className="lr-arrow" style={{ color: "var(--ink-3)" }}>
            →
          </div>
        </div>
      ))}
    </div>
  );
}
