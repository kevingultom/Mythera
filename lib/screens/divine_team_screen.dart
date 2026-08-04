import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/divine_team_data.dart';
import '../l10n/language_provider.dart';
import '../models/combatant.dart';
import '../models/god_model.dart';
import '../services/sound_service.dart';
import '../utils/app_fonts.dart';
import '../widgets/team_slot_card.dart';
import 'god_detail_screen.dart';
import 'pop_culture_detail_screen.dart';

const _gold = Color(0xFFB07800);
const _goldBright = Color(0xFFE0A82E);

enum _Phase { drafting, revealed }

/// Draft one god (or pop-culture character) per power theme, then see how
/// the assembled pantheon ranks.
///
/// Category names (Strength, Combat Skill, ...) and rank titles (Pantheon
/// Supreme, ...) stay English-only by design, like proper nouns — but the
/// surrounding UI text follows the app's language setting via [localize],
/// and nothing here renders [God.symbol] (still emoji-free).
class DivineTeamScreen extends StatefulWidget {
  const DivineTeamScreen({super.key});

  @override
  State<DivineTeamScreen> createState() => _DivineTeamScreenState();
}

class _DivineTeamScreenState extends State<DivineTeamScreen> {
  /// Tick delays for one roll: fast at first, easing to a stop — a slot
  /// machine deceleration rather than a constant-speed loop.
  static const _rollDelaysMs = [
    70, 70, 80, 90, 100, 120, 150, 190, 240, 300, 380,
  ];

  final Map<String, Combatant> _locked = {};
  final Map<String, Combatant> _showing = {};
  _Phase _phase = _Phase.drafting;
  bool _cycling = false;

  /// True from the first tap of Random until the draft resets. The button
  /// stays disabled for the rest of the draft — locking a slot chains
  /// straight into the next roll on its own, so a second press is never
  /// needed (or allowed).
  bool _randomStarted = false;

  /// Set true the moment a lock happens mid-roll, so the roll that's
  /// already in flight knows to chain into a fresh one once it settles
  /// (rather than every settle auto-restarting forever).
  bool _lockedSinceRollStart = false;

  final _rng = Random();
  Timer? _cycleTimer;

  /// Built once: [poolFor] is memoized, but resolving it in build would still
  /// churn ten map lookups per frame.
  late final Map<String, List<Combatant>> _pools = {
    for (final c in kTeamCategories) c.id: poolFor(c),
  };

  bool get _allLocked => _locked.length == kTeamCategories.length;
  bool get _anyUnlocked => _locked.length < kTeamCategories.length;

  List<DraftedSlot> get _team => [
        for (final c in kTeamCategories)
          if (_locked[c.id] != null)
            DraftedSlot(category: c, combatant: _locked[c.id]!),
      ];

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  /// Rolls every open slot through a fast-to-slow ramp that stops on its
  /// own — no separate stop control. Once it settles, slots sit still until
  /// the user locks one; locking a slot then automatically kicks off a
  /// fresh roll for whatever's still open, so Random never needs a second
  /// manual press.
  ///
  /// [fromButton] gates only the very first press — once the draft is
  /// under way, [_lockSlot] must be able to kick off every subsequent roll
  /// even though [_randomStarted] is already true.
  void _startRandom({bool fromButton = false}) {
    if (_cycling || !_anyUnlocked) return;
    if (fromButton && _randomStarted) return;
    SoundService.playClick();
    _lockedSinceRollStart = false;
    setState(() {
      _randomStarted = true;
      _cycling = true;
    });
    _runRollStep(0);
  }

  void _runRollStep(int step) {
    _rollOpenSlots();
    if (step >= _rollDelaysMs.length - 1) {
      setState(() => _cycling = false);
      SoundService.playRandomGodLand();
      // A lock landed mid-roll (the slot froze, but this roll kept running
      // for the others) — chain straight into a fresh roll for whatever's
      // still open, rather than leaving them sitting still.
      if (_lockedSinceRollStart && _anyUnlocked) _startRandom();
      return;
    }
    _cycleTimer = Timer(Duration(milliseconds: _rollDelaysMs[step]), () {
      if (!mounted) return;
      _runRollStep(step + 1);
    });
  }

