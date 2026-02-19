"""
Resources Routes - Real Data via OpenStreetMap + Mapillary
Replaces synthetic SQLite dataset with live location-aware POI data.
"""

from flask import Blueprint, request, jsonify
from services.mapillary_service import search_pois_overpass, get_mapillary_street_view, share_user_location

resources_bp = Blueprint('resources', __name__)


@resources_bp.route('/police-stations', methods=['GET'])
def get_police_stations():
    """
    Get real nearby police stations using OpenStreetMap + Mapillary.
    Query params: lat, lng, radius (default 5000m)
    """
    try:
        lat = float(request.args.get('lat'))
        lng = float(request.args.get('lng'))
        radius = int(request.args.get('radius', 5000))

        stations = search_pois_overpass(lat, lng, 'police', radius)

        return jsonify({
            'success': True,
            'count': len(stations),
            'stations': stations,
            'source': 'OpenStreetMap (live)',
            'user_location': {'lat': lat, 'lng': lng}
        }), 200

    except (TypeError, ValueError):
        return jsonify({'success': False, 'error': 'Valid lat and lng are required'}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@resources_bp.route('/hospitals', methods=['GET'])
def get_hospitals():
    """
    Get real nearby hospitals using OpenStreetMap + Mapillary.
    Query params: lat, lng, radius (default 5000m)
    """
    try:
        lat = float(request.args.get('lat'))
        lng = float(request.args.get('lng'))
        radius = int(request.args.get('radius', 5000))

        hospitals = search_pois_overpass(lat, lng, 'hospital', radius)

        return jsonify({
            'success': True,
            'count': len(hospitals),
            'hospitals': hospitals,
            'source': 'OpenStreetMap (live)',
            'user_location': {'lat': lat, 'lng': lng}
        }), 200

    except (TypeError, ValueError):
        return jsonify({'success': False, 'error': 'Valid lat and lng are required'}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@resources_bp.route('/street-view', methods=['GET'])
def get_street_view():
    """
    Get Mapillary street-level imagery context for a location.
    Returns tile URL for embedding in the map, plus nearby images.
    Query params: lat, lng
    """
    try:
        lat = float(request.args.get('lat'))
        lng = float(request.args.get('lng'))
        radius = int(request.args.get('radius', 200))

        data = get_mapillary_street_view(lat, lng, radius)

        return jsonify({
            'success': True,
            **data
        }), 200

    except (TypeError, ValueError):
        return jsonify({'success': False, 'error': 'Valid lat and lng are required'}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@resources_bp.route('/share-location', methods=['POST'])
def share_location():
    """
    Share user location and get Mapillary street view coverage info.
    Body: { user_id, lat, lng, accuracy? }
    """
    try:
        data = request.json
        lat = float(data['lat'])
        lng = float(data['lng'])
        user_id = data.get('user_id', 'anonymous')
        accuracy = float(data.get('accuracy', 10.0))

        result = share_user_location(lat, lng, user_id, accuracy)

        return jsonify({'success': True, **result}), 200

    except (KeyError, TypeError, ValueError) as e:
        return jsonify({'success': False, 'error': f'Invalid data: {e}'}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@resources_bp.route('/emergency-contacts', methods=['GET'])
def get_emergency_contacts():
    """Tamil Nadu emergency contact numbers."""
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
        },
        'source': 'Tamil Nadu Government'
    }), 200