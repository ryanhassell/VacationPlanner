from typing import List

from pydantic import BaseModel
from enum import Enum


class LandmarkTypeEnum(str, Enum):
    food = "Food"
    park = "Park"
    historic = "Historic"
    memorials = "Memorials"
    museums = "Museums"
    art = "Art"
    entertainment = "Entertainment"


class Landmark(BaseModel):
    name: str
    lat: float
    long: float
    type: LandmarkTypeEnum


class TripResponse(BaseModel):
    trip_id: int
    group: int
    location_lat: float
    location_long: float
    landmarks: List[Landmark]

    class Config:
        arbitrary_types_allowed = True
