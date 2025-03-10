import random
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from app.global_vars import DB_USERNAME, DB_PASSWORD, DB_HOST, DB_NAME
from app.models import Trip, Base
from schemas.trip import TripResponse

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


@router.post("/generate_trip", response_model=TripResponse)
def generate_trip(group: int, location_lat: float, location_long: float, db: Session = Depends(get_db)):
    # Generate a small random offset (adjust the range as needed)
    lat_offset = random.uniform(-0.01, 0.01)
    long_offset = random.uniform(-0.01, 0.01)

    new_trip = Trip(
        group=group,
        location_lat=location_lat + lat_offset,
        location_long=location_long + long_offset
    )
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)

    return TripResponse(
        trip_id=new_trip.tid,
        group=new_trip.group,
        location_lat=new_trip.location_lat,
        location_long=new_trip.location_long
    )
