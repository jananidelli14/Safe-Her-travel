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
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _isOtpMode = true;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  String? _demoOtp;
  
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
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
    setState(() { _loading = true; _error = null; });
    
    Map<String, dynamic> res;
    if (_isOtpMode) {
      if (_otpCtrl.text.trim().length != 6) {
        setState(() { _loading = false; _error = 'Enter 6-digit OTP'; });
        return;
      }
      res = await _api.login(phone: _phoneCtrl.text.trim(), otp: _otpCtrl.text.trim());
    } else {
      if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
        setState(() { _loading = false; _error = 'Enter email and password'; });
        return;
      }
      res = await _api.loginWithEmail(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    }

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Professional Logo
                Center(
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D3891).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF5D3891), size: 48),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Safe Her Travel', textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                const Text('Tamil Nadu\'s trusted safety companion', textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
                const SizedBox(height: 48),

                // Mode Toggle
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildToggleButton(label: 'OTP Login', active: _isOtpMode, onTap: () => setState(() { _isOtpMode = true; _error = null; })),
                      _buildToggleButton(label: 'Email Login', active: !_isOtpMode, onTap: () => setState(() { _isOtpMode = false; _error = null; })),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (_isOtpMode) ...[
                  _buildField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    enabled: !_otpSent,
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _otpCtrl,
                      label: 'Enter 6-digit OTP',
                      icon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    if (_demoOtp != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Demo OTP: $_demoOtp', textAlign: TextAlign.center, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                  ],
                ] else ...[
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _passCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                ],
                
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFE71C23), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),

                _buildPrimaryButton(
                  label: _loading ? 'Please wait...' : (_isOtpMode && !_otpSent ? 'Send OTP' : 'Login'),
                  onTap: _loading ? null : (_isOtpMode && !_otpSent ? _sendOtp : _login),
                ),

                if (_isOtpMode && _otpSent)
                  TextButton(
                    onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
                    child: const Text('Change phone number', style: TextStyle(color: Color(0xFF5D3891), fontWeight: FontWeight.w600)),
                  ),

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF666666))),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupPage(onSignupSuccess: widget.onLoginSuccess))),
                      child: const Text('Sign Up', style: TextStyle(color: Color(0xFF5D3891), fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({required String label, required bool active, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: active ? const Color(0xFF5D3891) : const Color(0xFF8E8E93), fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
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
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        obscureText: isPassword,
        style: const TextStyle(color: Color(0xFF1F1F1F)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback? onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5D3891),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
