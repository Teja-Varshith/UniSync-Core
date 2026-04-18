import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/peer_connect/peers/peer_card.dart';
import 'package:UniSync/features/peer_connect/peers/peer_controller.dart';
import 'package:UniSync/models/peer_model.dart';

class _PeerProfilePalette {
  const _PeerProfilePalette({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.success,
  });

  final bool isDark;
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color success;

  factory _PeerProfilePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return _PeerProfilePalette(
      isDark: isDark,
      bg: theme.scaffoldBackgroundColor,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceAlt: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
      border: border,
      divider: border.withValues(alpha: isDark ? 0.9 : 1),
      textPrimary: scheme.onSurface,
      textSecondary:
          isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      textMuted: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      success: AppColors.success,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PeerProfile
// ─────────────────────────────────────────────────────────────────────────────
class PeerProfile extends ConsumerStatefulWidget {
  const PeerProfile({super.key});

  @override
  ConsumerState<PeerProfile> createState() => _PeerProfileState();
}

class _PeerProfileState extends ConsumerState<PeerProfile> {
  void _openForm({PeerModel? existing, required String userId}) {
    final palette = _PeerProfilePalette.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: Border(
          top: BorderSide(color: palette.divider, width: 0.8)),
      builder: (_) => PeerCardFormSheet(
        peerModel: existing,
        userId: userId,
        onSave: () { Navigator.pop(context); setState(() {}); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PeerProfilePalette.of(context);
    final ctrl = ref.watch(PeerControllerProvider.notifier);
    final user = ref.watch(userProvider)!;
    final userId = user.id!;
    final liveCollegeName = user.collegeName;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(child: Column(children: [

        // ── Top bar ────────────────────────────────────────────────
        Container(
          color: palette.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            NeoPopButton(
              color: palette.surfaceAlt,
              bottomShadowColor: palette.border,
              rightShadowColor: palette.border,
              depth: 3,
              onTapUp: () => Navigator.pop(context),
              onTapDown: () {},
              child: SizedBox(width: 40, height: 40,
                  child: Center(child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: palette.textPrimary))),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#MY PEERCARD',
                  style: TextStyle(color: palette.accent, fontSize: 9,
                      fontWeight: FontWeight.w700, letterSpacing: 1.8)),
              const SizedBox(height: 2),
              RichText(text: TextSpan(children: [
                TextSpan(text: 'Your ',
                    style: TextStyle(color: palette.textPrimary,
                        fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                TextSpan(text: 'identity',
                    style: TextStyle(color: palette.accent,
                        fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              ])),
            ]),
          ]),
        ),
        Container(height: 0.8, color: palette.divider),

        // ── Body ──────────────────────────────────────────────────
        Expanded(
          child: FutureBuilder<PeerModel?>(
            future: ctrl.getMyPeerCard(userId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)));
              }
              if (snap.hasData) {
                return _ExistingProfile(
                  peerModel: snap.data!.copyWith(
                    userId: snap.data!.userId ?? userId,
                    collegeName: liveCollegeName,
                  ),
                  onEdit: () => _openForm(existing: snap.data!, userId: userId),
                );
              }
              return _CreatePrompt(
                  onTap: () => _openForm(userId: userId));
            },
          ),
        ),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EXISTING PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class _ExistingProfile extends StatelessWidget {
  const _ExistingProfile({required this.peerModel, required this.onEdit});
  final PeerModel peerModel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerProfilePalette.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Meta row
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your card',
                  style: TextStyle(color: palette.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Row(children: [
                Container(width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: peerModel.isPublic
                          ? palette.success
                          : palette.textMuted,
                      shape: BoxShape.circle,
                    )),
                const SizedBox(width: 6),
                Text(
                  peerModel.isPublic
                      ? 'Visible to everyone'
                      : 'Only visible to you',
                  style: TextStyle(
                    color: palette.textMuted, fontSize: 12),
                ),
              ]),
            ],
          )),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                border: Border.all(color: palette.accent.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_outlined, size: 13, color: palette.accent),
                SizedBox(width: 6),
                Text('Edit', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: palette.accent,
                )),
              ]),
            ),
          ),
        ]),

        const SizedBox(height: 20),
        PeerCard(peerModel: peerModel),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREATE PROMPT
