import 'package:flutter/material.dart';
import '../data/divine_team_data.dart';
import '../models/combatant.dart';
import 'god_card.dart';

const _goldBright = Color(0xFFE0A82E);

/// One slot in the Divine Team grid.
///
/// Static — no spin animation. While cycling (driven by the parent's Random
/// button), it simply swaps its portrait through [showing]; once locked it
/// shows [lockedGod] and stops reacting to [showing] updates. Tap locks in
/// whichever god is currently displayed — one-way, so a locked slot no
/// longer responds to taps. [showing]/[lockedGod] can be a real god or a
/// pop-culture character; the latter gets a small "POP" badge.
class TeamSlotCard extends StatelessWidget {
  final TeamCategory category;
  final Combatant? showing;
  final Combatant? lockedGod;
  final bool isCycling;
  final VoidCallback onTap;

  const TeamSlotCard({
    super.key,
    required this.category,
    required this.showing,
    required this.lockedGod,
    required this.isCycling,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lockedGod != null;
    final god = lockedGod ?? showing;
    final accent = god == null
        ? const Color(0xFF2A2A2A)
        : GodCard.mythologyColor(god.mythology);

    // The portrait sizes itself off the available width (LayoutBuilder)
    // rather than a fixed AspectRatio, and the label sits below it in the
    // Column. That keeps this widget's total height exactly what it needs —
    // no dependency on the parent grid guessing a childAspectRatio, so it
    // can never overflow its cell.
    return GestureDetector(
      // Locked slots are final for the rest of the draft — no tap handler
      // once locked, so there's no way to undo a pick.
      onTap: (god == null || locked) ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: constraints.maxWidth / 0.82,
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (god != null)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 90),
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                            fit: StackFit.expand,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          ),
                          child: Image.asset(
                            god.imageUrl,
                            key: ValueKey(god.id),
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFF1A1A1A)),
                          ),
                        )
                      else
                        Center(
                          child: Icon(category.icon,
                              size: 26, color: const Color(0xFF3A3A3A)),
                        ),
                      if (god != null)
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.55, 1.0],
                              colors: [Colors.transparent, Color(0xE6000000)],
                            ),
                          ),
                        ),
                      if (locked)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.lock_rounded,
                                size: 11, color: accent),
                          ),
                        ),
                      if (god != null && god.isPopCulture)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
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
                        ),
                      if (god != null)
                        Positioned(
                          left: 6,
                          right: 6,
                          bottom: 6,
                          child: Text(
                            god.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: locked
                                  ? Colors.white
                                  : const Color(0xFFCCCCCC),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            category.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: locked ? accent : const Color(0xFF7A7A7A),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
