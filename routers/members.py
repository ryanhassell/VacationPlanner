from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import crud

from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, Member, Group
from schemas.group import GroupResponse
from schemas.member import MemberResponse, MemberCreate, UpdateRoleRequest


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


@router.get("/by_uid/{uid}", response_model=list[MemberResponse])
async def get_mem_by_uid(uid: str, db: Session = Depends(get_db)):
    members = db.query(Member).filter(Member.uid == uid).all()
    return members


##gets all users within a certain group id
@router.get("/{gid}", response_model=list[MemberResponse])
async def get_members_by_gid(gid: int, db: Session = Depends(get_db)):
    members = db.query(Member).filter(Member.gid == gid).all()
    return members

@router.get("/{gid}/{uid}", response_model=list[MemberResponse])
async def get_members_by_gid(gid: int, uid: str, db: Session = Depends(get_db)):
    members = db.query(Member).filter(Member.gid == gid, Member.uid == uid).all()  # Fixed this line
    return members

@router.delete("/{gid}/{uid}", status_code=200)
async def delete_member(uid: str, gid: int, db: Session = Depends(get_db)):
    invite = db.query(Member).filter(Member.uid == uid, Member.gid == gid).first()

    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")

    db.delete(invite)
    db.commit()

    return {"message": "Invite successfully deleted"}

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
@router.put("/{gid}/{uid}", response_model=MemberResponse)
def update_role(
    gid: int,
    uid: str,
    update_role_request: UpdateRoleRequest,
    db: Session = Depends(get_db)
):
    # Check if the user exists in the group
    members = db.query(Member).filter(Member.gid == gid, Member.uid == uid).first()

    # Check if the role is valid
    if update_role_request.role not in ['Member', 'Admin', 'Owner']:
        raise HTTPException(status_code=400, detail="Invalid role")

    # Update the member's role
    members.role = update_role_request.role
    db.commit()
    db.refresh(members)

    return members
