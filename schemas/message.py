from datetime import datetime

from pydantic import BaseModel


class MessageResponse(BaseModel):
    group_id: int
    sender_uid: str
    sender_name: str
    text: str
    id: int
    timestamp: datetime
