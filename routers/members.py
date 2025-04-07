from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, Member
from schemas.member import MemberResponse, MemberCreate

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


##gets all users within a certain group id
@router.get("/{gid}", response_model=list[MemberResponse])
async def get_members_by_gid(gid: int, db: Session = Depends(get_db)):
    members = db.query(Member).filter(Member.gid == gid).all()
    return members

##gets all groups within a certain user id
@router.get("/{uid}", response_model=list[MemberResponse])
async def get_members_by_uid(uid: str, db: Session = Depends(get_db)):
    members = db.query(Member).filter(Member.uid == uid).all()
    return members

##Create a member
@router.post("", response_model=MemberCreate)
async def create_group(member: MemberCreate, db: Session = Depends(get_db)):
    # Create a new group in the database
    new_member = Member(
        uid=member.uid,
        gid=member.gid,
        role=member.role
    )
    db.add(new_member)
    db.commit()
    db.refresh(new_member)
    return new_member