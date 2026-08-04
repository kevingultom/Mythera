import 'package:flutter/material.dart';
import '../utils/app_fonts.dart';
import '../models/history_model.dart';
import '../l10n/language_provider.dart';
import '../services/sound_service.dart';
import '../services/reading_service.dart';

/// Book-style, paginated reader for a single [MythStory].
///
/// Pages: cover (title + timeline + summary + main characters) → one page per
/// narrative chapter → chronology → impact & mythological meaning. The user
/// flips through with swipe or the Next/Previous buttons, with a page
/// indicator, so no content is ever truncated.
class HistoryStoryDetailScreen extends StatefulWidget {
  final MythStory story;

  const HistoryStoryDetailScreen({super.key, required this.story});

  @override
  State<HistoryStoryDetailScreen> createState() =>
      _HistoryStoryDetailScreenState();
}

class _HistoryStoryDetailScreenState extends State<HistoryStoryDetailScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  late bool _read;

  static const _textShadow = [Shadow(color: Colors.black, blurRadius: 8)];
  static const _readGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    _read = ReadingService.isStoryRead(widget.story.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleRead() async {
    SoundService.playClick();
    final nowRead = await ReadingService.toggleStoryRead(widget.story);
    if (mounted) setState(() => _read = nowRead);
  }

  void _goTo(int page, int total) {
    if (page < 0 || page >= total) return;
    SoundService.playClick();
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageProvider.of(context).value;
    // +4 = title page, summary page, chronology page, impact/meaning page.
    final total = widget.story.chapters.length + 4;

    return Scaffold(
      backgroundColor: Colors.black,
      // The PageView sits outside SafeArea so the title page's hero image
      // can run edge-to-edge under the status bar — the header/nav bar
      // below float as an overlay on top of it instead of pushing it down,
      // which is what every other page still visually relies on (the
      // status-bar strip just reads as part of that page's own dark
      // background/gradient).
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Map / parchment background
          const _MapBackground(),
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: total,
            // Built lazily per-page — only the page(s) actually
            // visible get constructed, instead of the whole story.
            itemBuilder: (_, i) => _buildPageAt(i, lang),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const Spacer(),
                _buildNavBar(lang, total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 4),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.only(right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom navigation ──────────────────────────────────
  Widget _buildNavBar(String lang, int total) {
    final canPrev = _page > 0;
    final canNext = _page < total - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Row(
        children: [
          Flexible(
            child: _navButton(
              label: localize(lang, 'Sebelumnya', 'Previous'),
              icon: Icons.chevron_left_rounded,
              enabled: canPrev,
              onTap: () => _goTo(_page - 1, total),
              iconLeft: true,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${_page + 1} / $total',
                style: AppFonts.cinzel(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          Flexible(
            child: canNext
                ? _navButton(
                    label: localize(lang, 'Berikutnya', 'Next'),
                    icon: Icons.chevron_right_rounded,
                    enabled: true,
                    onTap: () => _goTo(_page + 1, total),
                    iconLeft: false,
                  )
                // Final page — Mark Read lives on the page itself instead.
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkReadButton(String lang) {
    return GestureDetector(
      onTap: _toggleRead,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _read
              ? _readGreen.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: _read
                  ? _readGreen.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _read
                    ? localize(lang, 'Sudah Dibaca', 'Read')
                    : localize(lang, 'Tandai Dibaca', 'Mark Read'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _read ? _readGreen : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              _read
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              color: _read ? _readGreen : Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required bool iconLeft,
  }) {
    final content = <Widget>[
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white24,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ];
    final iconW = Icon(icon,
        color: enabled ? Colors.white : Colors.white24, size: 20);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? Colors.white.withValues(alpha: 0.5) : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconLeft
              ? [iconW, const SizedBox(width: 4), ...content]
              : [...content, const SizedBox(width: 4), iconW],
        ),
      ),
    );
  }

  // ─── Pages ──────────────────────────────────────────────
  /// Builds only the requested page — keeps PageView.builder's laziness so
  /// a page flip or a setState (e.g. toggling "read") doesn't reconstruct
  /// every chapter in the story.
  Widget _buildPageAt(int i, String lang) {
    final s = widget.story;
    if (i == 0) return _titlePage(lang);
    if (i == 1) return _summaryPage(lang);
    final chapterIndex = i - 2;
    if (chapterIndex < s.chapters.length) {
      return _chapterPage(
          s.chapters[chapterIndex], chapterIndex, s.chapters.length, lang);
    }
    final afterChapters = chapterIndex - s.chapters.length;
    if (afterChapters == 0) return _chronologyPage(lang);
    return _impactMeaningPage(lang);
  }

  /// Reusable scrollable page shell — transparent so the map background
  /// shows through and the text blends into the parchment. Wrapped in its
  /// own SafeArea (the PageView now sits outside the screen's SafeArea, so
  /// the title page's image can run under the status bar) with extra top
  /// padding to clear the floating header and bottom padding to clear the
  /// floating nav bar, since both are overlaid rather than pushing layout.
  Widget _pageShell({required List<Widget> children}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  /// Page 1: title page. Just the portrait hero image filling the frame,
  /// with the mythology badge, title, and timeline overlaid near the
  /// bottom — no summary or character list here, so the illustration is
  /// seen at full size rather than sharing space with body text.
  Widget _titlePage(String lang) {
    final s = widget.story;
    // The nav bar floats over this page too (see build()) — clear it with
    // extra bottom room rather than the smaller margin the scrollable pages
    // get from _pageShell's SafeArea padding.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (s.imageUrl.isNotEmpty)
          _titleImage(s.imageUrl, s.icon)
        else
          const SizedBox.shrink(),
        Positioned(
          left: 20,
          right: 20,
          bottom: 72 + bottomInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  s.mythology.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    shadows: _textShadow,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.localizedTitle(lang),
                style: AppFonts.cinzel(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.localizedTimeline(lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  shadows: _textShadow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Page 2: summary + main characters — the content that used to share
  /// the cover page with the hero image, now on its own page.
  Widget _summaryPage(String lang) {
    final s = widget.story;
    return _pageShell(
      children: [
        _sectionLabel(localize(lang, 'Ringkasan', 'Summary')),
        const SizedBox(height: 12),
        Text(
          s.localizedSummary(lang),
          textAlign: TextAlign.justify,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.7,
            shadows: _textShadow,
          ),
        ),
        const SizedBox(height: 22),
        _ornament(),
        const SizedBox(height: 18),
        _sectionLabel(localize(lang, 'Tokoh Utama', 'Main Characters')),
        const SizedBox(height: 12),
        ...s.localizedCharacters(lang).map((c) => _characterItem(c)),
      ],
    );
  }

  Widget _chapterPage(
      StoryChapter ch, int index, int total, String lang) {
    return _pageShell(
      children: [
        Text(
          '${localize(lang, 'BAB', 'CHAPTER')} ${index + 1} / $total',
          style: AppFonts.cinzel(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            shadows: _textShadow,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ch.localizedHeading(lang),
          style: AppFonts.cinzel(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.25,
            shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          ch.localizedBody(lang),
          textAlign: TextAlign.justify,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.85,
            letterSpacing: 0.2,
            shadows: _textShadow,
          ),
        ),
      ],
    );
  }

  Widget _chronologyPage(String lang) {
    final steps = widget.story.localizedChronology(lang);
    return _pageShell(
      children: [
        _sectionLabel(localize(lang, 'Kronologi', 'Chronology')),
        const SizedBox(height: 16),
        for (int i = 0; i < steps.length; i++) ...[
          _chronologyItem(i + 1, steps[i]),
          if (i != steps.length - 1) const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _impactMeaningPage(String lang) {
    final s = widget.story;
    return _pageShell(
      children: [
        _sectionLabel(localize(lang, 'Dampak', 'Impact')),
        const SizedBox(height: 12),
        Text(
          s.localizedImpact(lang),
          textAlign: TextAlign.justify,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.8,
            shadows: _textShadow,
          ),
        ),
        const SizedBox(height: 26),
        _sectionLabel(localize(lang, 'Makna Mitologis', 'Mythological Meaning')),
        const SizedBox(height: 12),
        Text(
          s.localizedMeaning(lang),
          textAlign: TextAlign.justify,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.8,
            shadows: _textShadow,
          ),
        ),
        const SizedBox(height: 20),
        Center(child: _buildMarkReadButton(lang)),
      ],
    );
  }

  // ─── Small building blocks ──────────────────────────────
  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.cinzel(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              shadows: _textShadow,
            ),
          ),
        ),
      ],
    );
  }

  Widget _characterItem(String text) {
    // Split "Name, role" so the name can be emphasised.
    final parts = text.split(',');
    final name = parts.first.trim();
    final role = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      shadows: _textShadow,
                    ),
                  ),
                  if (role.isNotEmpty)
                    TextSpan(
                      text: '  ($role)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                        shadows: _textShadow,
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

  Widget _chronologyItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                text,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  height: 1.55,
                  shadows: _textShadow,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-bleed portrait hero image filling the entire title page — the
  /// same frame size on every story regardless of that story's own image
  /// dimensions, with a bottom fade so the overlaid title text stays
  /// readable against whatever the illustration looks like underneath.
  Widget _titleImage(String url, String icon) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          url,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF161210),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 52)),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.45, 1.0],
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ornament() {
    return Row(
      children: [
        Container(width: 32, height: 1, color: Colors.white.withValues(alpha: 0.6)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.auto_awesome, color: Colors.white, size: 13),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

/// Map/parchment background + darkening gradient, split out as its own
/// const widget so it never rebuilds when the reader's page or read-state
/// changes — only the visible page content should redraw on setState.
class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/peta.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF1A1410)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.72),
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
