"""Settings from the environment. Every value has a default, so `.env` can stay short."""

import os
from pathlib import Path

MODEL_DIR = Path(os.environ.get("MODEL_DIR") or "/models")
# cpu, cuda or openvino. The published image contains the CPU runtime.
ACCEL = os.environ.get("ML_ACCEL") or "cpu"
# buffalo_l, or buffalo_s for slower machines.
FACE_MODEL = os.environ.get("ML_FACE_MODEL") or "buffalo_l"
# Processor threads per model. Empty or 0 lets the runtime use all of them.
THREADS = int(os.environ.get("ML_THREADS") or "0")
# Minutes without a request before a model leaves memory. 0 keeps models loaded for good.
IDLE_MINUTES = float(os.environ.get("ML_IDLE_MINUTES") or "5")
# Largest picture the service accepts, in megabytes. A larger request is answered with 413.
MAX_BODY_BYTES = int(float(os.environ.get("ML_MAX_BODY_MB") or "64") * 1024 * 1024)
# When set, every endpoint except the health check asks for this bearer token.
TOKEN = os.environ.get("ML_TOKEN", "").strip()

PROVIDERS = {
    "cpu": ["CPUExecutionProvider"],
    "cuda": ["CUDAExecutionProvider", "CPUExecutionProvider"],
    "openvino": ["OpenVINOExecutionProvider", "CPUExecutionProvider"],
}
