import math
import urllib

import requests
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from app.global_vars import DB_USERNAME, DB_PASSWORD, DB_HOST, DB_NAME, MAPBOX_PUBLIC_TOKEN
from app.models import Trip, Base
from schemas.trip import TripResponse

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
    """Returns distance in miles between two lat/long points using the Haversine formula."""
    R = 3958.8  # Earth radius in miles
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = math.sin(d_lat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def get_landmarks(lat: float, lng: float, landmark_types: str, max_distance: float, num_destinations: int):
    """
    For each selected category, searches for nearby places using Mapbox Places API within a bounding box defined by max_distance.
    It gathers valid candidates (with a relevance above a threshold, passing unwanted words and distance checks)
    and selects the best candidate (highest relevance) per category.
    Then, if the total number is less than num_destinations, additional candidates from all categories (sorted by relevance)
    are added until the desired number is reached. Finally, the resulting list is sorted by relevance and trimmed.
    """
    print("get_landmarks() called with:")
    print("  lat =", lat, "lng =", lng)
    print("  landmark_types =", landmark_types)
    print("  max_distance =", max_distance)
    print("  num_destinations =", num_destinations)

    # Parse the comma-separated categories.
    categories = [cat.strip() for cat in landmark_types.split(",") if cat.strip()]
    print("Parsed categories:", categories)

    # Expanded mapping: category -> list of alternative keywords.
    query_mapping = {
        "Food": [
            "restaurant", "cafe", "diner", "bistro", "eatery", "food", "coffee shop"
        ],
        "Parks": [
            "park", "botanical garden", "green space", "garden", "nature reserve", "public park", "urban park"
        ],
        "Historic": [
            "historic building", "heritage site", "historical site", "landmark", "old building", "monumental"
        ],
        "Memorials": [
            "memorial", "monument", "commemorative", "statue", "cenotaph", "tribute"
        ],
        "Museums": [
            "museum", "art gallery", "exhibit", "history museum", "science museum", "cultural center"
        ],
        "Art": [
            "art gallery", "exhibit", "showcase", "gallery", "art center", "art museum", "creative space"
        ],
        "Entertainment": [
            "cinema", "movie theater", "theater", "amusement", "entertainment", "arcade", "playhouse", "live performance"
        ]
    }

    # Expanded list of unwanted words (case-insensitive)
    unwanted_words = [
        "street", "drive", "way", "avenue",
        "development", "developments", "residential",
        "commercial", "office", "plaza", "mall", "complex", "apartment", "lane", "parkway", "court", "cm"
    ]

    def is_unwanted(name: str) -> bool:
        lower_name = name.lower()
        return any(word in lower_name for word in unwanted_words)

    # Define a relevance threshold (0.0 to 1.0)
    RELEVANCE_THRESHOLD = 0.7

    # Calculate bounding box using an approximate conversion (1 degree latitude ~ 69 miles)
    lat_delta = max_distance / 69.0
    lon_delta = max_distance / (69.0 * math.cos(math.radians(lat)))
    min_lat = lat - lat_delta
    max_lat = lat + lat_delta
    min_lon = lng - lon_delta
    max_lon = lng + lon_delta
    bbox = f"{min_lon},{min_lat},{max_lon},{max_lat}"
    print("Calculated bounding box:", bbox)

    best_per_category = {}   # Key: category, Value: candidate dict.
    extra_candidates = []    # All candidates that pass filters.

    # Process each category.
    for cat in categories:
        alternatives = query_mapping.get(cat, [cat])
        for search_query in alternatives:
            encoded_query = urllib.parse.quote(search_query)
            url = (
                f"https://api.mapbox.com/geocoding/v5/mapbox.places/{encoded_query}.json"
                f"?proximity={lng},{lat}"
                f"&bbox={bbox}"
                f"&limit=50"
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
                coords = feat.get("center", [])
                if not coords or len(coords) < 2:
                    continue
                relevance = feat.get("relevance", 0)
                if relevance < RELEVANCE_THRESHOLD:
                    continue
                f_lon = float(coords[0])
                f_lat = float(coords[1])
                dist = haversine_distance(lat, lng, f_lat, f_lon)
                if dist > max_distance:
                    continue
                name = feat.get("text", search_query)
                if is_unwanted(name):
                    continue
                candidate = {
                    "name": name,
                    "lat": f_lat,
                    "long": f_lon,
                    "type": "Park" if cat == "Parks" else cat,
                    "relevance": relevance
                }
                # Add candidate to extra pool.
                extra_candidates.append(candidate)
                # For best candidate per category: update if not set or if this candidate has higher relevance.
                if cat not in best_per_category or candidate["relevance"] > best_per_category[cat]["relevance"]:
                    best_per_category[cat] = candidate

    print(f"\nBest candidates per category: {best_per_category}")
    print(f"Total extra candidates collected: {len(extra_candidates)}")

    # Start with one candidate per category.
    selected_candidates = list(best_per_category.values())

    # If we need more candidates to reach num_destinations, add additional ones from extra_candidates
    # that are not already in selected_candidates.
    if len(selected_candidates) < num_destinations:
        # Exclude already selected ones (by name and type).
        selected_keys = {(c["name"], c["type"]) for c in selected_candidates}
        additional = [c for c in extra_candidates if (c["name"], c["type"]) not in selected_keys]
        # Sort additional candidates by relevance.
        additional.sort(key=lambda x: x["relevance"], reverse=True)
        # Append additional candidates until reaching num_destinations.
        while len(selected_candidates) < num_destinations and additional:
            selected_candidates.append(additional.pop(0))

    # Finally, if more than desired, sort all selected candidates and trim.
    selected_candidates.sort(key=lambda x: x["relevance"], reverse=True)
    if len(selected_candidates) > num_destinations:
        selected_candidates = selected_candidates[:num_destinations]

    # Remove the temporary 'relevance' key before returning.
    for candidate in selected_candidates:
        candidate.pop("relevance", None)

    print("\nFinal landmarks returned:", selected_candidates)
    return selected_candidates

@router.post("/generate_trip", response_model=TripResponse)
def generate_trip(
        group: int,
        location_lat: float,
        location_long: float,
        landmark_types: str = "",
        max_distance: float = 10.0,
        num_destinations: int = 1,
        db: Session = Depends(get_db)
):
    # Create trip in DB
    new_trip = Trip(
        group=group,
        location_lat=location_lat,
        location_long=location_long
    )
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)

    # Get landmarks using our improved algorithm.
    landmarks = get_landmarks(location_lat, location_long, landmark_types, max_distance, num_destinations)

    return TripResponse(
        trip_id=new_trip.tid,
        group=new_trip.group,
        location_lat=new_trip.location_lat,
        location_long=new_trip.location_long,
        landmarks=landmarks
    )
