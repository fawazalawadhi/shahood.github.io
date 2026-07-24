import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_category.dart';
import '../models/template_model.dart';
import '../providers/auth_provider.dart';
import '../providers/design_provider.dart';
import '../providers/template_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/smart_image.dart';
import 'design_screen.dart';

class TemplateGalleryScreen extends StatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> with SingleTickerProviderStateMixin {
  EventCategory? _filter; // null = عرض الكل
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر قالبك'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'القوالب العامة'), Tab(text: 'قوالبي الخاصة')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: OutlinedButton.icon(
                onPressed: () => _startBlank(context),
                icon: const Icon(Icons.add),
                label: const Text('ابدأ تصميم من فراغ (بدون قالب)'),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SystemTemplatesTab(
                    filter: _filter,
                    onFilterChanged: (c) => setState(() => _filter = c),
                    templates: templates,
                  ),
                  _MyTemplatesTab(templates: templates, userId: userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startBlank(BuildContext context) {
    context.read<DesignProvider>().resetBlank();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen()));
  }
}

class _SystemTemplatesTab extends StatelessWidget {
  final EventCategory? filter;
  final ValueChanged<EventCategory?> onFilterChanged;
  final TemplateProvider templates;
  const _SystemTemplatesTab({required this.filter, required this.onFilterChanged, required this.templates});

  @override
  Widget build(BuildContext context) {
    final items = filter == null ? templates.systemTemplates() : templates.byCategory(filter!);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChipItem(label: 'الكل', selected: filter == null, onTap: () => onFilterChanged(null)),
                ...EventCategory.values.map((c) => _FilterChipItem(
                      label: c.arabicLabel,
                      selected: filter == c,
                      onTap: () => onFilterChanged(c),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (templates.lastErrorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('تعذّر الاتصال بقاعدة البيانات، نعرض قوالب مؤقتة.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: templates.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('لا توجد قوالب في هذا التصنيف بعد'))
                    : _TemplateGrid(
                        items: items,
                        cardBuilder: (t) => _TemplateCard(
                          name: t.name,
                          thumbnailImagePath: t.thumbnailImagePath,
                          categoryLabel: t.category.arabicLabel,
                          onTap: () => _openInDesigner(context, t),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MyTemplatesTab extends StatelessWidget {
  final TemplateProvider templates;
  final String? userId;
  const _MyTemplatesTab({required this.templates, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('سجّل الدخول لعرض وحفظ قوالبك الخاصة.', textAlign: TextAlign.center),
        ),
      );
    }
    if (templates.isLoading) return const Center(child: CircularProgressIndicator());

    final items = templates.userTemplates(userId!);
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لا توجد قوالب خاصة بعد.\nيمكنك حفظ تصميمك الحالي كقالب من شاشة التصميم (حتى 3 قوالب).',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _TemplateGrid(
        items: items,
        cardBuilder: (t) => _TemplateCard(
          name: t.name,
          thumbnailImagePath: t.thumbnailImagePath,
          categoryLabel: t.category.arabicLabel,
          onTap: () => _openInDesigner(context, t),
          onDelete: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('حذف القالب'),
                content: Text('متأكد تبي تحذف "${t.name}"؟'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
                ],
              ),
            );
            if (confirmed != true) return;
            final messenger = ScaffoldMessenger.of(context);
            try {
              await context.read<TemplateProvider>().deleteTemplate(t.id);
            } catch (_) {
              messenger.showSnackBar(const SnackBar(content: Text('تعذّر حذف القالب، حاول مرة أخرى.')));
            }
          },
        ),
      ),
    );
  }
}

void _openInDesigner(BuildContext context, TemplateModel template) {
  context.read<DesignProvider>().loadFromTemplate(template);
  Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignScreen()));
}

class _TemplateGrid extends StatelessWidget {
  final List<TemplateModel> items;
  final Widget Function(TemplateModel t) cardBuilder;
  const _TemplateGrid({required this.items, required this.cardBuilder});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => cardBuilder(items[index]),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChipItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String name;
  final String categoryLabel;
  final String? thumbnailImagePath;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _TemplateCard({
    required this.name,
    required this.categoryLabel,
    required this.onTap,
    this.thumbnailImagePath,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasThumbnail = (thumbnailImagePath ?? '').isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasThumbnail)
                    SmartImage(path: thumbnailImagePath, fit: BoxFit.cover, errorBuilder: (_) => _placeholder())
                  else
                    _placeholder(),
                  if (onDelete != null)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: Material(
                        color: Colors.black26,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'حذف',
                          icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                          onPressed: onDelete,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                children: [
                  Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(categoryLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],

              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(child: Icon(Icons.card_giftcard, color: Colors.white, size: 40)),
      );
}
