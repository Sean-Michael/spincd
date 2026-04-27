from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class AlbumForm(BaseModel):
    title: str
    artist: str
    release_year: int | None = None
    genre: str | None = None
    label: str | None = None


@app.post("/albums")
async def create_album(album: AlbumForm):
    return album


@app.get("/albums")
async def get_albums():
    return


@app.get("/albums/{album_id}")
async def get_album_by_id(album_id):
    return


@app.put("/albums/{album_id}")
async def replace_album_by_id(album_id):
    return


@app.patch("/albums/{album_id}")
async def update_album_by_id(album_id):
    return


@app.delete("/albums/{album_id}")
async def delete_album_by_id(album_id):
    return