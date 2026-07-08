import os
from fastapi import APIRouter, UploadFile, File, HTTPException
from google import genai
from pydantic import BaseModel, Field
from openai import AsyncOpenAI
from supabase import create_client, Client
import tempfile
from fastapi import Depends
from dependencies.auth import get_current_user

voice_router = APIRouter()
ai_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
openai_client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
db: Client = create_client(os.getenv("SUPABASE_URL", ""), os.getenv("SUPABASE_ANON_KEY", ""))

class ToothFinding(BaseModel):
    tooth_number: int = Field(description="FDI World Dental Federation notation tooth number (11-48)")
    surface: str = Field(description="Face do dente afetada (e.g., oclusal, mesial, distal, vestibular, lingual) (MUST BE IN PORTUGUESE)")
    condition: str = Field(description="Condição clínica (e.g., cárie, fratura, restauração, ausente) (MUST BE IN PORTUGUESE)")

class ChartingResult(BaseModel):
    findings: list[ToothFinding] = Field(description="List of clinical findings extracted from the audio")

@voice_router.post("/chart", response_model=ChartingResult)
async def process_voice_charting(audio: UploadFile = File(...), user_id: str = Depends(get_current_user)):
    if not audio.content_type.startswith("audio/"):
        raise HTTPException(status_code=400, detail="Invalid file type. Must be audio.")

    temp_file_path = ""
    try:
        # Save uploaded audio to a temp file for OpenAI Whisper
        suffix = os.path.splitext(audio.filename)[1] if audio.filename else ".m4a"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(await audio.read())
            temp_file_path = tmp.name

        # 1. Transcribe using Whisper API
        with open(temp_file_path, "rb") as audio_file:
            transcript = await openai_client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                response_format="text"
            )

        # 2. Extract structured JSON using Gemini LLM
        prompt = f"""
        Você é um assistente odontológico especialista. Um dentista acabou de ditar as seguintes anotações clínicas em português:
        "{transcript}"
        
        Extraia o número do dente, a face (surface) e a condição (condition) para cada achado.
        ATENÇÃO: A saída ('surface' e 'condition') DEVE estar estritamente em Português do Brasil.
        Retorne APENAS um JSON válido mapeando para o esquema solicitado.
        """
        
        response = ai_client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
            config={'response_mime_type': 'application/json', 'response_schema': ChartingResult}
        )
        
        result = response.parsed
        
        # Log to Supabase securely using the authenticated user_id as staff_id
        if os.getenv("SUPABASE_URL"):
            db.table("odontogram_charts").insert({
                "patient_id": mock_patient_id,
                "staff_id": user_id,
                "chart_data": result.model_dump()
            }).execute()
        
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice charting failed: {str(e)}")
    finally:
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)
