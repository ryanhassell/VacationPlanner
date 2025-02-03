from enum import Enum
from typing import List

from pydantic import BaseModel


class GroupTypeEnum(str, Enum):
    planned = "planned"
    random = "random"


class GroupResponse(BaseModel):
    gid: int
    members: List[int]
    owner: int
    admin: List[int]
    group_name: str
    location_lat: float
    location_long: float
    group_type: GroupTypeEnum
