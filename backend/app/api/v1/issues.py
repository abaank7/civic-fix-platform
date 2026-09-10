from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.issue import Issue
from app.schemas.issue import IssueCreate, IssueResponse
from app.services.ai_service import categorize_issue

import cloudinary
import cloudinary.uploader

router = APIRouter()

# --- NEW: CLOUDINARY UPLOAD ENDPOINT ---
@router.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    """
    Streams an uploaded image directly to Cloudinary and returns the permanent URL.
    The Flutter app should call this first, then pass the returned URL to create_new_issue.
    """
    try:
        # Upload directly to Cloudinary (no local disk storage needed!)
        upload_result = cloudinary.uploader.upload(
            file.file,
            folder="civicfix_reports" # Creates a neat folder in your Cloudinary dashboard
        )
        secure_url = upload_result.get("secure_url")
        
        return {"image_url": secure_url}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image upload failed: {str(e)}")


# --- EXISTING: CREATE ISSUE ENDPOINT ---
@router.post("/", response_model=IssueResponse)
async def create_new_issue(issue_in: IssueCreate, db: Session = Depends(get_db)):
    # 1. Ask GPT-4o-mini Vision to categorize based on both description and image
    ai_category = await categorize_issue(issue_in.description, issue_in.image_url)
    
    # 2. Build the database row
    db_issue = Issue(
        description=issue_in.description,
        category=ai_category,
        latitude=issue_in.latitude,
        longitude=issue_in.longitude,
        image_url=issue_in.image_url,
        device_id=issue_in.device_id,
        status="Pending" 
    )
    
    # 3. Save to Supabase
    db.add(db_issue)
    db.commit()
    db.refresh(db_issue)
    
    return db_issue

# --- EXISTING: GET ALL ISSUES ---
@router.get("/", response_model=list[IssueResponse])
def get_all_public_issues(db: Session = Depends(get_db)):
    # Fetches all issues for the public map/dashboard, newest first
    return db.query(Issue).order_by(Issue.created_at.desc()).all()