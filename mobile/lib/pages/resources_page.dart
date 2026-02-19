import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  List<dynamic> _police = [];
  List<dynamic> _hospitals = [];
  bool _isLoading = true;
  String? _error;
  Position? _pos;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchResources() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final pos = await _locationService.getCurrentLocation();
      setState(() => _pos = pos);
      if (pos != null) {
        final policeRes = await _apiService.getNearbyPolice(pos.latitude, pos.longitude);
        final hospRes = await _apiService.getNearbyHospitals(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _police = policeRes['stations'] ?? policeRes['data'] ?? [];
            _hospitals = hospRes['hospitals'] ?? hospRes['data'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        setState(() { _error = "Location permission needed."; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Backend not reachable. Start the Python server."; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06D6A0), Color(0xFF048A81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("📍 Nearby Resources", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(
                          _pos != null
                              ? "Based on your location"
                              : "Enable location to find nearby services",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text("Police (${_police.length})"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_hospital_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text("Hospitals (${_hospitals.length})"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF06D6A0)),
                  SizedBox(height: 16),
                  Text("Finding nearby resources..."),
                ],
              ))
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_police, const Color(0xFF3A86FF), Icons.shield_rounded, "police"),
                      _buildList(_hospitals, const Color(0xFFFF006E), Icons.local_hospital_rounded, "hospital"),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchResources,
        backgroundColor: const Color(0xFF06D6A0),
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text("Refresh", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchResources,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, Color color, IconData icon, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text("No ${type == 'police' ? 'police stations' : 'hospitals'} found nearby",
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final dist = item['distance_km'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (dist != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text("$dist km away", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(height: 4),
                      Text(item['address'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (item['phone'] != null || item['emergency_phone'] != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.phone, color: color, size: 18),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
