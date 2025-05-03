import math
import urllib
import json
import random
from typing import List

import requests
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from app.global_vars import DB_USERNAME, DB_PASSWORD, DB_HOST, DB_NAME, MAPBOX_PUBLIC_TOKEN
from app.models import Trip, Base
from schemas.trip import TripResponse, TripSummaryResponse, Landmark, AlternateTripResponse

# Database setup
conn_string = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
engine = create_engine(conn_string)
Base.metadata.create_all(bind=engine)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

router = APIRouter()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# calculate haversine distance
def haversine_distance(lat1, lon1, lat2, lon2):
    R = 3958.8
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = math.sin(d_lat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(
        d_lon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def get_landmarks(lat: float, lng: float, landmark_types: str, max_distance: float, num_destinations: int,
                  category_counts_str: str):
    # Log input parameters for debugging
    print("get_landmarks() called with:")
    print("  lat =", lat, "lng =", lng)
    print("  landmark_types =", landmark_types)
    print("  max_distance =", max_distance)
    print("  num_destinations =", num_destinations)
    print("  category_counts_str =", category_counts_str)

    # Parse the landmark types and clean up any extra spaces
    categories = [cat.strip() for cat in landmark_types.split(",") if cat.strip()]
    print("Parsed categories:", categories)

    # Try parsing the category counts, defaulting to 1 for each category if parsing fails
    try:
        category_counts = json.loads(category_counts_str)
    except Exception as e:
        print("Error parsing category_counts; defaulting each category to 1:", e)
        category_counts = {cat: 1 for cat in categories}

    # Ensure all specified categories have an entry in category_counts
    for cat in categories:
        if cat not in category_counts:
            category_counts[cat] = 1
    print("Parsed category_counts:", category_counts)

    # Mapping for each category to relevant search terms for the API query
    query_mapping = {
        "Food": ["restaurant", "cafe", "diner", "bistro", "eatery", "food", "coffee shop", "grill", "pho", "ramen",
                 "yakitori", "la piazza"],
        "Parks": ["garden", "botanical garden", "green space", "nature reserve", "trail", "peak", "falls", "orchard"],
        "Historic": ["historic building", "heritage site", "historical site", "landmark", "old building", "monumental"],
        "Memorials": ["memorial", "monument", "commemorative", "statue", "cenotaph", "tribute"],
        "Museums": ["museum", "art gallery", "exhibit", "history museum", "science museum", "cultural center"],
        "Art": ["art gallery", "exhibit", "showcase", "gallery", "art center", "art museum", "creative space"],
        "Entertainment": ["cinema", "movie theater", "theater", "amusement", "entertainment", "arcade", "playhouse",
                          "live performance"]
    }

    # Define a list of unwanted terms that should be filtered out from landmark names
    unwanted_words = ["street", "drive", "way", "avenue", "road", "development", "developments", "residential",
                      "commercial", "office", "plaza", "mall", "complex", "apartment", "lane", "parkway", "court",
                      "common", "commons", "place"]

    # Helper function to check if a name contains unwanted terms
    def is_unwanted(name: str) -> bool:
        lower_name = name.lower()
        return any(word in lower_name for word in unwanted_words)

    # Calculate bounding box for the search area based on the max distance
    lat_delta = max_distance / 69.0
    lon_delta = max_distance / (69.0 * math.cos(math.radians(lat)))
    min_lat = lat - lat_delta
    max_lat = lat + lat_delta
    min_lon = lng - lon_delta
    max_lon = lng + lon_delta
    bbox = f"{min_lon},{min_lat},{max_lon},{max_lat}"
    print("Calculated bounding box:", bbox)

    # Initialize a dictionary to store candidate landmarks for each category
    candidates_per_category = {cat: [] for cat in categories}

    # Perform API requests for each category's landmarks
    for cat in categories:
        alternatives = query_mapping.get(cat, [cat])  # Use the category name or mapped queries
        for search_query in alternatives:
            encoded_query = urllib.parse.quote(search_query)  # URL encode the search term
            url = (
                f"https://api.mapbox.com/search/searchbox/v1/forward?q={encoded_query}"
                f"&types=poi&proximity={lng},{lat}&bbox={bbox}&limit=10"
                f"&access_token={MAPBOX_PUBLIC_TOKEN}"
            )
            print(f"\nRequesting for category '{cat}' using keyword '{search_query}' (encoded: '{encoded_query}'):")
            print("Request URL:", url)

            # Make the request to the Mapbox API
            res = requests.get(url)
            if res.status_code != 200:
                print(f"Error fetching for '{search_query}': {res.status_code}")
                continue  # Skip to the next query if the request fails

            result = res.json()
            features = result.get("features", [])
            print(f"Found {len(features)} features for keyword '{search_query}'")

            # Process the returned features
            for feat in features:
                coords = feat.get("geometry", {}).get("coordinates")
                if not coords or len(coords) < 2:
                    continue  # Skip if coordinates are invalid
                f_lon = float(coords[0])
                f_lat = float(coords[1])

                # Calculate the distance between the current point and the landmark
                dist = haversine_distance(lat, lng, f_lat, f_lon)
                if dist > max_distance:
                    continue  # Skip if the landmark is too far away

                prop = feat.get("properties", {})
                name = prop.get("name", search_query)

                # Skip unwanted landmarks based on their name
                if is_unwanted(name):
                    continue

                # Get the relevance score or default to 0 if not present
                try:
                    relevance = float(prop.get("relevance", 0))
                except (TypeError, ValueError):
                    relevance = 0

                # Create a candidate landmark and add it to the list
                candidate = {
                    "name": name,
                    "lat": f_lat,
                    "long": f_lon,
                    "type": "Park" if cat == "Parks" else cat,  # Special case for "Parks"
                    "relevance": relevance
                }
                candidates_per_category[cat].append(candidate)

    # Select the best candidates for each category based on relevance and category counts
    selected_candidates = []
    for cat in categories:
        desired = int(category_counts.get(cat, 1))
        cat_candidates = candidates_per_category.get(cat, [])
        random.shuffle(cat_candidates)  # Shuffle to introduce randomness
        selected = sorted(cat_candidates[:desired], key=lambda x: x["relevance"], reverse=True)  # Sort by relevance
        selected_candidates.extend(selected)
        print(f"Selected for {cat} (desired {desired}):", selected)

    # Ensure uniqueness of landmarks, keeping the one with the highest relevance
    unique = {}
    for c in selected_candidates:
        key = (c["name"], c["type"])
        if key in unique:
            if c["relevance"] > unique[key]["relevance"]:
                unique[key] = c
        else:
            unique[key] = c
    selected_candidates = list(unique.values())

    # Limit the number of destinations if necessary
    if len(selected_candidates) > num_destinations:
        random.shuffle(selected_candidates)
        selected_candidates = selected_candidates[:num_destinations]

    # Remove the "relevance" field from the final result
    for candidate in selected_candidates:
        candidate.pop("relevance", None)

    # Log and return the final selected landmarks
    print("\nFinal landmarks returned:", selected_candidates)
    return selected_candidates


# finally, generate the trip
@router.post("/generate_trip", response_model=TripResponse)
def generate_trip(
        group: int,
        uid: str,
        location_lat: float,
        location_long: float,
        landmark_types: str = "",
        max_distance: float = 50.0,
        num_destinations: int = 0,
        category_counts: str = "{}",
        db: Session = Depends(get_db)
):
    # Get landmarks FIRST
    landmarks = get_landmarks(location_lat, location_long, landmark_types, max_distance, num_destinations,
                              category_counts)

    new_trip = Trip(
        group=group,
        uid=uid,
        location_lat=location_lat,
        location_long=location_long,
        landmarks=landmarks,
        num_destinations=num_destinations
    )

    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)

    return TripResponse(
        trip_id=new_trip.tid,
        group=new_trip.group,
        uid=new_trip.uid,
        location_lat=new_trip.location_lat,
        location_long=new_trip.location_long,
        landmarks=landmarks,
        num_destinations=num_destinations
    )


# custom create
@router.post("/custom_trip", response_model=TripResponse)
def create_custom_trip(
        group: int,
        uid: str,
        landmarks: list[dict],
        num_destinations: int,
        db: Session = Depends(get_db)
):
    new_trip = Trip(
        group=group,
        uid=uid,
        location_lat=landmarks[0]["lat"],  # Just pick first landmark for rough center
        location_long=landmarks[0]["long"],
        landmarks=landmarks,  # save all landmark dicts directly
        num_destinations=num_destinations
    )

    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)

    return TripResponse(
        trip_id=new_trip.tid,
        group=new_trip.group,
        uid=new_trip.uid,
        location_lat=new_trip.location_lat,
        location_long=new_trip.location_long,
        landmarks=landmarks,
        num_destinations=num_destinations
    )