  void _rollOpenSlots() {
    setState(() {
      for (final c in kTeamCategories) {
        if (_locked.containsKey(c.id)) continue;
        final pool = _pools[c.id] ?? const [];
        if (pool.isEmpty) continue;
        _showing[c.id] = pool[_rng.nextInt(pool.length)];
      }
    });
  }

  /// Locks in whatever [c]'s slot is currently showing. One-way: once a
  /// slot is locked it stays locked for the rest of the draft — tapping a
  /// locked card does nothing.
  void _lockSlot(TeamCategory c) {
    if (_locked.containsKey(c.id)) return;
    // Locking mid-roll just freezes this one slot on whatever it's
    // currently showing; the rest keep rolling toward their own stop.
    final god = _showing[c.id];
    if (god == null) return;
    SoundService.playRandomGodTick();
    setState(() => _locked[c.id] = god);
    if (_allLocked) {
      _reveal();
      return;
    }
    if (_cycling) {
      // Tell the in-flight roll to chain into another one once it settles.
      _lockedSinceRollStart = true;
    } else {
      // The previous roll had already settled — start a new one right now.
      _startRandom();
    }
  }

  /// Moves to the result screen. Called automatically the instant the
  /// tenth slot locks — there's no separate "reveal" button to press.
  void _reveal() {
    SoundService.playRandomGodLand();
    setState(() => _phase = _Phase.revealed);
  }

  void _reset() {
    SoundService.playClick();
    _cycleTimer?.cancel();
    _cycleTimer = null;
    _lockedSinceRollStart = false;
    setState(() {
      _locked.clear();
      _showing.clear();
      _cycling = false;
      _randomStarted = false;
      _phase = _Phase.drafting;
    });
  }

