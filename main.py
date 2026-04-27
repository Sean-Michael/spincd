from fastapi import FastAPI

app = FastAPI()

@app.post("/albums")
async def create_album():
    return


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