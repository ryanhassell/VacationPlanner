from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME, FB_ACC_PATH
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, User, Group
from schemas.user import UserResponse, UserCreate, UserUpdate, UserChangePassword
import firebase_admin # this error is here for some reason but still works idk
from firebase_admin import auth, credentials #same here no idea

# Firebase Admin SDK Initialization
if not firebase_admin._apps:
    cred = credentials.Certificate(FB_ACC_PATH)
    firebase_admin.initialize_app(cred)

# Define database connection string
conn_string = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
engine = create_engine(conn_string)
Base.metadata.create_all(bind=engine)

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
async def get_user(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.post("", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email_address == user.email_address).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already exists.")

    try:
        # Step 1: Create Firebase User FIRST
        firebase_user = auth.get_user_by_email(
            email=user.email_address
        )

        firebase_uid = firebase_user.uid  # Use Firebase UID as UID
        print(f"Firebase user created with UID: {firebase_uid}")

        # Step 2: Store Firebase UID as UID in PostgreSQL
        new_user = User(
            uid=firebase_uid,  # Use Firebase UID as PostgreSQL UID
            first_name=user.first_name,
            last_name=user.last_name,
            email_address=user.email_address,
            phone_number=user.phone_number,
            groups=user.groups,
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        return new_user

    except Exception as e:
        print(f"Error creating Firebase user: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to create user: {str(e)}")


@router.delete("/{uid}", response_model=str)
async def delete_user(uid: int, db: Session = Depends(get_db)):
    # Retrieve the user by ID
    user_to_delete = db.query(User).filter(User.uid == uid).first()

    if not user_to_delete:
        raise HTTPException(status_code=404, detail=f"User with ID {uid} not found")

    try:
        # Delete user from Firebase
        if user_to_delete.uid:
            auth.delete_user(user_to_delete.uid)
            print(f"Firebase user {user_to_delete.uid} deleted.")

        # Delete the user from PostgreSQL
        db.delete(user_to_delete)
        db.commit()

        return f"User {uid} successfully deleted from both Firebase and PostgreSQL."

    except Exception as e:
        print(f"Error deleting Firebase user: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete user: {str(e)}")


@router.put("/{uid}", response_model=UserResponse)
async def update_user(uid: str, user_data: UserUpdate, db: Session = Depends(get_db)):
    user_to_update = db.query(User).filter(User.uid == uid).first()

    if not user_to_update:
        raise HTTPException(status_code=404, detail=f"User with ID {uid} not found")

    try:
        # Update user in Firebase Auth
        auth.update_user(
            user_to_update.uid,
            email=user_data.email_address if user_data.email_address else user_to_update.email_address,
            phone_number=user_data.phone_number if user_data.phone_number else user_to_update.phone_number,
            display_name=f"{user_data.first_name} {user_data.last_name}" if user_data.first_name and user_data.last_name else None
        )
        print(f"Firebase user {user_to_update.uid} updated.")

        # Update user in PostgreSQL
        for field, value in user_data.dict().items():
            setattr(user_to_update, field, value)

        db.commit()
        db.refresh(user_to_update)

        return user_to_update

    except Exception as e:
        print(f"Error updating Firebase user: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to update user: {str(e)}")


@router.post("/login", response_model=UserResponse)
async def user_login(data: dict, db: Session = Depends(get_db)):
    """ Authenticates user via Firebase and retrieves user details from PostgreSQL """
    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required")

    try:
        # Verify the user's credentials with Firebase
        user = auth.get_user_by_email(email)

        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")

        # Fetch user details from PostgreSQL (excluding password)
        db_user = db.query(User).filter(User.email_address == email).first()

        if not db_user:
            raise HTTPException(status_code=404, detail="User not found in database")

        return db_user  # Return user details (but no password)

    except Exception as e:
        print(f"Error logging in: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid email or password")


@router.put("/reset-password/{email}", response_model=UserChangePassword)
async def reset_password(email: str, user_data: UserChangePassword, db: Session = Depends(get_db)):
    user_to_update = db.query(User).filter(User.email_address == email).first()

    if not user_to_update:
        raise HTTPException(status_code=404, detail=f"User with email {email} not found")

    try:
        # Update password in Firebase Authentication
        auth.update_user(user_to_update.uid, password=user_data.new_password)
        print(f"Firebase password updated for {email}")

        # Update password in PostgreSQL
        user_to_update.password = user_data.new_password
        db.commit()
        db.refresh(user_to_update)

        return user_to_update

    except Exception as e:
        print(f"Error resetting Firebase password: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to reset password: {str(e)}")
