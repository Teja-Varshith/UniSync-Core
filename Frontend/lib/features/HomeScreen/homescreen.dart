import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:routemaster/routemaster.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisync/features/HomeScreen/homepagetab.dart';
import 'package:unisync/features/interview/view/carrer_interview_screen.dart';
import 'package:unisync/features/peer_connect/peers/peer_screen.dart';


class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  int _currentPageIndex = 3;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Iconsax.code,          activeIcon: Iconsax.code5,           label: 'Opportunities'),
    _NavItem(icon: Iconsax.microphone,    activeIcon: Iconsax.microphone5,     label: 'Mock'),
    _NavItem(icon: Iconsax.home_2,        activeIcon: Iconsax.home_25,         label: 'Home', isHome: true),
    _NavItem(icon: Iconsax.profile_2user, activeIcon: Iconsax.profile_2user5,  label: 'Peer Connect'),
    _NavItem(icon: Iconsax.setting_2,     activeIcon: Iconsax.setting_2,      label: 'Settings'),
  ];

  late final List<Widget> _pages = [
    const _PlaceholderPage(label: 'Attendance', emoji: '📊'),
    const _PlaceholderPage(label: 'Opportunities', emoji: '🏆'),
    const CarrerInterviewScreen(),
    HomePageTab(onInternalRouteTap: _handleHomeRouteTap),
    const PeerScreen(),
    const _PlaceholderPage(label: 'Settings', emoji: '⚙️'),
  ];

  int? get _currentNavIndex => _currentPageIndex == 0 ? null : _currentPageIndex - 1;

  void _onNavIndexChanged(int navIndex) {
    final targetPageIndex = navIndex + 1;
    if (_currentPageIndex == targetPageIndex) return;
    setState(() => _currentPageIndex = targetPageIndex);
  }

  void _activateAttendanceEdge() {
    if (_currentPageIndex == 0) return;
    setState(() => _currentPageIndex = 0);
  }

  void _handleHomeRouteTap(String route) {
    if (route == '/peer') {
      _onNavIndexChanged(3);
      return;
    }

    if (route == '/carrer-interview-screen') {
      _onNavIndexChanged(1);
      return;
    }

    if (route == '/campXLogin' || route == '/liveAttendence') {
      _activateAttendanceEdge();
      return;
    }

    if (!mounted) return;
    Routemaster.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      body: IndexedStack(index: _currentPageIndex, children: _pages),
      bottomNavigationBar: _CircleNavBar(
        items: _navItems,
        currentIndex: _currentNavIndex,
        onIndexChanged: _onNavIndexChanged,
        leftEdgeWidget: _NavAttendanceWidget(
          isActive: _currentPageIndex == 0,
          onTap: _activateAttendanceEdge,
        ),
        rightEdgeWidget: const _NavFollowWidget(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CIRCLE NAV BAR
// ─────────────────────────────────────────────

class _CircleNavBar extends StatefulWidget {
  final List<_NavItem> items;
  final int? currentIndex;
  final ValueChanged<int> onIndexChanged;

  final Widget leftEdgeWidget;

  final Widget rightEdgeWidget;

  const _CircleNavBar({
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.leftEdgeWidget,
    required this.rightEdgeWidget,
  });

  @override
  State<_CircleNavBar> createState() => _CircleNavBarState();
}

class _CircleNavBarState extends State<_CircleNavBar> {
  late final ScrollController _sc;

  static const double _chipSize = 58.0;
  static const double _spacing  = 16.0;
  static const double _stride   = _chipSize + _spacing;
  static const double _labelH   = 30.0;
  static const double _vPad     = 9.0;

  int  _lastHapticIdx   = -1;
  bool _isSnapping      = false;
  bool _scrollDidChange = false;

  double _offsetFor(int i)     => i * _stride;
  int    _nearestIdx(double x) =>
      (x / _stride).round().clamp(0, widget.items.length - 1);

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sc.hasClients) _sc.jumpTo(_clampedOffset(widget.currentIndex ?? 0));
    });
  }

  @override
  void dispose() { _sc.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(_CircleNavBar old) {
    super.didUpdateWidget(old);
    if (widget.currentIndex == null &&
        old.currentIndex != null &&
        !_scrollDidChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _snapToStart());
      return;
    }

    if (widget.currentIndex != null &&
        widget.currentIndex != old.currentIndex &&
        !_scrollDidChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _snap(widget.currentIndex!));
    }
    _scrollDidChange = false;
  }

  Future<void> _snapToStart({bool animated = true}) async {
    if (!_sc.hasClients) return;
    const target = 0.0;
    if ((_sc.offset - target).abs() < 0.5) return;
    _isSnapping = true;
    if (animated) {
      await _sc.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _sc.jumpTo(target);
    }
    _isSnapping = false;
  }

  double _clampedOffset(int i) {
    if (!_sc.hasClients) return _offsetFor(i);
    return _offsetFor(i).clamp(0.0, _sc.position.maxScrollExtent);
  }

  Future<void> _snap(int i, {bool animated = true}) async {
    if (!_sc.hasClients) return;
    final target = _clampedOffset(i);
    if ((_sc.offset - target).abs() < 0.5) return;
    _isSnapping = true;
    if (animated) {
      await _sc.animateTo(target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    } else {
      _sc.jumpTo(target);
    }
    _isSnapping = false;
  }

  bool _onNotification(ScrollNotification n) {
    if (n is ScrollUpdateNotification && !_isSnapping) {
      final idx = _nearestIdx(_sc.offset);
      if (idx != _lastHapticIdx) {
        _lastHapticIdx = idx;
        HapticFeedback.selectionClick();
        if (idx != widget.currentIndex) {
          _scrollDidChange = true;
          widget.onIndexChanged(idx);
        }
      }
    }
    if (n is ScrollEndNotification && !_isSnapping) {
      _snap(_nearestIdx(_sc.offset));
    }
    return false;
  }

  void _onTap(int i) {
    if (i == widget.currentIndex) return;
    HapticFeedback.lightImpact();
    _scrollDidChange = true;
    widget.onIndexChanged(i);
    _snap(i);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final barH   = _chipSize + _labelH + _vPad * 2 + bottom + 6;

    return Container(
      height: barH,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.8)),
      ),
      child: LayoutBuilder(builder: (ctx, box) {
        // exact width of each edge zone — same as old padding value
        final edgeWidth = box.maxWidth / 2 - _chipSize / 2;

        return NotificationListener<ScrollNotification>(
          onNotification: _onNotification,
          child: ScrollConfiguration(
            behavior: _NoGlowBehavior(),
            child: ListView(
              controller: _sc,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              // No horizontal padding — edge widgets fill that space instead
              padding: EdgeInsets.fromLTRB(0, _vPad, 0, _vPad + bottom),
              children: [

                // ─── LEFT EDGE WIDGET ───────────────────
                SizedBox(
                  width: edgeWidth,
                  child: widget.leftEdgeWidget,
                ),

                // ─── CHIPS ──────────────────────────────
                for (int i = 0; i < widget.items.length; i++) ...[
                  if (i != 0) const SizedBox(width: _spacing),
                  _CircleChip(
                    item: widget.items[i],
                    isActive: widget.currentIndex == i,
                    size: _chipSize,
                    onTap: () => _onTap(i),
                  ),
                ],

                // ─── RIGHT EDGE WIDGET ──────────────────
                SizedBox(
                  width: edgeWidth,
                  child: widget.rightEdgeWidget,
                ),

              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// EXAMPLE LEFT EDGE — User Avatar + Notif dot
// Replace with whatever you want
// ─────────────────────────────────────────────

class _NavAttendanceWidget extends StatelessWidget {
  const _NavAttendanceWidget({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0x2AFFD72F) : const Color(0xFF2A2A2A),
                    border: Border.all(
                      color: isActive ? const Color(0xFFFFD72F) : const Color(0xFF343434),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Iconsax.calendar_1,
                      size: 18,
                      color: isActive ? const Color(0xFFFFD72F) : const Color(0xFFA09D95),
                    ),
                  ),
                ),
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? const Color(0xFFFFD72F) : const Color(0xFF343434),
                      border: Border.all(color: const Color(0xFF121212), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Attendance',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? const Color(0xFFFFD72F) : const Color(0xFFA09D95),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavFollowWidget extends StatelessWidget {
  const _NavFollowWidget();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Follow us on',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA09D95),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SocialIcon(
                icon: Iconsax.link,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _open('https://www.linkedin.com/company/unisyncofficial');
                },
              ),
              const SizedBox(width: 8),
              _SocialIcon(
                icon: Iconsax.instagram,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _open('https://www.instagram.com/unisyncofficial');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E1E),
          border: Border.all(
            color: const Color(0xFF343434),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(icon, size: 16, color: const Color(0xFFA09D95)),
        ),
      ),
    );
  }
}
class _CircleChip extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final double size;
  final VoidCallback onTap;

  const _CircleChip({
    required this.item,
    required this.isActive,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = isActive;
    final isHome = item.isHome;

    const yellow     = Color(0xFFFFD72F);
    const yellowSoft = Color(0x2AFFD72F);
    const darkBg     = Color(0xFF0B0B0D);
    const chipBg     = Color(0xFF1E1E1E);
    const muted      = Color(0xFFA09D95);
    const dur        = Duration(milliseconds: 280);
    const curve      = Curves.easeOutCubic;

    final circleBg    = isHome && active ? yellow : active ? yellowSoft : chipBg;
    final borderColor = active ? yellow
        : isHome ? yellow.withValues(alpha: 0.35)
        : const Color(0xFF343434);
    final iconColor   = isHome && active ? darkBg : active ? yellow : muted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: dur,
                curve: curve,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleBg,
                  border: Border.all(color: borderColor, width: active ? 2.0 : 1.2),
                  boxShadow: active
                      ? [BoxShadow(
                          color: yellow.withValues(alpha: isHome ? 0.42 : 0.24),
                          blurRadius: isHome ? 20 : 12,
                        )]
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      active ? item.activeIcon : item.icon,
                      key: ValueKey(active),
                      size: isHome ? 24 : 20,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? yellow : muted,
                  letterSpacing: 0.15,
                  height: 1.3,
                ),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ─────────────────────────────────────────────
// NO GLOW
// ─────────────────────────────────────────────

class _NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) => child;
}

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final bool     isHome;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isHome = false,
  });
}

// ─────────────────────────────────────────────
// PLACEHOLDER PAGES
// ─────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  final String label;
  final String emoji;
  const _PlaceholderPage({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFF1EFE7), fontSize: 22,
                  fontWeight: FontWeight.w600, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}