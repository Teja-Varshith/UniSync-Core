import 'package:flutter/material.dart';
import 'package:unisync/models/peer_model.dart';
import 'peer_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PeerCardDeck
//
//  currentUserId — passed down to every PeerCard so the like button
//  knows whether to show and what state it's in.
// ─────────────────────────────────────────────────────────────────────────────
class PeerCardDeck extends StatefulWidget {
  const PeerCardDeck({
    super.key,
    required this.peers,
    required this.currentUserId,   // ← NEW
  });

  final List<PeerModel> peers;
  final String currentUserId;

  @override
  State<PeerCardDeck> createState() => _PeerCardDeckState();
}

class _PeerCardDeckState extends State<PeerCardDeck>
    with SingleTickerProviderStateMixin {
  int    _topIndex  = 0;
  double _dragOffset = 0;
  double _dragAngle  = 0;
  bool   _isDragging = false;

  static const double _swipeThreshold = 100;
  static const int    _visibleCount   = 3;

  @override
  void didUpdateWidget(PeerCardDeck old) {
    super.didUpdateWidget(old);
    if (old.peers != widget.peers) {
      setState(() { _topIndex = 0; _dragOffset = 0; _dragAngle = 0; });
    }
  }

  void _advance() {
    if (widget.peers.isEmpty) return;
    setState(() {
      _topIndex   = (_topIndex + 1) % widget.peers.length;
      _dragOffset = 0; _dragAngle = 0;
    });
  }

  void _goBack() {
    if (widget.peers.isEmpty) return;
    setState(() {
      _topIndex   = (_topIndex - 1 + widget.peers.length) % widget.peers.length;
      _dragOffset = 0; _dragAngle = 0;
    });
  }

  void _onDragUpdate(DragUpdateDetails d) => setState(() {
    _isDragging  = true;
    _dragOffset += d.delta.dx;
    _dragAngle   = (_dragOffset / 300).clamp(-0.25, 0.25);
  });

  void _onDragEnd(DragEndDetails d) {
    if (_dragOffset.abs() >= _swipeThreshold) {
      _advance();
    } else {
      setState(() { _dragOffset = 0; _dragAngle = 0; _isDragging = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.peers.isEmpty) return _EmptyDeck();

    return Column(children: [
      // Card count
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            border: Border.all(color: const Color(0xFF333333)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_topIndex + 1} / ${widget.peers.length}',
            style: const TextStyle(color: Color(0xFF888888),
                fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        )),
      ),

      // Stack
      SizedBox(
        height: 560,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Background cards
            for (int layer = _visibleCount - 1; layer >= 1; layer--)
              _BackCard(
                peer: widget.peers[(_topIndex + layer) % widget.peers.length],
                currentUserId: widget.currentUserId,
                layer: layer,
              ),

            // Top card (draggable)
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedContainer(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: Matrix4.identity()
                  ..translate(_dragOffset, 0.0)
                  ..rotateZ(_dragAngle),
                transformAlignment: Alignment.bottomCenter,
                child: Stack(children: [
                  PeerCard(
                    peerModel:     widget.peers[_topIndex],
                    currentUserId: widget.currentUserId,
                    expanded:      true,
                  ),
                  if (_isDragging)
                    Positioned.fill(child: _SwipeHint(offset: _dragOffset)),
                ]),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      // Nav buttons
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _NavBtn(icon: Icons.arrow_back_rounded, onTap: _goBack, tooltip: 'Previous'),
        const SizedBox(width: 16),
        _NavBtn(
          icon: Icons.close_rounded, onTap: _advance, tooltip: 'Skip',
          size: 56, iconSize: 24,
          color: const Color(0xFF2A1010), iconColor: const Color(0xFFE05252),
          borderColor: const Color(0xFF3D1515),
        ),
        const SizedBox(width: 16),
        _NavBtn(icon: Icons.arrow_forward_rounded, onTap: _advance, tooltip: 'Next'),
      ]),

      const SizedBox(height: 10),
      const Text('Swipe or use arrows · Cycles back at end',
          style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
    ]);
  }
}

// ── Background card ───────────────────────────────────────────────────────────
class _BackCard extends StatelessWidget {
  const _BackCard({required this.peer, required this.currentUserId, required this.layer});
  final PeerModel peer;
  final String currentUserId;
  final int layer;

  @override
  Widget build(BuildContext context) {
    final scale    = 1.0 - layer * 0.04;
    final yOffset  = layer * 10.0;
    final rotation = (layer % 2 == 0 ? 1 : -1) * layer * 0.015;
    return Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.identity()
        ..translate(0.0, yOffset)..scale(scale)..rotateZ(rotation),
      child: Opacity(opacity: 1.0 - layer * 0.15,
        child: IgnorePointer(
          child: PeerCard(
            peerModel: peer,
            currentUserId: currentUserId,
            expanded: true,
          ),
        ),
      ),
    );
  }
}

// ── Swipe hint overlay ────────────────────────────────────────────────────────
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.offset});
  final double offset;
  @override
  Widget build(BuildContext context) {
    if (offset.abs() < 20) return const SizedBox.shrink();
    final isRight = offset > 0;
    final opacity = ((offset.abs() - 20) / 80).clamp(0.0, 0.8);
    return Container(
      decoration: BoxDecoration(
        color: (isRight ? const Color(0xFF3ECF8E) : const Color(0xFFE05252))
            .withOpacity(opacity * 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isRight ? const Color(0xFF3ECF8E) : const Color(0xFFE05252))
              .withOpacity(opacity * 0.5)),
      ),
      child: Align(
        alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
        child: Padding(padding: const EdgeInsets.all(16),
          child: Icon(
            isRight ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: (isRight ? const Color(0xFF3ECF8E) : const Color(0xFFE05252))
                .withOpacity(opacity),
            size: 32)),
      ),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon, required this.onTap, required this.tooltip,
    this.size = 46, this.iconSize = 20,
    this.color = const Color(0xFF1A1A1A),
    this.iconColor = const Color(0xFF888888),
    this.borderColor = const Color(0xFF333333),
  });
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size, iconSize;
  final Color color, iconColor, borderColor;
  @override
  Widget build(_) => GestureDetector(onTap: onTap,
    child: Container(width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5)),
      child: Center(child: Icon(icon, size: iconSize, color: iconColor))));
}

// ── Empty deck ────────────────────────────────────────────────────────────────
class _EmptyDeck extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64, color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.people_outline_rounded,
            color: Color(0xFF555555), size: 28)),
      const SizedBox(height: 16),
      const Text('No peers match your filters',
          style: TextStyle(color: Color(0xFFAAAAAA),
              fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Try adjusting or clearing your filters',
          style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
    ]),
  );
}