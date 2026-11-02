from fastapi import FastAPI

app = FastAPI(title="Mediarr ML")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
