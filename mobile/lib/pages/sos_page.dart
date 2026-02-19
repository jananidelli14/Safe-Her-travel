import 'package:flutter/material.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  bool _isActivating = false;
  bool _isTriggered = false;
  int _countdown = 5;
  Timer? _timer;
  Position? _currentPosition;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (mounted) setState(() => _currentPosition = pos);
  }

  void _startCountdown() {
    setState(() { _isActivating = true; _countdown = 5; });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _activateSOS();
      }
    });
  }

  void _cancelSOS() {
    _timer?.cancel();
    setState(() { _isActivating = false; _countdown = 5; });
  }

  void _activateSOS() async {
    final pos = _currentPosition ?? await _locationService.getCurrentLocation();
    if (pos != null) {
      final res = await _apiService.activateSOS(
        userId: 'flutter_user_001',
        lat: pos.latitude,
        lng: pos.longitude,
        emergencyContacts: ['+919876543210'],
      );
      if (mounted) {
        setState(() { _isTriggered = true; _isActivating = false; });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isTriggered) return _buildSuccessScreen();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _isActivating
              ? const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFAD0038)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              : const LinearGradient(colors: [Color(0xFF1B0033), Color(0xFF3B1FAD)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildStatusBar(),
                const Spacer(),
                _isActivating ? _buildCountdownDisplay() : _buildMainSOSButton(),
                const Spacer(),
                _buildEmergencyContacts(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Column(
      children: [
        Text(
          _isActivating ? "⚠️ ACTIVATING SOS" : "🛡️ Safe Her SOS",
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 14, color: _currentPosition != null ? Colors.greenAccent : Colors.white54),
            const SizedBox(width: 4),
            Text(
              _currentPosition != null ? "Location active" : "Getting location...",
              style: TextStyle(color: _currentPosition != null ? Colors.greenAccent : Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainSOSButton() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (ctx, _) => Transform.scale(
        scale: _pulseAnim.value,
        child: GestureDetector(
          onLongPress: _startCountdown,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.15),
                ),
              ),
              Container(
                width: 170, height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.25),
                ),
              ),
              Container(
                width: 140, height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0xFFFF4D6D), Color(0xFFC1121F)]),
                  boxShadow: [BoxShadow(color: Color(0xAAFF4D6D), blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_active, color: Colors.white, size: 44),
                    Text("HOLD SOS", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownDisplay() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200, height: 200,
              child: CircularProgressIndicator(
                value: _countdown / 5,
                strokeWidth: 12,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            Column(
              children: [
                Text("$_countdown", style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
                const Text("seconds", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: _cancelSOS,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, color: Colors.white),
                SizedBox(width: 8),
                Text("CANCEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContacts() {
    return Column(
      children: [
        const Text("EMERGENCY CONTACTS", style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _emergencyButton("100", "TN Police"),
            _emergencyButton("108", "Ambulance"),
            _emergencyButton("112", "National"),
            _emergencyButton("1091", "Women"),
          ],
        ),
      ],
    );
  }

  Widget _emergencyButton(String num, String label) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
          ),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06D6A0), Color(0xFF048A81)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 100),
              const SizedBox(height: 24),
              const Text("Help is on the Way!", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("TN Police and your emergency\ncontacts have been notified.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => setState(() => _isTriggered = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text("✅  I Am Safe Now", style: TextStyle(color: Color(0xFF06D6A0), fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
