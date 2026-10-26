from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, time, timezone

from app.db.session import get_db
from app.models.issue import Issue
from app.schemas.issue import IssueCreate, IssueResponse
from app.services.ai_service import categorize_issue

import cloudinary
import cloudinary.uploader

router = APIRouter()

# --- EXISTING: CLOUDINARY UPLOAD ENDPOINT ---
@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    """
    Streams an uploaded image directly to Cloudinary and returns the permanent URL.
    """
    try:
        upload_result = cloudinary.uploader.upload(
            file.file,
            folder="civicfix_reports"
        )
        secure_url = upload_result.get("secure_url")
        return {"image_url": secure_url}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {str(e)}")


# --- UPDATED: CREATE ISSUE ENDPOINT WITH RATE LIMITING ---
@router.post("/", response_model=IssueResponse)
async def create_new_issue(issue_in: IssueCreate, db: Session = Depends(get_db)):
    
    # ========================================================
    # 1. RATE LIMITING LOGIC (Max 5 per day per device)
    # ========================================================
    # Get the start of today (Midnight UTC)
    today_start = datetime.combine(datetime.now(timezone.utc).date(), time.min)
    
    # Count how many issues this device has reported today[cite: 9]
    daily_count = db.query(Issue).filter(
        Issue.device_id == issue_in.device_id,
        Issue.created_at >= today_start
    ).count()
    
    if daily_count >= 5:
        # 429 is the standard HTTP status code for "Too Many Requests"
        raise HTTPException(
            status_code=429, 
            detail="Thank you for being so active! You've reached your daily limit of 5 reports. Please try again tomorrow."
        )
    # ========================================================

    # 2. Ask GPT-4o-mini Vision to categorize based on both description and image[cite: 9]
    ai_category = await categorize_issue(issue_in.description, issue_in.image_url)
    
    # 3. Build the database row[cite: 9]
    db_issue = Issue(
        description=issue_in.description,
        category=ai_category,
        latitude=issue_in.latitude,
        longitude=issue_in.longitude,
        image_url=issue_in.image_url,
        device_id=issue_in.device_id,
        status="Pending" 
    )
    
    # 4. Save to Supabase[cite: 9]
    db.add(db_issue)
    db.commit()
    db.refresh(db_issue)
    
    return db_issue

# --- EXISTING: GET ALL ISSUES ---
@router.get("/", response_model=list[IssueResponse])
def get_all_public_issues(db: Session = Depends(get_db)):
    # Fetches all issues for the public map/dashboard, newest first[cite: 9]
    return db.query(Issue).order_by(Issue.created_at.desc()).all()