import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _police = [];
  List<dynamic> _hospitals = [];
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      Position pos = await Geolocator.getCurrentPosition();
      
      // Load both in parallel - radius is already increased to 10k in api_service
      final results = await Future.wait([
        _api.getNearbyPolice(pos.latitude, pos.longitude),
        _api.getNearbyHospitals(pos.latitude, pos.longitude),
      ]);

      if (mounted) {
        setState(() {
          _police = results[0]['resources'] ?? [];
          _hospitals = results[1]['resources'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Safety Resources', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1A0533),
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadResources, icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFF4D6D),
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.security), text: 'Police'),
            Tab(icon: Icon(Icons.local_hospital), text: 'Hospitals'),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_police, Icons.policy_rounded, Colors.blue),
              _buildList(_hospitals, Icons.local_hospital_rounded, Colors.red),
            ],
          ),
    );
  }

  Widget _buildList(List<dynamic> items, IconData icon, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No resources found nearby', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const Text('Try refreshing or check location permission', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _resourceCard(items[i], icon, color),
    );
  }

  Widget _resourceCard(dynamic item, IconData icon, Color color) {
    final dist = item['distance_km'] != null ? '${(item['distance_km'] as double).toStringAsFixed(2)} km' : 'Nearby';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchMaps(item['latitude'], item['longitude']),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A0533))),
                      const SizedBox(height: 4),
                      Text(item['address'] ?? 'Tamil Nadu, India', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF06D6A0).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(dist, style: const TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.directions_rounded, color: Color(0xFF6C3DE0), size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}
