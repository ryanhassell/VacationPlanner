from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, Group
from schemas.group import GroupResponse, GroupCreate, GroupUpdate, IDGroupResponse, TempGroupResponse

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
    groups = db.query(Group).filter(Group.gid == gid).all()
    return groups


@router.get("", response_model=list[GroupResponse])
async def list_groups(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    groups = db.query(Group).offset(skip).limit(limit).all()
    return groups

@router.get("/get/{gid}", response_model=TempGroupResponse)
async def get_group_by_gid(gid: int, db: Session = Depends(get_db)):
    group = db.query(
        Group.gid,
        Group.owner,
        Group.group_name,
        #Group.location_lat,
        #Group.location_long,
        Group.group_type
    ).filter(Group.gid == gid).first()

    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    return {
        "gid": group.gid,
        "owner": group.owner,
        "group_name": group.group_name,
        #"location_lat": group.location_lat,
        #"location_long": group.location_long,
        "group_type": group.group_type
    }

@router.get("/{uid}", response_model=list[GroupResponse])
async def get_groups_by_uid(uid: str, db: Session = Depends(get_db)):
    groups = db.query(Group).filter(Group.owner == uid).all()
    return groups

@router.get("/identify/{uid}", response_model=list[IDGroupResponse])
async def groups_gid_by_uid(uid: str, db: Session = Depends(get_db)):
    groups = db.query(Group.gid, Group.group_name).filter(Group.owner == uid).all()
    return [{"gid": g[0], "group_name": g[1]} for g in groups]

@router.post("", response_model=GroupResponse)
async def create_group(group: GroupCreate, db: Session = Depends(get_db)):
    # Create a new group in the database
    new_group = Group(
        owner=group.owner,
        group_name=group.group_name,
        #location_lat=group.location_lat,
        #location_long=group.location_long,
        group_type=group.group_type
    )
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    return new_group

@router.delete("/{gid}", response_model=str)
async def delete_group(gid: int, db: Session = Depends(get_db)):
    # Retrieve the Group object by its ID
    group_to_delete = db.query(Group).filter(Group.gid == gid).first()

    if group_to_delete:
        # Delete the Group object
        db.delete(group_to_delete)
        db.commit()
        return f"Group {gid} successfully deleted."
    else:
        raise HTTPException(status_code=404, detail=f"Group with ID {gid} not found")


@router.put("/{uid}", response_model=GroupResponse)
async def update_group(
    gid: int, group_data: GroupUpdate, db: Session = Depends(get_db)
):
    group_to_update = db.query(Group).filter(Group.gid == gid).first()

    if group_to_update:
        # Update the Group object with the new data
        for field, value in group_data.dict().items():
            setattr(group_to_update, field, value)

        db.commit()
        db.refresh(group_to_update)
        return group_to_update
    else:
        raise HTTPException(status_code=404, detail=f"Group with ID {gid} not found")
