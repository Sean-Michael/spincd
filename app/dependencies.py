from typing import Annotated
from fastapi import Depends
from sqlmodel import Session

# Local modules
from .config import Settings, get_settings
from .database import get_session

# Type aliases for dependency injection
SettingsDep = Annotated[Settings, Depends(get_settings)]

SessionDep = Annotated[Session, Depends(get_session)]
