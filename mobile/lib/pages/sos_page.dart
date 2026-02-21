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
  Map<String, dynamic>? _sosResponse;
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
        setState(() { 
          _isTriggered = true; 
          _isActivating = false;
          _sosResponse = res;
        });
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
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
    );
  }

  Widget _buildStatusBar() {
    return Column(
      children: [
        Text(
          _isActivating ? "ACTIVATING SOS" : "Safe Her SOS",
          style: TextStyle(
            color: _isActivating ? const Color(0xFFE71C23) : const Color(0xFF1F1F1F),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPosition != null ? const Color(0xFF00ADB5) : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _currentPosition != null ? "Precision Location Active" : "Searching for GPS signal...",
              style: TextStyle(color: const Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w500),
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
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE71C23),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE71C23).withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 60),
                SizedBox(height: 8),
                Text("SOS", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2)),
                Text("LONG PRESS", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
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
              width: 220, height: 220,
              child: CircularProgressIndicator(
                value: _countdown / 5,
                strokeWidth: 10,
                color: const Color(0xFFE71C23),
                backgroundColor: const Color(0xFFF2F2F7),
              ),
            ),
            Text("$_countdown", style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 84, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 48),
        TextButton.icon(
          onPressed: _cancelSOS,
          icon: const Icon(Icons.close_rounded, color: Color(0xFFE71C23)),
          label: const Text("CANCEL DISPATCH", style: TextStyle(color: Color(0xFFE71C23), fontWeight: FontWeight.w900, letterSpacing: 1)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            side: const BorderSide(color: Color(0xFFE71C23), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContacts() {
    return Column(
      children: [
        const Text("EMERGENCY DISPATCH", style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _emergencyButton("100", "Police"),
            _emergencyButton("108", "Med"),
            _emergencyButton("112", "SOS"),
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
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(child: Text(num, style: const TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.w900, fontSize: 15))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Color(0xFF00ADB5), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 32),
              const Text("Alert Sent!", style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              if (_sosResponse?['police_station'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_police_rounded, color: Color(0xFF5D3891), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _sosResponse!['police_station']['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Help arriving in approx. ${_sosResponse!['eta_minutes']} minutes",
                        style: const TextStyle(color: Color(0xFFE71C23), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                _sosResponse?['police_station'] != null 
                  ? "Your location has been broadcast to ${_sosResponse!['police_station']['name']}. Help is on the way."
                  : "Your location and SOS signal have been broadcast to local emergency services and your contacts.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => setState(() => _isTriggered = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D3891),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("I AM SAFE NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
