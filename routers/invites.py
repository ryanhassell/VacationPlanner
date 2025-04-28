from typing import List

from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, Group, Invite
from schemas.invite import InviteResponse, InviteCreate

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

@router.get("/{uid}", response_model=list[InviteResponse])
async def get_members_by_uid(uid: str, db: Session = Depends(get_db)):
    invites = db.query(Invite).filter(Invite.uid == uid).all()
    return invites

@router.post("", response_model=InviteCreate)
async def create_group(invite: InviteCreate, db: Session = Depends(get_db)):
    # Create a new group in the database
    new_invite = Invite(
        uid=invite.uid,
        gid=invite.gid,
        invited_by=invite.invited_by,
        role=invite.role,
    )
    db.add(new_invite)
    db.commit()
    db.refresh(new_invite)
    return new_invite


@router.get("/list_invites_by_user/{uid}", response_model=List[InviteResponse])
def list_invites_by_user(uid: str, db: Session = Depends(get_db)):
    invites = db.query(Invite).filter(Invite.uid == uid).all()
    if not invites:
        return []
    return invites

@router.delete("/{uid}/{gid}", status_code=200)
async def delete_invite(uid: str, gid: int, db: Session = Depends(get_db)):
    invite = db.query(Invite).filter(Invite.uid == uid, Invite.gid == gid).first()

    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")

    db.delete(invite)
    db.commit()

    return {"message": "Invite successfully deleted"}