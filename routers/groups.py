from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, Group
from schemas.group import GroupResponse, GroupCreate

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


# API that gets a list of all the groups in the database
@router.get("/{gid}", response_model=list[GroupResponse])
async def get_group_by_gid(gid: int, db: Session = Depends(get_db)):
    groups = db.query(Group).filter(Group.gid == gid)
    return groups


@router.get("", response_model=list[GroupResponse])
async def list_groups(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    groups = db.query(Group).offset(skip).limit(limit).all()
    return groups


@router.get("/{gid}", response_model=list[GroupResponse])
async def list_users_by_gid(gid: int, db: Session = Depends(get_db)):
    members = db.query(Group.members).filter(Group.gid == gid).all()
    return members


@router.post("", response_model=GroupResponse)
async def create_group(group: GroupCreate, db: Session = Depends(get_db)):
    # Create a new group in the database
    new_group = Group(
        members=group.members,
        owner=group.owner,
        admin=group.admin,
        group_name=group.group_name,
        location_lat=group.location_lat,
        location_long=group.location_long,
        group_type=group.group_type
    )
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    return new_group
