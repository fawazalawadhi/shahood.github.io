import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invitation_draft.dart';
import '../models/gallery_layout.dart';
import '../models/invitation_section.dart';
import '../models/section_icon_presets.dart';
import '../theme/app_fonts.dart';

/// يبني الويدجت المناسب لكل نوع قسم. يُستدعى لكل قسم مفعّل بالترتيب
/// المحدد من المستخدم.
Widget buildSectionWidget(SectionType type, InvitationDraft draft, Color accent) {
  switch (type) {
    case SectionType.welcomeNote:
      return _WelcomeNoteSection(draft: draft, accent: accent);
    case SectionType.hostNames:
      return _HostNamesSection(draft: draft, accent: accent);
    case SectionType.gallery:
      return _GallerySection(draft: draft, accent: accent);
    case SectionType.dateTime:
      return _DateTimeSection(draft: draft, accent: accent);
    case SectionType.location:
      return _LocationSection(draft: draft, accent: accent);
    case SectionType.rules:
      return _RulesSection(draft: draft, accent: accent);
    case SectionType.countdown:
      return _CountdownSection(draft: draft, accent: accent);
    case SectionType.gifts:
      return _GiftsSection(draft: draft, accent: accent);
    case SectionType.whatsappContact:
      return _WhatsappSection(draft: draft, accent: accent);
    case SectionType.rsvp:
      return _RsvpSection(draft: draft, accent: accent);
  }
}

