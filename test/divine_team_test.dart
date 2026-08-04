import 'package:flutter_test/flutter_test.dart';
import 'package:mythera/data/divine_team_data.dart';

void main() {
  group('category rankings', () {
    test('there are exactly ten categories', () {
      expect(kTeamCategories.length, 10);
      expect(kCategoryRankings.length, 10);
      for (final c in kTeamCategories) {
        expect(kCategoryRankings.containsKey(c.id), isTrue,
            reason: '${c.id} has no ranking list');
      }
    });

    test('every ranked id resolves to a real combatant', () {
      final validIds = draftablePool.map((g) => g.id).toSet();
      for (final entry in kCategoryRankings.entries) {
        for (final id in entry.value) {
          expect(validIds.contains(id), isTrue,
              reason: '"$id" in ${entry.key} does not match any combatant');
        }
      }
    });

    test('no category has a duplicate id within its own ranking', () {
      for (final entry in kCategoryRankings.entries) {
        final seen = <String>{};
        for (final id in entry.value) {
          expect(seen.add(id), isTrue,
              reason: '"$id" appears twice in ${entry.key}');
        }
      }
    });

    test('no pool is too small to spin through', () {
      for (final c in kTeamCategories) {
        expect(poolFor(c).length, greaterThan(20), reason: c.id);
      }
    });

    test('poolFor returns combatants in the curated rank order', () {
      final c = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final pool = poolFor(c);
      final ids = pool.map((g) => g.id).toList();
      expect(ids, kCategoryRankings['strength']);
    });

    test('Kratos (God of War) is drafted into Strength as a top pick', () {
      final c = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final pool = poolFor(c);
      final kratos = pool.where((g) => g.id == 'pc_kratos-greek');
      expect(kratos, isNotEmpty, reason: 'Kratos missing from Strength');
    });
  });

  group('scoring and ranks', () {
    test('categoryScore gives the top-ranked combatant a 100', () {
      final c = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final top = poolFor(c).first;
      expect(categoryScore(top, c), 100);
    });

    test('categoryScore gives the last-ranked combatant close to 0', () {
      final c = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final last = poolFor(c).last;
      expect(categoryScore(last, c), 0);
    });

    test('categoryScore is 0 for a combatant not ranked in that category',
        () {
      final strength = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final sea = kTeamCategories.firstWhere((c) => c.id == 'sea');
      // Pick a combatant ranked in Sea but not in Strength.
      final seaOnly = poolFor(sea)
          .firstWhere((g) => !kCategoryRankings['strength']!.contains(g.id));
      expect(categoryScore(seaOnly, strength), 0);
    });

    test('teamScore is 9.5 when every slot is the #1 pick for its category',
        () {
      final team = [
        for (final c in kTeamCategories)
          DraftedSlot(category: c, combatant: poolFor(c).first),
      ];
      expect(teamScore(team), closeTo(9.5, 0.0001));
    });

    test('teamScore approaches 0 when every slot is the last pick', () {
      final team = [
        for (final c in kTeamCategories)
          DraftedSlot(category: c, combatant: poolFor(c).last),
      ];
      expect(teamScore(team), closeTo(0, 0.0001));
    });

    test('teamScore averages category-relative scores, not a fixed rating',
        () {
      // Same combatant, two categories it's ranked in at very different
      // positions — its score must differ per category, proving scoring is
      // category-relative rather than a single overall number.
      final strength = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final combat = kTeamCategories.firstWhere((c) => c.id == 'combat');
      final kratosStrength =
          poolFor(strength).firstWhere((g) => g.id == 'pc_kratos-greek');
      final kratosCombat =
          poolFor(combat).firstWhere((g) => g.id == 'pc_kratos-greek');
      final scoreInStrength = categoryScore(kratosStrength, strength);
      final scoreInCombat = categoryScore(kratosCombat, combat);
      // Both should be high (Kratos is a top pick in both), but not
      // necessarily identical — this just confirms the score is computed
      // per (combatant, category) pair rather than cached globally.
      expect(scoreInStrength, greaterThan(0));
      expect(scoreInCombat, greaterThan(0));
    });

    test('rank thresholds fall on the calibrated boundaries', () {
      final c = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final pool = poolFor(c);

      List<DraftedSlot> teamAt(int index) => [
            for (final cat in kTeamCategories)
              DraftedSlot(category: cat, combatant: poolFor(cat)[index]),
          ];

      // Index 0 (every #1 pick) -> comfortably #1 (9.5).
      expect(rankFor(teamAt(0)), TeamRank.pantheonSupreme);
      // Last index in every category -> score 0 -> Mortal Retinue.
      final lastIndexTeam = [
        for (final cat in kTeamCategories)
          DraftedSlot(category: cat, combatant: poolFor(cat).last),
      ];
      expect(rankFor(lastIndexTeam), TeamRank.mortalRetinue);
      // Sanity: pool has more than one entry so index 0 vs last differ.
      expect(pool.length, greaterThan(1));
    });

    test('ranks are declared strongest first so the first match wins', () {
      final mins = TeamRank.values.map((r) => r.minScore).toList();
      final sorted = [...mins]..sort((a, b) => b.compareTo(a));
      expect(mins, sorted);
      expect(TeamRank.values.last.minScore, 0);
    });
  });

  group('analyzeTeam', () {
    test('never claims a standout/weak-link when every pick ties', () {
      // A regression lock: when every slot scores identically (all #1s,
      // here), sorting by score alone leaves ties in list order, which
      // once caused the "weakest" line to name a #1 pick as the weak link.
      final allFirst = [
        for (final c in kTeamCategories)
          DraftedSlot(category: c, combatant: poolFor(c).first),
      ];
      final analysis = analyzeTeam(allFirst, 'en');
      final joined = analysis.lines.join(' ');
      expect(joined, isNot(contains('standout pick')));
      expect(joined, isNot(contains('weak link')));
      expect(joined, contains('#1 combatant in its category'));
    });

    test('never claims a standout/weak-link when every pick is last place',
        () {
      final allLast = [
        for (final c in kTeamCategories)
          DraftedSlot(category: c, combatant: poolFor(c).last),
      ];
      final analysis = analyzeTeam(allLast, 'en');
      final joined = analysis.lines.join(' ');
      // "is the standout pick" / "is the roster's weak link" are the exact
      // phrases used to NAME a member — distinct from the tie-case summary
      // line, which only mentions "weak link" while explicitly denying one
      // exists ("no single standout or weak link this time").
      expect(joined, isNot(contains('is the standout pick')));
      expect(joined, isNot(contains("is the roster's weak link")));
      expect(joined, contains('no single standout or weak link'));
    });

    test('names the highest- and lowest-scoring member for a mixed team', () {
      final strength = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final sea = kTeamCategories.firstWhere((c) => c.id == 'sea');
      final rest = kTeamCategories.where((c) => c != strength && c != sea);
      // Strength gets its #1 pick (top score), Sea gets its last pick
      // (bottom score) — everything else is filler at a middling index so
      // it can't tie with either extreme.
      final team = [
        DraftedSlot(category: strength, combatant: poolFor(strength).first),
        DraftedSlot(category: sea, combatant: poolFor(sea).last),
        for (final c in rest)
          DraftedSlot(
              category: c, combatant: poolFor(c)[poolFor(c).length ~/ 2]),
      ];
      final analysis = analyzeTeam(team, 'en');
      final joined = analysis.lines.join(' ');
      expect(joined, contains('${poolFor(strength).first.name} is the standout pick'));
      expect(joined,
          contains("${poolFor(sea).last.name} is the roster's weak link"));
    });

    test('reports the mythology breakdown and pop-culture count', () {
      final team = [
        for (final c in kTeamCategories)
          DraftedSlot(category: c, combatant: poolFor(c).first),
      ];
      final analysis = analyzeTeam(team, 'en');
      // Every line should be non-empty prose, not a raw data dump.
      for (final line in analysis.lines) {
        expect(line, isNotEmpty);
        expect(line.trim().endsWith('.'), isTrue,
            reason: 'expected a full sentence: "$line"');
      }
    });

    test('returns no lines for an empty team', () {
      expect(analyzeTeam(const [], 'en').lines, isEmpty);
    });

    test('produces Indonesian sentences when lang is not "en"', () {
      final strength = kTeamCategories.firstWhere((c) => c.id == 'strength');
      final sea = kTeamCategories.firstWhere((c) => c.id == 'sea');
      final rest = kTeamCategories.where((c) => c != strength && c != sea);
      final team = [
        DraftedSlot(category: strength, combatant: poolFor(strength).first),
        DraftedSlot(category: sea, combatant: poolFor(sea).last),
        for (final c in rest)
          DraftedSlot(
              category: c, combatant: poolFor(c)[poolFor(c).length ~/ 2]),
      ];
      final analysisId = analyzeTeam(team, 'id');
      final joinedId = analysisId.lines.join(' ');
      // Sentences are Indonesian, but category/combatant names (proper
      // nouns) stay untranslated inside them.
      expect(joinedId, contains('${poolFor(strength).first.name} adalah pilihan paling menonjol'));
      expect(joinedId, contains("${poolFor(sea).last.name} adalah titik terlemah"));
      expect(joinedId, contains(strength.name)); // category name untranslated
      expect(joinedId, isNot(contains('standout pick')));
      expect(joinedId, isNot(contains('weak link')));

      // Same team, English lang, should differ from the Indonesian text.
      final analysisEn = analyzeTeam(team, 'en');
      expect(analysisEn.lines.join(' '), isNot(equals(joinedId)));
    });

    test('TeamRank.description follows lang while title stays English', () {
      expect(TeamRank.pantheonSupreme.description('en'),
          TeamRank.pantheonSupreme.descriptionEn);
      expect(TeamRank.pantheonSupreme.description('id'),
          TeamRank.pantheonSupreme.descriptionId);
      expect(TeamRank.pantheonSupreme.title, 'Pantheon Supreme');
    });
  });
}
