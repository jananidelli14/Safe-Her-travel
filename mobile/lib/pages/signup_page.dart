import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onSignupSuccess;
  const SignupPage({super.key, required this.onSignupSuccess});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final ApiService _api = ApiService();
  int _step = 0; // 0=details, 1=otp
  bool _loading = false;
  String? _error;
  String? _demoOtp;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final List<TextEditingController> _contactCtrls = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _otpCtrl.dispose();
    for (final c in _contactCtrls) { c.dispose(); }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final city = _cityCtrl.text.trim();

    if (name.isEmpty || phone.length < 10 || city.isEmpty) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }

    // Validate at least one emergency contact
    final contacts = _contactCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (contacts.isEmpty) {
      setState(() => _error = 'Please add at least one emergency contact number');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final res = await _api.sendOtp(phone);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true) {
          _step = 1;
          _demoOtp = res['demo_otp']?.toString();
        } else {
          _error = res['error'] ?? 'Failed to send OTP';
        }
      });
    }
  }

  Future<void> _register() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    final contacts = _contactCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    setState(() { _loading = true; _error = null; });

    final res = await _api.register(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      emergencyContacts: contacts,
      otp: _otpCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _loading = false);
      if (res['success'] == true) {
        await AuthService.saveSession(user: res['user'], token: res['token']);
        widget.onSignupSuccess();
      } else {
        setState(() => _error = res['error'] ?? 'Registration failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2E4B), Color(0xFF3B0F6F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _step == 1 ? setState(() { _step = 0; _error = null; }) : Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Step ${_step + 1} of 2', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 2,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D6D)),
                    minHeight: 4,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _step == 0 ? _buildDetailsStep() : _buildOtpStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        _sectionLabel('Personal Information'),
        const SizedBox(height: 12),
        _buildField(_nameCtrl, 'Full Name *', Icons.person_outline_rounded),
        const SizedBox(height: 12),
        _buildField(_phoneCtrl, 'Phone Number *', Icons.phone_outlined, TextInputType.phone),
        const SizedBox(height: 12),
        _buildField(_cityCtrl, 'City / Location *', Icons.location_city_outlined),
        const SizedBox(height: 24),

        _sectionLabel('🆘 Emergency Contacts (for SOS alerts)'),
        const SizedBox(height: 4),
        Text('At least 1 required — these people will be notified during SOS.',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        const SizedBox(height: 12),
        ..._contactCtrls.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildField(e.value, 'Emergency Contact ${e.key + 1}${e.key == 0 ? ' *' : ''}',
              Icons.emergency_outlined, TextInputType.phone),
        )),

        const SizedBox(height: 8),
        if (_error != null) _buildErrorBox(_error!),

        const SizedBox(height: 8),
        _buildGradientButton(
          label: _loading ? 'Sending OTP...' : 'Send OTP to verify',
          onTap: _loading ? null : _sendOtp,
          icon: Icons.send_rounded,
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            children: [
              Text('Already have an account? ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('Login', style: TextStyle(color: Color(0xFFFF4D6D), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              const Icon(Icons.mobile_friendly_rounded, color: Color(0xFFFF4D6D), size: 48),
              const SizedBox(height: 12),
              const Text('Verify your number', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('We sent an OTP to ${_phoneCtrl.text}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildField(_otpCtrl, 'Enter 6-digit OTP', Icons.lock_outline_rounded, TextInputType.number),

        if (_demoOtp != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Demo OTP (check backend console too)', style: TextStyle(color: Colors.amber, fontSize: 11)),
                      Text(_demoOtp!, style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 6)),
                    ],
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 20),
        if (_error != null) _buildErrorBox(_error!),
        const SizedBox(height: 8),
        _buildGradientButton(
          label: _loading ? 'Creating account...' : 'Verify & Continue',
          onTap: _loading ? null : _register,
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _loading ? null : () => setState(() { _step = 0; _error = null; }),
          child: Text('Resend OTP / Edit details', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      [TextInputType? type]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton({required String label, required VoidCallback? onTap, required IconData icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFF9B0038)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