  /// Opens the detail screen for a drafted member — [GodDetailScreen] for a
  /// real god, [PopCultureDetailScreen] for a pop-culture character, since
  /// they're different screens built around different models.
  void _openGod(Combatant g) {
    SoundService.playClick();
    final Widget screen = switch (g) {
      God() => GodDetailScreen(god: g),
      PcCombatant() => PopCultureDetailScreen(character: g.character),
      _ => throw StateError('Unknown Combatant type: ${g.runtimeType}'),
    };
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back sits outside the scrollable so it never scrolls away.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        localize(lang, 'Kembali', 'Back'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _phase == _Phase.drafting
                    ? _draftingView(lang)
                    : _TeamResultView(
                        team: _team,
                        lang: lang,
                        onBuildAgain: _reset,
                        onOpenGod: _openGod,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _draftingView(String lang) {
    return Column(
      key: const ValueKey('drafting'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Text(
                localize(lang, 'TIM PARA DEWA', 'DIVINE TEAM'),
                style: AppFonts.cinzel(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localize(
                  lang,
                  'Tekan Random untuk mengacak semua slot yang belum terisi. '
                      'Ketuk kartu setelah berhenti untuk mengunci dewa itu — '
                      'sisanya akan otomatis diacak lagi sampai semua slot terkunci.',
                  'Hit Random to roll every open slot. Tap a card once it '
                      'settles to lock that god in — the rest roll again on '
                      'their own until every slot is locked.',
                ),
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              _progressBar(lang),
              const SizedBox(height: 14),
              // Wrap instead of GridView.count: each card sizes its own
              // height from its content (portrait + label), so nothing
              // depends on guessing a fixed aspect ratio that fits every
              // state (empty placeholder vs. a god's name showing).
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  final cardWidth = (constraints.maxWidth - spacing * 2) / 3;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 12,
                    children: [
                      for (final c in kTeamCategories)
                        SizedBox(
                          width: cardWidth,
                          child: TeamSlotCard(
                            category: c,
                            showing: _showing[c.id],
                            lockedGod: _locked[c.id],
                            isCycling: _cycling,
                            onTap: () => _lockSlot(c),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _randomButton(lang),
        ),
      ],
    );
  }

  Widget _randomButton(String lang) {
    final enabled = !_randomStarted;
    return GestureDetector(
      onTap: enabled ? () => _startRandom(fromButton: true) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _goldBright.withValues(alpha: 0.6)),
          ),
          child: Center(
            child: Text(
              localize(lang, 'Acak', 'Random'),
              style: const TextStyle(
                color: _goldBright,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressBar(String lang) {
    final done = _locked.length;
    final total = kTeamCategories.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localize(lang, '$done / $total terkunci', '$done / $total locked'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (done > 0)
              Text(
                localize(lang, 'Pilihan yang terkunci bersifat final',
                    'Locked picks are final'),
                style: const TextStyle(color: Color(0xFF6E6E6E), fontSize: 10.5),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: done / total,
            minHeight: 4,
            backgroundColor: const Color(0xFF1E1E1E),
            valueColor: const AlwaysStoppedAnimation<Color>(_goldBright),
          ),
        ),
      ],
    );
  }

}

/// Final standing for a completed team.
class _TeamResultView extends StatelessWidget {
  final List<DraftedSlot> team;
  final String lang;
  final VoidCallback onBuildAgain;
  final ValueChanged<Combatant> onOpenGod;

  const _TeamResultView({
    required this.team,
    required this.lang,
    required this.onBuildAgain,
    required this.onOpenGod,
  });

  @override
  Widget build(BuildContext context) {
    final rank = rankFor(team);
    final score = teamScore(team);

    // How many slots landed the single strongest (#1) or top-3 pick for
    // their category, per the curated ranking — a quick read on how
    // fortunate the draft was, in place of the old tier-badge breakdown.
    final topPicks = team
        .where((s) =>
            (kCategoryRankings[s.category.id]?.indexOf(s.combatant.id) ??
                -1) ==
            0)
        .length;
    final top3Picks = team
        .where((s) {
          final idx =
              kCategoryRankings[s.category.id]?.indexOf(s.combatant.id) ?? -1;
          return idx >= 0 && idx < 3;
        })
        .length;

    return ListView(
      key: const ValueKey('revealed'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: _goldBright.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _goldBright.withValues(alpha: 0.55)),
                ),
                child: Text(
                  rank.label,
                  style: AppFonts.cinzel(
                    color: _goldBright,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                rank.title,
                textAlign: TextAlign.center,
                style: AppFonts.cinzel(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rank.description(lang),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                localize(lang, 'Kekuatan rata-rata ${score.toStringAsFixed(2)} / 9.50',
                    'Average power ${score.toStringAsFixed(2)} / 9.50'),
                style: const TextStyle(
                  color: Color(0xFF8A8A8A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (topPicks > 0)
              _statChip(localize(
                  lang, '$topPicks pilihan #1', '$topPicks #1 picks')),
            if (top3Picks > 0)
              _statChip(localize(lang, '$top3Picks pilihan top-3',
                  '$top3Picks top-3 picks')),
          ],
        ),
        const SizedBox(height: 20),
        _analysisPanel(analyzeTeam(team, lang), lang),
        const SizedBox(height: 22),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            for (final slot in team) _memberTile(slot, lang),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onBuildAgain,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_gold, _goldBright]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                localize(lang, 'Rakit Lagi', 'Build Again'),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _analysisPanel(TeamAnalysis analysis, String lang) {
    if (analysis.lines.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: _goldBright),
              const SizedBox(width: 6),
              Text(
                localize(lang, 'ANALISIS PANTHEON', 'PANTHEON ANALYSIS'),
                style: const TextStyle(
                  color: _goldBright,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < analysis.lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 7),
            Text(
              analysis.lines[i],
              style: const TextStyle(
                color: Color(0xFFC9C9C9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _memberTile(DraftedSlot slot, String lang) {
    final category = slot.category;
    final god = slot.combatant;
    // Position within the category's curated ranking (#1 = strongest).
    // The category name itself (e.g. "Speed") stays English by design.
    final rankIdx = kCategoryRankings[category.id]?.indexOf(god.id) ?? -1;
    final subtitle = rankIdx >= 0
        ? localize(lang, '#${rankIdx + 1} di ${category.name}',
            '#${rankIdx + 1} in ${category.name}')
        : category.name;
    return GestureDetector(
      onTap: () => onOpenGod(god),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF242424)),
        ),
        child: Row(
          children: [
            Icon(category.icon, size: 15, color: _goldBright),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          god.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (god.isPopCulture) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _goldBright.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'POP',
                            style: TextStyle(
                              color: _goldBright,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
