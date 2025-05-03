from typing import List

from enum import Enum
from pydantic import BaseModel

#enum for each possible role
class RoleEnum(str, Enum):
    owner = "Owner"
    admin = "Admin"
    member = "Member"

#response model
class MemberResponse(BaseModel):
    uid: str
    gid: int
    role: RoleEnum

#create model
class MemberCreate(BaseModel):
    uid: str
    gid: int
    role: RoleEnum

#model for updating a role
class UpdateRoleRequest(BaseModel):
    role: str
