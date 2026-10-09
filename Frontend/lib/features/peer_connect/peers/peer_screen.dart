import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:UniSync/app/theme/app_colors.dart';
import 'package:UniSync/app/providers.dart';
import 'package:UniSync/features/peer_connect/peers/peer_controller.dart';
import 'package:UniSync/features/peer_connect/peers/peer_decs.dart';
import 'package:UniSync/models/peer_model.dart';

class _PeerPalette {
  const _PeerPalette({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.muted,
    required this.textPrimary,
    required this.accent,
    required this.onAccent,
  });

  final bool isDark;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color muted;
  final Color textPrimary;
  final Color accent;
  final Color onAccent;

  factory _PeerPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return _PeerPalette(
      isDark: isDark,
      bg: theme.scaffoldBackgroundColor,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surface2: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
      border: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      muted: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      textPrimary: scheme.onSurface,
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
    );
  }
}

class PeerScreen extends ConsumerStatefulWidget {
  const PeerScreen({super.key});

  @override
  ConsumerState<PeerScreen> createState() => _PeerScreenState();
}

class _PeerScreenState extends ConsumerState<PeerScreen> {
  final _searchCtrl = TextEditingController();

  List<PeerModel> _allPeers  = [];
  List<String>    _allSkills = [];
  List<String>    _allTraits = [];
  bool            _loading   = true;
  String?         _error;

