from datetime import datetime

from pydantic import BaseModel


from datetime import datetime
from pydantic import BaseModel

class MessageCreateRequest(BaseModel):
    gid: int
    sender_uid: str
    sender_name: str
    text: str
    timestamp: datetime


class MessageResponse(BaseModel):
    gid: int
    sender_uid: str
    sender_name: str
    text: str
    timestamp: datetime

    class Config:
        orm_mode = True
