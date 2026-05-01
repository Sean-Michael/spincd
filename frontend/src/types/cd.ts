export interface CD {
  id: number;
  artist: string;
  title: string;
  year: number;
  genre: string[];
  hue: number;
  accent: string;
  added: string;
  rating: number;
  notes: string;
  tracks: string[];
  scanFront: string | null;
  scanBack: string | null;
  scanDisc: string | null;
}

export type ViewMode = "carousel" | "grid" | "list";
export type AppMode = "public" | "admin";
export type Face = "front" | "back" | "disc";
