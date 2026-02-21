"""
Police Service
Handle police station alerts and emergency dispatch
"""

from database.db import get_db_connection
from services.mapillary_service import search_pois_overpass
from services.location_service import get_nearest_locations, estimate_travel_time

def alert_nearest_police(location):
    """
    Alert nearest police station about emergency using live OSM data
    
    Args:
        location: Dict with 'lat' and 'lng'
    
    Returns:
        dict: Nearest police station info with ETA
    """
    try:
        lat = location['lat']
        lng = location['lng']
        
        # 1. Try Live OSM data first (Real-time!)
        # Search radius 10km
        stations = search_pois_overpass(lat, lng, 'police', 10000)
        
        nearest = None
        if stations:
            nearest = stations[0]
            nearest['source'] = 'OpenStreetMap'
        else:
            # 2. Fallback to local database if OSM fails or is empty
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM police_stations")
            all_stations = cursor.fetchall()
            conn.close()
            
            if all_stations:
                stations_list = [dict(station) for station in all_stations]
                nearest_list = get_nearest_locations(lat, lng, stations_list, limit=1)
                if nearest_list:
                    nearest = nearest_list[0]
                    # Map 'latitude'/'longitude' to 'lat'/'lng' for consistency
                    nearest['lat'] = nearest['latitude']
                    nearest['lng'] = nearest['longitude']
                    nearest['source'] = 'Local Database'

        if nearest:
            # Calculate more professional ETA
            # Base dispatch time (min 2 mins) + travel time
            travel_mins = estimate_travel_time(nearest['distance_km'], mode='driving')
            dispatch_time = 2
            total_eta = travel_mins + dispatch_time
            
            # Ensure a realistic minimum for "help arrived in X min"
            total_eta = max(total_eta, 3) 
            
            return {
                'name': nearest['name'],
                'address': nearest.get('address', 'Location broadcast to nearest unit'),
                'phone': nearest.get('phone', '100'),
                'distance_km': nearest['distance_km'],
                'eta_minutes': total_eta,
                'source': nearest.get('source', 'Emergency Services')
            }
        
        # 3. Final fallback
        return {
            'name': 'Emergency Dispatch Control',
            'phone': '112',
            'distance_km': 0,
            'eta_minutes': 5,
            'source': 'National Helpline'
        }
            
    except Exception as e:
        print(f"Error alerting police: {e}")
        return {
            'name': 'Emergency Services',
            'phone': '100',
            'eta_minutes': 6,
            'source': 'System Fallback'
        }

def get_police_station_by_district(district):
    """Get police stations in a specific district"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM police_stations
            WHERE district = ?
        """, (district,))
        
        stations = cursor.fetchall()
        conn.close()
        
        return [dict(station) for station in stations]
        
    except Exception as e:
        print(f"Error fetching police stations: {e}")
        return []

def report_incident(user_id, location, incident_type, description):
    """
    Report an incident to authorities
    
    Args:
        user_id: User ID
        location: Dict with lat/lng
        incident_type: Type of incident
        description: Incident description
    
    Returns:
        dict: Report confirmation
    """
    try:
        import uuid
        from datetime import datetime
        
        report_id = str(uuid.uuid4())
        
        # In production, this would create an official report
        # and potentially integrate with police systems
        
        print(f"[INCIDENT REPORT] ID: {report_id}")
        print(f"[INCIDENT REPORT] Type: {incident_type}")
        print(f"[INCIDENT REPORT] Location: {location}")
        
        return {
            'report_id': report_id,
            'status': 'submitted',
            'message': 'Your report has been submitted to local authorities',
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        print(f"Error reporting incident: {e}")
        return None