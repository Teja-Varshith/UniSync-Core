import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:UniSync/constants/constant.dart';
import 'package:UniSync/features/peer_connect/peers/peer_controller.dart';
import 'package:UniSync/models/peer_model.dart';

const double kCardHeight = 440.0;

// Characters at which we consider bio "long" and show Read more
// ~45 chars/line × 2 lines = ~90, use 100 as safe threshold
const int _bioCollapseThreshold = 100;

// ─────────────────────────────────────────────────────────────────────────────
//  PeerCard
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
    // print(peerModel.bio);
    if (peerModel.cardStyle == 'techy') {
      return _TechyCard(
          peerModel: peerModel, currentUserId: currentUserId,
          expanded: expanded, ref: ref);
    }
    return _MinimalCard(
        peerModel: peerModel, currentUserId: currentUserId,
        expanded: expanded, ref: ref);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LIKE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _LikeButton extends ConsumerStatefulWidget {
  const _LikeButton({required this.peerModel, required this.currentUserId});
  final PeerModel peerModel;
  final String currentUserId;

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  late bool _liked;
  late int _count;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.peerModel.likedBy.contains(widget.currentUserId);
    _count = widget.peerModel.likedBy.length;
  }

  Future<void> _toggle() async {
    if (_loading) return;
    setState(() { _liked = !_liked; _count += _liked ? 1 : -1; _loading = true; });
    try {
      await ref.read(PeerControllerProvider.notifier).toggleLike(
            cardOwnerId: widget.peerModel.userId!,
            currentUserId: widget.currentUserId,
          );
    } catch (_) {
      setState(() { _liked = !_liked; _count += _liked ? 1 : -1; });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor     = _liked ? const Color(0xFF2A1212) : const Color(0xFF161B22);
    final shadowColor = _liked ? const Color(0xFF180808) : const Color(0xFF090C12);
    final iconColor   = _liked ? const Color(0xFFFF6B6B) : const Color(0xFF555F6D);

    return NeoPopButton(
      color: bgColor, bottomShadowColor: shadowColor,
      rightShadowColor: shadowColor, depth: 4,
      onTapUp: _toggle, onTapDown: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _loading
              ? SizedBox(width: 13, height: 13,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: iconColor))
              : Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 14, color: iconColor),
          if (_count > 0) ...[
            const SizedBox(width: 5),
            Text('$_count', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: iconColor, letterSpacing: 0.2)),
          ],
        ]),
      ),
    );
  }
}

bool _canLike(PeerModel peer, String? uid) =>
    uid != null && uid.isNotEmpty && uid != peer.userId;

