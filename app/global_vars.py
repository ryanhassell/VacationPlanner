from fastapi import FastAPI
#from routers import

app = FastAPI()
origins = [
    "http://192.168.1.172/",
    "http://192.168.1.172/:8000",
]

app.include_router()