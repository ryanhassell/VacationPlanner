from pydantic import BaseModel


class UserResponse(BaseModel):
    uid: int
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    #user_type: Enum
    password: str
    groups: int

    class Config:
        arbitrary_types_allowed = True