// ─────────────────────────────────────────────────────────────────────────────
//  MINIMAL CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MinimalCard extends StatelessWidget {
  const _MinimalCard({
    required this.peerModel, required this.currentUserId,
    required this.expanded, required this.ref,
  });
  final PeerModel peerModel;
  final String? currentUserId;
  final bool expanded;
  final WidgetRef ref;

  static const List<_Palette> _palettes = [
    _Palette(glow: Color(0xFF4A90E2), ring: Color(0xFF2D5F9E)),
    _Palette(glow: Color(0xFF3ECF8E), ring: Color(0xFF27916A)),
    _Palette(glow: Color(0xFFF5A623), ring: Color(0xFFB87A1A)),
    _Palette(glow: Color(0xFFB06FD8), ring: Color(0xFF7A4A9E)),
    _Palette(glow: Color(0xFFFF6B6B), ring: Color(0xFFB84A4A)),
    _Palette(glow: Color(0xFF38BDF8), ring: Color(0xFF2080B0)),
  ];

  _Palette _palette() {
    final n = peerModel.name;
    return _palettes[n.isEmpty ? 0 : n.codeUnitAt(0) % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final p        = _palette();
    final initials = peerModel.name.trim().split(' ')
        .take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final showLike = _canLike(peerModel, currentUserId);
    final bio      = peerModel.bio.trim();

    Widget? likeWidget;
    if (showLike) {
      likeWidget = _LikeButton(peerModel: peerModel, currentUserId: currentUserId!);
    } else if (currentUserId == peerModel.userId && peerModel.likedBy.isNotEmpty) {
      likeWidget = _LikeCountPill(count: peerModel.likedBy.length);
    }

    return SizedBox(
      height: kCardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1118),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: p.glow.withOpacity(0.08),
                blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [

          // Accent top line
          Container(height: 2, color: p.glow.withOpacity(0.7)),

          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Avatar(initials: initials, glow: p.glow, ring: p.ring, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                      child: Text(peerModel.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    ),
                    if (likeWidget != null) ...[const SizedBox(width: 8), likeWidget],
                  ]),
                  // College — only here
                  if ((peerModel.collegeName ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.school_outlined, size: 11,
                          color: p.glow.withOpacity(0.75)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(peerModel.collegeName!.trim(),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.glow.withOpacity(0.8),
                              fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    if (peerModel.skills.isNotEmpty)
                      _SkillPill(label: peerModel.skills.first, color: p.glow),
                    if (!peerModel.isPublic) ...[
                      const SizedBox(width: 6), _PrivatePill(),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),

          Container(height: 1, color: Colors.white.withOpacity(0.06)),

          // ── Scrollable body ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Text(peerModel.bio),

                // Bio — always rendered if non-empty, read more via char threshold
                if (bio.isNotEmpty) ...[
                  _ReadMoreBio(bio: bio, accentColor: p.glow),
                  const SizedBox(height: 16),
                ],

                // Skills (skip first — already in header pill)
                if (peerModel.skills.length > 1) ...[
                  _SectionLabel(text: 'SKILLS'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6,
                    children: peerModel.skills.skip(1)
                        .map((s) => _OutlineChip(label: s, color: p.glow))
                        .toList()),
                  const SizedBox(height: 14),
                ],

                if (peerModel.traits.isNotEmpty) ...[
                  _SectionLabel(text: 'INTERESTS'),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6,
                    children: peerModel.traits
                        .map((t) => _GhostChip(label: t))
                        .toList()),
                  const SizedBox(height: 14),
                ],

                // Social CTAs
                if (peerModel.linkedinLink != null ||
                    peerModel.gitHubLink != null) ...[
                  Container(height: 1, color: Colors.white.withOpacity(0.06)),
                  const SizedBox(height: 12),
                  Row(children: [
                    if (peerModel.linkedinLink != null) ...[
                      Expanded(child: _NeoLink(
                        label: 'LinkedIn', icon: Icons.work_outline_rounded,
                        color: const Color(0xFF1A2A4A),
                        shadow: const Color(0xFF0D1929),
                        textColor: const Color(0xFF4A90E2),
                        onTap: () => _launch(peerModel.linkedinLink!),
                      )),
                      if (peerModel.gitHubLink != null) const SizedBox(width: 8),
                    ],
                    if (peerModel.gitHubLink != null)
                      Expanded(child: _NeoLink(
                        label: 'GitHub', icon: Icons.code_rounded,
                        color: const Color(0xFF161B22),
                        shadow: const Color(0xFF090C12),
                        textColor: const Color(0xFF8B949E),
                        onTap: () => _launch(peerModel.gitHubLink!),
                      )),
                  ]),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  static Future<void> _launch(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw Exception('Could not launch');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TECHY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _TechyCard extends StatelessWidget {
  const _TechyCard({
    required this.peerModel, required this.currentUserId,
    required this.expanded, required this.ref,
  });
  final PeerModel peerModel;
  final String? currentUserId;
  final bool expanded;
  final WidgetRef ref;

  static const _bg       = Color(0xFF0D1117);
  static const _surface  = Color(0xFF161B22);
  static const _surface2 = Color(0xFF1C2128);
  static const _border   = Color(0xFF30363D);
  static const _lineNum  = Color(0xFF3D444D);
  static const _green    = Color(0xFF3FB950);
  static const _blue     = Color(0xFF79C0FF);
  static const _purple   = Color(0xFFD2A8FF);
  static const _orange   = Color(0xFFFFA657);
  static const _comment  = Color(0xFF8B949E);
  static const _string   = Color(0xFFA5D6FF);
  static const _white    = Color(0xFFE6EDF3);

  String get _slug => peerModel.name.toLowerCase().replaceAll(' ', '_');

  @override
  Widget build(BuildContext context) {
    final initials = peerModel.name.trim().split(' ')
        .take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final showLike = _canLike(peerModel, currentUserId);
    final bio      = peerModel.bio.trim();
    final college  = (peerModel.collegeName ?? '').trim();

    Widget? likeWidget;
    if (showLike) {
      likeWidget = _LikeButton(peerModel: peerModel, currentUserId: currentUserId!);
    } else if (currentUserId == peerModel.userId && peerModel.likedBy.isNotEmpty) {
      likeWidget = _LikeCountPill(count: peerModel.likedBy.length);
    }

    // Code lines — NO name/college here, those live in the footer
    final lines = <_Line>[];
    int n = 1;
    lines.add(_Line(n++, [_ts('export const ', _purple), _ts('dev', _blue), _ts(' = {', _white)]));

    if (!peerModel.isPublic) {
      lines.add(_Line(n++, [_ts('  visibility', _orange), _ts(': ', _white), _ts('"private"', _string), _ts(',', _white)]));
    }
    

   

    if (peerModel.skills.isNotEmpty) {
      lines.add(_Line(n++, [_ts('  skills', _orange), _ts(': [', _white)]));
      for (final s in peerModel.skills) {
        lines.add(_Line(n++, [_ts('    ', _white), _ts('"$s"', _green), _ts(',', _white)]));
      }
      lines.add(_Line(n++, [_ts('  ],', _white)]));
    }

    if (peerModel.traits.isNotEmpty) {
      lines.add(_Line(n++, [_ts('  interests', _orange), _ts(': [', _white)]));
      for (final t in peerModel.traits) {
        lines.add(_Line(n++, [_ts('    ', _white), _ts('"$t"', _purple), _ts(',', _white)]));
      }
      lines.add(_Line(n++, [_ts('  ],', _white)]));
    }

    lines.add(_Line(n++, [_ts('}', _white)]));

     // Bio as comment block — shown in code, NOT duplicated
   if (bio.isNotEmpty) {
  
  
  // Split on explicit newlines first, then wrap each paragraph at 50 chars
  final paragraphs = bio.split('\n');
  for (final paragraph in paragraphs) {
    if (paragraph.trim().isEmpty) {
      // Blank line — emit an empty comment to preserve spacing
      lines.add(_Line(n++, [_ts('  //', _comment)]));
      continue;
    }
    final words = paragraph.split(' ');
    final commentLines = <String>[];
    var current = '';
    for (final word in words) {
      if (word.isEmpty) continue;
      if ((current + word).length > 50) {
        if (current.isNotEmpty) commentLines.add(current.trim());
        current = '$word ';
      } else {
        current += '$word ';
      }
    }
    if (current.trim().isNotEmpty) commentLines.add(current.trim());
    for (final cl in commentLines) {
      lines.add(_Line(n++, [_ts('  // $cl', _comment)]));
    }
  }
}

    return SizedBox(
      height: kCardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: _bg, border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: _green.withOpacity(0.05),
                blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(children: [

          // ── Tab bar ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                decoration: const BoxDecoration(
                  color: _bg,
                  border: Border(
                    top:   BorderSide(color: _green, width: 1.5),
                    left:  BorderSide(color: _border),
                    right: BorderSide(color: _border),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.description_outlined, size: 11, color: _comment),
                  const SizedBox(width: 5),
                  Text('$_slug.uni', style: const TextStyle(
                      color: _comment, fontSize: 11, fontFamily: 'monospace')),
                ]),
              ),
              const Spacer(),
              _Dot(color: const Color(0xFFFF5F57)),
              const SizedBox(width: 5),
              _Dot(color: const Color(0xFFFFBD2E)),
              const SizedBox(width: 5),
              _Dot(color: const Color(0xFF28C840)),
            ]),
          ),

          // ── Code editor (scrollable) ──────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Gutter
                  Container(
                    color: _surface2, width: 38,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: lines.map((l) => SizedBox(
                        height: 22,
                        child: Center(child: Text('${l.num}',
                            style: const TextStyle(color: _lineNum,
                                fontSize: 11, fontFamily: 'monospace'))),
                      )).toList()),
                  ),
                  // Code
                  Expanded(child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: lines.map((l) => SizedBox(
                        height: 22,
                        child: RichText(text: TextSpan(children: l.spans)),
                      )).toList()),
                  )),
                ]),
              ),
            ),
          ),

          // ── Footer: name, college, like, links ──────────────
          Container(
            decoration: const BoxDecoration(
              color: _surface,
              border: Border(top: BorderSide(color: _border)),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(children: [
              // Avatar
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_blue.withOpacity(0.5), _purple.withOpacity(0.5)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _border),
                ),
                child: Center(child: Text(initials,
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
              ),
              const SizedBox(width: 10),
              // Name + college
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(peerModel.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _white, fontSize: 13,
                          fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                  if (college.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(college,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _comment, fontSize: 10,
                            fontFamily: 'monospace')),
                  ],
                ],
              )),
              // Like
              if (likeWidget != null) ...[likeWidget, const SizedBox(width: 8)],
              // Links
              if (peerModel.linkedinLink != null) ...[
                _TechIconBtn(icon: Icons.work_outline_rounded,
                    color: _blue, onTap: () => _launch(peerModel.linkedinLink!)),
                const SizedBox(width: 6),
              ],
              if (peerModel.gitHubLink != null)
                _TechIconBtn(icon: Icons.code_rounded,
                    color: _comment, onTap: () => _launch(peerModel.gitHubLink!)),
            ]),
          ),
        ]),
      ),
    );
  }

  static TextSpan _ts(String t, Color c) => TextSpan(
      text: t,
      style: TextStyle(color: c, fontFamily: 'monospace', fontSize: 12.5, height: 1.7));

  static Future<void> _launch(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw Exception('Could not launch');
  }
}

