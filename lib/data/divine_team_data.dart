import 'package:flutter/material.dart';
import '../models/combatant.dart';
import 'gods_data.dart';

/// Data and scoring for the Divine Team builder: ten themed slots, each
/// spinning through the gods (and pop-culture characters) whose powers match
/// that theme.
///
/// Unlike a keyword-matching system, each category's roster and internal
/// ranking are curated by hand (see [kCategoryRankings]) — who belongs in
/// "Strength" and how they stack up against each other is a judgment call
/// about the character's actual portrayed power, not something a tag-based
/// filter can derive. A combatant's score is therefore category-relative:
/// Kratos might rank #2 in Strength but much lower in Intellect, and his
/// score reflects the category he was drafted into, not a single fixed
/// overall rating.
///
/// This feature is intentionally English-only (no [localize] calls) and
/// emoji-free, so it reads [Combatant.titleEn] / [Combatant.powersEn]
/// directly and never renders [God.symbol].

/// One draft slot: a theme, its icon, and the combatants who can fill it.
class TeamCategory {
  /// Stable key used for state maps and widget keys, and the lookup key
  /// into [kCategoryRankings].
  final String id;
  final String name;
  final IconData icon;

  const TeamCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// The ten slots. Names are kept to one short word so they fit under a
/// small card image.
const List<TeamCategory> kTeamCategories = [
  TeamCategory(id: 'strength', name: 'Strength', icon: Icons.fitness_center_rounded),
  TeamCategory(id: 'combat', name: 'Combat Skill', icon: Icons.shield_rounded),
  TeamCategory(id: 'intellect', name: 'Intellect', icon: Icons.menu_book_rounded),
  TeamCategory(id: 'magic', name: 'Magic Power', icon: Icons.auto_fix_high_rounded),
  TeamCategory(id: 'monster', name: 'Monster', icon: Icons.pest_control_rounded),
  TeamCategory(id: 'regeneration', name: 'Regeneration', icon: Icons.autorenew_rounded),
  TeamCategory(id: 'protection', name: 'Protection', icon: Icons.security_rounded),
  TeamCategory(id: 'speed', name: 'Speed', icon: Icons.bolt_rounded),
  TeamCategory(id: 'sea', name: 'Sea', icon: Icons.waves_rounded),
  TeamCategory(id: 'sun', name: 'Sun', icon: Icons.wb_sunny_rounded),
];

/// Hand-curated power ranking per category, strongest first (index 0 = the
/// single strongest combatant in that category). Values are [Combatant.id]:
/// a real god's plain numeric id (e.g. '1' for Zeus) or a pop-culture
/// character's `pc_`-prefixed id (e.g. 'pc_kratos-greek').
///
/// This is the sole source of truth for both category membership (a
/// combatant not listed here for a category simply isn't draftable into it)
/// and in-category strength ordering — there is no keyword matching or tier
/// fallback. Rankings were compiled from each figure's canon
/// stories/games/films rather than the app's own tier badges, since a
/// character's standing in, say, Speed has little to do with their overall
/// God Battle tier.
const Map<String, List<String>> kCategoryRankings = {
  'strength': [
    '215', // Pangu
    'pc_asura-wrath', // Asura (Asura's Wrath)
    '177', // Typhon
    '147', // Varaha
    '148', // Narasimha
    '29', // Vishnu
    '150', // Parashurama
    '34', // Krishna
    '163', // Hanuman
    'pc_sun-wukong-blackmyth', // Sun Wukong (Black Myth)
    'pc_monkey-king-general', // Monkey King
    '239', // Sun Wukong
    'pc_erlang-shen-blackmyth', // Erlang Shen (Black Myth)
    '164', // Ravana
    'pc_ravana-general', // Ravana (pop)
    '74', // Fenrir
    '75', // Jörmungandr
    '68', // Ymir
    '69', // Surtr
    '314', // Yamata no Orochi
    'pc_kratos-nordic', // Kratos Era Nordik
    'pc_kratos-greek', // Kratos (God of War)
    '20', // Thor
    '52', // Atlas
    '1', // Zeus
    '4', // Poseidon
    '105', // Heracles
    '32', // Kali
    '31', // Durga
    'pc_ares-godofwar', // Ares (God of War)
    '7', // Ares
    '19', // Odin
    'pc_fenrir-gow', // Fenrir (GoW)
    'pc_thor-marvel', // Thor (MCU)
    '211', // Guan Yu
    '55', // Menoetius
    '271', // Takemikazuchi
    '16', // Seth
    '127', // Sekhmet
    '12', // Ra
    '71', // Hrungnir
    '61', // Vidar
    'pc_baldur-gow', // Baldur (GoW)
    'pc_hela-mcu', // Hela (Thor Ragnarok)
    '168', // Garuda
    '155', // Indra
    '170', // Asura
    '167', // Naga
    '169', // Nandi
    '65', // Vili & Vé
    '296', // Takeminakata
    '212', // Zhao Gongming
    '214', // Zhong Kui
    'pc_nezha-film', // Nezha (film)
    '204', // Erlang Shen
    'pc_makara-smite', // Makara
    '101', // Cerberus
    '113', // Hydra
    '112', // Chimera
    '116', // Cyclops
    '111', // Minotaur
    '78', // Nidhogg
    '195', // Utgard-Loki
    '70', // Thrym
    '309', // Oni
    'pc_susanoo-naruto', // Susanoo (Naruto)
    'pc_apophis-stargate', // Apophis (Stargate)
    'pc_set-godsofegypt', // Set (Gods of Egypt)
    'pc_horus-godsofegypt', // Horus (Gods of Egypt)
    'pc_anubis-acorigins', // Anubis (AC Origins)
    'pc_khonshu-moonknight', // Khonshu (Moon Knight)
    'pc_troll-gow', // Troll
    'pc_ogre-gow', // Ogre
    '130', // Sobek
    '190', // Mnevis
    '203', // Queen Mother of the West
    '229', // Hou Yi
    '236', // Ox-Head
    '241', // Zhu Bajie
    '242', // Sha Wujing
    '247', // Long (Dragon)
    '253', // Peng
    '255', // Bixie
    '256', // White Tiger
    '303', // Yamato Takeru
    '304', // Momotaro
    '306', // Kintaro
    '307', // Benkei
    '313', // Kappa
    '315', // Raiju
    '79', // Draugr
    '77', // Sleipnir
    '103', // Triton
    '180', // Thetis
    '109', // Odysseus
    'pc_satyr-gow', // Satyr
    'pc_pegasus-gow', // Pegasus
    'pc_centaur-gow', // Centaur
    'pc_griffin-gow', // Griffin
    'pc_nemean-lion-gow', // Nemean Lion
  ],
  'combat': [
    'pc_kratos-nordic', // Kratos Era Nordik
    'pc_kratos-greek', // Kratos
    '239', // Sun Wukong
    '211', // Guan Yu
    '308', // Minamoto no Yoshitsune
    '108', // Achilles
    '2', // Athena
    '23', // Tyr
    '214', // Zhong Kui
    '19', // Odin
    '201', // Bhishma
    '293', // Hachiman
    '294', // Bishamonten
    '163', // Hanuman
    '31', // Durga
    '154', // Kartikeya
    '7', // Ares
    'pc_ares-godofwar', // Ares (pop)
    '106', // Perseus
    '107', // Theseus
    '204', // Erlang Shen
    'pc_erlang-shen-blackmyth', // Erlang Shen (Black Myth)
    '243', // Mulan
    '245', // Lu Dongbin
    '295', // Marishiten
    '271', // Takemikazuchi
    '310', // Tengu
    '272', // Futsunushi
    'pc_zagreus', // Zagreus
    'pc_kali-smite', // Kali (SMITE)
    'pc_hela-mcu', // Hela
    '105', // Heracles
    '148', // Narasimha
    '34', // Krishna
    '212', // Zhao Gongming
    '242', // Sha Wujing
    '256', // White Tiger
    '22', // Freya
    '80', // Valkyrie
    '296', // Takeminakata
    '303', // Yamato Takeru
    'pc_atreus-loki-gow', // Atreus/Loki Muda
    'pc_dark-elf-gow', // Dark Elf
    '155', // Indra
    '127', // Sekhmet
    '185', // Wepwawet
    '196', // Vishwakarma
    '69', // Surtr
    '1', // Zeus
    '224', // Lei Gong
    '309', // Oni
    'pc_percy-jackson', // Percy Jackson
    'pc_apophis-stargate', // Apophis
    '109', // Odysseus
    '10', // Hephaestus
    'pc_satyr-gow', // Satyr
    'pc_centaur-gow', // Centaur
    'pc_nemean-lion-gow', // Nemean Lion
    '268', // Susanoo
    '170', // Asura
    '164', // Ravana
    '15', // Horus
    '20', // Thor
  ],
  'intellect': [
    '17', // Thoth
    '36', // Saraswati
    '30', // Brahma
    '152', // Buddha
    '63', // Mimir
    'pc_mimir-gow', // Mimir (GoW)
    '19', // Odin
    '2', // Athena
    '196', // Vishwakarma
    '135', // Seshat
    '14', // Isis
    '109', // Odysseus
    '1', // Zeus
    '26', // Frigg
    '216', // Nu Wa
    '217', // Fuxi
    '201', // Bhishma
    '34', // Krishna
    '45', // Coeus
    '49', // Phoebe
    '51', // Mnemosyne
    '181', // Proteus
    '104', // Nereus
    '194', // Huginn & Muninn
    '59', // Bragi
    '192', // Forseti
    '149', // Vamana
    '164', // Ravana
    'pc_ravana-general', // Ravana (pop)
    '208', // Wen Chang
    '207', // Tai Bai Jin Xing
    '240', // Tang Sanzang
    '232', // Judge Cui
    '245', // Lu Dongbin
    '244', // Eight Immortals
    '246', // Jigong
    '300', // Fukurokuju
    '299', // Benzaiten
    '301', // Jurojin
    '145', // Matsya
    '167', // Naga
    '169', // Nandi
    '249', // Qilin
    '258', // Black Tortoise
    '251', // Huli Jing
    '311', // Kitsune
    '243', // Mulan
    '222', // Dragon King of the West
    'pc_atreus-loki-gow', // Atreus/Loki Muda
    'pc_kratos-nordic', // Kratos Era Nordik
    '21', // Loki
    '24', // Baldur
  ],
  'magic': [
    '172', // Hecate
    '14', // Isis
    '17', // Thoth
    '195', // Utgard-Loki
    '22', // Freya
    '239', // Sun Wukong
    'pc_sun-wukong-blackmyth', // Sun Wukong (Black Myth)
    'pc_monkey-king-general', // Monkey King
    '19', // Odin
    '21', // Loki
    'pc_loki-marvel', // Loki (MCU)
    'pc_amaterasu-okami', // Amaterasu (Okami)
    '31', // Durga
    '204', // Erlang Shen
    '34', // Krishna
    '149', // Vamana
    '164', // Ravana
    '212', // Zhao Gongming
    '227', // Feng Bo
    '244', // Eight Immortals
    '241', // Zhu Bajie
    '251', // Huli Jing
    '311', // Kitsune
    '125', // Nephthys
    '187', // Serqet
    '181', // Proteus
    '174', // Morpheus
    '115', // Sirens
    '72', // Angrboda
    '79', // Draugr
    '70', // Thrym
    '273', // Ōkuninushi
    '318', // Jorōgumo
    '312', // Tanuki
    '310', // Tengu
    '309', // Oni
    '313', // Kappa
    '206', // Li Jing
    'pc_rakshasa-ff', // Rakshasa
    'pc_lamia-fgo', // Lamia
    '110', // Medusa
    '24', // Baldur
    'pc_dark-elf-gow', // Dark Elf
    'pc_atreus-loki-gow', // Atreus/Loki Muda
    'pc_nightmare-gow', // Nightmare
    'pc_revenant-gow', // Revenant
    '7', // Ares
    'pc_apophis-stargate', // Apophis
  ],
  'monster': [
    '177', // Typhon
    '75', // Jörmungandr
    '138', // Apep
    '74', // Fenrir
    '69', // Surtr
    '314', // Yamata no Orochi
    '178', // Echidna
    '319', // Gashadokuro
    '129', // Ammit
    'pc_basilisk-hp', // Basilisk
    '113', // Hydra
    '112', // Chimera
    '78', // Nidhogg
    '68', // Ymir
    '110', // Medusa
    'pc_medusa-percyjackson', // Medusa (pop)
    '320', // Nue
    '179', // Scylla & Charybdis
    '114', // Sphinx
    '101', // Cerberus
    'pc_rakshasa-ff', // Rakshasa
    '170', // Asura
    '167', // Naga
    '111', // Minotaur
    '79', // Draugr
    '309', // Oni
    '250', // Jiangshi
    'pc_tsuchigumo-nioh', // Tsuchigumo
    'pc_lamia-fgo', // Lamia
    '287', // Kuraokami
    '316', // Baku
    '281', // Ryujin
    '305', // Urashima Taro
  ],
  'regeneration': [
    '13', // Osiris
    '186', // Bennu
    'pc_zagreus', // Zagreus
    '239', // Sun Wukong
    'pc_sun-wukong-blackmyth', // Sun Wukong (Black Myth)
    'pc_monkey-king-general', // Monkey King
    '113', // Hydra
    '53', // Prometheus
    '29', // Vishnu
    '97', // Persephone
    '60', // Idun
    '182', // Khepri
    '124', // Nut
    '184', // Sokar
    '230', // Chang'e
    '219', // Taiyi
    '205', // Nezha
    'pc_nezha-film', // Nezha (pop)
    '146', // Kurma
    '147', // Varaha
    '203', // Queen Mother of the West
    '231', // Yanluo Wang
    '233', // Meng Po
    '244', // Eight Immortals
    '245', // Lu Dongbin
    'pc_raiden-mk', // Raiden (Mortal Kombat)
    '79', // Draugr
    'pc_thor-marvel', // Thor (MCU)
    'pc_hela-mcu', // Hela
    '170', // Asura
  ],
  'protection': [
    '29', // Vishnu
    '31', // Durga
    '25', // Heimdall
    '294', // Bishamonten
    '11', // Anubis
    'pc_anubis-acorigins', // Anubis (AC Origins)
    '18', // Bastet
    '188', // Wadjet
    '189', // Nekhbet
    '20', // Thor
    '1', // Zeus
    '14', // Isis
    '124', // Nut
    '125', // Nephthys
    '132', // Taweret
    '130', // Sobek
    '133', // Bes
    '187', // Serqet
    '134', // Min
    '185', // Wepwawet
    '15', // Horus
    '145', // Matsya
    '216', // Nu Wa
    '6', // Artemis
    '46', // Rhea
    '101', // Cerberus
    'pc_cerberus-hades', // Cerberus (Hades)
    '162', // Kubera
    '167', // Naga
    '168', // Garuda
    '148', // Narasimha
    '316', // Baku
    '214', // Zhong Kui
    '210', // Menshen
    '254', // Pixiu
    '255', // Bixie
    '213', // Tu Di Gong
    '236', // Ox-Head
    '237', // Horse-Face
    '221', // Dragon King of the South
    '223', // Dragon King of the North
    'pc_raiden-mk', // Raiden
    '206', // Li Jing
    '272', // Futsunushi
    '293', // Hachiman
    '26', // Frigg
    '307', // Benkei
    '268', // Susanoo
    'pc_dreki-gowr', // Dreki
    'pc_satyr-gow', // Satyr
    '179', // Scylla & Charybdis
    '114', // Sphinx
    '180', // Thetis
    '110', // Medusa
  ],
  'speed': [
    '9', // Hermes
    '168', // Garuda
    '77', // Sleipnir
    'pc_monkey-king-general', // Monkey King
    '157', // Vayu
    '280', // Fujin
    '286', // Shinatsuhiko
    '227', // Feng Bo
    '315', // Raiju
    '253', // Peng
    '205', // Nezha
    '21', // Loki
    '310', // Tengu
    '194', // Huginn & Muninn
    '193', // Ratatoskr
    '108', // Achilles
    '126', // Khonsu
    '121', // Shu
    '154', // Kartikeya
    '198', // Ashwini Kumaras
    '296', // Takeminakata
    '295', // Marishiten
    '80', // Valkyrie
    '67', // Njord
    '58', // Amun
    '207', // Tai Bai Jin Xing
    '237', // Horse-Face
    'pc_zagreus', // Zagreus
    'pc_harpy-gow', // Harpy
    'pc_griffin-gow', // Griffin
    'pc_pegasus-gow', // Pegasus
    'pc_stymphalian-birds-gow', // Stymphalian Birds
    'pc_dreki-gowr', // Dreki
    'pc_wulver-gowr', // Wulver
    'pc_atreus-loki-gow', // Atreus/Loki Muda
    'pc_nightmare-gow', // Nightmare
    'pc_revenant-gow', // Revenant
    'pc_satyr-gow', // Satyr
    '268', // Susanoo
    'pc_centaur-gow', // Centaur
  ],
  'sea': [
    '4', // Poseidon
    '158', // Varuna
    '41', // Oceanus
    '281', // Ryujin
    '220', // Dragon King of the East
    '221', // Dragon King of the South
    '222', // Dragon King of the West
    '223', // Dragon King of the North
    '146', // Kurma
    '75', // Jörmungandr
    '73', // Aegir & Rán
    '67', // Njord
    '47', // Tethys
    '102', // Amphitrite
    '287', // Kuraokami
    '282', // Watatsumi
    '268', // Susanoo
    '131', // Hapi
    '122', // Tefnut
    '103', // Triton
    '104', // Nereus
    '181', // Proteus
    '180', // Thetis
    '130', // Sobek
    '283', // Suijin
    '247', // Long (Dragon)
    '226', // Yu Shi
    '228', // He Bo
    '242', // Sha Wujing
    '279', // Raijin
    '204', // Erlang Shen
    '258', // Black Tortoise
    '296', // Takeminakata
    '299', // Benzaiten
    '313', // Kappa
    'pc_makara-smite', // Makara
    'pc_percy-jackson', // Percy Jackson
  ],
  'sun': [
    '12', // Ra
    '266', // Amaterasu
    'pc_amaterasu-okami', // Amaterasu (Okami)
    '159', // Surya
    '5', // Apollo
    '183', // Aten
    '43', // Hyperion
    '48', // Theia
    '120', // Atum
    '156', // Agni
    '127', // Sekhmet
    '182', // Khepri
    '1', // Zeus
    '295', // Marishiten
    '198', // Ashwini Kumaras
    '191', // Nefertem
    '186', // Bennu
    '188', // Wadjet
    '121', // Shu
    '190', // Mnevis
    '49', // Phoebe
    '53', // Prometheus
    '259', // Vermilion Bird
    '224', // Lei Gong
    '225', // Dian Mu
    '205', // Nezha
    'pc_nezha-film', // Nezha (film)
    '221', // Dragon King of the South
    '24', // Baldur
    '25', // Heimdall
    '69', // Surtr
    '58', // Amun
    'pc_dreki-gowr', // Dreki
    'pc_raiden-mk', // Raiden
    '279', // Raijin
    '315', // Raiju
    '270', // Ame-no-Uzume
    'pc_thor-marvel', // Thor (MCU)
    'pc_dark-elf-gow', // Dark Elf
    '112', // Chimera
    '177', // Typhon
    '10', // Hephaestus
    '267', // Tsukuyomi
    '126', // Khonsu
    'pc_khonshu-moonknight', // Khonshu
    '160', // Chandra
    '6', // Artemis
    '230', // Chang'e
  ],
};

List<Combatant>? _draftableCache;

/// Every combatant referenced anywhere in [kCategoryRankings]: real gods
/// plus every pop-culture character with a curated combat profile.
List<Combatant> get draftablePool {
  if (_draftableCache != null) return _draftableCache!;
  final byId = <String, Combatant>{
    for (final g in godsData) g.id: g,
    for (final c in popCultureCombatants) c.id: c,
  };
  final ids = kCategoryRankings.values.expand((l) => l).toSet();
  return _draftableCache = [for (final id in ids) byId[id]!];
}

final Map<String, List<Combatant>> _poolCache = {};

/// The combatants that can fill [c], strongest first — directly the curated
/// order from [kCategoryRankings].
List<Combatant> poolFor(TeamCategory c) {
  return _poolCache[c.id] ??= () {
    final byId = <String, Combatant>{
      for (final g in godsData) g.id: g,
      for (final pc in popCultureCombatants) pc.id: pc,
    };
    final ids = kCategoryRankings[c.id] ?? const [];
    return [for (final id in ids) byId[id]!];
  }();
}

/// A combatant's strength score within [c], derived purely from their
/// position in [kCategoryRankings]: #1 (index 0) scores 100, the last-placed
/// combatant approaches 0, linearly in between. Returns 0 if [g] isn't
/// ranked in [c] at all (shouldn't happen for anything drafted through
/// [poolFor]).
double categoryScore(Combatant g, TeamCategory c) {
  final ranking = kCategoryRankings[c.id];
  if (ranking == null || ranking.isEmpty) return 0;
  final index = ranking.indexOf(g.id);
  if (index == -1) return 0;
  if (ranking.length == 1) return 100;
  return 100 * (1 - index / (ranking.length - 1));
}

/// One drafted slot: the category it fills and the combatant locked into it
/// — pairing the two is what lets [teamScore] read each member's
/// category-relative rank rather than a single fixed rating.
class DraftedSlot {
  final TeamCategory category;
  final Combatant combatant;

