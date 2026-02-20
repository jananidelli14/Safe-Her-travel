"""
Resources Routes - Merged Data (DB + OSM)
"""

from flask import Blueprint, request, jsonify
from services.mapillary_service import search_pois_overpass, haversine
from database.db import get_db_connection

resources_bp = Blueprint('resources', __name__)


def get_db_resources(table, lat, lng, radius_km):
    """Fetch resources from local SQLite database."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(f"SELECT * FROM {table}")
        rows = cursor.fetchall()
        conn.close()

        results = []
        for row in rows:
            dist = haversine(lat, lng, row['latitude'], row['longitude'])
            if dist <= radius_km:
                d = dict(row)
                d['distance_km'] = round(dist, 2)
                d['source'] = 'Local Database'
                results.append(d)
        return results
    except Exception as e:
        print(f"DB Error fetching {table}: {e}")
        return []


@resources_bp.route('/police-stations', methods=['GET'])
def get_police_stations():
    try:
        lat = float(request.args.get('lat'))
        lng = float(request.args.get('lng'))
        radius_m = int(request.args.get('radius', 10000))
        radius_km = radius_m / 1000

        # 1. Try Live OSM data
        stations = search_pois_overpass(lat, lng, 'police', radius_m)
        
        # 2. Add local DB data (fallback/seed)
        db_stations = get_db_resources('police_stations', lat, lng, radius_km)
        
        # Merge and remove duplicates by ID or name
        merged = {s['name'].lower(): s for s in db_stations}
        for s in stations:
            merged[s['name'].lower()] = s
            
        final_list = sorted(merged.values(), key=lambda x: x['distance_km'])

        return jsonify({
            'success': True,
            'count': len(final_list),
            'resources': final_list,
            'source': 'Merged (OSM + DB)',
            'user_location': {'lat': lat, 'lng': lng}
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@resources_bp.route('/hospitals', methods=['GET'])
def get_hospitals():
    try:
        lat = float(request.args.get('lat'))
        lng = float(request.args.get('lng'))
        radius_m = int(request.args.get('radius', 10000))
        radius_km = radius_m / 1000

        # 1. Try Live OSM data
        hospitals = search_pois_overpass(lat, lng, 'hospital', radius_m)
        
        # 2. Add local DB data (fallback/seed)
        db_hospitals = get_db_resources('hospitals', lat, lng, radius_km)
        
        # Merge
        merged = {h['name'].lower(): h for h in db_hospitals}
        for h in hospitals:
            merged[h['name'].lower()] = h
            
        final_list = sorted(merged.values(), key=lambda x: x['distance_km'])

        return jsonify({
            'success': True,
            'count': len(final_list),
            'resources': final_list,
            'source': 'Merged (OSM + DB)',
            'user_location': {'lat': lat, 'lng': lng}
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@resources_bp.route('/emergency-contacts', methods=['GET'])
def get_emergency_contacts():
    return jsonify({
        'success': True,
        'contacts': {
            'police': '100',
            'national_emergency': '112',
            'ambulance': '108',
            'women_helpline': '1091',
            'child_helpline': '1098',
            'fire': '101',
            'tn_police_control': '044-23452323',
            'tn_women_helpline': '044-28592750',
        }
    }), 200