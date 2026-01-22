import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'pages/home_page.dart';
import 'pages/details_page.dart';
import 'pages/profile_page.dart';
import 'pages/management_page.dart';
import 'pages/login_page.dart';
import 'services/firebase_service.dart';
import 'widgets/image_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('تم تهيئة Firebase بنجاح');
  } catch (e) {
    debugPrint('فشل تهيئة Firebase: $e');
  }

  runApp(const MartyrSystemApp());
}

class MartyrSystemApp extends StatelessWidget {
  const MartyrSystemApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الشهداء - ذاكرة الوفاء',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Arial',
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? isLoggedIn =true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      isLoggedIn = false;
    });
  }

  Future<void> _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    setState(() {
      isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D9488),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return MainScreen(onLogout: _onLogout);
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const MainScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ViewType currentView = ViewType.home;
  Martyr? selectedMartyr;
  List<Martyr> martyrs = [];
  List<Stance> stances = [];
  List<Stance> crimes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final loadedMartyrs = await FirebaseService.getMartyrs();
      final loadedStances = await FirebaseService.getStances();
      final loadedCrimes = await FirebaseService.getCrimes();

      setState(() {
        martyrs = loadedMartyrs;
        stances = loadedStances;
        crimes = loadedCrimes;
      });
    } catch (e) {
      debugPrint('فشل تحميل البيانات: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToDetails(Martyr martyr) {
    setState(() {
      selectedMartyr = martyr;
      currentView = ViewType.details;
    });
  }

  void _goBack() {
    setState(() {
      currentView = ViewType.home;
      selectedMartyr = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF14B8A6), width: 4),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ذاكرة الوفاء',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'جاري المزامنة...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _renderContent(),
          if (currentView != ViewType.details) _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _renderContent() {
    switch (currentView) {
      case ViewType.home:
        return HomePage(
          martyrs: martyrs,
          stances: stances,
          crimes: crimes,
          onSelectMartyr: _navigateToDetails,
        );
      case ViewType.profile:
        return ProfilePage(onLogout: widget.onLogout);
      case ViewType.management:
        return ManagementPage(onDataChange: _loadData);
      case ViewType.details:
        return selectedMartyr != null
            ? DetailsPage(martyr: selectedMartyr!, onBack: _goBack)
            : HomePage(
                martyrs: martyrs,
                stances: stances,
                crimes: crimes,
                onSelectMartyr: _navigateToDetails,
              );
      case ViewType.martyrs:
        return _buildMartyrsList();
      case ViewType.stances:
      case ViewType.crimes:
        return _buildStancesCrimesList();
    }
  }

  Widget _buildMartyrsList() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                border: Border(
                    right: BorderSide(color: Color(0xFF14B8A6), width: 4)),
              ),
              child: const Text(
                'سجل الشهداء الخالدين',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 24),
            martyrs.isNotEmpty
                ? Column(
                    children: martyrs
                        .map((martyr) => Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () => _navigateToDetails(martyr),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: ImageHelper.buildImage(
                                          martyr.imageUrl,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          errorWidget: Container(
                                            width: 96,
                                            height: 96,
                                            color: const Color(0xFFF1F5F9),
                                            child: const Icon(Icons.person,
                                                color: Color(0xFF94A3B8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                martyr.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                martyr.title,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF0D9488),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                martyr.bio,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Color(0xFF94A3B8),
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(96),
                      child: Text(
                        'لا يوجد شهداء مسجلون حالياً',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCBD5E1),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStancesCrimesList() {
    final list = currentView == ViewType.crimes ? crimes : stances;
    final title =
        currentView == ViewType.crimes ? 'جرائم العدوان' : 'المواقف الخالدة';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 128),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                border: Border(
                    right: BorderSide(color: Color(0xFF14B8A6), width: 4)),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(height: 24),
            list.isNotEmpty
                ? Column(
                    children: list
                        .map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ImageHelper.buildImage(
                                      item.imageUrl,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorWidget: Container(
                                        width: 96,
                                        height: 96,
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(Icons.image,
                                            color: Color(0xFF94A3B8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.subtitle,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF64748B),
                                              height: 1.5,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(96),
                      child: Text(
                        'لا توجد بيانات حالياً',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCBD5E1),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // FAB
          if (currentView != ViewType.management)
            Positioned(
              top: -96,
              left: 24,
              child: GestureDetector(
                onTap: () => setState(() => currentView = ViewType.management),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA3781F),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),

          // Bottom Navigation
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 40,
                  offset: Offset(0, -15),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(ViewType.profile, Icons.person, 'ملفي'),
                _buildNavItem(ViewType.stances, Icons.groups, 'المواقف'),
                _buildCenterNavItem(),
                _buildNavItem(
                    ViewType.crimes, Icons.local_fire_department, 'الجرائم'),
                _buildNavItem(ViewType.martyrs, Icons.people, 'الشهداء'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(ViewType viewType, IconData icon, String label) {
    final isActive = currentView == viewType;
    return GestureDetector(
      onTap: () => setState(() => currentView = viewType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: isActive ? const EdgeInsets.all(6) : EdgeInsets.zero,
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                icon,
                color: isActive
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isActive
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => currentView = ViewType.home),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: currentView == ViewType.home
                    ? const Color(0xFF0D9488)
                    : const Color(0xFF14B8A6),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5EEAD4).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
