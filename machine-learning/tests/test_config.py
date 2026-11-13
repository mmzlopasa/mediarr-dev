import importlib

import pytest

from app import config


@pytest.fixture
def reload_config(monkeypatch):
    def load(**values: str):
        for name, value in values.items():
            monkeypatch.setenv(name, value)
        return importlib.reload(config)

    yield load
    monkeypatch.undo()
    importlib.reload(config)


def test_empty_settings_mean_the_defaults(reload_config):
    settings = reload_config(
        ML_THREADS="",
        ML_IDLE_MINUTES="",
        ML_ACCEL="",
        ML_FACE_MODEL="",
        ML_MAX_BODY_MB="",
        MODEL_DIR="",
    )
    assert settings.THREADS == 0
    assert settings.IDLE_MINUTES == 5
    assert settings.ACCEL == "cpu"
    assert settings.FACE_MODEL == "buffalo_l"
    assert settings.MAX_BODY_BYTES == 64 * 1024 * 1024
    assert str(settings.MODEL_DIR) == "/models"


def test_settings_are_read(reload_config):
    settings = reload_config(ML_THREADS="4", ML_MAX_BODY_MB="1")
    assert settings.THREADS == 4
    assert settings.MAX_BODY_BYTES == 1024 * 1024
