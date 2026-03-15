import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/peer_connect/peers/peer_controller.dart';
import 'package:unisync/models/peer_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PeerCard
//
//  currentUserId — the logged-in user's id.
//    • If null        → like button hidden (not logged in)
//    • If == owner    → like button hidden (self-like blocked)
//    • Otherwise      → like button shown, toggleable
//
//  expanded: true → full layout used in the deck
// ─────────────────────────────────────────────────────────────────────────────
class PeerCard extends ConsumerWidget {
  const PeerCard({
    super.key,
    required this.peerModel,
    this.currentUserId,
    this.expanded = false,
  });

  final PeerModel peerModel;
  final String? currentUserId;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (peerModel.cardStyle == 'techy') {
      return _TechyCard(
          peerModel: peerModel,
          currentUserId: currentUserId,
          expanded: expanded,
          ref: ref);
    }
    return _MinimalCard(
        peerModel: peerModel,
        currentUserId: currentUserId,
        expanded: expanded,
        ref: ref);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIKE BUTTON  — stateful, handles optimistic toggle
// ─────────────────────────────────────────────────────────────────────────────
class _LikeButton extends ConsumerStatefulWidget {
  const _LikeButton({
    required this.peerModel,
    required this.currentUserId,
  });

  final PeerModel peerModel;
  final String currentUserId;

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton>
    with SingleTickerProviderStateMixin {
  late bool _liked;
  late int _count;
  bool _loading = false;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    // Derive initial state from the model's likedBy list
    _liked = widget.peerModel.likedBy.contains(widget.currentUserId);
    _count = widget.peerModel.likedBy.length;

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _bounceAnim = CurvedAnimation(
        parent: _bounceCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;

    // Optimistic update
    setState(() {
      _liked  = !_liked;
      _count += _liked ? 1 : -1;
      _loading = true;
    });

    // Bounce animation
    _bounceCtrl.reverse().then((_) => _bounceCtrl.forward());

    try {
      await ref.read(PeerControllerProvider.notifier).toggleLike(
        cardOwnerId:   widget.peerModel.userId!,
        currentUserId: widget.currentUserId,
      );
    } catch (_) {
      // Revert on failure
      setState(() {
        _liked  = !_liked;
        _count += _liked ? 1 : -1;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: ScaleTransition(
        scale: _bounceAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _liked
                ? const Color(0xFFE05252).withOpacity(0.12)
                : UniSyncColors.surfaceCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _liked
                  ? const Color(0xFFE05252).withOpacity(0.4)
                  : UniSyncColors.border,
              width: _liked ? 1.5 : 1,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 15,
              color: _liked
                  ? const Color(0xFFE05252)
                  : UniSyncColors.textMuted,
            ),
            if (_count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$_count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _liked
                      ? const Color(0xFFE05252)
                      : UniSyncColors.textMuted,
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Whether to show the like button for this viewer
// ─────────────────────────────────────────────────────────────────────────────
bool _canLike(PeerModel peer, String? currentUserId) {
  if (currentUserId == null) return false;
  if (currentUserId == peer.userId) return false; // self-like blocked
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
//  MINIMAL CARD  — dark mode
// ─────────────────────────────────────────────────────────────────────────────
class _MinimalCard extends StatelessWidget {
  const _MinimalCard({
    required this.peerModel,
    required this.currentUserId,
    required this.expanded,
    required this.ref,
  });

  final PeerModel peerModel;
  final String? currentUserId;
  final bool expanded;
  final WidgetRef ref;

  static const List<_MinTheme> _themes = [
    _MinTheme(stripe: Color(0xFF1E3A5F), accent: Color(0xFF4A90E2), avatarBg: Color(0xFF1A2F4A)),
    _MinTheme(stripe: Color(0xFF0D2B1A), accent: Color(0xFF3ECF8E), avatarBg: Color(0xFF0D2218)),
    _MinTheme(stripe: Color(0xFF2B1A00), accent: Color(0xFFE8A838), avatarBg: Color(0xFF241500)),
    _MinTheme(stripe: Color(0xFF1E0B2E), accent: Color(0xFFB06FD8), avatarBg: Color(0xFF190825)),
    _MinTheme(stripe: Color(0xFF2B0D0D), accent: Color(0xFFE05252), avatarBg: Color(0xFF220A0A)),
    _MinTheme(stripe: Color(0xFF0B1E2B), accent: Color(0xFF38BDF8), avatarBg: Color(0xFF081929)),
  ];

  _MinTheme _theme() {
    final n = peerModel.name;
    final idx = n.isEmpty ? 0 : n.codeUnitAt(0) % _themes.length;
    return _themes[idx];
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme();
    final initials = peerModel.name.trim().split(' ')
        .take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final showLike = _canLike(peerModel, currentUserId);

    final Widget? topLikeWidget = showLike
        ? _LikeButton(
            peerModel: peerModel,
            currentUserId: currentUserId!,
          )
        : (currentUserId == peerModel.userId && peerModel.likedBy.isNotEmpty)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE05252).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE05252).withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFE05252)),
                  const SizedBox(width: 5),
                  Text(
                    '${peerModel.likedBy.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE05252),
                    ),
                  ),
                ]),
              )
            : null;

    return Container(
      decoration: BoxDecoration(
        color: UniSyncColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UniSyncColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header stripe ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          color: t.stripe,
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: expanded ? 58 : 48,
              height: expanded ? 58 : 48,
              decoration: BoxDecoration(
                color: t.avatarBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.accent.withOpacity(0.4), width: 1.5),
              ),
              child: Center(child: Text(initials, style: TextStyle(
                color: t.accent,
                fontSize: expanded ? 22 : 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(peerModel.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ))),
                  if (topLikeWidget != null) ...[
                    const SizedBox(width: 8),
                    topLikeWidget,
                  ],
                  if (!peerModel.isPublic)
                    _Badge(label: 'PRIVATE', color: const Color(0xFFE8A838)),
                ]),
                const SizedBox(height: 5),
                if (peerModel.skills.isNotEmpty)
                  _Badge(label: peerModel.skills.first, color: t.accent),
              ],
            )),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if (peerModel.bio.isNotEmpty) ...[
              _ExpandableBio(
                bio: peerModel.bio,
                style: const TextStyle(
                  color: UniSyncColors.textSecondary, fontSize: 13, height: 1.5),
                maxLines: expanded ? 6 : 3,
                readMoreColor: t.accent,
              ),
              const SizedBox(height: 14),
            ],

            if (peerModel.skills.isNotEmpty) ...[
              _Section(label: 'SKILLS', labelColor: t.accent,
                children: peerModel.skills.take(expanded ? 999 : 5)
                    .map((s) => _Chip(label: s, accent: t.accent, filled: true))
                    .toList()),
              const SizedBox(height: 12),
            ],

            if (peerModel.traits.isNotEmpty) ...[
              _Section(label: 'INTERESTS', labelColor: UniSyncColors.textMuted,
                children: peerModel.traits.take(expanded ? 999 : 4)
                    .map((t2) => _Chip(label: t2, accent: t.accent, filled: false))
                    .toList()),
              const SizedBox(height: 14),
            ] else
              const SizedBox(height: 4),

            // ── Action row: links + like ────────────────────────
            if (peerModel.linkedinLink != null ||
                peerModel.gitHubLink != null) ...[
              Divider(color: UniSyncColors.divider.withOpacity(0.5), height: 1),
              const SizedBox(height: 12),
              Row(children: [
                if (peerModel.linkedinLink != null) ...[
                  Expanded(child: _LinkBtn(
                    label: 'LinkedIn', icon: Icons.work_outline_rounded,
                    accent: const Color(0xFF4A90E2),
                    onTap: () => _launch(peerModel.linkedinLink!))),
                  if (peerModel.gitHubLink != null)
                    const SizedBox(width: 8),
                ],
                if (peerModel.gitHubLink != null) ...[
                  Expanded(child: _LinkBtn(
                    label: 'GitHub', icon: Icons.code_rounded,
                    accent: UniSyncColors.textSecondary,
                    onTap: () => _launch(peerModel.gitHubLink!))),
                ],
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  static Future<void> _launch(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw Exception('Could not launch');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TECHY CARD  — dark terminal style
// ─────────────────────────────────────────────────────────────────────────────
class _TechyCard extends StatelessWidget {
  const _TechyCard({
    required this.peerModel,
    required this.currentUserId,
    required this.expanded,
    required this.ref,
  });

  final PeerModel peerModel;
  final String? currentUserId;
  final bool expanded;
  final WidgetRef ref;

  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF30363D);
  static const _green   = Color(0xFF3FB950);
  static const _blue    = Color(0xFF58A6FF);
  static const _purple  = Color(0xFFD2A8FF);
  static const _orange  = Color(0xFFFFA657);
  static const _comment = Color(0xFF8B949E);
  static const _string  = Color(0xFFA5D6FF);

  String get _slug =>
      peerModel.name.toLowerCase().replaceAll(' ', '_');

  @override
  Widget build(BuildContext context) {
    final initials = peerModel.name.trim().split(' ')
        .take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final showLike = _canLike(peerModel, currentUserId);

    final Widget? topLikeWidget = showLike
        ? _LikeButton(
            peerModel: peerModel,
            currentUserId: currentUserId!,
          )
        : (currentUserId == peerModel.userId && peerModel.likedBy.isNotEmpty)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE05252).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE05252).withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFE05252)),
                  const SizedBox(width: 5),
                  Text(
                    '${peerModel.likedBy.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE05252),
                    ),
                  ),
                ]),
              )
            : null;

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Window chrome
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(children: [
            _Dot(color: const Color(0xFFFF5F57)),
            const SizedBox(width: 6),
            _Dot(color: const Color(0xFFFFBD2E)),
            const SizedBox(width: 6),
            _Dot(color: const Color(0xFF28C840)),
            const Spacer(),
            Text('$_slug.json', style: const TextStyle(
                color: _comment, fontSize: 12, fontFamily: 'monospace')),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _CodeLine(children: [_kw('const '), _sym('_dev '), _plain('= {')]),
            const SizedBox(height: 10),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: expanded ? 56 : 46, height: expanded ? 56 : 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue.withOpacity(0.6), _purple.withOpacity(0.6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(child: Text(initials, style: TextStyle(
                    color: Colors.white,
                    fontSize: expanded ? 20 : 16,
                    fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CodeLine(children: [_prop('  name'), _plain(': "'),
                    _str(peerModel.name), _plain('",')]),
                  if (!peerModel.isPublic) ...[
                    const SizedBox(height: 4),
                    _CodeLine(children: [_prop('  visibility'), _plain(': "'),
                      _str('private'), _plain('",')]),
                  ],
                ])),
              if (topLikeWidget != null) ...[
                const SizedBox(width: 8),
                topLikeWidget,
              ],
            ]),

            const SizedBox(height: 10),

            if (peerModel.bio.isNotEmpty) ...[
              _ExpandableBio(
                bio: peerModel.bio,
                style: const TextStyle(
                    color: _comment, fontSize: 12, fontFamily: 'monospace'),
                maxLines: expanded ? 6 : 2,
                readMoreColor: _blue,
              ),
              const SizedBox(height: 10),
            ],

            if (peerModel.skills.isNotEmpty) ...[
              _CodeLine(children: [_prop('  skills'), _plain(': [')]),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.only(left: 16),
                child: Wrap(spacing: 6, runSpacing: 6,
                  children: peerModel.skills.take(expanded ? 999 : 5)
                      .map((s) => _CodeChip(label: '"$s"', color: _green)).toList())),
              const SizedBox(height: 4),
              _CodeLine(children: [_plain('  ],')]),
              const SizedBox(height: 10),
            ],

            if (peerModel.traits.isNotEmpty) ...[
              _CodeLine(children: [_prop('  interests'), _plain(': [')]),
              const SizedBox(height: 6),
              Padding(padding: const EdgeInsets.only(left: 16),
                child: Wrap(spacing: 6, runSpacing: 6,
                  children: peerModel.traits.take(expanded ? 999 : 3)
                      .map((t) => _CodeChip(label: '"$t"', color: _purple)).toList())),
              const SizedBox(height: 4),
              _CodeLine(children: [_plain('  ],')]),
              const SizedBox(height: 10),
            ],

            _CodeLine(children: [_plain('}')]),
            const SizedBox(height: 14),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 12),

            Row(children: [
              if (peerModel.linkedinLink != null) ...[
                Expanded(child: _TechBtn(
                  label: 'LinkedIn', icon: Icons.work_outline_rounded,
                  color: _blue, onTap: () => _launch(peerModel.linkedinLink!))),
                if (peerModel.gitHubLink != null)
                  const SizedBox(width: 10),
              ],
              if (peerModel.gitHubLink != null) ...[
                Expanded(child: _TechBtn(
                  label: 'GitHub', icon: Icons.code_rounded,
                  color: _comment, onTap: () => _launch(peerModel.gitHubLink!))),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  static TextSpan _kw(String t)    => TextSpan(text: t, style: const TextStyle(color: _purple,  fontFamily: 'monospace', fontSize: 13));
  static TextSpan _sym(String t)   => TextSpan(text: t, style: const TextStyle(color: _blue,    fontFamily: 'monospace', fontSize: 13));
  static TextSpan _plain(String t) => TextSpan(text: t, style: const TextStyle(color: Color(0xFFE6EDF3), fontFamily: 'monospace', fontSize: 13));
  static TextSpan _prop(String t)  => TextSpan(text: t, style: const TextStyle(color: _orange,  fontFamily: 'monospace', fontSize: 13));
  static TextSpan _str(String t)   => TextSpan(text: t, style: const TextStyle(color: _string,  fontFamily: 'monospace', fontSize: 13));

  static Future<void> _launch(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw Exception('Could not launch');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _MinTheme {
  const _MinTheme({required this.stripe, required this.accent, required this.avatarBg});
  final Color stripe, accent, avatarBg;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(_) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(label, style: TextStyle(
        fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.8)),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.labelColor, required this.children});
  final String label;
  final Color labelColor;
  final List<Widget> children;
  @override
  Widget build(_) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(
      color: labelColor.withOpacity(0.7), fontSize: 9,
      fontWeight: FontWeight.w700, letterSpacing: 1.4)),
    const SizedBox(height: 7),
    Wrap(spacing: 6, runSpacing: 6, children: children),
  ]);
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.accent, required this.filled});
  final String label;
  final Color accent;
  final bool filled;
  @override
  Widget build(_) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? accent.withOpacity(0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: filled ? accent.withOpacity(0.3) : UniSyncColors.border)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
        color: filled ? accent : UniSyncColors.textSecondary)),
  );
}

