from fastapi import FastAPI

app = FastAPI(
    title="dBLog API",
    description="API para medir, registrar y documentar legalmente el ruido excesivo.",
    version="0.1.0",
)


@app.get("/health")
async def health():
    return {"status": "ok"}