class _Line {
  const _Line(this.num, this.spans);
  final int num;
  final List<TextSpan> spans;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Read-more bio — character threshold, no LayoutBuilder
// ─────────────────────────────────────────────────────────────────────────────
// Lines at which we collapse — much more reliable than char count
const int _bioCollapseLines = 5;



class _ReadMoreBio extends StatefulWidget {
  const _ReadMoreBio({required this.bio, required this.accentColor});
  final String bio;
  final Color accentColor;

  @override
  State<_ReadMoreBio> createState() => _ReadMoreBioState();
}

class _ReadMoreBioState extends State<_ReadMoreBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 13,
          height: 1.65,
          letterSpacing: 0.1,
        );

        // Count explicit newline-based lines first
        final explicitLines = '\n'.allMatches(widget.bio).length + 1;

        // Then check if text wraps beyond our threshold
        final tp = TextPainter(
          text: TextSpan(text: widget.bio, style: style),
          maxLines: _bioCollapseLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        // Overflow if either explicit newlines OR wrapped text exceeds limit
        final didExceed = tp.didExceedMaxLines || explicitLines > _bioCollapseLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bio,
              maxLines: _expanded ? null : _bioCollapseLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: style,
            ),
            if (didExceed) ...[
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Read less ↑' : 'Read more ↓',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  const _Palette({required this.glow, required this.ring});
  final Color glow, ring;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.glow,
      required this.ring, required this.size});
  final String initials;
  final Color glow, ring;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
          colors: [ring.withOpacity(0.45), const Color(0xFF0A0D14)],
          stops: const [0.35, 1.0]),
      border: Border.all(color: glow.withOpacity(0.4), width: 1.5),
      boxShadow: [BoxShadow(color: glow.withOpacity(0.12), blurRadius: 10)],
    ),
    child: Center(child: Text(initials,
        style: TextStyle(color: glow, fontSize: size * 0.33,
            fontWeight: FontWeight.w800, letterSpacing: -0.5))),
  );
}

