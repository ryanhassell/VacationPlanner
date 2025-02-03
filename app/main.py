from fastapi import FastAPI
from routers import users

app = FastAPI()
origins = [
    "http://localhost/",
    "http://localhost/:8000",
]

app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(users.router, prefix="/groups", tags=["Groups"])
