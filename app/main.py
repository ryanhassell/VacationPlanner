from fastapi import FastAPI
from routers import users, groups, trips
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
origins = [
    "http://localhost/",
    "http://localhost/:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this to specific frontend domains in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/users", tags=["Users"])
app.include_router(groups.router, prefix="/groups", tags=["Groups"])
app.include_router(trips.router, prefix="/trips", tags=["Trips"])
