from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import uuid

# What Flutter sends us when creating an issue
class IssueCreate(BaseModel):
    # Description is now completely optional with no character limits
    description: Optional[str] = Field(default="", description="Optional description of the issue")
    latitude: float
    longitude: float
    image_url: Optional[str] = None
    device_id: str

# What we send back to Flutter and the Admin Dashboard
class IssueResponse(BaseModel):
    id: uuid.UUID
    description: str
    category: str
    status: str
    latitude: float
    longitude: float
    image_url: Optional[str]
    device_id: str
    created_at: datetime

    class Config:
        from_attributes = True