  const DraftedSlot({required this.category, required this.combatant});
}

/// Mean score of the drafted team, on a 0-9.5 scale to match the
/// thresholds in [TeamRank] (a 0-100 [categoryScore] average is divided by
/// (100 / 9.5) so a team of #1-ranked picks in every category — the
/// strongest possible draft — lands at exactly 9.5).
double teamScore(List<DraftedSlot> team) {
  if (team.isEmpty) return 0;
  var sum = 0.0;
  for (final slot in team) {
    sum += categoryScore(slot.combatant, slot.category);
  }
  return (sum / team.length) * (9.5 / 100);
}

/// Final standing awarded for a completed team.
///
/// Thresholds are calibrated against 200,000 simulated random teams (mean
/// 6.66, sd 0.59, best observed 8.82; a perfectly played team reaches 9.50).
/// The shares below are how often each rank falls out of random play, so
/// [pantheonSupreme] stays genuinely rare without being unreachable.
///
/// [title] (the rank name, e.g. "Pantheon Supreme") stays English-only by
/// design, like the category names — [descriptionId]/[descriptionEn] are
/// the parts that follow the app's language setting.
enum TeamRank {
  /// ~2% of random teams.
  pantheonSupreme(
    label: '#1',
    title: 'Pantheon Supreme',
    descriptionId: 'Kumpulan dewa yang bisa menghancurkan dunia.',
    descriptionEn: 'A gathering that could unmake the world.',
    minScore: 7.80,
    color: Color(0xFFD4AF37),
  ),

