import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_category.dart';
import '../../providers/design_provider.dart';
import '../../providers/template_provider.dart';
import '../../theme/app_theme.dart';
import '../design_screen.dart';

/// شاشة الأدمن: عرض كل القوالب العامة الحالية، مع إمكانية التعديل عليها
/// (يفتح نفس شاشة التصميم التي يستخدمها أي مستخدم) أو حذفها أو إعادة تسميتها.
/// لإضافة قالب جديد: الأدمن يضغط "تصميم قالب جديد"، يصمم عبر شاشة التصميم
/// العادية، وعند الحفظ يفعّل خيار "قالب عام" ليظهر للجميع في المعرض.
class AdminTemplatesScreen extends StatelessWidget {
  const AdminTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateProvider>().systemTemplates();

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الأدمن - القوالب العامة')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<DesignProvider>().resetBlank();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('تصميم قالب جديد'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softGradient),
        child: templates.isEmpty
            ? const Center(child: Text('لا توجد قوالب عامة بعد. اضغط "تصميم قالب جديد" للبدء.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Color(t.draftSnapshot.primaryColorValue),
                        child: const Icon(Icons.card_giftcard, color: Colors.white),
                      ),
                      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t.category.arabicLabel),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'فتح للتعديل في شاشة التصميم',
                            onPressed: () {
                              context.read<DesignProvider>().loadFromTemplate(t);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen()));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.drive_file_rename_outline),
                            tooltip: 'إعادة تسمية',
                            onPressed: () => _renameDialog(context, t.id, t.name),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, t.id, t.name),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _renameDialog(BuildContext context, String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة تسمية القالب'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              context.read<TemplateProvider>().renameTemplate(id, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القالب'),
        content: Text('متأكد تبي تحذف "$name"؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              context.read<TemplateProvider>().deleteTemplate(id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
