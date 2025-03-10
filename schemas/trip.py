from typing import List

from pydantic import BaseModel


class TripResponse(BaseModel):
    trip_id: int
    group: int
    location_lat: float
    location_long: float

    class Config:
        arbitrary_types_allowed = True
