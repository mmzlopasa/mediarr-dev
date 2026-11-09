"""Reads text on pictures, so that it can be searched."""

import io

import numpy as np
from PIL import Image

from . import config, lifecycle

MIN_SCORE = 0.5


def _open_engine():
    # Imported here because it brings OpenCV, which an empty service has no use for.
    from rapidocr import RapidOCR

    folder = config.MODEL_DIR / "ocr"
    folder.mkdir(parents=True, exist_ok=True)
    return RapidOCR(params={"Rec.lang_type": "hr", "Global.model_root_dir": str(folder)})


_engine = lifecycle.registry.add("ocr", _open_engine)


def read_text(data: bytes) -> str:
    picture = np.asarray(Image.open(io.BytesIO(data)).convert("RGB"))[:, :, ::-1]
    with _engine.use() as engine:
        result = engine(picture)
    if result.txts is None:
        return ""
    return " ".join(
        text for text, score in zip(result.txts, result.scores, strict=True) if score >= MIN_SCORE
    )
