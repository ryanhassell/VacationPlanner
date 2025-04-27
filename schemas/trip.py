from typing import List

from pydantic import BaseModel
from enum import Enum


class Landmark(BaseModel):
    name: str
    lat: float
    long: float
    type: str


class LandmarkTypeEnum(str, Enum):
    food = "Food"
    park = "Park"
    historic = "Historic"
    memorials = "Memorials"
    museums = "Museums"
    art = "Art"
    entertainment = "Entertainment"


class TripResponse(BaseModel):
    trip_id: int
    group: int
    location_lat: float
    location_long: float
    landmarks: List[Landmark]
    uid: str

    class Config:
        arbitrary_types_allowed = True


class TripSummaryResponse(BaseModel):
    trip_id: int
    group: int
    location_lat: float
    location_long: float
