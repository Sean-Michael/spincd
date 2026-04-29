import type { Album, AlbumCreate, AlbumUpdate } from "../types/album";

const BASE_URL = 'http://localhost:8000';

// Define a client for the albums api router
export const albumsApi = {
    // GET /albums
    getAll: async (): Promise<Album[]> => {
        const res = await fetch(`${BASE_URL}/albums/`);
        if (!res.ok) throw new Error('Failed to fetch albums');
        return res.json();
    },

    // GET /albums/{album_id}
    getByalbum_id: async (album_id: number): Promise<Album> => {
        const res = await fetch(`${BASE_URL}/albums/${album_id}`);
        if (!res.ok) throw new Error(`Album ${album_id} not found`);
        return res.json();
    },

    // POST /albums
    create: async (album: AlbumCreate): Promise<Album> => {
        const res = await fetch(`${BASE_URL}/albums/`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(album),
        });
        if (!res.ok) throw new Error('Failed to create album');
        return res.json();
    },

    // PATCH /albums/{album_id}
    update: async (album: AlbumUpdate, album_id: number): Promise<Album> => {
        const res = await fetch(`${BASE_URL}/albums/${album_id}`, {
            method: 'PATCH',
            headers: { 'Content=Type': 'application/json' },
            body: JSON.stringify(album),
        });
        if (!res.ok) throw new Error(`Failed to update album ${album_id}`)
        return res.json();
    },

    // DELETE /albums/{album_id}
    delete: async (album_id: number): Promise<void> => {
        const res = await fetch(`${BASE_URL}/albums/${album_id}`);
        if (!res.ok) throw new Error(`Failed to delete album ${album_id}`)
    }
};

