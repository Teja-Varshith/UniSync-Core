import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neopop/neopop.dart';
import 'package:routemaster/routemaster.dart';
import 'package:unisync/app/providers.dart';
import 'package:unisync/constants/constant.dart';
import 'package:unisync/features/peer_connect/peers/peer_controller.dart';
import 'package:unisync/features/peer_connect/peers/peer_decs.dart';
import 'package:unisync/models/peer_model.dart';

class PeerScreen extends ConsumerStatefulWidget {
  const PeerScreen({super.key});

  @override
  ConsumerState<PeerScreen> createState() => _PeerScreenState();
}

class _PeerScreenState extends ConsumerState<PeerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

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
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

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

  bool _hasFilters() =>
      _selectedSkills.isNotEmpty ||
      _selectedTraits.isNotEmpty ||
      _searchQuery.isNotEmpty;

  void _clearFilters() => setState(() {
    _selectedSkills.clear(); _selectedTraits.clear();
    _searchQuery = ''; _searchCtrl.clear();
  });

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniSyncColors.backgroundSecondary,
      shape: const Border(
          top: BorderSide(color: UniSyncColors.divider, width: 0.8)),
      builder: (_) => _FilterSheet(
        allSkills: _allSkills, allTraits: _allTraits,
        selectedSkills: List.from(_selectedSkills),
        selectedTraits: List.from(_selectedTraits),
        onApply: ({required skills, required traits}) =>
            setState(() { _selectedSkills = skills; _selectedTraits = traits; }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── currentUserId from auth provider ────────────────────────────────────
    final currentUserId = ref.watch(userProvider)?.id ?? '';

    return Scaffold(
      backgroundColor: UniSyncColors.backgroundPrimary,
      body: SafeArea(child: Column(children: [

        // ── Top bar ────────────────────────────────────────────────
        Container(
          color: UniSyncColors.backgroundSecondary,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('#PEER CONNECT', style: TextStyle(
                  color: UniSyncColors.accent, fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1.8)),
              const SizedBox(height: 2),
              RichText(text: const TextSpan(children: [
                TextSpan(text: 'Find your ',
                    style: TextStyle(color: UniSyncColors.textPrimary,
                        fontSize: 18, fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                TextSpan(text: 'people',
                    style: TextStyle(color: UniSyncColors.accent,
                        fontSize: 18, fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
              ])),
            ]),
            const Spacer(),
            NeoPopButton(
              color: UniSyncColors.accent,
              // border: Border.all(color: Colors.white),
              bottomShadowColor: UniSyncColors.backgroundPrimary,
              rightShadowColor: UniSyncColors.backgroundPrimary,
              depth: 3,
              onTapUp: () => Routemaster.of(context).push('/peerProfile'),
              onTapDown: () {},
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('My Card', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: UniSyncColors.buttonPrimaryFg)),
                  SizedBox(width: 5),
                  Icon(Icons.launch_rounded, size: 13,
                      color: UniSyncColors.buttonPrimaryFg),
                ]),
              ),
            ),
          ]),
        ),

        // ── Search + filter ────────────────────────────────────────
        Container(
          color: UniSyncColors.backgroundSecondary,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: UniSyncColors.surfaceCard,
                  border: Border.all(color: UniSyncColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      color: UniSyncColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: const TextStyle(
                        color: UniSyncColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: UniSyncColors.textMuted, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: UniSyncColors.textMuted, size: 16),
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
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (_selectedSkills.isNotEmpty || _selectedTraits.isNotEmpty)
                      ? UniSyncColors.accent
                      : UniSyncColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_selectedSkills.isNotEmpty || _selectedTraits.isNotEmpty)
                        ? UniSyncColors.accent
                        : UniSyncColors.border)),
                child: Center(child: Icon(Icons.tune_rounded, size: 18,
                    color: (_selectedSkills.isNotEmpty || _selectedTraits.isNotEmpty)
                        ? UniSyncColors.buttonPrimaryFg
                        : UniSyncColors.textSecondary)),
              ),
            ),
          ]),
        ),

        Container(height: 0.8, color: UniSyncColors.divider),

        // ── Active filter chips ────────────────────────────────────
        if (_hasFilters())
          Container(
            color: UniSyncColors.backgroundSecondary,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Expanded(
              
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
                    child: const Text('Clear all', style: TextStyle(
                      color: UniSyncColors.accent, fontSize: 11,
                      fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
          ),

        // ── Deck ──────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAll,
            color: UniSyncColors.accent,
            child: _loading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: UniSyncColors.accent,
                          ),
                        ),
                      ),
                    ],
                  )
                : _error != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          _ErrorState(onRetry: _loadAll),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        child: Column(children: [
                          if (_hasFilters())
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Center(child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: UniSyncColors.surfaceCard,
                                  border: Border.all(color: UniSyncColors.border),
                                  borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  '${_filtered.length} of ${_allPeers.length} peers',
                                  style: const TextStyle(
                                    color: UniSyncColors.textMuted,
                                    fontSize: 11, fontWeight: FontWeight.w600)))) ,
                            ),
                          PeerCardDeck(
                            peers:         _filtered,
                            currentUserId: currentUserId,  // ← passed here
                          ),
                        ]),
                      ),
          ),
        ),
      ])),
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
  final void Function({required List<String> skills, required List<String> traits}) onApply;

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
    final visibleSkills = widget.allSkills.take(_skillsShown).toList();
    final visibleTraits = widget.allTraits.take(_traitsShown).toList();
    final moreSkills    = widget.allSkills.length - _skillsShown;
    final moreTraits    = widget.allTraits.length - _traitsShown;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4, maxChildSize: 0.95,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: UniSyncColors.border,
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Text('Filters', style: TextStyle(color: UniSyncColors.textPrimary,
                fontSize: 17, fontWeight: FontWeight.w700)),
            if (_activeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: UniSyncColors.accent,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$_activeCount', style: const TextStyle(
                    color: UniSyncColors.buttonPrimaryFg,
                    fontSize: 10, fontWeight: FontWeight.w700))),
            ],
            const Spacer(),
            if (_activeCount > 0)
              GestureDetector(
                onTap: () => setState(() { _skills.clear(); _traits.clear(); }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: UniSyncColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: UniSyncColors.accent.withOpacity(0.25))),
                  child: const Text('Clear all', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: UniSyncColors.accent))),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        const Divider(color: UniSyncColors.divider, height: 1),

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
              child: Container(height: 50,
                decoration: BoxDecoration(color: UniSyncColors.accent,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(
                  _activeCount > 0
                      ? 'Apply $_activeCount filter${_activeCount > 1 ? 's' : ''}'
                      : 'Apply',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: UniSyncColors.buttonPrimaryFg, letterSpacing: 0.2)))),
            ),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOCAL HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.selectedCount});
  final String label;
  final int selectedCount;
  @override
  Widget build(_) => Row(children: [
    Text(label, style: const TextStyle(color: UniSyncColors.accent, fontSize: 9,
        fontWeight: FontWeight.w700, letterSpacing: 1.6)),
    if (selectedCount > 0) ...[
      const SizedBox(width: 8),
      Text('$selectedCount selected', style: const TextStyle(
          color: UniSyncColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
    ],
  ]);
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.items, required this.selected, required this.onTap});
  final List<String> items, selected;
  final ValueChanged<String> onTap;
  @override
  Widget build(_) => Wrap(spacing: 8, runSpacing: 8,
    children: items.map((item) {
      final active = selected.contains(item);
      return GestureDetector(onTap: () => onTap(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? UniSyncColors.accent.withOpacity(0.12) : UniSyncColors.surfaceCard,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? UniSyncColors.accent.withOpacity(0.5) : UniSyncColors.border,
              width: active ? 1.5 : 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (active) ...[
              const Icon(Icons.check_rounded, size: 11, color: UniSyncColors.accent),
              const SizedBox(width: 4),
            ],
            Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: active ? UniSyncColors.accent : UniSyncColors.textSecondary)),
          ])));
    }).toList());
}

