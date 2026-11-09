import numpy as np
import pytest
from fastapi.testclient import TestClient

from app import clip, config
from app.main import app

client = TestClient(app)
PROTECTED = [
    ("GET", "/status"),
    ("GET", "/docs"),
    ("GET", "/openapi.json"),
    ("POST", "/clip/text"),
    ("POST", "/clip/image"),
    ("POST", "/faces"),
    ("POST", "/ocr"),
]


@pytest.fixture
def token(monkeypatch):
    monkeypatch.setattr(config, "TOKEN", "s3cret")


class FakeSession:
    def run(self, _outputs, _inputs):
        return [np.array([[3.0, 4.0]])]


class FakeTokenizer:
    def encode(self, _text):
        return type("Encoded", (), {"ids": [1, 2]})()


@pytest.fixture
def fake_text_model(monkeypatch):
    monkeypatch.setattr(clip._text, "_loader", lambda: (FakeSession(), FakeTokenizer()))
    yield
    clip._text.release_if_idle(0)


@pytest.mark.parametrize(("method", "path"), PROTECTED)
def test_without_the_right_token_the_answer_is_401(token, method, path):
    assert client.request(method, path).status_code == 401
    for header in ("Bearer wrong", "Basic s3cret", "s3cret", "Bearer ", "Bearer šš"):
        response = client.request(method, path, headers={"Authorization": header.encode()})
        assert response.status_code == 401
    assert client.request(method, path).headers["www-authenticate"] == "Bearer"


def test_health_needs_no_token(token):
    assert client.get("/health").status_code == 200


def test_the_right_token_is_accepted(token, fake_text_model):
    headers = {"Authorization": "Bearer s3cret"}
    assert client.get("/status", headers=headers).status_code == 200
    response = client.post("/clip/text", json={"text": "more"}, headers=headers)
    assert response.status_code == 200
    assert response.json()["embedding"] == pytest.approx([0.6, 0.8])


def test_without_a_configured_token_nothing_is_asked(fake_text_model):
    assert client.get("/status").status_code == 200
    assert client.post("/clip/text", json={"text": "more"}).status_code == 200


def test_status_says_what_is_loaded(fake_text_model):
    before = client.get("/status").json()
    assert {model["name"] for model in before["models"]} == {
        "clip-image",
        "clip-text",
        "faces",
        "ocr",
    }
    assert not any(model["loaded"] for model in before["models"])
    assert before["rss_bytes"] > 0
    assert before["acceleration"] == {"requested": "cpu", "providers": ["CPUExecutionProvider"]}
    assert before["idle_minutes"] == config.IDLE_MINUTES

    client.post("/clip/text", json={"text": "more"})
    after = {model["name"]: model for model in client.get("/status").json()["models"]}
    assert after["clip-text"]["loaded"] and after["clip-text"]["in_use"] == 0
    assert not after["faces"]["loaded"]
