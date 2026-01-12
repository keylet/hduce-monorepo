from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, User

router = APIRouter()

@router.get("/test-super-simple")
async def test_super_simple():
    return {"status": "ok", "message": "Test super simple funciona"}

@router.get("/test-db-simple")
async def test_db_simple(db: Session = Depends(get_db)):
    try:
        count = db.query(User).count()
        return {"status": "ok", "user_count": count}
    except Exception as e:
        return {"status": "error", "error": str(e)}

@router.post("/login-test")
async def login_test():
    # Login sin dependencias complejas
    return {
        "access_token": "test_token_123",
        "token_type": "bearer", 
        "user": {"id": 1, "username": "test"}
    }
