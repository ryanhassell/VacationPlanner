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


def haversine_distance(lat1, lon1, lat2, lon2):
    R = 3958.8
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = math.sin(d_lat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def get_landmarks(lat: float, lng: float, landmark_types: str, max_distance: float, num_destinations: int, category_counts_str: str):
    print("get_landmarks() called with:")
    print("  lat =", lat, "lng =", lng)
    print("  landmark_types =", landmark_types)
    print("  max_distance =", max_distance)
    print("  num_destinations =", num_destinations)
    print("  category_counts_str =", category_counts_str)

    categories = [cat.strip() for cat in landmark_types.split(",") if cat.strip()]
    print("Parsed categories:", categories)

    try:
        category_counts = json.loads(category_counts_str)
    except Exception as e:
        print("Error parsing category_counts; defaulting each category to 1:", e)
        category_counts = {cat: 1 for cat in categories}

    for cat in categories:
        if cat not in category_counts:
            category_counts[cat] = 1
    print("Parsed category_counts:", category_counts)

    query_mapping = {
        "Food": ["restaurant", "cafe", "diner", "bistro", "eatery", "food", "coffee shop", "grill", "pho", "ramen", "yakitori", "la piazza"],
        "Parks": ["garden", "botanical garden", "green space", "nature reserve", "trail", "peak", "falls", "orchard"],
        "Historic": ["historic building", "heritage site", "historical site", "landmark", "old building", "monumental"],
        "Memorials": ["memorial", "monument", "commemorative", "statue", "cenotaph", "tribute"],
        "Museums": ["museum", "art gallery", "exhibit", "history museum", "science museum", "cultural center"],
        "Art": ["art gallery", "exhibit", "showcase", "gallery", "art center", "art museum", "creative space"],
        "Entertainment": ["cinema", "movie theater", "theater", "amusement", "entertainment", "arcade", "playhouse", "live performance"]
    }

    unwanted_words = ["street", "drive", "way", "avenue", "road", "development", "developments", "residential", "commercial", "office", "plaza", "mall", "complex", "apartment", "lane", "parkway", "court", "common", "commons", "place"]

    def is_unwanted(name: str) -> bool:
        lower_name = name.lower()
        return any(word in lower_name for word in unwanted_words)

    lat_delta = max_distance / 69.0
    lon_delta = max_distance / (69.0 * math.cos(math.radians(lat)))
    min_lat = lat - lat_delta
    max_lat = lat + lat_delta
    min_lon = lng - lon_delta
    max_lon = lng + lon_delta
    bbox = f"{min_lon},{min_lat},{max_lon},{max_lat}"
    print("Calculated bounding box:", bbox)

    candidates_per_category = {cat: [] for cat in categories}

    for cat in categories:
        alternatives = query_mapping.get(cat, [cat])
        for search_query in alternatives:
            encoded_query = urllib.parse.quote(search_query)
            url = (
                f"https://api.mapbox.com/search/searchbox/v1/forward?q={encoded_query}"
                f"&types=poi&proximity={lng},{lat}&bbox={bbox}&limit=10"
                f"&access_token={MAPBOX_PUBLIC_TOKEN}"
            )
            print(f"\nRequesting for category '{cat}' using keyword '{search_query}' (encoded: '{encoded_query}'):")
            print("Request URL:", url)
            res = requests.get(url)
            if res.status_code != 200:
                print(f"Error fetching for '{search_query}': {res.status_code}")
                continue
            result = res.json()
            features = result.get("features", [])
            print(f"Found {len(features)} features for keyword '{search_query}'")
            for feat in features:
                coords = feat.get("geometry", {}).get("coordinates")
                if not coords or len(coords) < 2:
                    continue
                f_lon = float(coords[0])
                f_lat = float(coords[1])
                dist = haversine_distance(lat, lng, f_lat, f_lon)
                if dist > max_distance:
                    continue
                prop = feat.get("properties", {})
                name = prop.get("name", search_query)
                if is_unwanted(name):
                    continue
                try:
                    relevance = float(prop.get("relevance", 0))
                except (TypeError, ValueError):
                    relevance = 0
                candidate = {
                    "name": name,
                    "lat": f_lat,
                    "long": f_lon,
                    "type": "Park" if cat == "Parks" else cat,
                    "relevance": relevance
                }
                candidates_per_category[cat].append(candidate)

    selected_candidates = []
    for cat in categories:
        desired = int(category_counts.get(cat, 1))
        cat_candidates = candidates_per_category.get(cat, [])
        random.shuffle(cat_candidates)  # <-- Add randomness to candidates
        selected = sorted(cat_candidates[:desired], key=lambda x: x["relevance"], reverse=True)  # Pick best of random
        selected_candidates.extend(selected)
        print(f"Selected for {cat} (desired {desired}):", selected)

    unique = {}
    for c in selected_candidates:
        key = (c["name"], c["type"])
        if key in unique:
            if c["relevance"] > unique[key]["relevance"]:
                unique[key] = c
        else:
            unique[key] = c
    selected_candidates = list(unique.values())

    if len(selected_candidates) > num_destinations:
        random.shuffle(selected_candidates)
        selected_candidates = selected_candidates[:num_destinations]

    for candidate in selected_candidates:
        candidate.pop("relevance", None)

    print("\nFinal landmarks returned:", selected_candidates)
    return selected_candidates



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


@router.delete("/delete_trip/{trip_id}")
def delete_trip(trip_id: int, db: Session = Depends(get_db)):
    trip = db.query(Trip).filter(Trip.tid == trip_id).first()
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")

    db.delete(trip)
    db.commit()
    return {"message": "Trip deleted successfully"}


@router.get("/list_trips_by_group/{gid}", response_model=list[AlternateTripResponse])
def list_trips_by_group(gid: int, db: Session = Depends(get_db)):
    return db.query(Trip).filter(Trip.group == gid).all()

