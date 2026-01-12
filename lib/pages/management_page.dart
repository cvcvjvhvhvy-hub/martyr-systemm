import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../widgets/image_helper.dart';

class ManagementPage extends StatefulWidget {
  final VoidCallback onDataChange;

  const ManagementPage({Key? key, required this.onDataChange}) : super(key: key);

  @override
  State<ManagementPage> createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  String? showForm;
  String? editingId;
  List<Martyr> martyrs = [];
  List<Stance> stances = [];
  List<Stance> crimes = [];

  final _formData = {
    'name': '',
    'title': '',
    'birthDate': '',
    'martyrdomDate': '',
    'cause': '',
    'rank': '',
    'job': '',
    'bio': '',
    'imageUrl': '',
  };

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل البيانات: $e')),
      );
    }
  }

  Future<void> _handleImagePicker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (bytes.length > 800 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حجم الصورة كبير، يرجى اختيار صورة أصغر من 800 كيلوبايت.')),
        );
        return;
      }
      
      final base64String = base64Encode(bytes);
      setState(() {
        _formData['imageUrl'] = 'data:image/jpeg;base64,$base64String';
      });
    }
  }

  void _startEdit(String type, dynamic item) {
    setState(() {
      editingId = item.id;
      showForm = type;
      
      if (type == 'martyr') {
        final m = item as Martyr;
        _formData['name'] = m.name;
        _formData['title'] = m.title;
        _formData['birthDate'] = m.birthDate;
        _formData['martyrdomDate'] = m.martyrdomDate;
        _formData['cause'] = m.cause;
        _formData['rank'] = m.rank;
        _formData['job'] = m.job;
        _formData['bio'] = m.bio;
        _formData['imageUrl'] = m.imageUrl;
      } else {
        final s = item as Stance;
        _formData['name'] = s.title;
        _formData['title'] = s.subtitle;
        _formData['imageUrl'] = s.imageUrl;
      }
    });
  }

  void _closeForm() {
    setState(() {
      showForm = null;
      editingId = null;
      _formData.updateAll((key, value) => '');
    });
  }

  Future<void> _handleSubmit() async {
    try {
      final id = editingId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      if (showForm == 'martyr') {
        final newMartyr = Martyr(
          id: id,
          name: _formData['name']!,
          title: _formData['title']!,
          birthDate: _formData['birthDate']!,
          martyrdomDate: _formData['martyrdomDate']!,
          cause: _formData['cause']!,
          rank: _formData['rank']!,
          job: _formData['job']!,
          bio: _formData['bio']!,
          imageUrl: _formData['imageUrl']!,
          battles: [],
        );
        
        if (editingId != null) {
          await FirebaseService.updateMartyr(newMartyr);
        } else {
          await FirebaseService.addMartyr(newMartyr);
        }
      } else {
        final newItem = Stance(
          id: id,
          title: _formData['name']!,
          subtitle: _formData['title']!,
          imageUrl: _formData['imageUrl']!,
        );
        
        if (showForm == 'crime') {
          if (editingId != null) {
            await FirebaseService.updateCrime(newItem);
          } else {
            await FirebaseService.addCrime(newItem);
          }
        } else {
          if (editingId != null) {
            await FirebaseService.updateStance(newItem);
          } else {
            await FirebaseService.addStance(newItem);
          }
        }
      }

      _closeForm();
      widget.onDataChange();
      _loadLists();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ البيانات بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في حفظ البيانات: $e')),
      );
    }
  }

  Future<void> _handleDelete(String store, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا السجل نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (store == 'martyrs') {
          await FirebaseService.deleteMartyr(id);
        } else if (store == 'stances') {
          await FirebaseService.deleteStance(id);
        } else {
          await FirebaseService.deleteCrime(id);
        }
        
        widget.onDataChange();
        _loadLists();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف السجل بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في حذف السجل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 128),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'إدارة البيانات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(child: _buildAddButton('شهيد', () => setState(() => showForm = 'martyr'), const Color(0xFF0D9488))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAddButton('موقف', () => setState(() => showForm = 'stance'), const Color(0xFF14B8A6))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAddButton('جريمة', () => setState(() => showForm = 'crime'), const Color(0xFF334155))),
                  ],
                ),

                const SizedBox(height: 40),

                _buildListSection('سجل الشهداء', martyrs, 'martyr'),
                const SizedBox(height: 40),
                _buildListSection('المواقف', stances, 'stance'),
                const SizedBox(height: 40),
                _buildListSection('الجرائم', crimes, 'crime'),
              ],
            ),
          ),

          if (showForm != null) _buildFormOverlay(),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed, Color color) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic> items, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            Text(
              '${items.length} عنصر',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        items.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'فارغ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFCBD5E1),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            : Column(
                children: items.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ImageHelper.buildImage(
                          item.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item is Martyr ? item.name : item.title,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF334155),
                              ),
                            ),
                            Text(
                              item is Martyr ? item.title : item.subtitle,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _startEdit(type, item),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDFA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Color(0xFF0D9488),
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _handleDelete(
                              type == 'martyr' ? 'martyrs' : type == 'stance' ? 'stances' : 'crimes',
                              item.id,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Color(0xFFDC2626),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
              ),
      ],
    );
  }

  Widget _buildFormOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editingId != null ? 'تعديل السجل' : 'إضافة سجل جديد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Image picker
                GestureDetector(
                  onTap: _handleImagePicker,
                  child: Container(
                    width: double.infinity,
                    height: 176,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _formData['imageUrl']!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: ImageHelper.buildImage(
                          _formData['imageUrl']!,
                          fit: BoxFit.cover,
                        ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 32,
                                color: Color(0x4D94A3B8),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'تحميل صورة',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0x4D94A3B8),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                _buildTextField('الاسم / العنوان', 'name', true),
                const SizedBox(height: 16),
                _buildTextField('الوصف المختصر', 'title', false),

                if (showForm == 'martyr') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('الميلاد', 'birthDate', false)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('الاستشهاد', 'martyrdomDate', false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('الرتبة', 'rank', false),
                  const SizedBox(height: 16),
                  _buildTextField('السيرة العطرة...', 'bio', false, maxLines: 4),
                ],

                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
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
                          'حفظ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _closeForm,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
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

  Widget _buildTextField(String hint, String key, bool required, {int maxLines = 1}) {
    return TextFormField(
      initialValue: _formData[key],
      onChanged: (value) => _formData[key] = value,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF0D9488)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF1E293B),
      ),
    );
  }
}