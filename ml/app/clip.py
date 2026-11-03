"""SigLIP2: pictures and text become vectors that can be compared, in many languages."""

import io
import threading

import numpy as np
from PIL import Image
from tokenizers import Tokenizer

from . import models

IMAGE_SIZE = 224
MAX_TOKENS = 64
PAD_TOKEN_ID = 0

_lock = threading.Lock()
_vision = None
_text = None
_tokenizer = None


def preprocess(picture: Image.Image) -> np.ndarray:
    resized = picture.convert("RGB").resize((IMAGE_SIZE, IMAGE_SIZE), Image.Resampling.BILINEAR)
    values = np.asarray(resized, dtype=np.float32) / 255.0
    values = (values - 0.5) / 0.5
    return values.transpose(2, 0, 1)[np.newaxis, ...]


def normalize(vector: np.ndarray) -> list[float]:
    length = float(np.linalg.norm(vector))
    if length == 0:
        return [0.0] * len(vector)
    return (vector / length).astype(float).tolist()


def encode_ids(ids: list[int]) -> np.ndarray:
    ids = ids[:MAX_TOKENS]
    return np.array([ids + [PAD_TOKEN_ID] * (MAX_TOKENS - len(ids))], dtype=np.int64)


def embed_image(data: bytes) -> list[float]:
    global _vision
    with _lock:
        if _vision is None:
            _vision = models.open_session(models.siglip_path("vision_model_fp16.onnx"))
    picture = Image.open(io.BytesIO(data))
    result = _vision.run(None, {"pixel_values": preprocess(picture)})
    return normalize(result[1][0] if len(result) > 1 else result[0][0])


def load_text_model() -> None:
    global _text, _tokenizer
    with _lock:
        if _text is None:
            _text = models.open_session(models.siglip_path("text_model_fp16.onnx"))
            _tokenizer = Tokenizer.from_file(str(models.siglip_path("tokenizer.json")))


def embed_text(text: str) -> list[float]:
    load_text_model()
    ids = _tokenizer.encode(text.strip().lower()).ids
    result = _text.run(None, {"input_ids": encode_ids(ids)})
    return normalize(result[1][0] if len(result) > 1 else result[0][0])
