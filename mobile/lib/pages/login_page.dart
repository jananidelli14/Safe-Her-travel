import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  String? _demoOtp;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await _api.sendOtp(_phoneCtrl.text.trim());
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true) {
          _otpSent = true;
          _demoOtp = res['demo_otp']?.toString();
        } else {
          _error = res['error'] ?? 'Failed to send OTP';
        }
      });
    }
  }

  Future<void> _login() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final res = await _api.login(phone: _phoneCtrl.text.trim(), otp: _otpCtrl.text.trim());
    if (mounted) {
      setState(() => _loading = false);
      if (res['success'] == true) {
        await AuthService.saveSession(user: res['user'], token: res['token']);
        widget.onLoginSuccess();
      } else {
        setState(() => _error = res['error'] ?? 'Login failed');
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
            colors: [Color(0xFF1A0533), Color(0xFF3B0F6F), Color(0xFF6C3DE0)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Logo
                  Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [Color(0xFFFF4D6D), Color(0xFF9B0038)]),
                        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 44),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Safe Her Travel', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('Your safety companion in Tamil Nadu', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13)),
                  const SizedBox(height: 48),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Login with your phone number + OTP', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 24),

                        // Phone field
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          enabled: !_otpSent,
                        ),
                        const SizedBox(height: 16),

                        if (_otpSent) ...[
                          _buildField(
                            controller: _otpCtrl,
                            label: 'Enter OTP',
                            icon: Icons.lock_outline_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          if (_demoOtp != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Demo OTP: $_demoOtp', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],

                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.withOpacity(0.4)),
                            ),
                            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),

                        _buildGradientButton(
                          label: _loading ? 'Please wait...' : (_otpSent ? 'Login' : 'Send OTP'),
                          onTap: _loading ? null : (_otpSent ? _login : _sendOtp),
                          icon: _otpSent ? Icons.login_rounded : Icons.send_rounded,
                        ),

                        if (_otpSent)
                          TextButton(
                            onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); _error = null; }),
                            child: Text('Change number', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign up CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("New to Safe Her? ", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupPage(onSignupSuccess: widget.onLoginSuccess))),
                        child: const Text('Sign Up', style: TextStyle(color: Color(0xFFFF4D6D), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(enabled ? 0.1 : 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
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
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFF9B0038)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
