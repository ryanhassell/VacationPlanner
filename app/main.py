from fastapi import FastAPI
from routers import users, groups

app = FastAPI()
origins = [
    "http://localhost/",
    "http://localhost/:8000",
]

app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(groups.router, prefix="/groups", tags=["Groups"])
