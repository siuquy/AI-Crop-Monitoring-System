import 'package:acmms/api/auth_api.dart';
import 'package:acmms/screens/home/home_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const Color primaryTeal = Color(0xFF4CAF50); // Xanh lá tươi
const Color darkTeal = Color(0xFF388E3C); // Xanh lá đậm

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthApi _authApi = AuthApi();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage; // Thêm biến lưu thông báo lỗi để hiển thị bự và rõ

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Xóa lỗi cũ khi bắt đầu đăng nhập lại
    });

    try {
      final result = await _authApi.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final bool success = result.success;
      final String message = result.message;
      final data = result.data;
      setState(() => _isLoading = false);

      if (success && data is Map<String, dynamic>) {
        final String userEmail = data['email'] ?? '';
        final String role = data['role'] ?? '';

        _showMessage(
          'Đăng nhập thành công: $userEmail ($role)',
          success: true,
        );

        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = message.isNotEmpty
              ? message
              : 'Sai thông tin đăng nhập hoặc mật khẩu không đúng!';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.';
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? primaryTeal : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE8F5E9), // Đổi màu nền ám xanh lá
            Color(0xFFF1F8E9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildLogo(),
                      const SizedBox(height: 20),
                      const Text(
                        'Đăng Nhập',
                        style: TextStyle(
                          fontSize: 30, // Chữ to hơn
                          fontWeight: FontWeight.bold,
                          color: darkTeal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Vui lòng nhập tài khoản được cấp\nđể xem công việc hôm nay',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16, // Chữ to hơn
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- KHUNG HIỂN THỊ LỖI ĐĂNG NHẬP MÀU ĐỎ TO BỰ ---
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.red.shade300, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.red, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _InputField(
                              controller: _emailController,
                              hint: 'Email',
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            _InputField(
                              controller: _passwordController,
                              hint: 'Mật khẩu',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: primaryTeal,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu!';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 60, // Tăng chiều cao nút bấm
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 6,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [primaryTeal, darkTeal],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          )
                                        : const Text(
                                            'Đăng Nhập Hệ Thống',
                                            style: TextStyle(
                                              fontSize:
                                                  18, // Chữ nút bấm to hơn
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 16),
                      // if (kDebugMode)
                      //   TextButton(
                      //     onPressed: _navigateToHome,
                      //     child: const Text(
                      //       'Dev Login',
                      //       style: TextStyle(
                      //         color: Colors.redAccent,
                      //         fontWeight: FontWeight.bold,
                      //       ),
                      //     ),
                      //   ),
                      // const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryTeal, darkTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.eco, // Đổi sang biểu tượng chiếc lá đồng bộ với WelcomeScreen
        color: Colors.white,
        size: 46,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16),
        prefixIcon: Icon(icon, color: primaryTeal),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
            vertical: 20), // Tăng vùng bấm bên trong Textfield
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
