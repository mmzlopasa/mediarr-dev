"""Fetches models once, into the volume, checks them, and opens them for inference."""

import hashlib
import logging
import os
import shutil
import tempfile
import zipfile
from pathlib import Path

import httpx
import onnxruntime as ort

from . import config

logger = logging.getLogger(__name__)

# A fixed commit, so the same files arrive on every server, and a hash for each of them.
SIGLIP_REVISION = "ba1f3b0843f24bc5417d38e19c37b287d719b2f4"
SIGLIP_REPO = (
    "https://huggingface.co/onnx-community/siglip2-base-patch16-224-ONNX/resolve/" + SIGLIP_REVISION
)
SIGLIP_FILES = {
    "vision_model_fp16.onnx": (
        "onnx/vision_model_fp16.onnx",
        "a1959f7bd3993a607e48839f6d01e25b876fe76afda301b028b78eef68aabd95",
    ),
    "text_model_fp16.onnx": (
        "onnx/text_model_fp16.onnx",
        "711da56ada0a4aa11c7dd3320df741081a3cae4f0ae1b5e5c6d5b294738d0eb0",
    ),
    "tokenizer.json": (
        "tokenizer.json",
        "cb9140fae3ac5122c972d37adf83e1248471a38147ad76f8215c8872c6fd8322",
    ),
}
# Each server fetches these from their source. Check their licence before any commercial use
FACE_RELEASE = "https://github.com/deepinsight/insightface/releases/download/v0.7"
FACE_ARCHIVES = {
    "buffalo_l": "80ffe37d8a5940d59a7384c201a2a38d4741f2f3c51eef46ebb28218a7b0ca2f",
    "buffalo_s": "d85a87f503f691807cd8bb97128bdf7a0660326cd9cd02657127fa978bab8b5e",
}
FACE_FILES = {
    "buffalo_l": (
        ("det_10g.onnx", "5838f7fe053675b1c7a08b633df49e7af5495cee0493c7dcf6697200b85b5b91"),
        ("w600k_r50.onnx", "4c06341c33c2ca1f86781dab0e829f88ad5b64be9fba56e56bc9ebdefc619e43"),
    ),
    "buffalo_s": (
        ("det_500m.onnx", "5e4447f50245bbd7966bd6c0fa52938c61474a04ec7def48753668a9d8b4ea3a"),
        ("w600k_mbf.onnx", "9cc6e4a75f0e2bf0b1aed94578f144d15175f357bdc05e815e5c4a02b319eb4f"),
    ),
}
DOWNLOAD_TIMEOUT = httpx.Timeout(60.0, read=600.0)
CHUNK = 1 << 20


class ModelIntegrityError(RuntimeError):
    """A model file is not the file this version expects."""


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        while chunk := source.read(CHUNK):
            digest.update(chunk)
    return digest.hexdigest()


def _marker(path: Path) -> Path:
    return path.with_name(f"{path.name}.sha256")


def _mark(path: Path, sha256: str) -> None:
    marker = _marker(path)
    handle, tmp = tempfile.mkstemp(dir=marker.parent, suffix=".part")
    with os.fdopen(handle, "w", encoding="ascii") as out:
        out.write(sha256)
    os.replace(tmp, marker)


def _is_good(path: Path, sha256: str) -> bool:
    """True when the file is there and is the expected one. A wrong file is removed."""
    if not path.exists():
        return False
    marker = _marker(path)
    try:
        if marker.read_text(encoding="ascii").strip() == sha256:
            return True
    except OSError:
        pass
    # Checked once, for files from before the hashes, then remembered beside the file.
    if _sha256(path) == sha256:
        _mark(path, sha256)
        return True
    logger.warning("model file %s is not the expected one; fetching it again", path)
    path.unlink(missing_ok=True)
    marker.unlink(missing_ok=True)
    return False


def _download(url: str, dest: Path, sha256: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    # A broken download must not look like a model, so the name appears only when it is complete.
    handle, tmp = tempfile.mkstemp(dir=dest.parent, suffix=".part")
    try:
        digest = hashlib.sha256()
        with (
            os.fdopen(handle, "wb") as out,
            httpx.stream("GET", url, follow_redirects=True, timeout=DOWNLOAD_TIMEOUT) as response,
        ):
            response.raise_for_status()
            for chunk in response.iter_bytes():
                digest.update(chunk)
                out.write(chunk)
        if digest.hexdigest() != sha256:
            logger.error(
                "refused %s: its SHA-256 is %s, expected %s; the file was deleted",
                url,
                digest.hexdigest(),
                sha256,
            )
            raise ModelIntegrityError(f"{url} does not match its expected SHA-256")
        os.replace(tmp, dest)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


def siglip_path(name: str) -> Path:
    path = config.MODEL_DIR / "siglip2" / name
    source, sha256 = SIGLIP_FILES[name]
    if not _is_good(path, sha256):
        _download(f"{SIGLIP_REPO}/{source}", path, sha256)
        _mark(path, sha256)
    return path


def face_paths(model: str) -> tuple[Path, Path]:
    files = FACE_FILES[model]
    folder = config.MODEL_DIR / model
    paths = (folder / files[0][0], folder / files[1][0])
    # Each file is checked on its own, so a run that stopped half way is finished, not trusted.
    if all(_is_good(path, sha256) for path, (_, sha256) in zip(paths, files, strict=True)):
        return paths
    folder.mkdir(parents=True, exist_ok=True)
    archive = folder / f"{model}.zip"
    if archive.exists() and _sha256(archive) != FACE_ARCHIVES[model]:
        archive.unlink()
    if not archive.exists():
        _download(f"{FACE_RELEASE}/{model}.zip", archive, FACE_ARCHIVES[model])
    # Unpacked beside the target and moved into place only when complete and checked.
    staging = Path(tempfile.mkdtemp(dir=folder, prefix=".extract-"))
    try:
        with zipfile.ZipFile(archive) as package:
            for name, sha256 in files:
                staged = staging / name
                with package.open(_member(package, name)) as source, staged.open("wb") as out:
                    shutil.copyfileobj(source, out, CHUNK)
                if _sha256(staged) != sha256:
                    logger.error("refused %s from %s: unexpected SHA-256", name, archive)
                    raise ModelIntegrityError(f"{name} in {archive.name} is not the expected file")
        for (name, sha256), path in zip(files, paths, strict=True):
            os.replace(staging / name, path)
            _mark(path, sha256)
    finally:
        shutil.rmtree(staging, ignore_errors=True)
    archive.unlink()
    return paths


def _member(package: zipfile.ZipFile, name: str) -> str:
    for member in package.namelist():
        if member == name or member.endswith(f"/{name}"):
            return member
    raise FileNotFoundError(name)


def providers() -> list[str]:
    """What the models run on: what was asked for, as far as this runtime has it."""
    available = ort.get_available_providers()
    wanted = config.PROVIDERS.get(config.ACCEL, config.PROVIDERS["cpu"])
    return [provider for provider in wanted if provider in available]


def open_session(path: Path) -> ort.InferenceSession:
    options = ort.SessionOptions()
    if config.THREADS > 0:
        options.intra_op_num_threads = config.THREADS
    return ort.InferenceSession(str(path), options, providers=providers())