  List<String> _selectedSkills = [];
  List<String> _selectedTraits = [];
  String       _searchQuery    = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final peers = await ref
          .read(PeerControllerProvider.notifier)
          .getAllPublicPeers();
      final skillsSet = <String>{};
      final traitsSet = <String>{};
      for (final p in peers) {
        skillsSet.addAll(p.skills);
        traitsSet.addAll(p.traits);
      }
      setState(() {
        _allPeers  = peers;
        _allSkills = skillsSet.toList()..sort();
        _allTraits = traitsSet.toList()..sort();
        _loading   = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<PeerModel> get _filtered {
    var peers = List<PeerModel>.from(_allPeers);
    if (_searchQuery.isNotEmpty) {
      peers = peers.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedSkills.isNotEmpty) {
      peers = peers.where((p) =>
          _selectedSkills.any((s) => p.skills.contains(s))).toList();
    }
    if (_selectedTraits.isNotEmpty) {
      peers = peers.where((p) =>
          _selectedTraits.any((t) => p.traits.contains(t))).toList();
    }
    peers.sort((a, b) => b.lastActive.compareTo(a.lastActive));
    return peers;
  }

  bool get _hasFilters =>
      _selectedSkills.isNotEmpty ||
      _selectedTraits.isNotEmpty ||
      _searchQuery.isNotEmpty;

  void _clearFilters() => setState(() {
    _selectedSkills.clear(); _selectedTraits.clear();
    _searchQuery = ''; _searchCtrl.clear();
  });

  void _showFilterSheet() {
    final palette = _PeerPalette.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: Border(top: BorderSide(color: palette.border, width: 1)),
      builder: (_) => _FilterSheet(
        allSkills:      _allSkills,
        allTraits:      _allTraits,
        selectedSkills: List.from(_selectedSkills),
        selectedTraits: List.from(_selectedTraits),
        onApply: ({required skills, required traits}) =>
            setState(() { _selectedSkills = skills; _selectedTraits = traits; }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _PeerPalette.of(context);
    final currentUserId = ref.watch(userProvider)?.id ?? '';
    final filtered      = _filtered;
    final isFiltered    = _hasFilters;
    final displayCount  = isFiltered
        ? '${filtered.length} / ${_allPeers.length} peers'
        : '${_allPeers.length} peers';

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ──────────────────────────────────────────
          Container(
            color: palette.surface,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PEER CONNECT',
                    style: TextStyle(color: palette.accent,
                        fontSize: 9, fontWeight: FontWeight.w700,
                        letterSpacing: 1.8)),
                const SizedBox(height: 2),
                RichText(text: TextSpan(children: [
                  TextSpan(text: 'Find your ',
                      style: TextStyle(color: palette.textPrimary, fontSize: 18,
                          fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                  TextSpan(text: 'people',
                      style: TextStyle(color: palette.accent,
                          fontSize: 18, fontWeight: FontWeight.w700,
                          letterSpacing: -0.4)),
                ])),
              ]),
              const Spacer(),
              // Quiet count
              if (!_loading && _error == null)
                Text(displayCount,
                    style: TextStyle(color: palette.muted, fontSize: 11,
                        fontWeight: FontWeight.w500, letterSpacing: 0.2)),
              const SizedBox(width: 14),
              NeoPopButton(
                color: palette.accent,
                bottomShadowColor: palette.bg,
                rightShadowColor: palette.bg,
                depth: 4,
                onTapUp: () => Routemaster.of(context).push('/peerProfile'),
                onTapDown: () {},
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('My Card',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: palette.onAccent)),
                    SizedBox(width: 5),
                    Icon(Icons.launch_rounded, size: 12,
                        color: palette.onAccent),
                  ]),
                ),
              ),
            ]),
          ),

          // ── Search + filter ──────────────────────────────────
          Container(
            color: palette.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.surface2,
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(13)),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: palette.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      hintStyle: TextStyle(color: palette.muted, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: palette.muted, size: 17),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: palette.muted, size: 15),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              })
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showFilterSheet,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: (_selectedSkills.isNotEmpty || _selectedTraits.isNotEmpty)
                        ? palette.accent : palette.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: (_selectedSkills.isNotEmpty || _selectedTraits.isNotEmpty)
                            ? palette.accent : palette.border)),
                  child: Center(child: Icon(Icons.tune_rounded, size: 17,
                      color: (_selectedSkills.isNotEmpty || _selectedTraits.isNotEmpty)
                          ? palette.onAccent : palette.muted)),
                ),
              ),
            ]),
          ),

          Container(height: 1, color: palette.border),

          // ── Active filter chips ──────────────────────────────
          if (_hasFilters)
            Container(
              color: palette.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  ..._selectedSkills.map((s) => _ActiveChip(
                      label: s,
                      onRemove: () => setState(() => _selectedSkills.remove(s)))),
                  ..._selectedTraits.map((t) => _ActiveChip(
                      label: t,
                      onRemove: () => setState(() => _selectedTraits.remove(t)))),
                  if (_selectedSkills.isNotEmpty || _selectedTraits.isNotEmpty)
                    const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Text('Clear all',
                        style: TextStyle(color: palette.accent,
                            fontSize: 11, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),

          // ── Deck area — fixed, NOT scrollable ────────────────
          // RefreshIndicator needs a scrollable child to detect the pull
          // gesture, so we wrap with a CustomScrollView that has a fixed
          // SliverFillRemaining — this gives us pull-to-refresh without
          // making the deck itself scroll.
          Expanded(
            child: _loading
                ? Center(
                    child: SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: palette.accent),
                    ))
                : _error != null
                    ? _ErrorState(onRetry: _loadAll)
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        color: palette.accent,
                        backgroundColor: palette.surface2,
                        displacement: 20,
                        child: CustomScrollView(
                          // Allow the overscroll that triggers pull-to-refresh
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              // hasScrollBody false = child is NOT scrollable,
                              // the sliver just fills remaining space
                              hasScrollBody: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                                child: PeerCardDeck(
                                  peers:         filtered,
                                  currentUserId: currentUserId,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILTER SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.allSkills, required this.allTraits,
    required this.selectedSkills, required this.selectedTraits,
    required this.onApply,
  });
  final List<String> allSkills, allTraits, selectedSkills, selectedTraits;
  final void Function({
    required List<String> skills,
    required List<String> traits,
  }) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<String> _skills;
  late List<String> _traits;
  static const int _step = 8;
  int _skillsShown = 8;
  int _traitsShown = 8;

  int get _activeCount => _skills.length + _traits.length;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.selectedSkills);
    _traits = List.from(widget.selectedTraits);
  }

  void _toggle(List<String> list, String item) =>
      setState(() => list.contains(item) ? list.remove(item) : list.add(item));

  @override
  Widget build(BuildContext context) {
    final palette = _PeerPalette.of(context);
    final visibleSkills = widget.allSkills.take(_skillsShown).toList();
    final visibleTraits = widget.allTraits.take(_traitsShown).toList();
    final moreSkills    = widget.allSkills.length - _skillsShown;
    final moreTraits    = widget.allTraits.length - _traitsShown;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 32, height: 3,
            decoration: BoxDecoration(color: palette.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('Filters',
                style: TextStyle(color: palette.textPrimary, fontSize: 17,
                    fontWeight: FontWeight.w700)),
            if (_activeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: palette.accent,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$_activeCount',
                    style: TextStyle(
                        color: palette.onAccent,
                        fontSize: 10, fontWeight: FontWeight.w700))),
            ],
            const Spacer(),
            if (_activeCount > 0)
              GestureDetector(
                onTap: () =>
                    setState(() { _skills.clear(); _traits.clear(); }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: palette.accent.withOpacity(0.25))),
                  child: Text('Clear all',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.accent))),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(height: 1, color: palette.border),

        Expanded(child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            if (widget.allSkills.isNotEmpty) ...[
              _SectionHeader(label: 'SKILLS', selectedCount: _skills.length),
              const SizedBox(height: 10),
              _ChipWrap(items: visibleSkills, selected: _skills,
                  onTap: (s) => _toggle(_skills, s)),
              if (moreSkills > 0) ...[
                const SizedBox(height: 8),
                _LoadMoreBtn(remaining: moreSkills,
                    onTap: () => setState(() => _skillsShown += _step)),
              ],
              const SizedBox(height: 22),
            ],
            if (widget.allTraits.isNotEmpty) ...[
              _SectionHeader(label: 'INTERESTS', selectedCount: _traits.length),
              const SizedBox(height: 10),
              _ChipWrap(items: visibleTraits, selected: _traits,
                  onTap: (t) => _toggle(_traits, t)),
              if (moreTraits > 0) ...[
                const SizedBox(height: 8),
                _LoadMoreBtn(remaining: moreTraits,
                    onTap: () => setState(() => _traitsShown += _step)),
              ],
              const SizedBox(height: 24),
            ],
            GestureDetector(
              onTap: () {
                widget.onApply(skills: _skills, traits: _traits);
                Navigator.pop(context);
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: palette.accent,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(
                  _activeCount > 0
                      ? 'Apply $_activeCount filter${_activeCount > 1 ? 's' : ''}'
                      : 'Apply',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: palette.onAccent,
                      letterSpacing: 0.2)))),
            ),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.selectedCount});
  final String label;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerPalette.of(context);
    return Row(children: [
    Text(label, style: TextStyle(color: palette.accent, fontSize: 9,
        fontWeight: FontWeight.w700, letterSpacing: 1.6)),
    if (selectedCount > 0) ...[
      const SizedBox(width: 8),
      Text('$selectedCount selected',
          style: TextStyle(color: palette.accent, fontSize: 10,
              fontWeight: FontWeight.w600)),
    ],
  ]);
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items, required this.selected, required this.onTap});
  final List<String> items, selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerPalette.of(context);
    return Wrap(spacing: 8, runSpacing: 8,
    children: items.map((item) {
      final active = selected.contains(item);
      return GestureDetector(
        onTap: () => onTap(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? palette.accent.withOpacity(0.1) : palette.surface2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? palette.accent.withOpacity(0.45) : palette.border,
              width: active ? 1.5 : 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (active) ...[
              Icon(Icons.check_rounded, size: 11, color: palette.accent),
              const SizedBox(width: 4),
            ],
            Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: active ? palette.accent : palette.muted)),
          ])));
    }).toList());
  }
}

