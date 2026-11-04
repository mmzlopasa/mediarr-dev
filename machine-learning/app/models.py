"""Fetches models once, into the volume, and opens them for inference."""

import io
import os
import tempfile
import zipfile
from pathlib import Path

import httpx
import onnxruntime as ort

from . import config

SIGLIP_REPO = "https://huggingface.co/onnx-community/siglip2-base-patch16-224-ONNX/resolve/main"
SIGLIP_FILES = {
    "vision_model_fp16.onnx": "onnx/vision_model_fp16.onnx",
    "text_model_fp16.onnx": "onnx/text_model_fp16.onnx",
    "tokenizer.json": "tokenizer.json",
}
# Each server fetches these from their source. Check their licence before any commercial use
FACE_RELEASE = "https://github.com/deepinsight/insightface/releases/download/v0.7"
FACE_FILES = {
    "buffalo_l": ("det_10g.onnx", "w600k_r50.onnx"),
    "buffalo_s": ("det_500m.onnx", "w600k_mbf.onnx"),
}
DOWNLOAD_TIMEOUT = httpx.Timeout(60.0, read=600.0)


def _download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    # A broken download must not look like a model, so the name appears only when it is complete.
    handle, tmp = tempfile.mkstemp(dir=dest.parent, suffix=".part")
    try:
        with (
            os.fdopen(handle, "wb") as out,
            httpx.stream("GET", url, follow_redirects=True, timeout=DOWNLOAD_TIMEOUT) as response,
        ):
            response.raise_for_status()
            for chunk in response.iter_bytes():
                out.write(chunk)
        os.replace(tmp, dest)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


def siglip_path(name: str) -> Path:
    path = config.MODEL_DIR / "siglip2" / name
    if not path.exists():
        _download(f"{SIGLIP_REPO}/{SIGLIP_FILES[name]}", path)
    return path


def face_paths(model: str) -> tuple[Path, Path]:
    names = FACE_FILES[model]
    folder = config.MODEL_DIR / model
    paths = (folder / names[0], folder / names[1])
    if all(path.exists() for path in paths):
        return paths
    archive = folder / f"{model}.zip"
    if not archive.exists():
        _download(f"{FACE_RELEASE}/{model}.zip", archive)
    with zipfile.ZipFile(io.BytesIO(archive.read_bytes())) as package:
        for name in names:
            with package.open(_member(package, name)) as source:
                (folder / name).write_bytes(source.read())
    archive.unlink()
    return paths


def _member(package: zipfile.ZipFile, name: str) -> str:
    for member in package.namelist():
        if member == name or member.endswith(f"/{name}"):
            return member
    raise FileNotFoundError(name)


def open_session(path: Path) -> ort.InferenceSession:
    options = ort.SessionOptions()
    if config.THREADS > 0:
        options.intra_op_num_threads = config.THREADS
    providers = [
        provider
        for provider in config.PROVIDERS.get(config.ACCEL, config.PROVIDERS["cpu"])
        if provider in ort.get_available_providers()
    ]
    return ort.InferenceSession(str(path), options, providers=providers)
