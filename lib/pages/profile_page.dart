import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../services/firebase_service.dart';
import '../widgets/image_helper.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  String userName = 'المستخدم العزيز';
  String userBio = 'مرحباً بك في تطبيق ذاكرة الوفاء، هنا نخلد ذكرى الأبطال.';
  String? profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'المستخدم العزيز';
      userBio = prefs.getString('user_bio') ??
          'مرحباً بك في تطبيق ذاكرة الوفاء، هنا نخلد ذكرى الأبطال.';
      profileImage = prefs.getString('user_image');
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName);
    await prefs.setString('user_bio', userBio);
    setState(() {
      isEditing = false;
    });
  }

  Future<void> _handleImagePicker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user_image', 'data:image/jpeg;base64,$base64String');

      setState(() {
        profileImage = 'data:image/jpeg;base64,$base64String';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: 192,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0D9488),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(48)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -48,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(36),
                          child: profileImage != null
                              ? ImageHelper.buildImage(
                                  profileImage!,
                                  fit: BoxFit.cover,
                                  errorWidget: const Icon(
                                    Icons.person,
                                    size: 64,
                                    color: Color(0xFF0D9488),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 64,
                                  color: Color(0xFF0D9488),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 64),

            // User Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userBio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFF00BFA5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () async {
                            final Uri url =
                                Uri.parse('');
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            )) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('تعذر فتح لوحة الإدارة')),
                              );
                            }
                          },
                          child: const Text(
                            'الذهاب إلى الإدارة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00BFA5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Logout Button
                  GestureDetector(
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تأكيد تسجيل الخروج'),
                          content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('تسجيل الخروج'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await FirebaseService.signOut();
                        widget.onLogout();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 128),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
