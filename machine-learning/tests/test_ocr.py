from pathlib import Path

from app import config, ocr


def test_the_engine_is_used_by_one_request_at_a_time():
    assert ocr._engine._turn is not None


def test_engine_threads_follow_the_setting(monkeypatch):
    monkeypatch.setattr(config, "THREADS", 2)
    params = ocr.engine_params(Path("/models/ocr"))
    assert params["EngineConfig.onnxruntime.intra_op_num_threads"] == 2
    assert params["Global.model_root_dir"] == "/models/ocr"


def test_without_a_thread_setting_the_engine_chooses(monkeypatch):
    monkeypatch.setattr(config, "THREADS", 0)
    assert "EngineConfig.onnxruntime.intra_op_num_threads" not in ocr.engine_params(Path("/m"))


def test_the_parameters_are_accepted_by_the_engine(monkeypatch):
    import rapidocr
    from rapidocr.utils.parse_parameters import ParseParams

    monkeypatch.setattr(config, "THREADS", 2)
    cfg = ParseParams.load(Path(rapidocr.__file__).parent / "config.yaml")
    cfg = ParseParams.update_batch(cfg, ocr.engine_params(Path("/models/ocr")))
    assert cfg.EngineConfig.onnxruntime.intra_op_num_threads == 2
    assert cfg.Global.log_level == "warning"
