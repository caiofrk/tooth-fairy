import os
from fastapi import FastAPI, UploadFile, File, HTTPException
from google import genai
from pydantic import BaseModel, Field
from supabase import create_client, Client

app = FastAPI(title="Dental AI Microservices")
ai_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
db: Client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_ANON_KEY"))

class TriageResult(BaseModel):
    urgency_level: str = Field(description="Low, Medium, or High")
    preliminary_findings: list[str] = Field(description="Visible issues e.g., calculus, recession")
    image_quality_acceptable: bool = Field(description="False if image is blurry or poorly lit")
    recommendation: str

@app.post("/api/v1/triage/analyze", response_model=TriageResult)
async def analyze_dental_scan(patient_id: str, image: UploadFile = File(...)):
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type. Must be an image.")

    try:
        image_bytes = await image.read()
        
        # LLM Vision Analysis
        prompt = """
        You are an expert dental triage AI. Analyze this intraoral photograph.
        Return structured JSON. If the image is blurry, set image_quality_acceptable to false.
        DISCLAIMER: This is a preliminary screening for scheduling priority, not a clinical diagnosis.
        """
        response = ai_client.models.generate_content(
            model='gemini-3-flash-preview',
            contents=[{'mime_type': image.content_type, 'data': image_bytes}, prompt],
            config={'response_mime_type': 'application/json', 'response_schema': TriageResult}
        )
        result = response.parsed
        
        if result.image_quality_acceptable:
            # Securely log to Supabase for the dentist's dashboard
            db.table("triage_scans").insert({
                "patient_id": patient_id,
                "findings": result.model_dump(),
                "status": "pending_review"
            }).execute()
            
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
