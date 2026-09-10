import os
from fastapi import APIRouter, Depends, HTTPException, Header
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.issue import Issue
from app.schemas.issue import IssueResponse

router = APIRouter()
ADMIN_SECRET = os.getenv("ADMIN_SECRET_KEY")

class StatusUpdate(BaseModel):
    status: str

# Dependency to check the secret key
def verify_admin(x_admin_key: str = Header(...)):
    if x_admin_key != ADMIN_SECRET:
        raise HTTPException(status_code=403, detail="Unauthorized: Invalid Admin Key")

@router.patch("/issues/{issue_id}/status", response_model=IssueResponse, dependencies=[Depends(verify_admin)])
def update_issue_status(issue_id: str, update: StatusUpdate, db: Session = Depends(get_db)):
    # Ensure the admin only uses the 3 approved states
    valid_statuses = ["Pending", "In Progress", "Resolved"]
    if update.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Status must be one of: {valid_statuses}")
        
    db_issue = db.query(Issue).filter(Issue.id == issue_id).first()
    if not db_issue:
        raise HTTPException(status_code=404, detail="Issue not found")
        
    # Apply update and save
    db_issue.status = update.status
    db.commit()
    db.refresh(db_issue)
    
    return db_issue