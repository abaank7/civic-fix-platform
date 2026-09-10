from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from dotenv import load_dotenv
import os

from app.api.v1 import issues, admin
from app.db.session import engine, Base, get_db
from app.models.issue import Issue

load_dotenv()



# Automatically create tables if they don't exist. 
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Civic Fix API", version="0.1.0")

# Register our route files
app.include_router(issues.router, prefix="/api/v1/issues", tags=["Public Issues"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Admin Portal"])

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Use ["*"] to allow requests from any origin
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, PUT, DELETE, PATCH, etc.)
    allow_headers=["*"],  # Allows all headers
)

# --- SECURITY DEPENDENCY ---
def get_admin_key(x_admin_key: str = Header(None)):
    """Validates the x-admin-key header against the .env file"""
    EXPECTED_KEY = os.getenv("ADMIN_SECRET_KEY")

    if not EXPECTED_KEY:
        raise HTTPException(
            status_code=500,
            detail="Server configuration error: Admin key missing"
        )

    if x_admin_key != EXPECTED_KEY:
        raise HTTPException(
            status_code=403,
            detail="Invalid Admin Key"
        )

    return x_admin_key


# --- ROOT ENDPOINT ---
@app.get("/")
def read_root():
    return {"message": "CivicFix API is running!"}


# --- ADMIN VERIFY ENDPOINT ---
@app.get("/api/v1/admin/verify")
def verify_admin_key_endpoint(valid_key: str = Depends(get_admin_key)):
    """
    React Admin Login screen calls this.
    Because it uses Depends(get_admin_key), it will automatically throw a 403 error 
    if the key is wrong before this function even runs.
    """
    return {"status": "success", "message": "Authentication successful"}


# --- ADMIN DELETE ENDPOINT ---
# FIX: The path must exactly match what the React app is calling!
@app.delete("/api/v1/admin/issues/{issue_id}")
def delete_issue(
    issue_id: str, 
    db: Session = Depends(get_db), 
    valid_key: str = Depends(get_admin_key) 
):
    """
    Permanently deletes a reported issue from the database.
    Requires a valid x-admin-key header.
    """
    # 1. Find the issue in the database
    issue = db.query(Issue).filter(Issue.id == issue_id).first()
    
    # 2. If it doesn't exist, return a 404
    if not issue:
        raise HTTPException(status_code=404, detail="Issue not found")
        
    # 3. Delete the issue and save changes
    db.delete(issue)
    db.commit()
    
    return {"status": "success", "message": f"Issue {issue_id} permanently deleted."}