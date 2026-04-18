import 'package:flutter/material.dart';
import 'package:neopop/neopop.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/models/peer_model.dart';
import 'peer_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PeerCardDeck
// ─────────────────────────────────────────────────────────────────────────────
class PeerCardDeck extends StatefulWidget {
  const PeerCardDeck({
    super.key,
    required this.peers,
    required this.currentUserId,
  });

  final List<PeerModel> peers;
  final String currentUserId;

  @override
  State<PeerCardDeck> createState() => _PeerCardDeckState();
}

class _PeerCardDeckState extends State<PeerCardDeck>
    with SingleTickerProviderStateMixin {
  int _topIndex = 0;

  double _dragOffset = 0;
  bool   _isDragging = false;

  late AnimationController _snapCtrl;
  late Animation<double>   _snapAnim;

  // Gen Z slangs — right swipe = positive, left = skip
  static const List<String> _rightSlangs = ['SLAY', 'RIZZ', 'FR FR', 'BUSSIN', 'NO CAP', 'GOATED'];
  static const List<String> _leftSlangs  = ['PASS', 'MID', 'NPC', 'SKIP', 'L BOZO', 'RATIO'];

  static const double _velocityThreshold  = 500;
  static const double _distanceThreshold  = 90;
  static const int    _visibleCount       = 3;
  static const double _peekShift          = 10.0;

  // Pick a slang based on the current card index so it's consistent per card
  String get _rightSlang => _rightSlangs[_topIndex % _rightSlangs.length];
  String get _leftSlang  => _leftSlangs[_topIndex  % _leftSlangs.length];

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PeerCardDeck old) {
    super.didUpdateWidget(old);
    if (old.peers != widget.peers) _hardReset();
  }

  void _hardReset() {
    _snapCtrl.stop();
    setState(() {
      _topIndex   = 0;
      _dragOffset = 0;
      _isDragging = false;
    });
  }

  void _advance() {
    if (widget.peers.isEmpty) return;
    setState(() {
      _topIndex   = (_topIndex + 1) % widget.peers.length;
      _dragOffset = 0;
      _isDragging = false;
    });
  }

  void _goBack() {
    if (widget.peers.isEmpty) return;
    setState(() {
      _topIndex   = (_topIndex - 1 + widget.peers.length) % widget.peers.length;
      _dragOffset = 0;
    });
  }

  void _onDragStart(DragStartDetails _) {
    _snapCtrl.stop();
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails d) =>
      setState(() => _dragOffset += d.delta.dx);

  void _onDragEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond.dx;
    final shouldSwipe = _dragOffset.abs() > _distanceThreshold ||
        velocity.abs() > _velocityThreshold;

    if (shouldSwipe) {
      _advance();
    } else {
      final from = _dragOffset;
      _snapAnim = Tween<double>(begin: from, end: 0).animate(
        CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
      )..addListener(() => setState(() => _dragOffset = _snapAnim.value));
      _snapCtrl
        ..value    = 0
        ..duration = const Duration(milliseconds: 500)
        ..forward(from: 0);
      setState(() => _isDragging = false);
    }
  }

  double get _tilt          => (_dragOffset / 320).clamp(-0.28, 0.28);
  double get _swipeProgress => (_dragOffset.abs() / _distanceThreshold).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final deckSurface = isDark ? AppColors.darkCard : AppColors.lightCardAlt;
    final deckBg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textPrimary = theme.colorScheme.onSurface;

    if (widget.peers.isEmpty) return const _EmptyDeck();

    final stackHeight = kCardHeight + (_visibleCount - 1) * _peekShift + 14;

    return Column(children: [
      // ── Card stack ──────────────────────────────────────────
      SizedBox(
        height: stackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            for (int layer = _visibleCount - 1; layer >= 1; layer--)
              _BackCard(
                peer:          widget.peers[(_topIndex + layer) % widget.peers.length],
                currentUserId: widget.currentUserId,
                layer:         layer,
                swipeProgress: _swipeProgress,
              ),

            GestureDetector(
              onHorizontalDragStart:  _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd:    _onDragEnd,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()
                  ..translate(_dragOffset, 0.0)
                  ..rotateZ(_tilt),
                child: Stack(children: [
                  PeerCard(
                    peerModel:     widget.peers[_topIndex],
                    currentUserId: widget.currentUserId,
                    expanded:      true,
                  ),
                  if (_isDragging && _dragOffset.abs() > 8)
                    Positioned.fill(
                      child: _SwipeStamp(
                        offset:     _dragOffset,
                        rightSlang: _rightSlang,
                        leftSlang:  _leftSlang,
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 22),

      // ── Nav ─────────────────────────────────────────────────
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        NeoPopButton(
          color:             deckSurface,
          bottomShadowColor: deckBg,
          rightShadowColor:  deckBg,
          depth: 5,
          onTapUp:   _goBack,
          onTapDown: () {},
          child: SizedBox(
            width: 50, height: 44,
            child: Center(child: Icon(Icons.arrow_back_rounded,
                size: 17, color: muted)),
        ),
        ),
        const SizedBox(width: 16),
        NeoPopButton(
          color:             deckSurface,
          bottomShadowColor: deckBg,
          rightShadowColor:  deckBg,
          depth: 5,
          onTapUp:   _advance,
          onTapDown: () {},
          child: SizedBox(
            width: 50, height: 44,
            child: Center(child: Icon(Icons.arrow_forward_rounded,
                size: 17, color: muted)),
        ),
        ),
      ]),

      const SizedBox(height: 10),
      Text('swipe or tap arrows',
          style: TextStyle(color: textPrimary,
              fontSize: 11, letterSpacing: 0.6)),
    ]);
  }
}

// ── Back card ─────────────────────────────────────────────────────────────────
class _BackCard extends StatelessWidget {
  const _BackCard({
    required this.peer,
    required this.currentUserId,
    required this.layer,
    required this.swipeProgress,
  });
  final PeerModel peer;
  final String    currentUserId;
  final int       layer;
  final double    swipeProgress;

  static const double _peekShift = 10.0;
  static const double _scaleStep = 0.030;

  @override
  Widget build(BuildContext context) {
    final currentScale = 1.0 -  layer      * _scaleStep;
    final targetScale  = 1.0 - (layer - 1) * _scaleStep;
    final scale        = currentScale + (targetScale - currentScale) * swipeProgress;

    final currentY = layer       * _peekShift;
    final targetY  = (layer - 1) * _peekShift;
    final yOffset  = currentY + (targetY - currentY) * swipeProgress;
    final tilt     = (layer % 2 == 0 ? 1 : -1) * layer * 0.012;

    return Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.identity()
        ..translate(0.0, yOffset)
        ..scale(scale)
        ..rotateZ(tilt),
      child: Opacity(
        opacity: (1.0 - layer * 0.22).clamp(0.0, 1.0),
        child: IgnorePointer(
          child: PeerCard(
            peerModel:     peer,
            currentUserId: currentUserId,
            expanded:      true,
          ),
        ),
      ),
    );
  }
}

