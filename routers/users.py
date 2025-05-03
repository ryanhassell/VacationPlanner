from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.global_vars import DB_HOST, DB_NAME, DB_PASSWORD, DB_USERNAME, FB_ACC_PATH
from fastapi import FastAPI, HTTPException, Depends, APIRouter
from app.models import Base, User, Group
from schemas.user import UserResponse, UserCreate, UserUpdate, UserChangePassword, UserMember, UserInvite
import firebase_admin  # Firebase Admin SDK for user management
from firebase_admin import auth, credentials  # Firebase authentication and credentials management

# Firebase Admin SDK Initialization
# Initialize Firebase app if not already initialized
if not firebase_admin._apps:
    cred = credentials.Certificate(FB_ACC_PATH)  # Load the Firebase credentials
    firebase_admin.initialize_app(cred)  # Initialize Firebase app

# Define database connection string
conn_string = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
engine = create_engine(conn_string)  # Create engine to connect to PostgreSQL
Base.metadata.create_all(bind=engine)  # Create tables in PostgreSQL using SQLAlchemy

# Create a session factory for database sessions
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

router = APIRouter()  # Initialize FastAPI APIRouter


# Dependency to get a database session
def get_db():
    db = SessionLocal()  # Start a new database session
    try:
        yield db  # Yield the session for use in route handlers
    finally:
        db.close()  # Ensure the session is closed after use


# Route to fetch a user by UID
@router.get("/{uid}", response_model=UserResponse)
async def get_user(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()  # Query user by UID
    if not user:
        raise HTTPException(status_code=404, detail="User not found")  # Return error if user not found
    return user  # Return user data


# Route to fetch user membership information by UID
@router.get("/member/info/{uid}", response_model=UserMember)
async def get_user(uid: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.uid == uid).first()  # Query user by UID
    if not user:
        raise HTTPException(status_code=404, detail="User not found")  # Return error if user not found
    return user  # Return user membership information


# Route to fetch user by email for invite info
@router.get("/invite/id/{email_address}", response_model=UserInvite)
async def get_user(email_address: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email_address == email_address).first()  # Query user by email
    if not user:
        raise HTTPException(status_code=404, detail="User not found")  # Return error if user not found
    return user  # Return user invite information


# Route to create a new user
@router.post("", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email_address == user.email_address).first()  # Check if email exists
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already exists.")  # Return error if email is already taken

    try:
        # Step 1: Create Firebase User FIRST
        firebase_user = auth.get_user_by_email(email=user.email_address)  # Get user from Firebase by email

        firebase_uid = firebase_user.uid  # Use Firebase UID as UID for user
        print(f"Firebase user created with UID: {firebase_uid}")

        # Step 2: Store Firebase UID as UID in PostgreSQL
        new_user = User(
            uid=firebase_uid,  # Use Firebase UID as PostgreSQL UID
            first_name=user.first_name,
            last_name=user.last_name,
            email_address=user.email_address,
            phone_number=user.phone_number,
        )
        db.add(new_user)  # Add new user to the database
        db.commit()  # Commit the transaction
        db.refresh(new_user)  # Refresh to get the latest data for the new user

        return new_user  # Return the created user

    except Exception as e:
        print(f"Error creating Firebase user: {str(e)}")  # Print any errors that occur
        raise HTTPException(status_code=500, detail=f"Failed to create user: {str(e)}")  # Return error if creation fails


# Route to delete a user by UID
@router.delete("/{uid}", response_model=str)
async def delete_user(uid: int, db: Session = Depends(get_db)):
    user_to_delete = db.query(User).filter(User.uid == uid).first()  # Query user to delete by UID

    if not user_to_delete:
        raise HTTPException(status_code=404, detail=f"User with ID {uid} not found")  # Return error if user not found

    try:
        # Delete user from Firebase
        if user_to_delete.uid:
            auth.delete_user(user_to_delete.uid)  # Delete user from Firebase by UID
            print(f"Firebase user {user_to_delete.uid} deleted.")

        # Delete the user from PostgreSQL
        db.delete(user_to_delete)  # Delete user from database
        db.commit()  # Commit the deletion

        return f"User {uid} successfully deleted from both Firebase and PostgreSQL."  # Return success message

    except Exception as e:
        print(f"Error deleting Firebase user: {str(e)}")  # Print any errors that occur
        raise HTTPException(status_code=500, detail=f"Failed to delete user: {str(e)}")  # Return error if deletion fails


# Route to update user details by UID
@router.put("/{uid}", response_model=UserResponse)
async def update_user(uid: str, user_data: UserUpdate, db: Session = Depends(get_db)):
    user_to_update = db.query(User).filter(User.uid == uid).first()  # Query user by UID

    if not user_to_update:
        raise HTTPException(status_code=404, detail=f"User with ID {uid} not found")  # Return error if user not found

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
            setattr(user_to_update, field, value)  # Set each field value in the user

        db.commit()  # Commit the update
        db.refresh(user_to_update)  # Refresh to get the latest user data

        return user_to_update  # Return the updated user

    except Exception as e:
        print(f"Error updating Firebase user: {str(e)}")  # Print any errors that occur
        raise HTTPException(status_code=500, detail=f"Failed to update user: {str(e)}")  # Return error if update fails


# Route to authenticate user during login
@router.post("/login", response_model=UserResponse)
async def user_login(data: dict, db: Session = Depends(get_db)):
    """ Authenticates user via Firebase and retrieves user details from PostgreSQL """
    email = data.get("email")  # Get email from request
    password = data.get("password")  # Get password from request

    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required")  # Error if email or password missing

    try:
        # Verify the user's credentials with Firebase
        user = auth.get_user_by_email(email)

        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")  # Error if user not found in Firebase

        # Fetch user details from PostgreSQL (excluding password)
        db_user = db.query(User).filter(User.email_address == email).first()

        if not db_user:
            raise HTTPException(status_code=404, detail="User not found in database")  # Error if user not found in database

        return db_user  # Return the user's details (but not the password)

    except Exception as e:
        print(f"Error logging in: {str(e)}")  # Print any errors that occur
        raise HTTPException(status_code=401, detail="Invalid email or password")  # Return error if login fails


# Route to reset user's password
@router.put("/reset-password/{email}", response_model=UserChangePassword)
async def reset_password(email: str, user_data: UserChangePassword, db: Session = Depends(get_db)):
    user_to_update = db.query(User).filter(User.email_address == email).first()  # Query user by email

    if not user_to_update:
        raise HTTPException(status_code=404, detail=f"User with email {email} not found")  # Return error if user not found

    try:
        # Update password in Firebase Authentication
        auth.update_user(user_to_update.uid, password=user_data.new_password)  # Update password in Firebase
        print(f"Firebase password updated for {email}")

        # Update password in PostgreSQL
        user_to_update.password = user_data.new_password  # Update password in database
        db.commit()  # Commit the update
        db.refresh(user_to_update)  # Refresh to get the latest data

        return user_to_update  # Return updated user

    except Exception as e:
        print(f"Error resetting Firebase password: {str(e)}")  # Print any errors that occur
        raise HTTPException(status_code=500, detail=f"Failed to reset password: {str(e)}")  # Return error if reset fails