class _SectionShell extends StatelessWidget {
  final Widget child;
  final String? headerLabel;
  final IconData? headerIcon;
  final InvitationDraft draft;
  final Color accent;
  const _SectionShell({required this.child, required this.draft, required this.accent, this.headerLabel, this.headerIcon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Column(
        children: [
          if (headerLabel != null) ...[
            Icon(headerIcon, color: accent, size: 22),
            const SizedBox(height: 6),
            Text(
              headerLabel!,
              style: AppFonts.style(draft.titlesFontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: accent),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _WelcomeNoteSection extends StatelessWidget {
  final InvitationDraft draft;
  final Color accent;
  const _WelcomeNoteSection({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (draft.welcomeNoteText.trim().isEmpty) return const SizedBox.shrink();
    return _SectionShell(
      draft: draft,
      accent: accent,
      child: Text(
        draft.welcomeNoteText,
        textAlign: TextAlign.center,
        style: AppFonts.style(draft.bodyFontFamily, fontSize: 16, fontWeight: FontWeight.w400)
            .copyWith(height: 1.6, fontStyle: FontStyle.italic, color: Colors.black87),
      ),
    );
  }
}

class _HostNamesSection extends StatelessWidget {
  final InvitationDraft draft;
  final Color accent;
  const _HostNamesSection({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (draft.hostFamilyLine1.trim().isEmpty && draft.hostFamilyLine2.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return _SectionShell(
      draft: draft,
      accent: accent,
      headerLabel: 'يتشرف بدعوتكم',
      headerIcon: resolveSectionIcon(SectionType.hostNames, draft.sectionIconChoice),
      child: Column(
        children: [
          if (draft.hostFamilyLine1.trim().isNotEmpty)
            Text(draft.hostFamilyLine1,
                textAlign: TextAlign.center,
                style: AppFonts.style(draft.namesFontFamily, fontSize: 18, fontWeight: FontWeight.w700)),
          if (draft.hostFamilyLine1.trim().isNotEmpty && draft.hostFamilyLine2.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('&', style: AppFonts.style(draft.namesFontFamily, fontSize: 16, color: accent)),
            ),
          if (draft.hostFamilyLine2.trim().isNotEmpty)
            Text(draft.hostFamilyLine2,
                textAlign: TextAlign.center,
                style: AppFonts.style(draft.namesFontFamily, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  final InvitationDraft draft;
  final Color accent;
  const _GallerySection({required this.draft, required this.accent});

  Widget _img(String path) {
    Widget child;
    final fallback = Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image_outlined, color: Colors.white));
    if (path.startsWith('assets/')) {
      child = Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    } else if (kIsWeb || path.startsWith('http')) {
      child = Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    } else {
      child = Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: child);
  }

  @override
  Widget build(BuildContext context) {
    final images = draft.galleryImagePaths;
    if (images.isEmpty) return const SizedBox.shrink();

    Widget content;
    switch (draft.galleryLayout) {
      case GalleryLayout.grid:
        content = GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
          children: images.map((p) => _img(p)).toList(),
        );
        break;
      case GalleryLayout.stacked:
        content = Column(
          children: images
              .map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AspectRatio(aspectRatio: 4 / 3, child: _img(p)),
                  ))
              .toList(),
        );
        break;
      case GalleryLayout.sideBySide:
        content = SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => SizedBox(width: 140, child: _img(images[i])),
          ),
        );
        break;
    }

    return _SectionShell(draft: draft, accent: accent, headerLabel: 'صور من المناسبة', headerIcon: resolveSectionIcon(SectionType.gallery, draft.sectionIconChoice), child: content);
  }
}

class _DateTimeSection extends StatelessWidget {
  final InvitationDraft draft;
  final Color accent;
  const _DateTimeSection({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (draft.eventDate == null) return const SizedBox.shrink();
    final formatted = DateFormat('EEEE d MMMM yyyy - hh:mm a', 'ar').format(draft.eventDate!);
    return _SectionShell(
      draft: draft,
      accent: accent,
      headerLabel: 'التاريخ والوقت',
      headerIcon: resolveSectionIcon(SectionType.dateTime, draft.sectionIconChoice),
      child: Text(formatted, style: AppFonts.style(draft.bodyFontFamily, fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final InvitationDraft draft;
  final Color accent;
  const _LocationSection({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    if ((draft.locationText ?? '').trim().isEmpty) return const SizedBox.shrink();
    return _SectionShell(
      draft: draft,
      accent: accent,
      headerLabel: 'الموقع',
      headerIcon: resolveSectionIcon(SectionType.location, draft.sectionIconChoice),
      child: Column(
        children: [
          Text(draft.locationText!, textAlign: TextAlign.center, style: AppFonts.style(draft.bodyFontFamily, fontSize: 15)),
          if ((draft.locationMapUrl ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton.icon(
                onPressed: () {}, // TODO: فتح الرابط عبر url_launcher عند ربطه
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('فتح الموقع على الخريطة'),
              ),
            ),
        ],
      ),
    );
  }
}

class _RulesSection extends StatelessWidget {
  final InvitationDraft draft;
  final Color accent;
  const _RulesSection({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (draft.rulesText.trim().isEmpty) return const SizedBox.shrink();
    return _SectionShell(
      draft: draft,
      accent: accent,
      headerLabel: 'قواعد وتعليمات الحفل',
      headerIcon: resolveSectionIcon(SectionType.rules, draft.sectionIconChoice),
      child: Text(
        draft.rulesText,
        textAlign: TextAlign.center,
        style: AppFonts.style(draft.bodyFontFamily, fontSize: 14, fontWeight: FontWeight.w400).copyWith(height: 1.6),
      ),
    );
  }
}

class _CountdownSection extends StatefulWidget {
  final InvitationDraft draft;
  final Color accent;
  const _CountdownSection({required this.draft, required this.accent});

  @override
  State<_CountdownSection> createState() => _CountdownSectionState();
}

class _CountdownSectionState extends State<_CountdownSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.draft.eventDate == null) return const SizedBox.shrink();
    final diff = widget.draft.eventDate!.difference(DateTime.now());
    if (diff.isNegative) {
      return _SectionShell(
        draft: widget.draft,
        accent: widget.accent,
        child: Text('المناسبة الآن 🎉',
            style: AppFonts.style(widget.draft.bodyFontFamily, fontWeight: FontWeight.bold, fontSize: 16, color: widget.accent)),
      );
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    Widget unit(String value, String label) => Column(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(color: widget.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(value,
                  textAlign: TextAlign.center,
                  style: AppFonts.style(widget.draft.bodyFontFamily, fontWeight: FontWeight.bold, fontSize: 18, color: widget.accent)),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        );

    return _SectionShell(
      draft: widget.draft,
      accent: widget.accent,
      headerLabel: 'باقي على المناسبة',
      headerIcon: resolveSectionIcon(SectionType.countdown, widget.draft.sectionIconChoice),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          unit('$days', 'يوم'),
          const SizedBox(width: 8),
          unit('$hours', 'ساعة'),
          const SizedBox(width: 8),
          unit('$minutes', 'دقيقة'),
          const SizedBox(width: 8),
          unit('$seconds', 'ثانية'),
        ],
      ),
    );
  }
}

class _GiftsSection extends StatefulWidget {
  final InvitationDraft draft;
  final Color accent;
  const _GiftsSection({required this.draft, required this.accent});

  @override
  State<_GiftsSection> createState() => _GiftsSectionState();
}

class _GiftsSectionState extends State<_GiftsSection> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if ((widget.draft.giftAccountsText ?? '').trim().isEmpty) return const SizedBox.shrink();
    return _SectionShell(
      draft: widget.draft,
      accent: widget.accent,
      headerLabel: 'الهدايا',
      headerIcon: resolveSectionIcon(SectionType.gifts, widget.draft.sectionIconChoice),
      child: _revealed
          ? Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: widget.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: SelectableText(
                widget.draft.giftAccountsText!,
                textAlign: TextAlign.center,
                style: AppFonts.style(widget.draft.bodyFontFamily, fontSize: 14),
              ),
            )
          : OutlinedButton.icon(
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.card_giftcard, size: 18),
              label: const Text('عرض حسابات الهدايا'),
            ),
    );
  }
}

class _WhatsappSection extends StatelessWidget {
  final InvitationDraft draft;
  final Color accent;
  const _WhatsappSection({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    if ((draft.whatsappNumber ?? '').trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Material(
          color: const Color(0xFF25D366),
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {}, // TODO: فتح wa.me/<الرقم> عبر url_launcher عند ربطه
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(resolveSectionIcon(SectionType.whatsappContact, draft.sectionIconChoice), color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _RsvpSection extends StatefulWidget {
  final InvitationDraft draft;
  final Color accent;
  const _RsvpSection({required this.draft, required this.accent});

  @override
  State<_RsvpSection> createState() => _RsvpSectionState();
}

class _RsvpSectionState extends State<_RsvpSection> {
  bool? _attending;
  int _guestCount = 1;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      draft: widget.draft,
      accent: widget.accent,
      headerLabel: 'تأكيد الحضور',
      headerIcon: resolveSectionIcon(SectionType.rsvp, widget.draft.sectionIconChoice),
      child: Column(
        children: [
          if ((widget.draft.rsvpNote ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(widget.draft.rsvpNote!,
                  textAlign: TextAlign.center, style: AppFonts.style(widget.draft.bodyFontFamily, fontSize: 13, color: Colors.grey)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RsvpButton(label: 'سأحضر ✓', selected: _attending == true, color: widget.accent, onTap: () => setState(() => _attending = true)),
              const SizedBox(width: 10),
              _RsvpButton(label: 'اعتذر', selected: _attending == false, color: Colors.grey, onTap: () => setState(() => _attending = false)),
            ],
          ),
          if (_attending == true && widget.draft.rsvpAllowGuestCount)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('عدد المرافقين: '),
                  IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _guestCount = (_guestCount - 1).clamp(0, 20))),
                  Text('$_guestCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _guestCount = (_guestCount + 1).clamp(0, 20))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _RsvpButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
