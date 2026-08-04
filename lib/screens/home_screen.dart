import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/god_model.dart';
import '../models/pop_culture_model.dart';
import '../data/gods_data.dart';
import '../widgets/god_card.dart';
import '../widgets/random_god_dialog.dart';
import '../l10n/language_provider.dart';
import '../l10n/app_strings.dart';
import '../services/bookmark_service.dart';
import '../services/daily_free_service.dart';
import '../services/onboarding_service.dart';
import '../services/sound_service.dart';
import '../utils/app_fonts.dart';
import 'main_shell.dart';
import 'god_detail_screen.dart';
import 'pop_culture_detail_screen.dart';
import 'greek_category_screen.dart';
import 'nordic_category_screen.dart';
import 'egypt_category_screen.dart';
import 'hindu_category_screen.dart';
import 'chinese_category_screen.dart';
import 'japanese_category_screen.dart';
import 'god_battle_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late List<God> _allGods;
  List<God> _filteredGods = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedMythology = 'All';
  String? _expandedGodId;
  late final AnimationController _staggerCtrl;
  Timer? _freeCardClock;

  @override
  void initState() {
    super.initState();
    _allGods = List.from(godsData);
    _filteredGods = List.from(godsData);
    _searchController.addListener(_applyFilters);
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadBookmarks();
    _scheduleFreeCardRefresh();
  }

  /// The Free God Card's availability flips at the 9 AM day boundary
  /// (DailyFreeService._todayKey) purely by wall-clock time, with nothing
  /// else to trigger a rebuild. Rather than polling forever, sleep exactly
  /// until that next boundary, repaint the dice badge once, then schedule
  /// the following one — a single pending timer instead of a tick every
  /// minute for the life of the screen.
  void _scheduleFreeCardRefresh() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 9);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    _freeCardClock?.cancel();
    _freeCardClock = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleFreeCardRefresh();
    });
  }

  /// Returns a staggered animation for card at [index].
  Animation<double> _stagger(int index) {
    final count = _filteredGods.length.clamp(1, 20);
    final start = (index / count).clamp(0.0, 1.0);
    final end = ((index + 1) / count).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _loadBookmarks() async {
    final ids = await BookmarkService.load();
    for (final god in _allGods) {
      god.isBookmarked = ids.contains(god.id);
    }
    if (mounted) setState(() {});
  }

  /// Scrolls the Discover feed back to the top — called by [MainShell] when
  /// the Discover tab is re-tapped while already active.
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _freeCardClock?.cancel();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      final q = _searchController.text.toLowerCase();
      final lang = LanguageProvider.of(context).value;
      _filteredGods = _allGods.where((g) {
        final matchQ = q.isEmpty ||
            g.name.toLowerCase().contains(q) ||
            g.localizedTitle(lang).toLowerCase().contains(q) ||
            g.localizedPowers(lang).any((p) => p.toLowerCase().contains(q));
        final matchM =
            _selectedMythology == 'All' || g.mythology == _selectedMythology;
        return matchQ && matchM;
      }).toList();
    });
    _staggerCtrl
      ..reset()
      ..forward();
  }

  Future<void> _startRandomGod() async {
    if (_allGods.isEmpty) return;
    SoundService.playClick();
    final lang = LanguageProvider.of(context).value;

    // The dice spins the 6 mythic realms first, then a god within the one
    // it lands on — so the pool is real gods only, no pop-culture entries.
    final pool = <RandomEntry>[
      for (final g in _allGods)
        RandomEntry(
          imageUrl: g.imageUrl,
          name: g.name,
          subtitle: g.localizedTitle(lang),
          verse: g.mythology,
          payload: g,
        ),
    ];

    final result = await RandomGodDialog.show(context, pool);
    if (result == null || !mounted) return;

    final payload = result.payload;
    Widget page;
    if (payload is God) {
      page = GodDetailScreen(god: payload);
    } else if (payload is MythicPopCultureCharacter) {
      page = PopCultureDetailScreen(character: payload);
    } else {
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Bottom sheet on the dice button: "for fun" random god (Option 1) or the
  // daily free-god unlock (Option 2). Option 2's state is computed up front —
  // disabled if already claimed today or if no locked gods remain.
  void _openDiceMenu() {
    SoundService.playClick();
    final lang = LanguageProvider.of(context).value;
    final canClaim = DailyFreeService.canClaimFreeToday();
    final hasLocked = DailyFreeService.hasLockedGodsRemaining(_allGods);
    final freeEnabled = canClaim && hasLocked;

    final freeSubtitle = !hasLocked
        ? localize(lang, 'Semua dewa sudah kamu buka', 'You have unlocked every god')
        : !canClaim
            ? localize(lang, 'Kembali lagi besok jam 9 pagi', 'Come back tomorrow at 9 AM')
            : localize(lang, 'Buka 1 legenda dewa gratis hari ini', 'Unlock 1 god legend free today');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _diceMenuOption(
                icon: Icons.casino_rounded,
                iconColor: Colors.white,
                title: localize(lang, 'Dewa Acak (iseng)', 'Random God (for fun)'),
                subtitle: localize(lang, 'Jelajah dewa mana saja secara acak', 'Spin any god at random'),
                enabled: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startRandomGod();
                },
              ),
              const SizedBox(height: 10),
              _diceMenuOption(
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFFE0A82E),
                title: localize(lang, 'Kartu Dewa Gratis', 'Free God Card'),
                subtitle: freeSubtitle,
                enabled: freeEnabled,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startFreeGodRoll();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _diceMenuOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rolls a random god from the LOCKED pool only and unlocks its legend for
  // free (permanent), then opens its detail so the user can read right away.
  Future<void> _startFreeGodRoll() async {
    if (!DailyFreeService.canClaimFreeToday()) return;
    final locked = DailyFreeService.lockedPool(_allGods);
    if (locked.isEmpty) return;
    SoundService.playClick();
    final lang = LanguageProvider.of(context).value;

    final pool = <RandomEntry>[
      for (final g in locked)
        RandomEntry(
          imageUrl: g.imageUrl,
          name: g.name,
          subtitle: g.localizedTitle(lang),
          verse: g.mythology,
          payload: g,
        ),
    ];

    final result = await RandomGodDialog.show(context, pool);
    if (result == null || !mounted) return;
    final payload = result.payload;
    if (payload is! God) return;

    await DailyFreeService.claim(payload);
    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GodDetailScreen(god: payload),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _selectMythology(String m) {
    // Greek, Nordic, Egyptian, Hindu, Chinese & Japanese open a sub-category chooser
    if (m == 'Greek' || m == 'Nordic' || m == 'Egyptian' || m == 'Hindu' || m == 'Chinese' || m == 'Japanese') {
      SoundService.playClick();
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) {
            if (m == 'Greek') return const GreekCategoryScreen();
            if (m == 'Nordic') return const NordicCategoryScreen();
            if (m == 'Hindu') return const HinduCategoryScreen();
            if (m == 'Chinese') return const ChineseCategoryScreen();
            if (m == 'Japanese') return const JapaneseCategoryScreen();
            return const EgyptCategoryScreen();
          },
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
    setState(() => _selectedMythology = m);
    _applyFilters();
  }

  void _toggleLanguage() {
    final lang = LanguageProvider.of(context);
    lang.cycleLanguage();
  }

  void _showBattleDisclaimer(String lang) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: localize(lang, 'Tutup dialog', 'Dismiss dialog'),
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, a1, a2, child) {
        return FadeTransition(
          opacity: a1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, __, ___) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB07800).withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6F00).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF8A00),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  localize(lang, 'Pernyataan Penting', 'Important Notice'),
                  style: AppFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE0E0E0),
                    letterSpacing: 1,
                  ).copyWith(decoration: TextDecoration.none),
                ),
                const SizedBox(height: 14),
                // Warning text
                Text(
                  localize(lang,
                      'Fitur "Adu Dewa" dibuat semata-mata untuk hiburan dan edukasi mengenai mitologi.\n\nKami tidak bermaksud untuk menyinggung, menyalahgunakan, atau tidak menghormati dewa-dewi dari berbagai kepercayaan.\n\nGunakan fitur ini dengan bijak dan tetap hormati mitologi yang ada.',
                      'The "God Battle" feature is created solely for entertainment and educational purposes about mythology.\n\nWe do not intend to offend, misuse, or disrespect any deities from various beliefs.\n\nUse this feature wisely and remain respectful of existing mythologies.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                    height: 1.6,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    // Batal
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: Center(
                            child: Text(
                              localize(lang, 'Batal', 'Cancel'),
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Lanjut
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const GodBattleScreen(),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB07800),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              localize(lang, 'Lanjut', 'Continue'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildHeader(lang),
            _buildGenreCards(lang),
            _buildFeatureCards(lang),
            _buildSearchBar(lang),
            const SizedBox(height: 14),
            if (_filteredGods.isEmpty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 48, color: Color(0xFF555555)),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.get('emptyTitle', lang),
                        style: const TextStyle(
                            color: Color(0xFF999999), fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.get('emptySubtitle', lang),
                        style: const TextStyle(
                            color: Color(0xFF555555), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(
                _filteredGods.length,
                (i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: GodCard(
                    showInfoIcon: true,
                    god: _filteredGods[i],
                    isExpanded: _filteredGods[i].id == _expandedGodId,
                    entranceAnim: _stagger(i),
                    onToggle: () {
                      setState(() {
                        final tappedId = _filteredGods[i].id;
                        _expandedGodId =
                            _expandedGodId == tappedId ? null : tappedId;
                      });
                    },
                    onReturn: () => setState(() {}),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MYTHERA',
                  style: AppFonts.cinzel(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppStrings.get('homeSubtitle', lang),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language,
                      color: Color(0xFFB07800), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    LanguageNotifier.shortLabels[LanguageNotifier.supportedLanguages[
                        (LanguageNotifier.supportedLanguages.indexOf(lang) + 1) %
                            LanguageNotifier.supportedLanguages.length]] ?? 'EN',
                    style: const TextStyle(
                      color: Color(0xFFB07800),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: AppStrings.get('searchHint', lang),
                  hintStyle:
                      const TextStyle(color: Color(0xFF777777), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFB07800), size: 18),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 0),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF777777), size: 16),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 0),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Dice button — opens a menu: "for fun" random god, or the daily
          // free-god unlock. Turns gold with a "1" badge whenever today's
          // Free God Card is still unclaimed (day boundary is 9 AM — see
          // DailyFreeService._todayKey), so its availability is visible
          // without opening the menu. Long-press (debug only) resets
          // today's free claim so the daily limit can be tested without
          // waiting for 9 AM.
          Builder(builder: (context) {
            final freeCardAvailable = DailyFreeService.canClaimFreeToday() &&
                DailyFreeService.hasLockedGodsRemaining(_allGods);
            const gold = Color(0xFFE0A82E);
            return GestureDetector(
              onTap: _openDiceMenu,
              onLongPress: kDebugMode
                  ? () async {
                      await DailyFreeService.debugResetDailyClaim();
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('[Debug] Daily free claim reset'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  : null,
              child: SizedBox(
                height: 40,
                width: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: freeCardAvailable
                            ? gold.withValues(alpha: 0.14)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: freeCardAvailable
                              ? gold.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: freeCardAvailable
                            ? [
                                BoxShadow(
                                  color: gold.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.casino_rounded,
                        color: freeCardAvailable ? gold : Colors.white,
                        size: 23,
                      ),
                    ),
                    if (freeCardAvailable)
                      Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          height: 17,
                          width: 17,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF0B0B0B), width: 1.5),
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 6 pantheon cards (image background), horizontally scrollable, replacing
  // the old plain filter chips. Tapping opens that pantheon's god catalog.
  static const _genreCards = [
    (key: 'Greek', image: 'assets/images/greek.webp'),
    (key: 'Egyptian', image: 'assets/images/egypt.webp'),
    (key: 'Nordic', image: 'assets/images/nordik.webp'),
    (key: 'Hindu', image: 'assets/images/hindu.webp'),
    (key: 'Chinese', image: 'assets/images/cina.webp'),
    (key: 'Japanese', image: 'assets/images/japanese.webp'),
  ];

  // Genre cards with the user's onboarding realm (their patron god's pantheon)
  // moved to the front, so Discover opens on the world they chose.
  List<({String key, String image})> get _orderedGenreCards {
    final pref = OnboardingService.preferredPantheon;
    if (pref == null) return _genreCards;
    final list = [..._genreCards];
    final idx = list.indexWhere((g) => g.key == pref);
    if (idx > 0) list.insert(0, list.removeAt(idx));
    return list;
  }

  Widget _buildGenreCards(String lang) {
    final cards = _orderedGenreCards;
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final g = cards[i];
          final color = GodCard.mythologyColor(g.key);
          final count = godsData.where((x) => x.mythology == g.key).length;
          return GestureDetector(
            onTap: () => _selectMythology(g.key),
            child: Container(
              width: 116,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    g.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.55),
                            const Color(0xFF0E0E0E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.4, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.key,
                          style: GodCard.mythologyFont(
                            g.key,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$count ${localize(lang, 'dewa', 'gods')}',
                          style: const TextStyle(
                            color: Color(0xFFCFCFCF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCards(String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Expanded(
              child: _featureCard(
                image: 'assets/images/yourgods.webp',
                fallback: const Color(0xFFB07800),
                icon: Icons.psychology_rounded,
                title: localize(lang, 'Dewa Apa Dirimu?', "What's Your God?"),
                onTap: () async {
                  // Guards against a fast double-tap pushing two QuizScreen
                  // instances (which would let the second one's early pop
                  // reset this flag while the first is still open).
                  if (MainShell.quizActive.value) return;
                  SoundService.playClick();
                  MainShell.quizActive.value = true;
                  await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const QuizScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                  // Guaranteed to run once QuizScreen is popped, no matter
                  // how (back button, system back, multiple pops through
                  // the result screen) — a more reliable reset than relying
                  // on the quiz screen's own dispose() alone.
                  MainShell.quizActive.value = false;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _featureCard(
                image: 'assets/images/battle.webp',
                fallback: const Color(0xFFB07800),
                icon: Icons.flash_on_rounded,
                title: localize(lang, 'Adu Dewa', 'God Battle'),
                onTap: () {
                  SoundService.playClick();
                  _showBattleDisclaimer(lang);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same visual language as the "Favorites" card in Codex (icon circle +
  // title + chevron in a row, left-to-right dark gradient over the image),
  // just scaled down so two of these still fit side by side.
  Widget _featureCard({
    required String image,
    required Color fallback,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fallback.withValues(alpha: 0.5),
                      const Color(0xFF0E0E0E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              // ClipRect: guards against overflow if this card is ever
              // squeezed narrower than its icon+text+chevron minimum width
              // (e.g. a very narrow browser window on Flutter Web).
              child: ClipRect(
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: fallback, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: fallback, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

  // _buildList removed — god cards now inline in build() ListView.
