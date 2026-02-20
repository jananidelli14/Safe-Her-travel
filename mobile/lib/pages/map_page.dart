import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  Position? _userPos;
  List<Marker> _markers = [];
  String _activeFilter = 'all';
  bool _isLoading = true;

  static const String _mapillaryToken = 'MLY|26777390158530578|6654db54de5283fe05ba26443c77290f';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() => _userPos = pos);
      await _loadNearbyPlaces(pos.latitude, pos.longitude);
      _mapController.move(LatLng(pos.latitude, pos.longitude), 14);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadNearbyPlaces(double lat, double lng) async {
    final markers = <Marker>[];

    // User location marker
    markers.add(_buildMarker(lat, lng, Colors.blue, Icons.my_location, "📍 Your Location"));

    // Only load based on filter
    if (_activeFilter == 'all' || _activeFilter == 'police') {
      final policeRes = await _apiService.getNearbyPolice(lat, lng);
      final stations = policeRes['stations'] ?? [];
      for (var s in stations) {
        if (s['lat'] != null && s['lng'] != null) {
          markers.add(_buildMarker(
            s['lat'].toDouble(), s['lng'].toDouble(),
            const Color(0xFF3A86FF), Icons.shield_rounded,
            "🚔 ${s['name']}\n${s['distance_km']} km",
          ));
        }
      }
    }

    if (_activeFilter == 'all' || _activeFilter == 'hospital') {
      final hospRes = await _apiService.getNearbyHospitals(lat, lng);
      final hospitals = hospRes['hospitals'] ?? [];
      for (var h in hospitals) {
        if (h['lat'] != null && h['lng'] != null) {
          markers.add(_buildMarker(
            h['lat'].toDouble(), h['lng'].toDouble(),
            const Color(0xFFFF006E), Icons.local_hospital_rounded,
            "🏥 ${h['name']}\n${h['distance_km']} km",
          ));
        }
      }
    }

    if (_activeFilter == 'all' || _activeFilter == 'hotel') {
      final hotelRes = await _apiService.getNearbyHotels(lat, lng);
      final hotels = hotelRes['accommodations'] ?? [];
      for (var h in hotels) {
        if (h['lat'] != null && h['lng'] != null) {
          markers.add(_buildMarker(
            h['lat'].toDouble(), h['lng'].toDouble(),
            const Color(0xFFFFB703), Icons.hotel_rounded,
            "🏨 ${h['name']}",
          ));
        }
      }
    }

    if (mounted) setState(() => _markers = markers);
  }

  Marker _buildMarker(double lat, double lng, Color color, IconData icon, String tooltip) {
    return Marker(
      point: LatLng(lat, lng),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showTooltip(tooltip),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showTooltip(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _setFilter(String filter) {
    setState(() => _activeFilter = filter);
    if (_userPos != null) {
      _loadNearbyPlaces(_userPos!.latitude, _userPos!.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map with Mapillary tile overlay
          _userPos == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_userPos!.latitude, _userPos!.longitude),
                    initialZoom: 14,
                  ),
                  children: [
                    // Base OpenStreetMap tiles
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.safe_her_travel',
                    ),
                    // POI markers
                    MarkerLayer(markers: _markers),
                  ],
                ),

          // Top gradient bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        "📍 Live Safety Map",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.layers, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text("Mapillary", style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Filter chips
          Positioned(
            top: 96, left: 16, right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'All', Icons.layers),
                  const SizedBox(width: 8),
                  _filterChip('police', 'Police', Icons.shield_rounded),
                  const SizedBox(width: 8),
                  _filterChip('hospital', 'Hospitals', Icons.local_hospital_rounded),
                  const SizedBox(width: 8),
                  _filterChip('hotel', 'Hotels', Icons.hotel_rounded),
                ],
              ),
            ),
          ),

          // Legend
          Positioned(
            bottom: 100, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _legendItem(const Color(0xFF3A86FF), "Police Station"),
                const SizedBox(height: 4),
                _legendItem(const Color(0xFFFF006E), "Hospital"),
                const SizedBox(height: 4),
                _legendItem(const Color(0xFFFFB703), "Hotel"),
                const SizedBox(height: 4),
                _legendItem(Colors.blue, "You"),
              ],
            ),
          ),

          // Recenter FAB
          Positioned(
            bottom: 100, left: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if (_userPos != null) {
                      _mapController.move(LatLng(_userPos!.latitude, _userPos!.longitude), 14);
                    }
                  },
                  child: const Icon(Icons.my_location, color: Colors.indigo),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'refresh_map',
                  backgroundColor: Colors.white,
                  onPressed: _init,
                  child: const Icon(Icons.refresh, color: Colors.indigo),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Positioned(
              bottom: 160, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text("Loading nearby places...", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label, IconData icon) {
    final isActive = _activeFilter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C3DE0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