// ─────────────────────────────────────────────────────────────────────────────
class _CreatePrompt extends StatelessWidget {
  const _CreatePrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerProfilePalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            color: palette.surfaceAlt,
            child: Icon(Icons.person_add_alt_1_rounded,
                color: palette.accent, size: 30),
          ),
          const SizedBox(height: 22),
          Text('No PeerCard yet',
              style: TextStyle(color: palette.textPrimary,
                  fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text('Create your card and let other students discover you',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary,
                  fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
          NeoPopButton(
            color: palette.accent,
            bottomShadowColor: palette.bg,
            rightShadowColor: palette.bg,
            depth: 5,
            buttonPosition: Position.fullBottom,
            onTapUp: onTap, onTapDown: () {},
            child: SizedBox(height: 50, width: 220,
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 18, color: palette.onAccent),
                SizedBox(width: 8),
                Text('Create PeerCard', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: palette.onAccent, letterSpacing: 0.2,
                )),
              ]))),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class PeerCardFormSheet extends ConsumerStatefulWidget {
  const PeerCardFormSheet({
    super.key, this.peerModel,
    required this.userId, required this.onSave,
  });
  final PeerModel? peerModel;
  final String userId;
  final VoidCallback onSave;

  @override
  ConsumerState<PeerCardFormSheet> createState() => _PeerCardFormSheetState();
}

