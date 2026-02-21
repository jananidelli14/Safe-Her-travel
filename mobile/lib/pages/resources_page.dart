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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Safety Resources', 
            style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F1F1F), fontSize: 22, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(12)),
            child: IconButton(onPressed: _loadResources, icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5D3891))),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF8E8E93),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF5D3891),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.local_police_rounded, size: 18), SizedBox(width: 8), Text('Police')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.emergency_rounded, size: 18), SizedBox(width: 8), Text('Hospitals')])),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D3891)))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_police, Icons.local_police_rounded, const Color(0xFF2D31FA)),
              _buildList(_hospitals, Icons.emergency_rounded, const Color(0xFFE71C23)),
            ],
          ),
    );
  }

  Widget _buildList(List<dynamic> items, IconData icon, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_rounded, size: 80, color: const Color(0xFFF2F2F7)),
              const SizedBox(height: 24),
              const Text('No resources found nearby', 
                  style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Try refreshing or checking your location permissions.', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _resourceCard(items[i], icon, color),
    );
  }

  Widget _resourceCard(dynamic item, IconData icon, Color color) {
    final dist = item['distance_km'] != null ? '${(item['distance_km'] as double).toStringAsFixed(1)} km' : 'Nearby';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F2F7)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
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
                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] ?? 'Unknown', 
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F1F1F))),
                      const SizedBox(height: 4),
                      Text(item['address'] ?? 'Tamil Nadu, India', 
                          style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(10)),
                      child: Text(dist, style: const TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                    const SizedBox(height: 8),
                    const Text('GET INFO', style: TextStyle(color: Color(0xFF5D3891), fontWeight: FontWeight.w900, fontSize: 10)),
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