class _LoadMoreBtn extends StatelessWidget {
  const _LoadMoreBtn({required this.remaining, required this.onTap});
  final int remaining;
  final VoidCallback onTap;
  @override
  Widget build(_) => GestureDetector(onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: UniSyncColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: UniSyncColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.expand_more_rounded, size: 14, color: UniSyncColors.textMuted),
        const SizedBox(width: 5),
        Text('Show $remaining more', style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: UniSyncColors.textMuted)),
      ])));
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;
  @override
  Widget build(_) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.fromLTRB(9, 4, 6, 4),
    decoration: BoxDecoration(
      color: UniSyncColors.accent.withOpacity(0.1),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: UniSyncColors.accent.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: UniSyncColors.accent)),
      const SizedBox(width: 5),
      GestureDetector(onTap: onRemove,
        child: const Icon(Icons.close_rounded, size: 11, color: UniSyncColors.accent)),
    ]));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, color: UniSyncColors.textMuted, size: 36),
      const SizedBox(height: 12),
      const Text('Could not load peers', style: TextStyle(
          color: UniSyncColors.textPrimary,
          fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),
      GestureDetector(onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: UniSyncColors.surfaceCard,
              border: Border.all(color: UniSyncColors.accent),
              borderRadius: BorderRadius.circular(6)),
          child: const Text('Retry', style: TextStyle(
              color: UniSyncColors.accent, fontWeight: FontWeight.w600)))),
    ]));
}