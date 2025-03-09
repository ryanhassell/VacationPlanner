from typing import List

from pydantic import BaseModel


class UserResponse(BaseModel):
    uid: str
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    # user_type: Enum
    groups: List[int]

    class Config:
        arbitrary_types_allowed = True


class UserCreate(BaseModel):
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    # user_type: Enum
    groups: List[int]


class UserUpdate(BaseModel):
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    # user_type: Enum
    groups: List[int]

from pydantic import BaseModel

class UserChangePassword(BaseModel):
    new_password: str

    class Config:
        orm_mode = True
