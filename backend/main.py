from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from services.triage import app as triage_app
from services.ocr import ocr_router
from services.voice_charting import voice_router

# Main application combining all microservices
app = FastAPI(title="TOOTH FAIRY Backend API", version="1.0.0")

# Setup CORS for Flutter web/app clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount the triage microservice
app.mount("/api/v1/triage", triage_app)

# Include the OCR microservice router
app.include_router(ocr_router, prefix="/api/v1/ocr", tags=["ocr"])

# Include the Voice Charting microservice router
app.include_router(voice_router, prefix="/api/v1/voice", tags=["voice"])

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "tooth_fairy_backend"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
