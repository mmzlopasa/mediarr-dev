"""Settings from the environment. Every value has a default, so `.env` can stay short."""

import os
from pathlib import Path

MODEL_DIR = Path(os.environ.get("MODEL_DIR", "/models"))
# cpu, cuda or openvino. The published image contains the CPU runtime.
ACCEL = os.environ.get("ML_ACCEL", "cpu")
# buffalo_l, or buffalo_s for slower machines.
FACE_MODEL = os.environ.get("ML_FACE_MODEL", "buffalo_l")
THREADS = int(os.environ.get("ML_THREADS", "0"))

PROVIDERS = {
    "cpu": ["CPUExecutionProvider"],
    "cuda": ["CUDAExecutionProvider", "CPUExecutionProvider"],
    "openvino": ["OpenVINOExecutionProvider", "CPUExecutionProvider"],
}
