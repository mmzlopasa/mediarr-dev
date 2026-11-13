import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import Body, FastAPI, HTTPException
from pydantic import BaseModel

from . import clip, config, faces, lifecycle, models, ocr
from .auth import TokenMiddleware
from .limits import BodyLimitMiddleware
from .picture import UnreadablePicture


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    lifecycle.registry.start()
    yield
    lifecycle.registry.stop()


app = FastAPI(title="Mediarr ML", lifespan=lifespan)
app.add_middleware(BodyLimitMiddleware)
# Added last, so it runs first: without the token, not even the size of a body is looked at.
app.add_middleware(TokenMiddleware)

MAX_TEXT = 2000


class TextQuery(BaseModel):
    text: str


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


def _rss_bytes() -> int | None:
    try:
        with open("/proc/self/statm", encoding="ascii") as statm:
            return int(statm.read().split()[1]) * os.sysconf("SC_PAGE_SIZE")
    except OSError:
        return None


@app.get("/status")
def status() -> dict:
    return {
        "models": [slot.status() for slot in lifecycle.registry.slots],
        "rss_bytes": _rss_bytes(),
        "acceleration": {"requested": config.ACCEL, "providers": models.providers()},
        "idle_minutes": config.IDLE_MINUTES,
    }


# The server cancels the job on 422 instead of trying again.
def _picture_error(cause: Exception) -> HTTPException:
    return HTTPException(status_code=422, detail=f"not a readable picture: {cause}")


@app.post("/clip/image")
def clip_image(data: bytes = Body(media_type="application/octet-stream")) -> dict[str, list[float]]:
    try:
        return {"embedding": clip.embed_image(data)}
    except UnreadablePicture as cause:
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
    except UnreadablePicture as cause:
        raise _picture_error(cause) from cause


@app.post("/ocr")
def read_text(data: bytes = Body(media_type="application/octet-stream")) -> dict[str, str]:
    try:
        return {"text": ocr.read_text(data)}
    except UnreadablePicture as cause:
        raise _picture_error(cause) from cause