  /// ~17% of random teams.
  ascendantHost(
    label: '#2',
    title: 'Ascendant Host',
    descriptionId: 'Hanya sedikit pantheon yang sanggup melawan pasukan ini.',
    descriptionEn: 'Few pantheons could stand against this host.',
    minScore: 7.20,
    color: Color(0xFF7E57C2),
  ),

  /// ~43% of random teams, the most common outcome.
  divineVanguard(
    label: '#3',
    title: 'Divine Vanguard',
    descriptionId: 'Pasukan tangguh, siap menghadapi cobaan apa pun.',
    descriptionEn: 'A formidable company, ready for any trial.',
    minScore: 6.50,
    color: Color(0xFF4FA3D1),
  ),

  /// ~33% of random teams.
  sacredCompany(
    label: '#4',
    title: 'Sacred Company',
    descriptionId: 'Tangguh dan stabil, tapi ujian besar masih menanti.',
    descriptionEn: 'Steady hands, but the great trials lie ahead.',
    minScore: 5.70,
    color: Color(0xFF6FA86F),
  ),

  /// ~5% of random teams.
  mortalRetinue(
    label: '#5',
    title: 'Mortal Retinue',
    descriptionId: 'Awal yang sederhana. Legenda ini baru akan ditulis.',
    descriptionEn: 'Humble beginnings. The legend is yet unwritten.',
    minScore: 0,
    color: Color(0xFF9E9E9E),
  );

