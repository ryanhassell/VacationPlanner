from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from datetime import datetime

from app.global_vars import DB_USERNAME, DB_PASSWORD, DB_HOST, DB_NAME
from app.models import Message, Base, Group
from schemas.message import MessageResponse, MessageCreateRequest

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


@router.post("/send_message", response_model=MessageResponse)
def send_message(message: MessageCreateRequest, db: Session = Depends(get_db)):
    db_message = Message(
        gid=message.gid,
        sender_uid=message.sender_uid,
        sender_name=message.sender_name,
        text=message.text,
        timestamp=message.timestamp
    )
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    return db_message


@router.get("/get_messages/{gid}", response_model=List[MessageResponse])
def get_messages(gid: int, db: Session = Depends(get_db)):
    messages = db.query(Message).filter(Message.gid == gid).order_by(Message.timestamp).all()
    return messages


# Endpoint to get groups with unread messages
@router.get("/unread/{uid}")
def get_unread_groups(uid: str, db: Session = Depends(get_db)):
    unread_gids = (
        db.query(Message.gid)
        .filter(~Message.read_by.any(uid))
        .distinct()
        .all()
    )
    gids = [gid for (gid,) in unread_gids]
    groups = db.query(Group).filter(Group.gid.in_(gids)).all()
    return [{"gid": group.gid, "group_name": group.group_name} for group in groups]


# Endpoint to mark messages as read in a group
@router.post("/mark_read/{gid}/{uid}")
def mark_messages_as_read(gid: int, uid: str, db: Session = Depends(get_db)):
    messages = db.query(Message).filter(Message.gid == gid, ~Message.read_by.any(uid)).all()
    for message in messages:
        message.read_by.append(uid)
    db.commit()
    return {"status": "messages marked as read"}
