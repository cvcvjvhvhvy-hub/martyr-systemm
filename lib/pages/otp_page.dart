import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../services/firebase_service.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String name;
  final String password;
  final VoidCallback onVerifySuccess;
  final VoidCallback onBack;

  const OtpPage({
    Key? key,
    required this.phoneNumber,
    required this.name,
    required this.password,
    required this.onVerifySuccess,
    required this.onBack,
  }) : super(key: key);

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _remainingSeconds = 60;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();

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
    _timer?.cancel();
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_remainingSeconds != 0) return;
    
    setState(() => _isLoading = true);
    
    try {
      final success = await FirebaseService.resendOtp(
        // Callback 1: التحقق التلقائي
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ التحقق التلقائي عند إعادة الإرسال');
          setState(() => _isLoading = false);
          _showSuccessSnackBar('تم التحقق تلقائياً!');
          
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onVerifySuccess();
        },
        
        // Callback 2: فشل التحقق
        onVerificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showErrorSnackBar('فشل في إعادة الإرسال: ${e.message}');
        },
        
        // Callback 3: تم إرسال الكود
        onCodeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _startTimer();
          _showSuccessSnackBar('تم إرسال الرمز مرة أخرى');
          debugPrint('✅ تم إعادة إرسال الكود');
        },
        
        // Callback 4: انتهى الوقت
        onCodeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ انتهى وقت القراءة التلقائية');
        },
      );
      
      if (!success) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('فشل في إعادة إرسال الرمز');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('حدث خطأ: ${e.toString()}');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      _showErrorSnackBar('يرجى إدخال رمز التحقق كاملاً');
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔵 محاولة التحقق من OTP: $otp');
      
      // التحقق من OTP عبر Firebase
      final success = await FirebaseService.verifyOtp(otp);

      setState(() => _isLoading = false);

      if (success) {
        debugPrint('✅ تم التحقق بنجاح!');
        
        // حفظ حالة تسجيل الدخول
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('phone_number', widget.phoneNumber);
        await prefs.setString('user_name', widget.name);

        _showSuccessSnackBar('تم التحقق بنجاح!');
        await Future.delayed(const Duration(milliseconds: 500));
        
        widget.onVerifySuccess();
      } else {
        debugPrint('❌ رمز التحقق غير صحيح');
        _showErrorSnackBar('رمز التحقق غير صحيح، يرجى المحاولة مرة أخرى');
        _clearOtp();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      String errorMessage = 'حدث خطأ في التحقق';
      
      if (e.toString().contains('invalid-verification-code')) {
        errorMessage = 'رمز التحقق غير صحيح';
      } else if (e.toString().contains('session-expired')) {
        errorMessage = 'انتهت صلاحية الرمز، يرجى إعادة الإرسال';
      }
      
      debugPrint('❌ خطأ في التحقق: $e');
      _showErrorSnackBar(errorMessage);
      _clearOtp();
    }
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
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
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                // Header Section
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
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2),
                              ),
                              child: const Icon(
                                Icons.verified_user,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'التحقق من الهاتف',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'أدخل رمز التحقق المرسل',
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

                // OTP Form Section
                Expanded(
                  flex: 2,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back Button
                            IconButton(
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back,
                                  color: Color(0xFF64748B)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              'التحقق من الهاتف',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'أدخل الرمز المرسل إلى ${widget.phoneNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF64748B).withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // OTP Input Fields
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                  6, (index) => _buildOtpField(index)),
                            ),

                            const SizedBox(height: 24),

                            // Timer and Resend
                            Center(
                              child: _remainingSeconds > 0
                                  ? Text(
                                      'إعادة الإرسال بعد $_remainingSeconds ثانية',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: _isLoading ? null : _resendOtp,
                                      child: const Text(
                                        'إعادة إرسال الرمز',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 24),

                            // Verify Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 6,
                                  shadowColor:
                                      const Color(0xFF0D9488).withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'تحقق',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Info Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFF5EEAD4)
                                        .withOpacity(0.3)),
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
                                    'تحقق من رسائل SMS على هاتفك وأدخل الرمز المكون من 6 أرقام',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFF0F766E)
                                          .withOpacity(0.8),
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

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          counterText: '',
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
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          // Auto-verify when all fields are filled
          if (index == 5 && value.isNotEmpty) {
            final otp = _controllers.map((c) => c.text).join();
            if (otp.length == 6) {
              FocusScope.of(context).unfocus();
            }
          }
        },
      ),
    );
  }
}