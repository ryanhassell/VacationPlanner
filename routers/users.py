from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, User, Group
from schemas.user import UserResponse, UserCreate, UserUpdate

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
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("", response_model=list[UserResponse])
async def list_users(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    users = db.query(User).offset(skip).limit(limit).all()
    return users


@router.get("/{uid}", response_model=list[UserResponse])
async def list_groups_by_uid(uid: int, db: Session = Depends(get_db)):
    users = db.query(Group).filter(Group.gid == uid).all()
    return users


@router.post("", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Create a new user in the database
    new_user = User(
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


@router.delete("/{uid}", response_model=str)
async def delete_user(uid: int, db: Session = Depends(get_db)):
    # Retrieve the User object by its ID
    user_to_delete = db.query(User).filter(User.uid == uid).first()

    if user_to_delete:
        # Delete the User object
        db.delete(user_to_delete)
        db.commit()
        return f"User {uid} successfully deleted."
    else:
        raise HTTPException(status_code=404, detail=f"User with ID {uid} not found")


@router.put("/{uid}", response_model=UserResponse)
async def update_user(
    uid: int, user_data: UserUpdate, db: Session = Depends(get_db)
):
    # Retrieve the User object by its ID
    user_to_update = db.query(User).filter(User.uid == uid).first()

    if user_to_update:
        # Update the User object with the new data
        for field, value in user_data.dict().items():
            setattr(user_to_update, field, value)

        db.commit()
        db.refresh(user_to_update)
        return user_to_update
    else:
        raise HTTPException(status_code=404, detail=f"User with ID {uid} not found")


@router.get("/login/{email}/{password}", response_model=UserResponse)
async def user_login(email: str, password: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email_address == email, User.password == password).first()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    return user
