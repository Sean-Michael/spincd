from fastapi.testclient import TestClient

# Local imports
from ..main import app

client = TestClient(app)


def test_create_album():
    """Test the creation of a new album object"""
    pass


def test_read_albums():
    """Test reading of all the albums in the collection"""
    pass


def test_read_album_by_id():
    """Test reading a single album object by id"""
    pass
