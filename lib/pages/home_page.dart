import 'package:flutter/material.dart';
import '../models/models.dart';
import '../widgets/image_helper.dart';

class HomePage extends StatelessWidget {
  final List<Martyr> martyrs;
  final List<Stance> stances;
  final List<Stance> crimes;
  final Function(Martyr) onSelectMartyr;

  const HomePage({
    Key? key,
    required this.martyrs,
    required this.stances,
    required this.crimes,
    required this.onSelectMartyr,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final featuredMartyr = martyrs.isNotEmpty ? martyrs[0] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'ذاكرة الوفاء',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            'سجل الخلود والبطولة',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF0D9488),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'شهيد اليوم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'جديد',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  featuredMartyr != null
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFF8FAFC)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 256,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                      child: ImageHelper.buildImage(
                                        featuredMartyr.imageUrl,
                                        width: double.infinity,
                                        height: 256,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.8),
                                          ],
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                featuredMartyr.name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                featuredMartyr.title,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF5EEAD4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => onSelectMartyr(featuredMartyr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D9488),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor: const Color(0xFF0D9488).withOpacity(0.3),
                                    ),
                                    child: const Text(
                                      'قراءة السيرة العطرة',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          height: 224,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 32,
                                  color: Color(0x3394A3B8),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'لا توجد بيانات متاحة حالياً',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0x3394A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Lists
            _buildSection('الشهداء', martyrs.skip(1).toList(), (martyr) => onSelectMartyr(martyr as Martyr)),
            const SizedBox(height: 48),
            _buildSection('جرائم لا تُنسى', crimes, null),
            const SizedBox(height: 48),
            _buildSection('تخليد المواقف', stances, null),
            const SizedBox(height: 128),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, Function(dynamic)? onSelect) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'الكل',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'القائمة بانتظار التحديث...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFCBD5E1),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => onSelect?.call(item),
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(left: 16),
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
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    child: ImageHelper.buildImage(
                                      item.imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.6),
                                        ],
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              item is Martyr ? item.name : item.title,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item is Martyr ? item.title : item.subtitle,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF5EEAD4),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'التفاصيل',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}