from fastapi import FastAPI
from fastapi.responses import JSONResponse
import json
import os

app = FastAPI()
DATA_FILE = "/data/pomodoro.json"

def read_data():
    if not os.path.exists(DATA_FILE):
        return {}
    with open(DATA_FILE, "r") as f:
        return json.load(f)

def write_data(data: dict):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)

@app.get("/data")
def get_data():
    return JSONResponse(content=read_data())

@app.post("/data")
def post_data(payload: dict):
    write_data(payload)
    return {"status": "ok"}