class _LinkBtn extends StatelessWidget {
  const _LinkBtn({required this.label, required this.icon, required this.accent, required this.onTap});
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  @override
  Widget build(_) => GestureDetector(onTap: onTap,
    child: Container(height: 38,
      decoration: BoxDecoration(color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withOpacity(0.25))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: accent)),
      ])));
}

// Techy-specific helpers
class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(_) => Container(width: 12, height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({required this.children});
  final List<TextSpan> children;
  @override
  Widget build(_) => RichText(text: TextSpan(children: children));
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(_) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11,
        fontFamily: 'monospace', fontWeight: FontWeight.w500)));
}

class _TechBtn extends StatelessWidget {
  const _TechBtn({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(_) => GestureDetector(onTap: onTap,
    child: Container(height: 38,
      decoration: BoxDecoration(color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: color, fontFamily: 'monospace')),
      ])));
}

// ── Expandable bio ───────────────────────────────────────────────────────────
class _ExpandableBio extends StatefulWidget {
  const _ExpandableBio({
    required this.bio, required this.style,
    required this.maxLines, required this.readMoreColor,
  });
  final String bio;
  final TextStyle style;
  final int maxLines;
  final Color readMoreColor;
  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final tp = TextPainter(
        text: TextSpan(text: widget.bio, style: widget.style),
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: constraints.maxWidth);
      final overflow = tp.didExceedMaxLines;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.bio, style: widget.style,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? null : TextOverflow.ellipsis),
        if (overflow || _expanded) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Read less' : 'Read more',
              style: TextStyle(color: widget.readMoreColor,
                  fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ]);
    });
  }
}