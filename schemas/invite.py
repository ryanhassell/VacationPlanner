from pydantic import BaseModel

from schemas.member import RoleEnum


class InviteResponse(BaseModel):
    uid: str
    gid: int
    invited_by: str
    role: RoleEnum

class InviteCreate(BaseModel):
    uid: str
    gid: int
    invited_by: str
    role: RoleEnum

