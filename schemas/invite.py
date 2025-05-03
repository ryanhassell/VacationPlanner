from pydantic import BaseModel

from schemas.member import RoleEnum

#response model
class InviteResponse(BaseModel):
    uid: str
    gid: int
    invited_by: str
    role: RoleEnum

#create model
class InviteCreate(BaseModel):
    uid: str
    gid: int
    invited_by: str
    role: RoleEnum