class _SkillPill extends StatelessWidget {
  const _SkillPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label, style: TextStyle(color: color, fontSize: 10,
        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
  );
}

class _PrivatePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF5A623).withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF5A623).withOpacity(0.25))),
    child: const Text('PRIVATE', style: TextStyle(color: Color(0xFFF5A623),
        fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
  );
}

class _LikeCountPill extends StatelessWidget {
  const _LikeCountPill({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF2A1212), borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFFF6B6B)),
      const SizedBox(width: 4),
      Text('$count', style: const TextStyle(fontSize: 11,
          fontWeight: FontWeight.w700, color: Color(0xFFFF6B6B))),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9,
          fontWeight: FontWeight.w700, letterSpacing: 1.5));
}

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withOpacity(0.2))),
    child: Text(label, style: TextStyle(color: color.withOpacity(0.85),
        fontSize: 11, fontWeight: FontWeight.w500)),
  );
}

class _GhostChip extends StatelessWidget {
  const _GhostChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: Colors.white.withOpacity(0.1))),
    child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.42),
        fontSize: 11, fontWeight: FontWeight.w400)),
  );
}

class _NeoLink extends StatelessWidget {
  const _NeoLink({required this.label, required this.icon,
      required this.color, required this.shadow,
      required this.textColor, required this.onTap});
  final String label;
  final IconData icon;
  final Color color, shadow, textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => NeoPopButton(
    color: color, bottomShadowColor: shadow, rightShadowColor: shadow,
    depth: 4, onTapUp: onTap, onTapDown: () {},
    child: SizedBox(height: 38,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 13, color: textColor),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: textColor, fontSize: 12,
            fontWeight: FontWeight.w600)),
      ])),
  );
}

class _TechIconBtn extends StatelessWidget {
  const _TechIconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25))),
      child: Center(child: Icon(icon, size: 14, color: color)),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10, height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}