# trips by uid
@router.get("/list_trips_by_user/{uid}", response_model=List[TripSummaryResponse])
def list_trips_by_user(uid: str, db: Session = Depends(get_db)):
    trips = db.query(Trip).filter(Trip.uid == uid).all()
    if not trips:
        return []
    return [
        TripSummaryResponse(
            trip_id=trip.tid,
            group=trip.group,
            location_lat=trip.location_lat,
            location_long=trip.location_long,
            num_destinations=trip.num_destinations
        )
        for trip in trips
    ]


# get trip
@router.get("/get_trip/{trip_id}", response_model=TripResponse)
def get_trip(trip_id: int, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.tid == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    return TripResponse(
        trip_id=trip.tid,
        group=trip.group,
        uid=trip.uid,
        location_lat=trip.location_lat,
        location_long=trip.location_long,
        landmarks=trip.landmarks,
        num_destinations=trip.num_destinations
    )


# update trip
@router.put("/update_trip/{trip_id}", response_model=TripResponse)
def update_trip(
        trip_id: int,
        landmarks: List[dict],
        db: Session = Depends(get_db)
):
    trip = db.query(Trip).filter(Trip.tid == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    # Convert any Landmark objects to plain dicts if necessary
    updated_landmarks = []
    for l in landmarks:
        if isinstance(l, dict):
            updated_landmarks.append({
                "name": l["name"],
                "lat": l["lat"],
                "long": l["long"],
                "type": l.get("type", "custom")
            })
        else:  # If still a Landmark object
            updated_landmarks.append({
                "name": l.name,
                "lat": l.lat,
                "long": l.long,
                "type": l.type
            })

    trip.landmarks = updated_landmarks
    db.commit()
    db.refresh(trip)

    return TripResponse(
        trip_id=trip.tid,
        group=trip.group,
        uid=trip.uid,
        location_lat=trip.location_lat,
        location_long=trip.location_long,
        landmarks=trip.landmarks
    )


# delete trip
@router.delete("/delete_trip/{trip_id}")
def delete_trip(trip_id: int, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.tid == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    db.delete(trip)
    db.commit()
    return {"message": "Trip deleted successfully"}


# trips by group
@router.get("/list_trips_by_group/{gid}", response_model=list[AlternateTripResponse])
def list_trips_by_group(gid: int, db: Session = Depends(get_db)):
    return db.query(Trip).filter(Trip.group == gid).all()
