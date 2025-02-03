from pydantic import BaseModel


class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    email_address: str
    phone_number: str
    #user_type: Enum
    password: str

    class Config:
        arbitrary_types_allowed = True
