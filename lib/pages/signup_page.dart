import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:martyr_system/pages/otp_page.dart';
import '../services/firebase_service.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback onSignUpSuccess;
  final VoidCallback onBackToLogin;

  const SignUpPage({
    super.key,
    required this.onSignUpSuccess,
    required this.onBackToLogin,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('+')) {
      return RegExp(r'^\+\d{7,15}$').hasMatch(cleanPhone);
    } else {
      return RegExp(r'^\d{7,15}$').hasMatch(cleanPhone);
    }
  }

  String _formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.startsWith('+')) {
      return cleanPhone;
    }
    return '+$cleanPhone';
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      _showErrorSnackBar('يرجى ملء جميع الحقول');
      return;
    }

    if (!_isValidPhoneNumber(phone)) {
      _showErrorSnackBar('يرجى إدخال رقم هاتف صحيح (مع رمز الدولة مثال: +90XXXXXXXXXX)');
      return;
    }

    if (password.length < 6) {
      _showErrorSnackBar('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedPhone = _formatPhoneNumber(phone);

      debugPrint('🔵 بدء عملية التسجيل...');
      debugPrint('👤 الاسم: $name');
      debugPrint('📱 الهاتف: $formattedPhone');

      final success = await FirebaseService.signUp(
        formattedPhone,
        name,
        password,
        
        // Callback 1: التحقق التلقائي (Android فقط)
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ التحقق التلقائي اكتمل!');
          setState(() => _isLoading = false);
          _showSuccessSnackBar('تم التحقق تلقائياً!');
          
          // الانتقال للصفحة الرئيسية مباشرة
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onSignUpSuccess();
        },
        
        // Callback 2: فشل التحقق
        onVerificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          
          String errorMessage = 'حدث خطأ في التحقق';
          
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'رقم الهاتف غير صحيح';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'تم تجاوز عدد المحاولات، يرجى المحاولة لاحقاً';
          } else if (e.code == 'network-request-failed') {
            errorMessage = 'تحقق من اتصال الإنترنت';
          }
          
          _showErrorSnackBar(errorMessage);
        },
        
        // Callback 3: تم إرسال الكود ⭐
        onCodeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          
          debugPrint('✅ تم إرسال الكود، الانتقال لصفحة التحقق');
          
          // الانتقال لصفحة OTP
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OtpPage(
                  phoneNumber: formattedPhone,
                  name: name,
                  password: password,
                  onVerifySuccess: widget.onSignUpSuccess,
                  onBack: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          }
        },
        
        // Callback 4: انتهى وقت القراءة التلقائية
        onCodeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ انتهى وقت القراءة التلقائية');
        },
      );

      if (!success) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('فشل في إرسال رمز التحقق');
      }
    } catch (e) {
      debugPrint('❌ خطأ في التسجيل: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('حدث خطأ: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D9488),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                // Header
                Expanded(
                  flex: 1,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'إنشاء حساب جديد',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'انضم إلى ذاكرة الوفاء',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Form Section
                Expanded(
                  flex: 2,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            _buildTextField(
                              controller: _nameController,
                              label: 'الاسم الكامل',
                              icon: Icons.person_outline,
                              hint: 'أدخل اسمك الكامل',
                            ),

                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _phoneController,
                              label: 'رقم الهاتف',
                              icon: Icons.phone_outlined,
                              hint: 'مثال: +90XXXXXXXXXX أو +1XXXXXXXXXX',
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _passwordController,
                              label: 'كلمة المرور',
                              icon: Icons.lock_outline,
                              hint: 'أدخل كلمة المرور (6 أحرف على الأقل)',
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),

                            const SizedBox(height: 24),

                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 6,
                                  shadowColor: const Color(0xFF0D9488).withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'إنشاء الحساب',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Back to Login
                            Center(
                              child: TextButton(
                                onPressed: widget.onBackToLogin,
                                child: const Text(
                                  'لديك حساب بالفعل؟ تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Info Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF5EEAD4).withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: const Color(0xFF0D9488),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'ملاحظة',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'سيتم إرسال رمز التحقق عبر SMS إلى رقم هاتفك',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFF0F766E).withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF).withOpacity(0.7),
              fontSize: 12,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 18,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF6B7280),
                      size: 18,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}