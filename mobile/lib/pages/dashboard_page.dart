import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  int _nearbyPolice = 0;
  int _nearbyHospitals = 0;
  final ApiService _api = ApiService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await AuthService.getUser();
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final results = await Future.wait([
        _api.getNearbyPolice(pos.latitude, pos.longitude),
        _api.getNearbyHospitals(pos.latitude, pos.longitude),
      ]);

      if (mounted) {
        setState(() {
          _user = user;
          _nearbyPolice = results[0]['count'] ?? 0;
          _nearbyHospitals = results[1]['count'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _triggerEmergencySOS() {
    HapticFeedback.heavyImpact();
    widget.onNavigate(2); // Navigate to SOS tab
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0425),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF4D6D))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0425),
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D6D).withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 10),
                      _buildSafetyIllustration(),
                      const SizedBox(height: 30),
                      _buildSOSCenter(),
                      const SizedBox(height: 40),
                      _buildSafetyMetrics(),
                      const SizedBox(height: 40),
                      const Text(
                        'Empowering Features',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildVisualActionGrid(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFF6C3DE0)]),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1A103D),
                child: Text(
                  _user?['name']?.substring(0, 1).toUpperCase() ?? 'S',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, letterSpacing: 0.5),
                ),
                Text(
                  '${_user?['name'] ?? 'Traveler'} ✨',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyIllustration() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0, bottom: 0, top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(32), bottomRight: Radius.circular(32)),
              child: Image.asset(
                'assets/images/safety_shield.png',
                fit: BoxFit.cover,
                width: 200,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'You are Protected',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'SafeHer Shield is active\nin your current location.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSCenter() {
    return Column(
      children: [
        GestureDetector(
          onLongPress: _triggerEmergencySOS,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Multiple Pulse Rings
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180 * _pulseController.value,
                        height: 180 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D6D).withOpacity(0.12 * (1 - _pulseController.value)),
                        ),
                      ),
                      Container(
                        width: 220 * _pulseController.value,
                        height: 220 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF4D6D).withOpacity(0.05 * (1 - _pulseController.value)),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D6D), Color(0xFFC9184A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4D6D).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.white, size: 40),
                    SizedBox(height: 4),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'HOLD TO ACTIVATE SOS',
          style: TextStyle(
            color: Color(0xFFFF4D6D),
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyMetrics() {
    return Row(
      children: [
        _metricBox('Police Stations', _nearbyPolice.toString(), Icons.policy_rounded, const Color(0xFF00B4D8)),
        const SizedBox(width: 16),
        _metricBox('Hospitals', _nearbyHospitals.toString(), Icons.emergency_rounded, const Color(0xFFFF4D6D)),
      ],
    );
  }

  Widget _metricBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _featureCard('AI Chat', 'Safe Companion', 'assets/images/community.png', const Color(0xFF6C3DE0), 1),
        _featureCard('Safety Map', 'Live Navigation', 'assets/images/map_art.png', const Color(0xFF06D6A0), 3),
      ],
    );
  }

  Widget _featureCard(String title, String sub, String imgPath, Color color, int index) {
    return GestureDetector(
      onTap: () => widget.onNavigate(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                child: Image.asset(imgPath, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
