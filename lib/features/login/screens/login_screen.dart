import 'package:flutter/material.dart';
import 'package:nch_mobile/features/login/controllers/auth_controller.dart';
import 'package:nch_mobile/core/config/backdoor_helper.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  int _tapCount = 0;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    // Initialize base URL saat login screen dibuka
    BackdoorHelper.initializeBaseUrl();
  }

  @override
  void dispose() {
    _authController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleLogoTap() {
    setState(() {
      _tapCount++;
    });

    // Reset timer setiap kali tap
    _resetTimer?.cancel();
    _resetTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _tapCount = 0;
        });
      }
    });

    if (_tapCount >= 7) {
      _tapCount = 0;
      _resetTimer?.cancel();
      _showBackdoorDialog();
    }
  }

  void _showBackdoorDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.settings, color: Color(0xFF0F7836)),
                  SizedBox(width: 8),
                  Text('Developer Settings'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Base URL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F7836),
                    ),
                  ),
                  Text(
                    BackdoorHelper.getCurrentBaseUrl(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: 'New Base URL',
                      labelStyle: TextStyle(color: Color(0xFF0F7836)),
                      hintText: 'https://your-api-server.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF0F7836)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF0F7836)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Color(0xFF0F7836),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: BackdoorHelper.isUsingCustomUrl(),
                    builder: (context, snapshot) {
                      final isUsingCustom = snapshot.data ?? false;
                      return Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isUsingCustom
                                  ? Colors.orange[50]
                                  : Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUsingCustom ? Colors.orange : Colors.green,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUsingCustom
                                  ? Icons.warning
                                  : Icons.check_circle,
                              color:
                                  isUsingCustom ? Colors.orange : Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isUsingCustom
                                    ? 'Using Custom URL'
                                    : 'Using Default URL',
                                style: TextStyle(
                                  color:
                                      isUsingCustom
                                          ? Colors.orange[800]
                                          : Colors.green[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await BackdoorHelper.resetToDefaultBaseUrl();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reset to default URL'),
                        backgroundColor: Color(0xFF0F7836),
                      ),
                    );
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0F7836),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final newUrl = urlController.text.trim();
                    if (newUrl.isNotEmpty) {
                      // Validasi URL
                      if (newUrl.startsWith('http://') ||
                          newUrl.startsWith('https://')) {
                        final success = await BackdoorHelper.setCustomBaseUrl(
                          newUrl,
                        );

                        if (success) {
                          // Debug current status
                          await BackdoorHelper.debugFullStatus();

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Base URL updated to: $newUrl'),
                              backgroundColor: Color(0xFF0F7836),
                            ),
                          );

                          // Force refresh untuk memastikan URL teraplikasi
                          await BackdoorHelper.forceRefreshUrl();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to update URL. Please check the format.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'URL must start with http:// or https://',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: CustomClipPath(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/bg-login.png',
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.45,
                    fit: BoxFit.cover,
                  ),

                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color.fromARGB(
                              255,
                              246,
                              233,
                              139,
                            ).withOpacity(0.7),
                            const Color(0xFF0F7836).withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _handleLogoTap,
                          child: Image.asset('assets/login.png', width: 250),
                        ),
                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: _handleLogoTap,
                          child: const Text(
                            "Assalamu'alaikum",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        const Text(
                          "Selamat Datang, Bantu kami mengenali anda",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _authController.emailController,
                    decoration: InputDecoration(
                      labelText: 'Email / Nomor Handphone',
                      labelStyle: const TextStyle(color: Color(0xFF0F7836)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F7836)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F7836)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F7836),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _authController.passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Color(0xFF0F7836)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F7836)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF0F7836)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF0F7836),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F7836), Color(0xFFD4BF23)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _authController.login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Belum Memiliki Akun?',
                              style: TextStyle(
                                color: Color(0xFF0F7836),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: null, // Disable button
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Coming Soon',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 80,
                        color: const Color(0xFF0F7836).withOpacity(0.3),
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                color: Color(0xFF0F7836),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: null, // Disable button
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Perbarui',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Coming Soon',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Indikator tap count untuk backdoor
            if (_tapCount > 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tap ${7 - _tapCount} more times for developer mode',
                      style: TextStyle(
                        color: Color(0xFF0F7836),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(width: 8),
                    Row(
                      children: List.generate(7, (index) {
                        return Container(
                          margin: EdgeInsets.only(right: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                index < _tapCount
                                    ? Color(0xFF0F7836)
                                    : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
