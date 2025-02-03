from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, User
from schemas.user import UserResponse, UserCreate

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


@router.get("/{uid}", response_model=UserResponse)
async def get_user_by_uid(uid: int, db: Session = Depends(get_db)):
    users = db.query(User).filter(User.uid == uid)
    return users


@router.get("", response_model=list[UserResponse])
async def list_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    users = db.query(User).offset(skip).limit(limit).all()
    return users


@router.get("/{gid}", response_model=list[UserResponse])
async def list_users_by_gid(gid: int, db: Session = Depends(get_db)):
    users = db.query(User).filter(User.gid == gid).all()
    return users


@router.post("", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Create a new user in the database
    new_user = User(
        uid=user.uid,
        first_name=user.first_name,
        last_name=user.last_name,
        email_address=user.email_address,
        phone_number=user.phone_number,
        password=user.password,
        groups=user.groups
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user
