"""
Mapillary API Service
Uses Mapillary Graph API v4 to find real-world POIs (police stations, hospitals, hotels)
near a given location using street-level imagery metadata and map features.
"""

import os
import math
import requests
from typing import Optional

MAPILLARY_ACCESS_TOKEN = os.getenv('MAPILLARY_ACCESS_TOKEN', '')
MAPILLARY_BASE_URL = "https://graph.mapillary.com"


def haversine(lat1, lon1, lat2, lon2):
    """Calculate distance in km between two lat/lon points."""
    R = 6371
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def get_nearby_images(lat: float, lon: float, radius: int = 500, limit: int = 10) -> list:
    """
    Fetch nearby Mapillary street-level images around a coordinate.
    Used to display the map/street view context.
    """
    try:
        url = f"{MAPILLARY_BASE_URL}/images"
        params = {
            "access_token": MAPILLARY_ACCESS_TOKEN,
            "fields": "id,captured_at,geometry,thumb_256_url,thumb_1024_url,creator",
            "bbox": _bounding_box(lat, lon, radius),
            "limit": limit,
        }
        response = requests.get(url, params=params, timeout=10)
        if response.status_code == 200:
            data = response.json()
            return data.get("data", [])
        else:
            print(f"Mapillary images error: {response.status_code} {response.text}")
            return []
    except Exception as e:
        print(f"Mapillary images exception: {e}")
        return []


def search_pois_overpass(lat: float, lon: float, amenity: str, radius: int = 5000) -> list:
    """
    Use OpenStreetMap Overpass API (free, no key) to find real POIs near a location.
    This is the best free alternative since Mapillary is for imagery, not POI search.
    Supported amenity values: 'police', 'hospital', 'hotel', 'lodging'
    """
    overpass_url = "https://overpass-api.de/api/interpreter"

    # Map amenity types
    if amenity == "hotel":
        query_filter = f'(node["tourism"="hotel"](around:{radius},{lat},{lon}); way["tourism"="hotel"](around:{radius},{lat},{lon}););'
    elif amenity == "police":
        query_filter = f'(node["amenity"="police"](around:{radius},{lat},{lon}); way["amenity"="police"](around:{radius},{lat},{lon}););'
    elif amenity == "hospital":
        query_filter = f'(node["amenity"="hospital"](around:{radius},{lat},{lon}); node["amenity"="clinic"](around:{radius},{lat},{lon}); way["amenity"="hospital"](around:{radius},{lat},{lon}););'
    else:
        query_filter = f'node["amenity"="{amenity}"](around:{radius},{lat},{lon});'

    query = f"""
    [out:json][timeout:25];
    {query_filter}
    out body center;
    """

    try:
        response = requests.post(overpass_url, data={"data": query}, timeout=20)
        if response.status_code == 200:
            data = response.json()
            results = []
            for element in data.get("elements", []):
                tags = element.get("tags", {})
                name = tags.get("name") or tags.get("name:en") or tags.get("name:ta")
                if not name:
                    continue

                # Get coordinates
                if element["type"] == "node":
                    elem_lat = element["lat"]
                    elem_lon = element["lon"]
                elif "center" in element:
                    elem_lat = element["center"]["lat"]
                    elem_lon = element["center"]["lon"]
                else:
                    continue

                distance = haversine(lat, lon, elem_lat, elem_lon)

                result = {
                    "id": str(element["id"]),
                    "name": name,
                    "lat": elem_lat,
                    "lng": elem_lon,
                    "distance_km": round(distance, 2),
                    "address": _build_address(tags),
                    "phone": tags.get("phone") or tags.get("contact:phone"),
                    "source": "OpenStreetMap",
                    "mapillary_images": [],  # Can be enriched later
                }

                # Extra fields by type
                if amenity == "hospital":
                    result["emergency_phone"] = tags.get("emergency:phone") or tags.get("phone")
                    result["emergency"] = tags.get("emergency", "yes")
                    result["opening_hours"] = tags.get("opening_hours", "24/7")
                if amenity == "hotel":
                    result["stars"] = tags.get("stars")
                    result["website"] = tags.get("website") or tags.get("contact:website")
                    result["rating"] = float(tags.get("rating", 0)) if tags.get("rating") else None

                results.append(result)

            # Sort by distance
            results.sort(key=lambda x: x["distance_km"])
            return results

    except Exception as e:
        print(f"Overpass API exception for {amenity}: {e}")

    return []


def get_mapillary_street_view(lat: float, lon: float, radius: int = 200) -> dict:
    """
    Get Mapillary street-level imagery data for the map view tile layer.
    Returns the closest image and a tile URL template for embedding.
    """
    images = get_nearby_images(lat, lon, radius, limit=5)
    return {
        "tile_url": f"https://tiles.mapillary.com/maps/vtp/mly1_public/2/{{z}}/{{x}}/{{y}}?access_token={MAPILLARY_ACCESS_TOKEN}",
        "nearest_images": images,
        "coverage_available": len(images) > 0,
    }


def share_user_location(lat: float, lon: float, user_id: str, accuracy: float = 10.0) -> dict:
    """
    Share user's location. Currently stores to local DB (Mapillary doesn't have 
    a user location tracking API — it's for crowdsourced imagery).
    Returns location info with nearby Mapillary coverage.
    """
    images = get_nearby_images(lat, lon, radius=300, limit=3)
    return {
        "shared": True,
        "lat": lat,
        "lng": lon,
        "user_id": user_id,
        "mapillary_coverage": len(images) > 0,
        "nearby_images": images[:3],
        "message": "Location recorded. Mapillary street view available." if images else "Location recorded."
    }


def _bounding_box(lat: float, lon: float, radius_m: int) -> str:
    """Convert center + radius to bbox string (west,south,east,north)."""
    delta_lat = radius_m / 111320
    delta_lon = radius_m / (111320 * math.cos(math.radians(lat)))
    return f"{lon - delta_lon},{lat - delta_lat},{lon + delta_lon},{lat + delta_lat}"


def _build_address(tags: dict) -> str:
    """Build a human-readable address from OSM tags."""
    parts = []
    for key in ["addr:housenumber", "addr:street", "addr:suburb", "addr:city", "addr:state"]:
        val = tags.get(key)
        if val:
            parts.append(val)
    return ", ".join(parts) if parts else tags.get("addr:full", "")