class _PeerCardFormSheetState extends ConsumerState<PeerCardFormSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _profileCtrl  = TextEditingController();
  final _gitHubCtrl   = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _skillCtrl    = TextEditingController();
  final _traitCtrl    = TextEditingController();

  List<String> _skills = [];
  List<String> _traits = [];
  bool _isPublic       = true;
  bool _isLoading      = false;

  // ── NEW: card style picker
  String _cardStyle = 'minimal'; // 'techy' | 'minimal'

  @override
  void initState() {
    super.initState();
    if (widget.peerModel != null) _prefill();
  }

  void _prefill() {
    final p = widget.peerModel!;
    _nameCtrl.text     = p.name;
    _bioCtrl.text      = p.bio;
    _gitHubCtrl.text   = p.gitHubLink ?? '';
    _linkedinCtrl.text = p.linkedinLink ?? '';
    _skills            = List.from(p.skills);
    _traits            = List.from(p.traits);
    _isPublic          = p.isPublic;
    _cardStyle         = p.cardStyle ?? 'minimal'; // ← from model
  }

  void _addChip(TextEditingController c, List<String> list) {
    final t = c.text.trim();
    if (t.isNotEmpty && !list.contains(t)) {
      setState(() { list.add(t); c.clear(); });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) { _snack('Add at least one skill'); return; }
    final user = ref.read(userProvider);
    final collegeName = user?.collegeName ?? widget.peerModel?.collegeName;
    setState(() => _isLoading = true);
    try {
      final model = PeerModel(
        userId:      widget.userId,
        name:        _nameCtrl.text.trim(),
        collegeName: collegeName,
        profileLink: _profileCtrl.text.trim().isEmpty ? null : _profileCtrl.text.trim(),
        skills:      _skills,
        gitHubLink:  _gitHubCtrl.text.trim().isEmpty ? null : _gitHubCtrl.text.trim(),
        linkedinLink:_linkedinCtrl.text.trim(),
        traits:      _traits,
        bio:         _bioCtrl.text.trim(),
        isPublic:    _isPublic,
        lastActive:  DateTime.now(),
        cardStyle:   _cardStyle,        // ← save chosen style
      );
      await ref.read(PeerControllerProvider.notifier)
          .createPeerCard(model, widget.userId);
      widget.onSave();
      _snack(widget.peerModel != null
          ? 'PeerCard updated!' : 'PeerCard created!', ok: true);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _snack(String m, {bool ok = false}) =>
      _showSnack(m, ok: ok);

  void _showSnack(String m, {bool ok = false}) {
    final palette = _PeerProfilePalette.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m),
        backgroundColor: ok ? palette.success : palette.surfaceAlt,
      ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose(); _profileCtrl.dispose();
    _gitHubCtrl.dispose(); _linkedinCtrl.dispose();
    _skillCtrl.dispose(); _traitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PeerProfilePalette.of(context);
    final isEdit = widget.peerModel != null;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: palette.border,
              borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  border: Border.all(color: palette.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close_rounded, size: 16,
                    color: palette.textSecondary),
              ),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isEdit ? '#EDIT' : '#CREATE',
                  style: TextStyle(color: palette.accent, fontSize: 9,
                      fontWeight: FontWeight.w700, letterSpacing: 1.8)),
              Text(isEdit ? 'Update your card' : 'Build your card',
                  style: TextStyle(color: palette.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Container(height: 0.8, color: palette.divider),

        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [

                // ── Card style picker ──────────────────────────────
                _SectionLabel(label: 'CARD STYLE'),
                const SizedBox(height: 10),
                _CardStylePicker(
                  selected: _cardStyle,
                  onChange: (s) => setState(() => _cardStyle = s),
                ),
                const SizedBox(height: 22),

                // ── Form fields ────────────────────────────────────
                _FormField(ctrl: _nameCtrl, label: 'FULL NAME',
                    hint: 'Your full name',
                    validator: (v) => v!.isEmpty ? 'Required' : null),

                _FormField(ctrl: _bioCtrl, label: 'BIO',
    hint: 'Tell others about yourself...', maxLines: null,
    validator: (v) => v!.isEmpty ? 'Required' : null),


                _FormField(ctrl: _gitHubCtrl,
                    label: 'GITHUB (optional)',
                    hint: 'https://github.com/username'),

                _FormField(ctrl: _linkedinCtrl, label: 'LINKEDIN',
                    hint: 'https://linkedin.com/in/username'),

                _ChipField(
                  label: 'SKILLS',
                  hint: 'e.g. Flutter, Python',
                  ctrl: _skillCtrl, items: _skills,
                  onAdd: () => _addChip(_skillCtrl, _skills),
                  onRemove: (s) => setState(() => _skills.remove(s)),
                ),

                _ChipField(
                  label: 'INTERESTS / TRAITS',
                  hint: 'e.g. Open Source, Leadership',
                  ctrl: _traitCtrl, items: _traits,
                  onAdd: () => _addChip(_traitCtrl, _traits),
                  onRemove: (t) => setState(() => _traits.remove(t)),
                ),

                // Public toggle
                Container(
                  color: palette.surface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Public profile', style: TextStyle(
                          color: palette.textPrimary, fontSize: 14,
                          fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('Allow others to discover your card',
                            style: TextStyle(
                              color: palette.textMuted, fontSize: 12)),
                      ],
                    )),
                    Switch(
                      value: _isPublic,
                      onChanged: (v) => setState(() => _isPublic = v),
                      activeColor: palette.accent,
                    ),
                  ]),
                ),

                const SizedBox(height: 28),

                NeoPopButton(
                  color: palette.accent,
                  bottomShadowColor: palette.bg,
                  rightShadowColor: palette.bg,
                  depth: 5,
                  buttonPosition: Position.fullBottom,
                  onTapUp: _isLoading ? null : _save,
                  onTapDown: () {},
                  child: SizedBox(height: 50, child: Center(
                    child: _isLoading
                        ? SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: palette.onAccent))
                        : Text(isEdit ? 'Update PeerCard' : 'Create PeerCard',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: palette.onAccent,
                                letterSpacing: 0.2)),
                  )),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CARD STYLE PICKER  — two preview tiles
