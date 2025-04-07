import math
import urllib
import json
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
    a = math.sin(d_lat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def get_landmarks(lat: float, lng: float, landmark_types: str, max_distance: float, num_destinations: int, category_counts_str: str):
    """
    For each selected category, performs a forward search using the Mapbox Search Box API’s forward endpoint (with types=poi)
    and gathers candidates within max_distance (miles). For each category, it selects up to the desired number as specified in
    category_counts (a dict mapping category name to count; if a category isn’t specified, default is 1). Duplicates are removed,
    and the combined candidate list is sorted by relevance (highest first) and trimmed to the overall total.
    """
    print("get_landmarks() called with:")
    print("  lat =", lat, "lng =", lng)
    print("  landmark_types =", landmark_types)
    print("  max_distance =", max_distance)
    print("  num_destinations =", num_destinations)
    print("  category_counts_str =", category_counts_str)

    # Parse comma-separated categories.
    categories = [cat.strip() for cat in landmark_types.split(",") if cat.strip()]
    print("Parsed categories:", categories)

    # Parse category_counts JSON string (expected to be a dict: { "Food": 2, "Parks": 1, ... })
    try:
        category_counts = json.loads(category_counts_str)
    except Exception as e:
        print("Error parsing category_counts; defaulting each category to 1:", e)
        category_counts = {cat: 1 for cat in categories}
    # Ensure each selected category has a count; default to 1.
    for cat in categories:
        if cat not in category_counts:
            category_counts[cat] = 1
    print("Parsed category_counts:", category_counts)

    # Mapping: category -> list of alternative keywords.
    query_mapping = {
        "Food": [
            "restaurant", "cafe", "diner", "bistro", "eatery", "food",
            "coffee shop", "grill", "pho", "ramen", "yakitori"
        ],
        "Parks": [
            "garden", "botanical garden", "green space", "nature reserve",
            "trail", "peak", "falls", "orchard"
        ],
        "Historic": [
            "historic building", "heritage site", "historical site",
            "landmark", "old building", "monumental"
        ],
        "Memorials": [
            "memorial", "monument", "commemorative", "statue",
            "cenotaph", "tribute"
        ],
        "Museums": [
            "museum", "art gallery", "exhibit", "history museum",
            "science museum", "cultural center"
        ],
        "Art": [
            "art gallery", "exhibit", "showcase", "gallery", "art center",
            "art museum", "creative space"
        ],
        "Entertainment": [
            "cinema", "movie theater", "theater", "amusement", "entertainment",
            "arcade", "playhouse", "live performance"
        ]
    }

    # Unwanted words (case-insensitive) to filter out.
    unwanted_words = [
        "street", "drive", "way", "avenue", "road",
        "development", "developments", "residential",
        "commercial", "office", "plaza", "mall", "complex", "apartment", "lane",
        "parkway", "court", "common", "commons", "place"
    ]
    def is_unwanted(name: str) -> bool:
        lower_name = name.lower()
        return any(word in lower_name for word in unwanted_words)

    # Calculate bounding box.
    lat_delta = max_distance / 69.0
    lon_delta = max_distance / (69.0 * math.cos(math.radians(lat)))
    min_lat = lat - lat_delta
    max_lat = lat + lat_delta
    min_lon = lng - lon_delta
    max_lon = lng + lon_delta
    bbox = f"{min_lon},{min_lat},{max_lon},{max_lat}"
    print("Calculated bounding box:", bbox)

    # We'll collect candidates per category in a dict.
    candidates_per_category = {cat: [] for cat in categories}

    # Process each category.
    for cat in categories:
        alternatives = query_mapping.get(cat, [cat])
        for search_query in alternatives:
            encoded_query = urllib.parse.quote(search_query)
            # Use the forward endpoint of the Search Box API with types=poi.
            url = (
                f"https://api.mapbox.com/search/searchbox/v1/forward?q={encoded_query}"
                f"&types=poi"
                f"&proximity={lng},{lat}"
                f"&bbox={bbox}"
                f"&limit=10"  # API limit must be 1-10.
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
                # Try to get relevance; if missing, default to 0.
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

    # Now, for each category, sort candidates by relevance descending and select up to the desired count.
    selected_candidates = []
    for cat in categories:
        desired = int(category_counts.get(cat, 1))
        cat_candidates = candidates_per_category.get(cat, [])
        cat_candidates.sort(key=lambda x: x["relevance"], reverse=True)
        selected = cat_candidates[:desired]
        selected_candidates.extend(selected)
        print(f"Selected for {cat} (desired {desired}):", selected)

    # Remove duplicates based on (name, type).
    unique = {}
    for c in selected_candidates:
        key = (c["name"], c["type"])
        if key in unique:
            if c["relevance"] > unique[key]["relevance"]:
                unique[key] = c
        else:
            unique[key] = c
    selected_candidates = list(unique.values())

    # If total exceeds overall requested num_destinations, trim by relevance descending.
    selected_candidates.sort(key=lambda x: x["relevance"], reverse=True)
    if len(selected_candidates) > num_destinations:
        selected_candidates = selected_candidates[:num_destinations]

    # Remove auxiliary keys.
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
        max_distance: float = 50.0,
        num_destinations: int = 1,
        category_counts: str = "{}",  # Expecting JSON string, e.g. '{"Food": 1, "Parks": 2}'
        db: Session = Depends(get_db)
):
    new_trip = Trip(
        group=group,
        location_lat=location_lat,
        location_long=location_long
    )
    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)

    landmarks = get_landmarks(location_lat, location_long, landmark_types, max_distance, num_destinations, category_counts)

    return TripResponse(
        trip_id=new_trip.tid,
        group=new_trip.group,
        location_lat=new_trip.location_lat,
        location_long=new_trip.location_long,
        landmarks=landmarks
    )
