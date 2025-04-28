from typing import List

from enum import Enum
from pydantic import BaseModel


class RoleEnum(str, Enum):
    owner = "Owner"
    admin = "Admin"
    member = "Member"


class MemberResponse(BaseModel):
    uid: str
    gid: int
    role: RoleEnum


class MemberCreate(BaseModel):
    uid: str
    gid: int
    role: RoleEnum

class UpdateRoleRequest(BaseModel):
    role: str
