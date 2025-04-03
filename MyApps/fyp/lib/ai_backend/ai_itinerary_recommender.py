from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pymongo
import pandas as pd
from sklearn.neighbors import NearestNeighbors
from bson import ObjectId
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Add CORS middleware (if necessary for cross-origin requests)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (can be restricted to your frontend domains in production)
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods (GET, POST, etc.)
    allow_headers=["*"],  # Allows all headers
)

# ✅ Connect to MongoDB
client = pymongo.MongoClient("mongodb+srv://LZY1272:Ling_1272@cluster0.pqdov.mongodb.net/")
db = client["user"]
itinerary_collection = db["itineraries"]
user_collection = db["users"]  # Assuming a 'users' collection exists

# ✅ Load Itineraries
itinerary_data = list(itinerary_collection.find({}))
df = pd.DataFrame(itinerary_data)
if df.empty:
    raise HTTPException(status_code=404, detail="No itineraries found!")

# 🔄 Preprocess Data
df = df.drop(columns=["_id", "userId", "destination", "startDate", "endDate", "timestamp", "__v", "itinerary"])
list_columns = ["activityPreferences", "interestCategories"]

for col in list_columns:
    df[col] = df[col].apply(lambda x: ",".join(x) if isinstance(x, list) else str(x))

categorical_columns = ["travelType", "activityPreferences", "interestCategories"]
df = pd.get_dummies(df, columns=categorical_columns).fillna(0)

# ✅ Train AI Model
model = NearestNeighbors(n_neighbors=5, metric="euclidean")
model.fit(df)

# ✅ Define the route with the userId as a path parameter
@app.get("/home_recommendations/{userId}")
def recommend_for_home(userId: str):
    try:
        # Convert userId to ObjectId
        user_id = ObjectId(userId)
        user = user_collection.find_one({"_id": user_id})

        if not user:
            raise HTTPException(status_code=404, detail="User not found")
    except:
        raise HTTPException(status_code=400, detail="Invalid userId format")

    # Extract user preferences
    user_prefs = {
        "activityPreferences": user.get("activityPreferences", []),
        "interestCategories": user.get("interestCategories", [])
    }

    print("Extracted user preferences:", user_prefs)  # Debugging step

    input_df = pd.DataFrame([user_prefs])

    list_columns = ["activityPreferences", "interestCategories"]
    for col in list_columns:
        input_df[col] = input_df[col].apply(lambda x: ",".join(x) if isinstance(x, list) else str(x))

    input_df = pd.get_dummies(input_df, columns=list_columns)

    # Align input features with model
    for col in set(df.columns) - set(input_df.columns):
        input_df[col] = 0
    input_df = input_df[df.columns]

    # ✅ Find nearest itineraries
    distances, indices = model.kneighbors(input_df)

    recommendations = []
    for idx in indices[0]:  # Loop over recommended indices
        original_itinerary = itinerary_data[idx]  # Get data from original list
        recommendations.append({
            "id": str(original_itinerary["_id"]),  # Convert ObjectId to string
            "destination": original_itinerary.get("destination", "Unknown"),
            "activityPreferences": original_itinerary.get("activityPreferences", []),
            "interestCategories": original_itinerary.get("interestCategories", []),
            "similarity_score": 1 / (1 + distances[0][indices[0].tolist().index(idx)]),
        })

    return {"recommendations": recommendations}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)