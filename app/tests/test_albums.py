import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
from sqlmodel.pool import StaticPool

# Local imports
from ..main import app
from ..database import get_session
from ..models.albums import Album


@pytest.fixture(name="session")
def session_fixture():
    """Spin up a SQLite DB in-memory for testing"""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


@pytest.fixture(name="client")
def client_fixture(session: Session):
    """Temporarily override the FastAPI dependency get_session()"""

    def get_session_override():
        return session

    app.dependency_overrides[get_session] = get_session_override
    client = TestClient(app)
    yield client
    app.dependency_overrides.clear()


def test_create_album(client: TestClient):
    """Test the creation of a new album object"""
    response = client.post(
        "/albums/",
        json={
            "title": "Kid A",
            "artist": "Radiohead",
            "release_year": 2000,
            "genre": ["Art Rock", "Electronic"],
            "tracks": ["Everything in Its Right Place", "Kid A"],
            "notes": "Still feels like the future.",
            "rating": 5,
            "hue": 220,
            "accent": "#5E81AC",
            "added": "2023-11-20",
            "label": "Parlophone",
        },
    )
    data = response.json()
    assert response.status_code == 200
    assert data["title"] == "Kid A"
    assert data["artist"] == "Radiohead"
    assert data["release_year"] == 2000
    assert data["genre"] == ["Art Rock", "Electronic"]
    assert data["tracks"] == ["Everything in Its Right Place", "Kid A"]
    assert data["notes"] == "Still feels like the future."
    assert data["rating"] == 5
    assert data["hue"] == 220
    assert data["accent"] == "#5E81AC"
    assert data["added"] == "2023-11-20"
    assert data["label"] == "Parlophone"
    assert data["scan_front"] is None
    assert data["scan_back"] is None
    assert data["scan_disc"] is None
    assert data["id"] is not None


def test_create_album_missing_required_field(client: TestClient):
    """Missing required fields should fail validation"""
    response = client.post("/albums/", json={"title": "No Artist"})
    assert response.status_code == 422


def test_read_albums(session: Session, client: TestClient):
    """Test reading of all the albums in the collection"""
    album_1 = Album(title="In Rainbows", artist="Radiohead", release_year=2007)
    album_2 = Album(title="Blonde", artist="Frank Ocean", release_year=2016)
    session.add(album_1)
    session.add(album_2)
    session.commit()

    response = client.get("/albums/")
    data = response.json()

    assert response.status_code == 200
    assert len(data) == 2
    assert data[0]["title"] == album_1.title
    assert data[0]["artist"] == album_1.artist
    assert data[0]["id"] == album_1.id
    assert data[1]["title"] == album_2.title
    assert data[1]["artist"] == album_2.artist
    assert data[1]["id"] == album_2.id


def test_read_albums_empty(client: TestClient):
    """Reading from an empty collection should return an empty list"""
    response = client.get("/albums/")
    assert response.status_code == 200
    assert response.json() == []


def test_read_album_by_id(session: Session, client: TestClient):
    """Test reading a single album object by id"""
    album = Album(title="Grace", artist="Jeff Buckley", release_year=1994)
    session.add(album)
    session.commit()

    response = client.get(f"/albums/{album.id}")
    data = response.json()

    assert response.status_code == 200
    assert data["title"] == album.title
    assert data["artist"] == album.artist
    assert data["release_year"] == album.release_year
    assert data["id"] == album.id


def test_read_album_by_id_not_found(client: TestClient):
    """Reading a missing album should 404"""
    response = client.get("/albums/999")
    assert response.status_code == 404
    assert response.json() == {"detail": "Album not found"}


def test_replace_album_by_id(session: Session, client: TestClient):
    """Test replacing a single album by id idempotently"""

    # Create an album in the DB with the minimum required fields
    album = Album(title="Bleach", artist="Nirvana")
    session.add(album)
    session.commit()

    response = client.put(
        f"/albums/{album.id}",
        json={
            "title": "Bleach",
            "artist": "Nirvana",
            "release_year": 1989,
            "genre": ["Grunge"],
            "label": "Sub Pop",
        },
    )
    data = response.json()
    assert response.status_code == 200
    assert data["title"] == "Bleach"
    assert data["artist"] == "Nirvana"
    assert data["release_year"] == 1989
    assert data["genre"] == ["Grunge"]
    assert data["label"] == "Sub Pop"


def test_replace_album_by_id_not_found(client: TestClient):
    """Attempting to patch an album that doesn't exist should return a 404"""
    response = client.put(
        "/albums/69",
        json={
            "title": "Bleach",
            "artist": "Nirvana",
            "release_year": 1989,
            "genre": "Grunge",
            "label": "Sub Pop",
        },
    )
    data = response.json()
    assert response.status_code == 404
    assert data["detail"] == "Album not found"


def test_update_album_by_id(session: Session, client: TestClient):
    """Patching an album should update only the fields provided"""
    album = Album(
        title="Sgt. Pepper's",
        artist="The Beatles",
        release_year=1967,
        genre="Rock",
        label="Parlophone",
    )
    session.add(album)
    session.commit()

    response = client.patch(
        f"/albums/{album.id}",
        json={"genre": "Psychedelic Rock"},
    )
    data = response.json()
    assert response.status_code == 200
    assert data["genre"] == "Psychedelic Rock"
    # Untouched fields should be unchanged
    assert data["title"] == "Sgt. Pepper's"
    assert data["artist"] == "The Beatles"
    assert data["release_year"] == 1967
    assert data["label"] == "Parlophone"
    assert data["id"] == album.id


def test_update_album_by_id_not_found(client: TestClient):
    """Patching an album that doesn't exist should return a 404"""
    response = client.patch("/albums/69", json={"genre": "Jazz"})
    assert response.status_code == 404
    assert response.json() == {"detail": "Album not found"}


def test_delete_album_by_id(session: Session, client: TestClient):
    """Deleting an album should remove it from the DB"""
    album = Album(title="OK Computer", artist="Radiohead")
    session.add(album)
    session.commit()
    album_id = album.id

    response = client.delete(f"/albums/{album_id}")
    assert response.status_code == 200
    assert response.json() == {"ok": True}

    # A subsequent GET should now 404
    follow_up = client.get(f"/albums/{album_id}")
    assert follow_up.status_code == 404


def test_delete_album_by_id_not_found(client: TestClient):
    """Deleting an album that doesn't exist should return a 404"""
    response = client.delete("/albums/69")
    assert response.status_code == 404
    assert response.json() == {"detail": "Album not found"}
