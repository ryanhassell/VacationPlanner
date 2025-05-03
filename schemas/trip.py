from typing import List

from pydantic import BaseModel
from enum import Enum

#landmark psuedo model
class Landmark(BaseModel):
    name: str
    lat: float
    long: float
    type: str

#landmark enum
class LandmarkTypeEnum(str, Enum):
    food = "Food"
    park = "Park"
    historic = "Historic"
    memorials = "Memorials"
    museums = "Museums"
    art = "Art"
    entertainment = "Entertainment"

#default trip response
class TripResponse(BaseModel):
    trip_id: int
    group: int
    location_lat: float
    location_long: float
    landmarks: List[Landmark]
    uid: str
    num_destinations: int

    class Config:
        arbitrary_types_allowed = True
        orm_mode = True


class TripSummaryResponse(BaseModel):
    trip_id: int
    group: int
    location_lat: float
    location_long: float
    num_destinations: int

    class Config:
        orm_mode = True


class CustomTripResponse(BaseModel):
    trip_id: int
    group: int
    location_lat: float
    location_long: float
    landmarks: List[Landmark]
    uid: str

    class Config:
        arbitrary_types_allowed = True
        orm_mode = True

#to fix weird error w trip id
class AlternateTripResponse(BaseModel):
    tid: int
    group: int
    location_lat: float
    location_long: float
    landmarks: List[Landmark]
    uid: str
    num_destinations: int

    class Config:
        arbitrary_types_allowed = True
        orm_mode = True