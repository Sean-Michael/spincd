export interface Album {
  id: number;
  title: string;
  artist: string;
  release_year: number | null;
  genre: string[];
  tracks: string[];
  notes: string | null;
  rating: number | null;
  hue: number | null;
  accent: string | null;
  added: string | null;
  scan_front: string | null;
  scan_back: string | null;
  scan_disc: string | null;
  label: string | null;
}

export interface AlbumCreate {
  title: string;
  artist: string;
  release_year?: number | null;
  genre?: string[];
  tracks?: string[];
  notes?: string | null;
  rating?: number | null;
  hue?: number | null;
  accent?: string | null;
  added?: string | null;
  scan_front?: string | null;
  scan_back?: string | null;
  scan_disc?: string | null;
  label?: string | null;
}

export type AlbumUpdate = Partial<AlbumCreate>;

export type ViewMode = "carousel" | "grid" | "list";
export type AppMode = "public" | "admin";
export type Face = "front" | "back" | "disc";
