import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_category.dart';
import '../providers/design_provider.dart';
import '../providers/template_provider.dart';
import '../theme/app_theme.dart';
import 'design_screen.dart';

class TemplateGalleryScreen extends StatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  State<TemplateGalleryScreen> createState() => _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends State<TemplateGalleryScreen> {
  EventCategory? _filter; // null = عرض الكل

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateProvider>();
    final items = _filter == null
        ? templates.systemTemplates()
        : templates.byCategory(_filter!);

    return Scaffold(
      appBar: AppBar(title: const Text('اختر قالبك')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softGradient),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChipItem(
                    label: 'الكل',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ...EventCategory.values.map((c) => _FilterChipItem(
                        label: c.arabicLabel,
                        selected: _filter == c,
                        onTap: () => setState(() => _filter = c),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('لا توجد قوالب في هذا التصنيف بعد'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final t = items[index];
                        return _TemplateCard(
                          name: t.name,
                          categoryLabel: t.category.arabicLabel,
                          onTap: () {
                            context.read<DesignProvider>().loadFromTemplate(t);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DesignScreen()),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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
  final VoidCallback onTap;
  const _TemplateCard({required this.name, required this.categoryLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: const Icon(Icons.card_giftcard, color: Colors.white, size: 40),
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
}
