import os
import httpx
from typing import Optional

from pathlib import Path

PROMPT_PATH = Path(__file__).parent / "system_prompt.txt"

system_prompt = PROMPT_PATH.read_text(encoding="utf-8")


OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")

async def categorize_issue(description: str, image_url: Optional[str] = None) -> str:
    """Uses OpenAI Vision to categorize the civic issue for the Kashmir region."""
    
    # 1. KILL SILENT FALLBACK #1 (Missing Key)
    if not OPENAI_API_KEY:
        raise ValueError("SERVER ERROR: OPENAI_API_KEY is completely missing from Render environment variables!")
        
    categories = ["PWD", "JSD", "SMC", "KPDCL", "JKFD", "Invalid"]
    
    user_text = "Categorize the civic issue shown in the image. "
    if description:
        user_text += f"The user also provided this note: '{description}'. If the note is irrelevant or contradicts the image, prioritize the image."
    
    user_content = [{"type": "text", "text": user_text}]
        
    if image_url:
        user_content.append({"type": "image_url", "image_url": {"url": image_url}})
    
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": "gpt-4o-mini", # Make sure this is gpt-4o-mini!
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content}
        ],
        "temperature": 0.0,
        "max_tokens": 10
    }
    
    endpoint = f"{OPENAI_BASE_URL}/chat/completions"
    
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(endpoint, headers=headers, json=payload)
            response.raise_for_status()
            
            result = response.json()["choices"][0]["message"]["content"].strip()
            result = result.replace(".", "").replace("'", "")
            
            if result in categories:
                return result
                
            # 2. KILL SILENT FALLBACK #2 (Chatty AI)
            raise ValueError(f"AI gave a weird answer instead of a token: '{result}'")
            
    except Exception as e:
        raise ValueError(f"OpenAI API Crashed: {str(e)}")