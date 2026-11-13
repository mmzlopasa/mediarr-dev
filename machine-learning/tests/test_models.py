import hashlib
import io
import zipfile
from contextlib import contextmanager

import pytest

from app import config, models


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class FakeResponse:
    def __init__(self, body: bytes) -> None:
        self.body = body

    def raise_for_status(self) -> None:
        pass

    def iter_bytes(self):
        yield self.body[: len(self.body) // 2]
        yield self.body[len(self.body) // 2 :]


@pytest.fixture
def server(monkeypatch, tmp_path):
    """Serves fixed bytes for each URL, and counts the requests."""
    monkeypatch.setattr(config, "MODEL_DIR", tmp_path)
    files: dict[str, bytes] = {}
    requests: list[str] = []

    @contextmanager
    def stream(_method, url, **_kwargs):
        requests.append(url)
        yield FakeResponse(files[url])

    monkeypatch.setattr(models.httpx, "stream", stream)
    return files, requests


def test_the_huggingface_files_come_from_a_fixed_commit():
    assert "/resolve/main" not in models.SIGLIP_REPO
    assert models.SIGLIP_REVISION in models.SIGLIP_REPO
    for _, sha256 in models.SIGLIP_FILES.values():
        assert len(sha256) == 64


def test_a_file_with_the_expected_hash_is_kept(server, monkeypatch):
    files, requests = server
    monkeypatch.setitem(models.SIGLIP_FILES, "tokenizer.json", ("tokenizer.json", sha(b"tok")))
    files[f"{models.SIGLIP_REPO}/tokenizer.json"] = b"tok"
    path = models.siglip_path("tokenizer.json")
    assert path.read_bytes() == b"tok"
    assert models.siglip_path("tokenizer.json") == path
    assert len(requests) == 1


def test_a_file_with_another_hash_is_refused_and_deleted(server, monkeypatch, caplog):
    files, _ = server
    monkeypatch.setitem(models.SIGLIP_FILES, "tokenizer.json", ("tokenizer.json", sha(b"tok")))
    files[f"{models.SIGLIP_REPO}/tokenizer.json"] = b"something else"
    with pytest.raises(models.ModelIntegrityError):
        models.siglip_path("tokenizer.json")
    folder = config.MODEL_DIR / "siglip2"
    assert list(folder.iterdir()) == []
    assert "SHA-256" in caplog.text


def test_an_old_file_that_does_not_match_is_fetched_again(server, monkeypatch):
    files, requests = server
    monkeypatch.setitem(models.SIGLIP_FILES, "tokenizer.json", ("tokenizer.json", sha(b"tok")))
    files[f"{models.SIGLIP_REPO}/tokenizer.json"] = b"tok"
    old = config.MODEL_DIR / "siglip2" / "tokenizer.json"
    old.parent.mkdir()
    old.write_bytes(b"from another revision")
    assert models.siglip_path("tokenizer.json").read_bytes() == b"tok"
    assert len(requests) == 1


def face_archive(files: dict[str, bytes]) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w") as package:
        for name, data in files.items():
            package.writestr(name, data)
    return buffer.getvalue()


@pytest.fixture
def fake_faces(server, monkeypatch):
    files, requests = server
    archive = face_archive({"det.onnx": b"detector", "rec.onnx": b"recognizer", "x.onnx": b"x"})
    monkeypatch.setitem(
        models.FACE_FILES,
        "tiny",
        (("det.onnx", sha(b"detector")), ("rec.onnx", sha(b"recognizer"))),
    )
    monkeypatch.setitem(models.FACE_ARCHIVES, "tiny", sha(archive))
    files[f"{models.FACE_RELEASE}/tiny.zip"] = archive
    return requests


def test_face_models_are_unpacked_and_the_archive_removed(fake_faces):
    detect, recognize = models.face_paths("tiny")
    assert detect.read_bytes() == b"detector"
    assert recognize.read_bytes() == b"recognizer"
    folder = config.MODEL_DIR / "tiny"
    assert sorted(path.name for path in folder.iterdir()) == [
        "det.onnx",
        "det.onnx.sha256",
        "rec.onnx",
        "rec.onnx.sha256",
    ]
    models.face_paths("tiny")
    assert len(fake_faces) == 1


def test_an_interrupted_unpacking_is_done_again(fake_faces):
    folder = config.MODEL_DIR / "tiny"
    folder.mkdir()
    # What an older version left when it stopped while writing the second file.
    (folder / "det.onnx").write_bytes(b"detector")
    (folder / "rec.onnx").write_bytes(b"recog")
    detect, recognize = models.face_paths("tiny")
    assert recognize.read_bytes() == b"recognizer"
    assert detect.read_bytes() == b"detector"
    assert len(fake_faces) == 1


def test_a_failed_unpacking_leaves_no_model(fake_faces, monkeypatch):
    monkeypatch.setitem(
        models.FACE_FILES, "tiny", (("det.onnx", sha(b"detector")), ("rec.onnx", sha(b"other")))
    )
    with pytest.raises(models.ModelIntegrityError):
        models.face_paths("tiny")
    folder = config.MODEL_DIR / "tiny"
    assert not (folder / "det.onnx").exists()
    assert not (folder / "rec.onnx").exists()
    assert not any(path.name.startswith(".extract-") for path in folder.iterdir())
