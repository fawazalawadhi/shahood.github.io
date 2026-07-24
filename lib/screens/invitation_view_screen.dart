import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invitation_draft.dart';
import '../providers/design_provider.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../widgets/live_preview.dart';

/// شاشة عرض الدعوة العامة: هذي الشاشة التي يفتحها الضيف عند الضغط على رابط
/// الدعوة المُرسَل له (مثلاً azzama.com/i/ahmad-sara-abc123)، بدون أي
/// تسجيل دخول. تجلب بيانات الدعوة من public.invitations حسب [slug]
/// (سياسة RLS "anyone can view published invitations" تسمح بهذا)
/// وتعرضها للقراءة فقط عبر نفس [LivePreview] المستخدمة أثناء التصميم.
class InvitationViewScreen extends StatefulWidget {
  final String slug;
  const InvitationViewScreen({super.key, required this.slug});

  @override
  State<InvitationViewScreen> createState() => _InvitationViewScreenState();
}

class _InvitationViewScreenState extends State<InvitationViewScreen> {
  bool _loading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await supabase.from('invitations').select().eq('slug', widget.slug).maybeSingle();
      if (!mounted) return;
      if (row == null) {
        setState(() {
          _notFound = true;
          _loading = false;
        });
        return;
      }
      final draft = InvitationDraft.fromJson(row['draft_json'] as Map<String, dynamic>);
      context.read<DesignProvider>().loadDraftForViewing(draft, invitationId: row['id'] as String);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notFound = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_notFound) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.softGradient),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'هذه الدعوة غير موجودة أو تم حذفها.\nتأكد من الرابط وحاول مرة أخرى.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: LivePreview());
  }
}
