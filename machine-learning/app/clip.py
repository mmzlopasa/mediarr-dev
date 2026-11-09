"""SigLIP2: pictures and text become vectors that can be compared, in many languages."""

import io

import numpy as np
from PIL import Image
from tokenizers import Tokenizer

from . import lifecycle, models

IMAGE_SIZE = 224
MAX_TOKENS = 64
PAD_TOKEN_ID = 0


def _open_vision():
    return models.open_session(models.siglip_path("vision_model_fp16.onnx"))


def _open_text():
    session = models.open_session(models.siglip_path("text_model_fp16.onnx"))
    return session, Tokenizer.from_file(str(models.siglip_path("tokenizer.json")))


_vision = lifecycle.registry.add("clip-image", _open_vision)
_text = lifecycle.registry.add("clip-text", _open_text)


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
    values = preprocess(Image.open(io.BytesIO(data)))
    with _vision.use() as session:
        result = session.run(None, {"pixel_values": values})
    return normalize(result[1][0] if len(result) > 1 else result[0][0])


def embed_text(text: str) -> list[float]:
    with _text.use() as (session, tokenizer):
        ids = tokenizer.encode(text.strip().lower()).ids
        result = session.run(None, {"input_ids": encode_ids(ids)})
    return normalize(result[1][0] if len(result) > 1 else result[0][0])
