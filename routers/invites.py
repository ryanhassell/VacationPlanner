from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel, EmailStr
import requests

router = APIRouter()


class InviteRequest(BaseModel):
    email: EmailStr
    group: int


class InviteSendResponse(BaseModel):
    detail: str
    invite_link: str

#
# # URL of your deployed Cloud Function (update with your Firebase project region and function name)
# CLOUD_FUNCTION_URL = "https://us-central1-vacation-698a8.cloudfunctions.net/sendInviteEmail"

#
# @router.post("/send_invite", response_model=InviteSendResponse)
# def send_invite(invite_req: InviteRequest, background_tasks: BackgroundTasks):
#     try:
#         # Generate the dynamic link for the invite
#         invite_response = generate_invite(invite_req.group)
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))
#
#     invite_link = invite_response.invite_link
#
#     # Prepare payload for Cloud Function call
#     payload = {
#         "email": invite_req.email,
#         "inviteLink": invite_link
#     }
#
#     try:
#         # Call the Cloud Function (synchronously here; you might also use background_tasks)
#         cf_response = requests.post(CLOUD_FUNCTION_URL, json=payload)
#         if cf_response.status_code != 200:
#             raise Exception(cf_response.text)
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error sending invite via Cloud Function: {str(e)}")
#
#     return InviteSendResponse(detail="Invite sent successfully.", invite_link=invite_link)
