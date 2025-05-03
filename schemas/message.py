from datetime import datetime

from pydantic import BaseModel

from datetime import datetime
from pydantic import BaseModel

#for creating messages
class MessageCreateRequest(BaseModel):
    gid: int
    sender_uid: str
    sender_name: str
    text: str
    timestamp: datetime

#response for messages
class MessageResponse(BaseModel):
    gid: int
    sender_uid: str
    sender_name: str
    text: str
    timestamp: datetime
    read_by: list[str] = []

    class Config:
        orm_mode = True
