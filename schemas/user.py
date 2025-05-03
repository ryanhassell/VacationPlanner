from typing import List, Optional
from pydantic import BaseModel

#default
class UserResponse(BaseModel):
    uid: str
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    # user_type: Enum
    profile_image_url: Optional[str]


class Config:
    arbitrary_types_allowed = True

#create a user response model
class UserCreate(BaseModel):
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    # user_type: Enum
    profile_image_url: Optional[str]


class UserUpdate(BaseModel):
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    # user_type: Enum
    profile_image_url: Optional[str]


class UserMember(BaseModel):
    uid: str
    first_name: str
    last_name: str
    email_address: str


class UserInvite(BaseModel):
    uid: str

#response for changing pass
class UserChangePassword(BaseModel):
    new_password: str

    class Config:
        orm_mode = True
