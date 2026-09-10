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
    
    # Updated fallback to match the new token set
    if not OPENAI_API_KEY:
        return "Invalid"
        
    # The exact tokens the AI is allowed to return
    categories = ["PWD", "JSD", "SMC", "KPDCL", "JKFD", "Invalid"]
    
    # 1. The Regional System Prompt
    # system_prompt = (
    #     "You are a civic issue classifier for the Kashmir region. Given an image and optional user description, "
    #     "output the responsible department acronym based on the following mapping:\n\n"
    #     "PWD: potholes, roads, broken surfaces, collapsed pavements, road construction\n"
    #     "JSD: water leaks, water supply issues, leaking pipes, burst lines, drainage, water stagnation\n"
    #     "SMC: garbage dumps, overflowing bins, street sanitation, broken street lights, unclean public areas\n"
    #     "KPDCL: exposed wires, fallen poles, broken transformers, power outages, electrical faults\n"
    #     "JKFD: fallen trees, trees blocking roads, landslides with vegetation, blocked forest paths\n\n"
    #     "If the image does not clearly show one of the above, or contains irrelevant content such as animals, "
    #     "natural scenery or people without a visible civic issue, output: Invalid\n\n"
    #     "Only output one of the following tokens:\n"
    #     "PWD\nJSD\nSMC\nKPDCL\nJKFD\nInvalid\n\n"
    #     "No explanation. No extra text. Just one of the Tokens."
    # )
    
    # 2. Build the User Content dynamically
    user_text = "Categorize the civic issue shown in the image. "
    if description:
        user_text += f"The user also provided this note: '{description}'. If the note is irrelevant or contradicts the image, prioritize the image."
    
    user_content = [{"type": "text", "text": user_text}]
        
    if image_url:
        user_content.append({
            "type": "image_url",
            "image_url": {
                "url": image_url
            }
        })
    
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": "gpt-4o-mini",
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
            
            # Strict validation: If the AI hallucinates, default to Invalid
            if result in categories:
                return result
            return "Invalid"
            
    except Exception as e:
        print(f"AI Categorization error: {e}")
        return "Invalid"