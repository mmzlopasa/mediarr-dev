# The packages are installed in a first stage, so uv and its cache stay out of the image.
FROM python:3.12-slim-trixie AS build

RUN pip install --no-cache-dir uv==0.13.6

WORKDIR /app
COPY pyproject.toml uv.lock ./
# Compiled here, because the running service cannot write beside its code.
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never
RUN uv sync --frozen --no-dev --no-cache

FROM python:3.12-slim-trixie

WORKDIR /app
COPY --from=build /app/.venv /app/.venv
COPY app ./app
RUN /app/.venv/bin/python -m compileall -q app && mkdir /models && chown 10001 /models
ENV MODEL_DIR=/models HOME=/tmp PYTHONUNBUFFERED=1

USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD ["/app/.venv/bin/python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"]

CMD ["/app/.venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-server-header"]