// ─────────────────────────────────────────────────────────────────────────────
class _CardStylePicker extends StatelessWidget {
  const _CardStylePicker({
    required this.selected, required this.onChange,
  });
  final String selected;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StyleTile(
        id: 'techy',
        title: 'Techy',
        subtitle: 'Terminal / code style',
        icon: Icons.terminal_rounded,
        selected: selected == 'techy',
        onTap: () => onChange('techy'),
        previewBg: const Color(0xFF0D1117),
        previewAccent: const Color(0xFF3FB950),
      )),
      const SizedBox(width: 12),
      Expanded(child: _StyleTile(
        id: 'minimal',
        title: 'Minimal',
        subtitle: 'Clean & friendly',
        icon: Icons.auto_awesome_rounded,
        selected: selected == 'minimal',
        onTap: () => onChange('minimal'),
        previewBg: const Color(0xFFF0F4FF),
        previewAccent: const Color(0xFF4A6CF7),
      )),
    ]);
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.id, required this.title, required this.subtitle,
    required this.icon, required this.selected,
    required this.onTap, required this.previewBg, required this.previewAccent,
  });
  final String id, title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color previewBg, previewAccent;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerProfilePalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          border: Border.all(
            color: selected
                ? palette.accent
                : palette.border,
            width: selected ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Mini card preview
          Container(
            height: 52, width: double.infinity,
            decoration: BoxDecoration(
              color: previewBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: previewAccent.withOpacity(0.3)),
            ),
            child: Center(child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: previewAccent.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    )),
                const SizedBox(width: 6),
                Column(mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(width: 48, height: 5,
                      decoration: BoxDecoration(
                        color: previewAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3))),
                  const SizedBox(height: 4),
                  Container(width: 32, height: 4,
                      decoration: BoxDecoration(
                        color: previewAccent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(3))),
                ]),
              ],
            )),
          ),

          const SizedBox(height: 10),

          Row(children: [
            Icon(icon, size: 14,
                color: selected
                    ? palette.accent
                    : palette.textMuted),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(
              color: selected
                  ? palette.accent
                  : palette.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w700,
            )),
          ]),

          const SizedBox(height: 2),

          Text(subtitle, style: TextStyle(
            color: palette.textMuted, fontSize: 10,
          )),

          const SizedBox(height: 8),

          // Selected checkmark
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: selected ? 1 : 0,
            child: Container(
              height: 20, width: double.infinity,
              decoration: BoxDecoration(
                color: palette.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_rounded,
                      size: 11, color: palette.accent),
                  SizedBox(width: 4),
                  Text('Selected', style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: palette.accent, letterSpacing: 0.4,
                  )),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(
    color: _PeerProfilePalette.of(context).accent, fontSize: 9,
    fontWeight: FontWeight.w700, letterSpacing: 1.6,
  ));
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.ctrl, required this.label, required this.hint,
    this.maxLines = 1, this.validator,           // keep default as 1
  });
  final TextEditingController ctrl;
  final String label, hint;
  final int? maxLines;                           // int → int?
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerProfilePalette.of(context);
    return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel(label: label),
      const SizedBox(height: 7),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,                      // null = unlimited, expands naturally
        minLines: maxLines == null ? 4 : null,   // show at least 4 rows for bio
        keyboardType: maxLines == null
            ? TextInputType.multiline            // enables newline key on keyboard
            : TextInputType.text,
        validator: validator,
        style: TextStyle(color: palette.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
          filled: true,
          fillColor: palette.surfaceAlt,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: palette.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: palette.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: palette.accent, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE05252))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]),
  );
  }
}
class _ChipField extends StatelessWidget {
  const _ChipField({
    required this.label, required this.hint, required this.ctrl,
    required this.items, required this.onAdd, required this.onRemove,
  });
  final String label, hint;
  final TextEditingController ctrl;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerProfilePalette.of(context);
    return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel(label: label),
      const SizedBox(height: 7),
      Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            onSubmitted: (_) => onAdd(),
            style: TextStyle(
                color: palette.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: palette.textMuted, fontSize: 13),
              filled: true,
              fillColor: palette.surfaceAlt,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: palette.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: palette.accent, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded, size: 20,
                color: palette.onAccent),
          ),
        ),
      ]),
      if (items.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: items.map((item) =>
          Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
            decoration: BoxDecoration(
              color: palette.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: palette.accent.withOpacity(0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(item, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: palette.accent)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => onRemove(item),
                child: Icon(Icons.close_rounded,
                    size: 12, color: palette.accent),
              ),
            ]),
          ),
        ).toList()),
      ],
    ]),
  );
  }
}
