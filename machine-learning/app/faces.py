"""Finds faces and turns each into a vector. Nothing here leaves the server."""

import numpy as np
from PIL import Image

from . import config, lifecycle, models
from . import picture as pictures

DETECT_SIZE = 640
SCORE_THRESHOLD = 0.5
NMS_THRESHOLD = 0.4
STRIDES = (8, 16, 32)
ANCHORS_PER_CELL = 2
FACE_SIZE = 112
# Where the eyes, nose and mouth corners belong in a 112 px face.
FACE_TEMPLATE = np.array(
    [
        [38.2946, 51.6963],
        [73.5318, 51.5014],
        [56.0252, 71.7366],
        [41.5493, 92.3655],
        [70.7299, 92.2041],
    ],
    dtype=np.float64,
)


def _open_sessions():
    detect, recognize = models.face_paths(config.FACE_MODEL)
    return models.open_session(detect), models.open_session(recognize)


_sessions = lifecycle.registry.add("faces", _open_sessions)


def letterbox(picture: Image.Image) -> tuple[np.ndarray, float]:
    """Scales to fit without distortion, and returns the scale for mapping results back."""
    scale = min(DETECT_SIZE / picture.width, DETECT_SIZE / picture.height)
    size = (max(1, round(picture.width * scale)), max(1, round(picture.height * scale)))
    canvas = Image.new("RGB", (DETECT_SIZE, DETECT_SIZE))
    canvas.paste(picture.convert("RGB").resize(size, Image.Resampling.BILINEAR), (0, 0))
    rgb = np.asarray(canvas, dtype=np.float32)
    values = (rgb[:, :, ::-1] - 127.5) / 128.0
    return values.transpose(2, 0, 1)[np.newaxis, ...], scale


def anchor_centers(stride: int) -> np.ndarray:
    cells = DETECT_SIZE // stride
    xs, ys = np.meshgrid(np.arange(cells), np.arange(cells))
    points = np.stack([xs, ys], axis=-1).reshape(-1, 2).astype(np.float32) * stride
    return np.repeat(points, ANCHORS_PER_CELL, axis=0)


def decode(outputs: list[np.ndarray]) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Turns the network's output into scores, boxes and five landmarks per face."""
    count = len(STRIDES)
    all_scores, all_boxes, all_points = [], [], []
    for index, stride in enumerate(STRIDES):
        scores = outputs[index].reshape(-1)
        keep = np.where(scores >= SCORE_THRESHOLD)[0]
        if len(keep) == 0:
            continue
        centers = anchor_centers(stride)[keep]
        distances = outputs[index + count].reshape(-1, 4)[keep] * stride
        boxes = np.concatenate([centers - distances[:, :2], centers + distances[:, 2:]], axis=1)
        offsets = outputs[index + count * 2].reshape(-1, 10)[keep] * stride
        points = np.repeat(centers[:, np.newaxis, :], 5, axis=1) + offsets.reshape(-1, 5, 2)
        all_scores.append(scores[keep])
        all_boxes.append(boxes)
        all_points.append(points)
    if not all_scores:
        return np.empty(0), np.empty((0, 4)), np.empty((0, 5, 2))
    return np.concatenate(all_scores), np.concatenate(all_boxes), np.concatenate(all_points)


def nms(scores: np.ndarray, boxes: np.ndarray) -> list[int]:
    """Keeps the best box where several boxes found the same face."""
    order = scores.argsort()[::-1]
    kept: list[int] = []
    while len(order) > 0:
        best = int(order[0])
        kept.append(best)
        rest = order[1:]
        x1 = np.maximum(boxes[best, 0], boxes[rest, 0])
        y1 = np.maximum(boxes[best, 1], boxes[rest, 1])
        x2 = np.minimum(boxes[best, 2], boxes[rest, 2])
        y2 = np.minimum(boxes[best, 3], boxes[rest, 3])
        overlap = np.clip(x2 - x1, 0, None) * np.clip(y2 - y1, 0, None)
        area_best = (boxes[best, 2] - boxes[best, 0]) * (boxes[best, 3] - boxes[best, 1])
        area_rest = (boxes[rest, 2] - boxes[rest, 0]) * (boxes[rest, 3] - boxes[rest, 1])
        union = area_best + area_rest - overlap
        order = rest[overlap / np.maximum(union, 1e-6) <= NMS_THRESHOLD]
    return kept


def similarity_transform(source: np.ndarray, target: np.ndarray) -> np.ndarray:
    """The rotation, scale and shift that best moves source points onto target points."""
    source_mean, target_mean = source.mean(axis=0), target.mean(axis=0)
    source_centered, target_centered = source - source_mean, target - target_mean
    covariance = target_centered.T @ source_centered / len(source)
    left, singular, right = np.linalg.svd(covariance)
    signs = np.ones(2)
    if np.linalg.det(left) * np.linalg.det(right) < 0:
        signs[-1] = -1
    rotation = left @ np.diag(signs) @ right
    variance = source_centered.var(axis=0).sum()
    scale = (singular * signs).sum() / variance if variance > 0 else 1.0
    matrix = np.zeros((2, 3))
    matrix[:, :2] = scale * rotation
    matrix[:, 2] = target_mean - scale * rotation @ source_mean
    return matrix


def align(picture: Image.Image, points: np.ndarray) -> Image.Image:
    forward = similarity_transform(points, FACE_TEMPLATE)
    full = np.vstack([forward, [0, 0, 1]])
    inverse = np.linalg.inv(full)[:2].reshape(-1).tolist()
    return picture.transform(
        (FACE_SIZE, FACE_SIZE), Image.Transform.AFFINE, inverse, Image.Resampling.BILINEAR
    )


def detect(data: bytes) -> list[dict]:
    picture = pictures.open_rgb(data)
    values, scale = letterbox(picture)
    with _sessions.use() as (detector, recognizer):
        name = detector.get_inputs()[0].name
        scores, boxes, points = decode(detector.run(None, {name: values}))
        faces = []
        input_name = recognizer.get_inputs()[0].name
        for index in nms(scores, boxes) if len(scores) else []:
            box = boxes[index] / scale
            marks = points[index] / scale
            face = np.asarray(align(picture, marks), dtype=np.float32)
            tensor = ((face - 127.5) / 127.5).transpose(2, 0, 1)[np.newaxis, ...]
            vector = recognizer.run(None, {input_name: tensor})[0][0]
            vector = vector / max(float(np.linalg.norm(vector)), 1e-9)
            faces.append(
                {
                    "box": [float(value) for value in box],
                    "score": float(scores[index]),
                    "embedding": vector.astype(float).tolist(),
                }
            )
    return faces