class _LoadMoreBtn extends StatelessWidget {
  const _LoadMoreBtn({required this.remaining, required this.onTap});
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerPalette.of(context);
    return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: palette.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: palette.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.expand_more_rounded, size: 14, color: palette.muted),
        const SizedBox(width: 5),
        Text('Show $remaining more',
            style: TextStyle(fontSize: 11,
                fontWeight: FontWeight.w600, color: palette.muted)),
      ])));
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerPalette.of(context);
    return Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.fromLTRB(9, 4, 6, 4),
    decoration: BoxDecoration(
      color: palette.accent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: palette.accent.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: palette.accent)),
      const SizedBox(width: 5),
      GestureDetector(
        onTap: onRemove,
        child: Icon(Icons.close_rounded, size: 11, color: palette.accent)),
    ]));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = _PeerPalette.of(context);
    return Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.wifi_off_rounded, color: palette.muted, size: 34),
      const SizedBox(height: 12),
      Text('Could not load peers',
          style: TextStyle(color: palette.textPrimary, fontSize: 14,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: palette.surface2,
              border: Border.all(color: palette.accent),
              borderRadius: BorderRadius.circular(6)),
          child: Text('Retry',
              style: TextStyle(color: palette.accent,
                  fontWeight: FontWeight.w600)))),
    ]));
  }
}
