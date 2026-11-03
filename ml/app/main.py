import logging
import threading
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import Body, FastAPI, HTTPException
from PIL import UnidentifiedImageError
from pydantic import BaseModel

from . import clip, faces, ocr

logger = logging.getLogger(__name__)


def _warm_up() -> None:
    # A person is waiting on a search, so its model is ready before the first one arrives.
    try:
        clip.load_text_model()
    except Exception:
        logger.exception("the search model could not be loaded yet")


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    threading.Thread(target=_warm_up, daemon=True).start()
    yield


app = FastAPI(title="Mediarr ML", lifespan=lifespan)

MAX_TEXT = 2000


class TextQuery(BaseModel):
    text: str


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


def _picture_error(cause: Exception) -> HTTPException:
    return HTTPException(status_code=422, detail=f"not a readable picture: {cause}")


@app.post("/clip/image")
def clip_image(data: bytes = Body(media_type="application/octet-stream")) -> dict[str, list[float]]:
    try:
        return {"embedding": clip.embed_image(data)}
    except (UnidentifiedImageError, OSError) as cause:
        raise _picture_error(cause) from cause


@app.post("/clip/text")
def clip_text(query: TextQuery) -> dict[str, list[float]]:
    if not query.text.strip() or len(query.text) > MAX_TEXT:
        raise HTTPException(status_code=422, detail="the text is empty or too long")
    return {"embedding": clip.embed_text(query.text)}


@app.post("/faces")
def find_faces(data: bytes = Body(media_type="application/octet-stream")) -> dict[str, list[dict]]:
    try:
        return {"faces": faces.detect(data)}
    except (UnidentifiedImageError, OSError) as cause:
        raise _picture_error(cause) from cause


@app.post("/ocr")
def read_text(data: bytes = Body(media_type="application/octet-stream")) -> dict[str, str]:
    try:
        return {"text": ocr.read_text(data)}
    except (UnidentifiedImageError, OSError) as cause:
        raise _picture_error(cause) from cause