// ── Swipe stamp with gen z slangs ────────────────────────────────────────────
class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({
    required this.offset,
    required this.rightSlang,
    required this.leftSlang,
  });
  final double offset;
  final String rightSlang;
  final String leftSlang;

  @override
  Widget build(BuildContext context) {
    final isRight = offset > 0;
    final t       = ((offset.abs() - 8) / 70).clamp(0.0, 1.0);
    final color   = isRight ? const Color(0xFF3ECF8E) : const Color(0xFFFF6B6B);
    final label   = isRight ? rightSlang : leftSlang;
    final angle   = isRight ? -0.28 : 0.28;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: color.withOpacity(t * 0.10),
        child: Align(
          alignment: isRight ? Alignment.topLeft : Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 2.5),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(label,
                      style: TextStyle(
                        color:        color,
                        fontSize:     15,
                        fontWeight:   FontWeight.w900,
                        letterSpacing: 2,
                      )),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────
class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textPrimary = theme.colorScheme.onSurface;

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border)),
          child: Icon(Icons.people_outline_rounded, color: muted, size: 24)),
        const SizedBox(height: 16),
        Text('No peers found',
            style: TextStyle(color: textPrimary, fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Try clearing your filters',
            style: TextStyle(color: muted, fontSize: 12)),
      ]),
    );
  }
}
