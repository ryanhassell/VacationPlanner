from enum import Enum
from typing import List

from pydantic import BaseModel

#test
class GroupTypeEnum(str, Enum):
    planned = "Planned"
    random = "Random"


class GroupResponse(BaseModel):
    gid: int
    members: List[int]
    owner: str
    admin: List[int]
    group_name: str
    location_lat: float
    location_long: float
    group_type: GroupTypeEnum


class GroupCreate(BaseModel):
    owner: str
    group_name: str
    location_lat: float
    location_long: float
    group_type: GroupTypeEnum


class GroupUpdate(BaseModel):
    members: List[int]
    owner: str
    admin: List[int]
    group_name: str
    location_lat: float
    location_long: float
    group_type: GroupTypeEnum

class IDGroupResponse(BaseModel):
    gid: int
    group_name: str
