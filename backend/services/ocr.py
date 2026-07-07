import os
from fastapi import APIRouter, UploadFile, File, HTTPException
from google import genai
from pydantic import BaseModel, Field

ocr_router = APIRouter()
ai_client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

class HealthCardData(BaseModel):
    carrier_name: str = Field(description="Name of the health insurance carrier (e.g. Bradesco Saúde, Amil, SulAmérica)")
    registration_number: str = Field(description="The unique patient registration number or ID on the card")
    expiry_date: str = Field(description="Expiry date of the card in MM/YYYY or DD/MM/YYYY format")
    is_valid_card: bool = Field(description="False if the image does not appear to be a valid health insurance card")

@ocr_router.post("/validate", response_model=HealthCardData)
async def extract_health_card_data(image: UploadFile = File(...)):
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Invalid file type. Must be an image.")

    try:
        image_bytes = await image.read()
        
        # LLM Vision Analysis for OCR
        prompt = """
        You are an expert AI specializing in Brazilian health insurance cards (convênios).
        Extract the carrier name, registration number, and expiry date from this image.
        If the image is blurry, irrelevant, or not a health card, set is_valid_card to false.
        Return ONLY valid structured JSON.
        """
        
        response = ai_client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[{'mime_type': image.content_type, 'data': image_bytes}, prompt],
            config={'response_mime_type': 'application/json', 'response_schema': HealthCardData}
        )
        result = response.parsed
        
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR Extraction failed: {str(e)}")
