import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key});

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  List<dynamic> _hotels = [];
  bool _isLoading = true;
  String? _error;
  Position? _pos;

  @override
  void initState() {
    super.initState();
    _fetchHotels();
  }

  Future<void> _fetchHotels() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final pos = await _locationService.getCurrentLocation();
      setState(() => _pos = pos);
      if (pos != null) {
        final res = await _apiService.getNearbyHotels(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _hotels = res['accommodations'] ?? res['hotels'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        setState(() { _error = "Location permission needed."; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Could not fetch hotels. Make sure backend is running."; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
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
                        const Text("🏨 Safe Hotels", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const Text("AI-vetted female-friendly stays", style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _chip(Icons.verified, "Safety Verified"),
                            const SizedBox(width: 8),
                            _chip(Icons.star, "Google Reviews"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFB703)),
                  SizedBox(height: 16),
                  Text("Finding safe hotels nearby..."),
                ],
              )),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hotel, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchHotels,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Try Again"),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB703)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Note: Hotel search requires GOOGLE_PLACES_API_KEY in the backend .env file.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_hotels.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("No hotels found nearby", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Text("Add your GOOGLE_PLACES_API_KEY to backend/.env for live results",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchHotels,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Refresh"),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB703)),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => _buildHotelCard(_hotels[index]),
                  childCount: _hotels.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHotelCard(dynamic hotel) {
    final rating = hotel['rating'] ?? hotel['safety_rating'] ?? 0.0;
    final ratingNum = rating is num ? rating.toDouble() : 0.0;
    final priceLevel = hotel['price_level'] ?? 2;
    final priceSigns = '\$' * (priceLevel is int ? priceLevel.clamp(1, 4) : 2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFFB703).withOpacity(0.3), const Color(0xFFFB8500).withOpacity(0.2)],
                ),
              ),
              child: const Center(child: Icon(Icons.hotel_rounded, size: 48, color: Color(0xFFFFB703))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(hotel['name'] ?? 'Hotel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(ratingNum.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(hotel['address'] ?? hotel['vicinity'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF06D6A0).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, size: 12, color: Color(0xFF06D6A0)),
                          SizedBox(width: 4),
                          Text("Safety Verified", style: TextStyle(color: Color(0xFF06D6A0), fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(priceSigns, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
