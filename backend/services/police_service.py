"""
Police Service
Handle police station alerts and emergency dispatch
"""

from database.db import get_db_connection
from services.location_service import get_nearest_locations

def alert_nearest_police(location):
    """
    Alert nearest police station about emergency
    
    Args:
        location: Dict with 'lat' and 'lng'
    
    Returns:
        dict: Nearest police station info
    """
    try:
        # Get all police stations from database
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM police_stations")
        all_stations = cursor.fetchall()
        conn.close()
        
        if not all_stations:
            return {
                'name': 'Emergency Dispatch',
                'phone': '100',
                'distance_km': 0,
                'eta_minutes': 6
            }
        
        # Convert to list of dicts
        stations_list = [dict(station) for station in all_stations]
        
        # Find nearest station
        nearest_stations = get_nearest_locations(
            location['lat'],
            location['lng'],
            stations_list,
            limit=1
        )
        
        if nearest_stations:
            nearest = nearest_stations[0]
            
            # In production, actually send alert to police station
            # For now, just return info
            print(f"[POLICE ALERT] Nearest station: {nearest['name']}")
            print(f"[POLICE ALERT] Distance: {nearest['distance_km']} km")
            
            # Estimate ETA (assuming police response time)
            base_eta = 3  # Base response time in minutes
            travel_eta = int(nearest['distance_km'] * 2)  # Assume 2 min per km
            total_eta = min(base_eta + travel_eta, 15)  # Cap at 15 minutes
            
            return {
                'name': nearest['name'],
                'address': nearest.get('address', ''),
                'phone': nearest.get('phone', '100'),
                'distance_km': nearest['distance_km'],
                'eta_minutes': total_eta
            }
        else:
            # Fallback to emergency number
            return {
                'name': 'Emergency Dispatch',
                'phone': '100',
                'distance_km': 0,
                'eta_minutes': 6
            }
            
    except Exception as e:
        print(f"Error alerting police: {e}")
        return {
            'name': 'Emergency Services',
            'phone': '100',
            'eta_minutes': 6
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