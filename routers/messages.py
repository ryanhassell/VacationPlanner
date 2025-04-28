from fastapi import APIRouter, Depends
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from datetime import datetime

from app.global_vars import DB_USERNAME, DB_PASSWORD, DB_HOST, DB_NAME
from app.models import Message, Base
from schemas.message import MessageResponse

# Define your connection string
conn_string = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
engine = create_engine(conn_string)
Base.metadata.create_all(bind=engine)

# Use the create_engine function to establish the connection
engine = create_engine(conn_string)

# Create a session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

router = APIRouter()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@router.post("/messages/send_message", response_model=MessageResponse)
def send_message(message: MessageResponse, db: Session = Depends(get_db)):
    new_message = Message(
        gid=message.group_id,
        sender_uid=message.sender_uid,
        sender_name=message.sender_name,
        text=message.text,
        timestamp=datetime.utcnow()
    )
    db.add(new_message)
    db.commit()
    db.refresh(new_message)
    return {"status": "success", "message_id": new_message.id}


@router.get("/get_messages", response_model=MessageResponse)
def get_messages(group_id: int, db: Session = Depends(get_db)):
    messages = db.query(Message).filter(Message.group_id == group_id).order_by(Message.timestamp.asc()).all()
    return [{"sender_name": m.sender_name, "text": m.text, "timestamp": m.timestamp.isoformat()} for m in messages]
