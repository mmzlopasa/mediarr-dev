"""Decodes the picture a request carries, and tells an unreadable picture from any other fault."""

import io

from PIL import Image, UnidentifiedImageError

# What Pillow raises for a file it cannot decode, or one that would decode to an enormous picture.
_DECODE_ERRORS = (
    UnidentifiedImageError,
    Image.DecompressionBombError,
    OSError,
    ValueError,
    SyntaxError,
)


class UnreadablePicture(Exception):
    """Trying again will not help: the server cancels the job when it is told so."""


def open_rgb(data: bytes) -> Image.Image:
    try:
        with Image.open(io.BytesIO(data)) as picture:
            return picture.convert("RGB")
    except _DECODE_ERRORS as cause:
        raise UnreadablePicture(str(cause) or type(cause).__name__) from cause
