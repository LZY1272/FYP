from fastapi import FastAPI
from fastapi.responses import FileResponse
import os

app = FastAPI()

@app.get("/output_tiles/{z}/{x}/{y}.pbf")
async def get_tile(z: int, x: int, y: int):
    tile_path = f"output_tiles/{z}/{x}/{y}.pbf"  # Update path to match your folder

    if os.path.exists(tile_path):
        return FileResponse(tile_path)
    else:
        return {"error": "Tile not found"}, 404
