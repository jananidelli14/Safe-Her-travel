import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updateLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (mounted) setState(() => _currentPosition = position);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C3DE0), Color(0xFF3B1FAD)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildSOSCard(),
                _buildQuickActions(),
                _buildEmergencyNumbers(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "🌸 TAMIL NADU WOMEN'S EDITION",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Safe Her Travel", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _currentPosition != null
                          ? "${_currentPosition!.latitude.toStringAsFixed(3)}, ${_currentPosition!.longitude.toStringAsFixed(3)}"
                          : "Getting location...",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _updateLocation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: GestureDetector(
                  onTap: () => widget.onNavigate(2),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [Color(0xFFFF4D6D), Color(0xFFAD0038)]),
                      boxShadow: [
                        BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active, color: Colors.white, size: 50),
                        Text("SOS", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Hold SOS on the SOS tab to alert TN Police", style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {"icon": Icons.chat_bubble_rounded, "title": "AI Chat", "sub": "Get guidance", "color": const Color(0xFF00B4D8), "index": 1},
      {"icon": Icons.shield_rounded, "title": "Resources", "sub": "Police & hospitals", "color": const Color(0xFF06D6A0), "index": 3},
      {"icon": Icons.hotel_rounded, "title": "Safe Hotels", "sub": "Vetted stays", "color": const Color(0xFFFFB703), "index": 4},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(Icons.flash_on, color: Color(0xFF6C3DE0)),
                SizedBox(width: 8),
                Text("Quick Access", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          ...actions.map((a) => ListTile(
            onTap: () => widget.onNavigate(a["index"] as int),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (a["color"] as Color).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(a["icon"] as IconData, color: a["color"] as Color),
            ),
            title: Text(a["title"] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(a["sub"] as String),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumbers() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFFF0A54)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sos, color: Colors.white),
                SizedBox(width: 8),
                Text("Emergency Numbers", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _emergencyNum("100", "TN Police"),
                _emergencyNum("108", "Ambulance"),
                _emergencyNum("112", "National"),
                _emergencyNum("1091", "Women"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyNum(String num, String label) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
