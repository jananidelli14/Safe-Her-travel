"""
Resources Routes
Police stations, hospitals, and emergency services in Tamil Nadu
"""

from flask import Blueprint, request, jsonify
from database.db import get_db_connection
from services.location_service import calculate_distance

resources_bp = Blueprint('resources', __name__)

@resources_bp.route('/police-stations', methods=['GET'])
def get_police_stations():
    """
    Get nearby police stations
    Query params: lat, lng, radius (in km, default 10)
    """
    try:
        lat = float(request.args.get('lat', 13.0827))
        lng = float(request.args.get('lng', 80.2707))
        radius = float(request.args.get('radius', 10))
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM police_stations")
        all_stations = cursor.fetchall()
        conn.close()
        
        # Calculate distances and filter by radius
        nearby_stations = []
        for station in all_stations:
            distance = calculate_distance(
                lat, lng,
                station['latitude'], station['longitude']
            )
            
            if distance <= radius:
                station_dict = dict(station)
                station_dict['distance_km'] = round(distance, 2)
                nearby_stations.append(station_dict)
        
        # Sort by distance
        nearby_stations.sort(key=lambda x: x['distance_km'])
        
        return jsonify({
            'success': True,
            'count': len(nearby_stations),
            'stations': nearby_stations[:10]  # Return top 10
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@resources_bp.route('/hospitals', methods=['GET'])
def get_hospitals():
    """Get nearby hospitals"""
    try:
        lat = float(request.args.get('lat', 13.0827))
        lng = float(request.args.get('lng', 80.2707))
        radius = float(request.args.get('radius', 10))
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM hospitals")
        all_hospitals = cursor.fetchall()
        conn.close()
        
        nearby_hospitals = []
        for hospital in all_hospitals:
            distance = calculate_distance(
                lat, lng,
                hospital['latitude'], hospital['longitude']
            )
            
            if distance <= radius:
                hospital_dict = dict(hospital)
                hospital_dict['distance_km'] = round(distance, 2)
                nearby_hospitals.append(hospital_dict)
        
        nearby_hospitals.sort(key=lambda x: x['distance_km'])
        
        return jsonify({
            'success': True,
            'count': len(nearby_hospitals),
            'hospitals': nearby_hospitals[:10]
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@resources_bp.route('/emergency-numbers', methods=['GET'])
def get_emergency_numbers():
    """Get all emergency contact numbers"""
    emergency_numbers = {
        'police': {
            'number': '100',
            'name': 'TN Police',
            'description': 'Tamil Nadu Police Emergency'
        },
        'ambulance': {
            'number': '108',
            'name': 'Ambulance',
            'description': 'Emergency Medical Services'
        },
        'national_emergency': {
            'number': '112',
            'name': 'National Emergency',
            'description': 'National Emergency Response'
        },
        'fire': {
            'number': '101',
            'name': 'Fire Service',
            'description': 'Fire and Rescue Services'
        },
        'women_helpline': {
            'number': '1091',
            'name': 'Women Helpline',
            'description': 'Women in Distress'
        },
        'child_helpline': {
            'number': '1098',
            'name': 'Child Helpline',
            'description': 'Child Emergency Services'
        }
    }
    
    return jsonify({
        'success': True,
        'emergency_numbers': emergency_numbers
    }), 200

@resources_bp.route('/safe-zones', methods=['GET'])
def get_safe_zones():
    """Get safe zones (well-lit public areas, 24/7 establishments)"""
    try:
        lat = float(request.args.get('lat', 13.0827))
        lng = float(request.args.get('lng', 80.2707))
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM safe_zones")
        all_zones = cursor.fetchall()
        conn.close()
        
        nearby_zones = []
        for zone in all_zones:
            distance = calculate_distance(
                lat, lng,
                zone['latitude'], zone['longitude']
            )
            
            zone_dict = dict(zone)
            zone_dict['distance_km'] = round(distance, 2)
            nearby_zones.append(zone_dict)
        
        nearby_zones.sort(key=lambda x: x['distance_km'])
        
        return jsonify({
            'success': True,
            'safe_zones': nearby_zones[:10]
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500