  final String label;
  final String title;
  final String descriptionId;
  final String descriptionEn;
  final double minScore;
  final Color color;

  const TeamRank({
    required this.label,
    required this.title,
    required this.descriptionId,
    required this.descriptionEn,
    required this.minScore,
    required this.color,
  });

  /// [lang] follows the app's `localize(lang, id, en)` convention: any value
  /// other than `'en'` (typically `'id'`) yields the Indonesian text.
  String description(String lang) => lang == 'en' ? descriptionEn : descriptionId;
}

/// The rank a completed [team] earns. Values are declared strongest-first,
/// so the first satisfied threshold wins.
TeamRank rankFor(List<DraftedSlot> team) {
  final score = teamScore(team);
  for (final rank in TeamRank.values) {
    if (score >= rank.minScore) return rank;
  }
  return TeamRank.mortalRetinue;
}

/// A template-generated (not AI-written) read on what a completed draft
/// says about itself: which mythology it leans on, how many picks are
/// pop-culture takes versus the original myth, and which category landed
/// the strongest and weakest pick.
class TeamAnalysis {
  /// One line per insight, in display order.
  final List<String> lines;

  const TeamAnalysis(this.lines);
}

/// Builds [TeamAnalysis] for a completed [team] (assumed to have one slot
/// per [kTeamCategories]). Every line is assembled from the team's own
/// data — mythology counts, pop-culture counts, and each slot's
/// [categoryScore] — rather than any freeform generation.
///
/// [lang] follows the app's `localize(lang, id, en)` convention: any value
/// other than `'en'` (typically `'id'`) produces Indonesian sentences.
/// Category names (e.g. "Strength") and combatant names stay as-is in both
/// languages by design — only the surrounding sentence changes.
TeamAnalysis analyzeTeam(List<DraftedSlot> team, String lang) {
  if (team.isEmpty) return const TeamAnalysis([]);
  final isEn = lang == 'en';
  final lines = <String>[];

  // Mythology makeup: which pantheon shows up most, and whether the team
  // draws from a single mythology or spans several.
  final mythCounts = <String, int>{};
  for (final slot in team) {
    final m = slot.combatant.mythology;
    mythCounts[m] = (mythCounts[m] ?? 0) + 1;
  }
  final sortedMyths = mythCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topMyth = sortedMyths.first;
  if (topMyth.value == team.length) {
    lines.add(isEn
        ? 'An all-${topMyth.key} pantheon — every pick drawn from the '
            'same mythology.'
        : 'Pantheon ${topMyth.key} sepenuhnya — semua pilihan berasal dari '
            'mitologi yang sama.');
  } else if (sortedMyths.length <= 2) {
    final other = sortedMyths.length == 2
        ? sortedMyths[1].key
        : (isEn ? 'no other mythology' : 'tidak ada mitologi lain');
    lines.add(isEn
        ? '${topMyth.key} leads the roster with ${topMyth.value} of ${team.length} '
            'picks, backed by $other.'
        : '${topMyth.key} mendominasi tim dengan ${topMyth.value} dari ${team.length} '
            'pilihan, didukung oleh $other.');
  } else {
    lines.add(isEn
        ? '${topMyth.key} leads with ${topMyth.value} picks, but this '
            'pantheon spans ${sortedMyths.length} mythologies in all.'
        : '${topMyth.key} unggul dengan ${topMyth.value} pilihan, tapi tim ini '
            'sebenarnya mencakup ${sortedMyths.length} mitologi berbeda.');
  }

  // Pop-culture vs. original-myth split.
  final popCount = team.where((s) => s.combatant.isPopCulture).length;
  if (popCount == 0) {
    lines.add(isEn
        ? 'Every member is drawn straight from the original myths — '
            'no pop-culture reinterpretations here.'
        : 'Semua anggota berasal langsung dari mitologi asli — tidak ada '
            'reinterpretasi pop culture di sini.');
  } else if (popCount == team.length) {
    lines.add(isEn
        ? 'Every single pick is a pop-culture reinterpretation, not '
            'one figure straight from the original myths.'
        : 'Semua pilihan adalah reinterpretasi pop culture, tidak satu pun '
            'sosok langsung dari mitologi aslinya.');
  } else {
    lines.add(isEn
        ? '$popCount of ${team.length} picks are pop-culture takes on the myths '
            '(games, films, comics) rather than the original figures.'
        : '$popCount dari ${team.length} pilihan adalah versi pop culture dari '
            'mitologi (game, film, komik), bukan sosok aslinya.');
  }

  // Strongest and weakest category placements, by this team's own
  // categoryScore — i.e. how high each pick ranked within its category.
  final byScore = [...team]..sort((a, b) =>
      categoryScore(b.combatant, b.category)
          .compareTo(categoryScore(a.combatant, a.category)));
  final best = byScore.first;
  final worst = byScore.last;
  final bestScore = categoryScore(best.combatant, best.category);
  final worstScore = categoryScore(worst.combatant, worst.category);
  final bestIdx = kCategoryRankings[best.category.id]!.indexOf(best.combatant.id);
  if (bestScore - worstScore < 0.01) {
    // Every pick landed the same spot in its category (all #1s, all
    // last-place, or any other tie) — "standout"/"weak link" would be
    // meaningless, so state the shared placement instead.
    if (bestScore >= 99.99) {
      lines.add(isEn
          ? 'Every pick is the #1 combatant in its category — as strong a '
              'draft as this game allows.'
          : 'Semua pilihan adalah kombatan #1 di kategorinya masing-masing — '
              'draft sekuat ini adalah yang terbaik yang bisa didapat.');
    } else {
      lines.add(isEn
          ? 'Every pick landed the same relative spot in its category — no '
              'single standout or weak link this time.'
          : 'Semua pilihan berada di posisi relatif yang sama di kategorinya '
              '— tidak ada yang menonjol atau lemah kali ini.');
    }
  } else {
    lines.add(isEn
        ? '${best.combatant.name} is the standout pick — ranked #${bestIdx + 1} '
            'in ${best.category.name}.'
        : '${best.combatant.name} adalah pilihan paling menonjol — peringkat '
            '#${bestIdx + 1} di ${best.category.name}.');
    final worstIdx =
        kCategoryRankings[worst.category.id]!.indexOf(worst.combatant.id);
    lines.add(isEn
        ? '${worst.combatant.name} is the roster\'s weak link, ranked #${worstIdx + 1} '
            'in ${worst.category.name}.'
        : '${worst.combatant.name} adalah titik terlemah tim ini, peringkat '
            '#${worstIdx + 1} di ${worst.category.name}.');
  }

  return TeamAnalysis(lines);
}
