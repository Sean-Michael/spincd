import type { Album, AlbumCreate, AlbumUpdate } from "../types/album";

const BASE_URL = "";

const json = { "Content-Type": "application/json" };

export const albumsApi = {
  // GET /albums
  getAll: async (): Promise<Album[]> => {
    const res = await fetch(`${BASE_URL}/albums/`);
    if (!res.ok) throw new Error("Failed to fetch albums");
    return res.json();
  },

  // GET /albums/{album_id}
  getById: async (id: number): Promise<Album> => {
    const res = await fetch(`${BASE_URL}/albums/${id}`);
    if (!res.ok) throw new Error(`Album ${id} not found`);
    return res.json();
  },

  // POST /albums
  create: async (album: AlbumCreate): Promise<Album> => {
    const res = await fetch(`${BASE_URL}/albums/`, {
      method: "POST",
      headers: json,
      body: JSON.stringify(album),
    });
    if (!res.ok) throw new Error("Failed to create album");
    return res.json();
  },

  // PATCH /albums/{album_id}
  update: async (id: number, patch: AlbumUpdate): Promise<Album> => {
    const res = await fetch(`${BASE_URL}/albums/${id}`, {
      method: "PATCH",
      headers: json,
      body: JSON.stringify(patch),
    });
    if (!res.ok) throw new Error(`Failed to update album ${id}`);
    return res.json();
  },

  // DELETE /albums/{album_id}
  delete: async (id: number): Promise<void> => {
    const res = await fetch(`${BASE_URL}/albums/${id}`, { method: "DELETE" });
    if (!res.ok) throw new Error(`Failed to delete album ${id}`);
  },
};
