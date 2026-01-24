from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db

router = APIRouter()

@router.post("/test-minimal")
async def test_minimal(user_id: str, db: Session = Depends(get_db)):
    return {"message": "Test OK", "user_id": user_id, "db_status": "connected"}

@router.post("/test-no-db")
async def test_no_db(user_id: str):
    return {"message": "Test OK sin DB", "user_id": user_id}
