"""Reads text on pictures, so that it can be searched."""

import io
import threading

import numpy as np
from PIL import Image
from rapidocr import RapidOCR

from . import config

MIN_SCORE = 0.5

_lock = threading.Lock()
_engine = None


def read_text(data: bytes) -> str:
    global _engine
    with _lock:
        if _engine is None:
            folder = config.MODEL_DIR / "ocr"
            folder.mkdir(parents=True, exist_ok=True)
            _engine = RapidOCR(params={"Rec.lang_type": "hr", "Global.model_root_dir": str(folder)})
    picture = np.asarray(Image.open(io.BytesIO(data)).convert("RGB"))[:, :, ::-1]
    result = _engine(picture)
    if result.txts is None:
        return ""
    return " ".join(
        text for text, score in zip(result.txts, result.scores, strict=True) if score >= MIN_SCORE
    )
