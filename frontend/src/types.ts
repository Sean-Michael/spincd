export interface Album {
    id: number;
    title: string;
    artist: string;
    release_year: number | null;
    genre: string | null;
    label: string | null;
}

export interface AlbumCreate {
    /* title and artist are required */
    title: string;
    artist: string;
    release_year?: number | null;
    genre?: string | null;
    label?: string | null;
}

export interface AlbumUpdate {
    /* All fields are optional */
    title?: string | null;
    artist?: string | null;
    release_year?: number | null;
    genre?: string | null;
    label?: string | null;
}
