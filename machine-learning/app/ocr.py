"""Reads text on pictures, so that it can be searched."""

import numpy as np

from . import config, lifecycle
from . import picture as pictures

MIN_SCORE = 0.5


def _open_engine():
    # Imported here because it brings OpenCV, which an empty service has no use for.
    from rapidocr import RapidOCR

    folder = config.MODEL_DIR / "ocr"
    folder.mkdir(parents=True, exist_ok=True)
    return RapidOCR(params=engine_params(folder))


def engine_params(folder) -> dict:
    params = {
        "Rec.lang_type": "hr",
        "Global.model_root_dir": str(folder),
        "Global.log_level": "warning",
    }
    if config.THREADS > 0:
        params["EngineConfig.onnxruntime.intra_op_num_threads"] = config.THREADS
    return params


# The engine sets up each picture's resizing on itself, so two pictures at once would mix them up.
_engine = lifecycle.registry.add("ocr", _open_engine, exclusive=True)


def read_text(data: bytes) -> str:
    picture = np.asarray(pictures.open_rgb(data))[:, :, ::-1]
    with _engine.use() as engine:
        result = engine(picture)
    if result.txts is None:
        return ""
    return " ".join(
        text for text, score in zip(result.txts, result.scores, strict=True) if score >= MIN_SCORE
    )
