import 'package:flutter/material.dart';

/// Power-tier classification for gods and beings across all six mythologies,
/// shown as a badge on the god detail screen and browsable via the Codex
/// "Tier" feature. Also feeds [BattleEngine]'s numeric strength score
/// directly (see `_tierOf`/`_godTierBase` there), so a god's visible tier
/// badge is a genuine predictor of their God Battle performance, not just
/// decorative, and individually hand-tuned gods still keep their finer-grained
/// override on top of the badge.
enum GodTier {
  anomaly(
    label: 'Anomaly',
    color: Color(0xFFD9663A),
    description:
        "Not a rank within mythology at all, but a fictional reinterpretation "
        "from a game, film, or novel that borrows a god's name and imagery "
        "but rewrites their power, parentage, or fate outright. Judging "
        "them on the same scale as authentic myth would be comparing two "
        "different stories, so they sit outside it entirely.",
    descriptionId:
        'Bukan peringkat dalam mitologi sama sekali, melainkan reinterpretasi '
        'fiksi dari game, film, atau novel yang meminjam nama dan citra '
        'seorang dewa namun menulis ulang kekuatan, asal-usul, atau '
        'takdirnya sepenuhnya. Menilainya dengan skala yang sama seperti '
        'mitologi asli sama saja membandingkan dua kisah yang berbeda, '
        'jadi mereka berdiri di luar sistem ini sepenuhnya.',
  ),
  worldEnder(
    label: 'World-Ender',
    color: Color(0xFFD4AF37),
    description:
        "The rarest and most terrifying rank in mythology, home to primordial "
        "forces and supreme gods whose power can create, reshape, or "
        "utterly end the world. Their conflicts don't just decide battles; "
        "they decide the fate of existence itself.",
    descriptionId:
        'Peringkat paling langka dan menakutkan dalam mitologi, tempat kekuatan '
        'purba dan dewa tertinggi yang mampu menciptakan, membentuk ulang, '
        'atau mengakhiri dunia sepenuhnya. Pertarungan mereka bukan sekadar '
        'menentukan kemenangan, melainkan menentukan nasib keberadaan itu '
        'sendiri.',
  ),
  legendary(
    label: 'Legendary',
    color: Color(0xFF7E57C2),
    description:
        'Gods and beings of extraordinary might, revered across the '
        'pantheon for feats that border on the impossible. They rule '
        'domains, command armies of lesser spirits, and are strong enough '
        'to stand toe-to-toe with the greatest threats mythology has to '
        'offer.',
    descriptionId:
        'Dewa dan makhluk berkekuatan luar biasa, dihormati di seluruh '
        'jajaran dewa karena pencapaian yang nyaris mustahil. Mereka '
        'menguasai wilayah kekuasaan, memimpin pasukan roh yang lebih '
        'rendah, dan cukup kuat untuk menghadapi ancaman terbesar dalam '
        'mitologi.',
  ),
  elite(
    label: 'Elite',
    color: Color(0xFFC62828),
    description:
        'Formidable warriors, monsters, and champions defined by raw '
        'combat prowess. Whether hero or beast, every name in this tier '
        'earned its reputation through battles that are still told and '
        'retold today.',
    descriptionId:
        'Prajurit, monster, dan jawara tangguh yang dikenal karena '
        'kemampuan bertarung luar biasa. Baik pahlawan maupun makhluk '
        'buas, setiap nama di tier ini meraih reputasinya lewat '
        'pertarungan yang masih diceritakan hingga kini.',
  ),
  veteran(
    label: 'Veteran',
    color: Color(0xFF1565C0),
    description:
        'Seasoned figures with real, tested power, strong enough to '
        "matter in any conflict, but standing a step below mythology's "
        'true titans. Their strength comes from experience, cunning, or a '
        'particular gift rather than sheer overwhelming force.',
    descriptionId:
        'Tokoh berpengalaman dengan kekuatan nyata yang telah teruji, '
        'cukup kuat untuk berperan penting dalam konflik apa pun, namun '
        'masih berada satu tingkat di bawah para raksasa sejati mitologi. '
        'Kekuatan mereka berasal dari pengalaman, kecerdikan, atau '
        'anugerah khusus, bukan sekadar kekuatan mentah.',
  ),
  noble(
    label: 'Noble',
    color: Color(0xFF2E7D32),
    description:
        'Figures whose true power lies beyond the battlefield, in '
        'wisdom, leadership, magic, craft, or sacred duty. They may not '
        'lead the charge, but mythology would fall apart without the '
        'roles they hold.',
    descriptionId:
        'Tokoh yang kekuatan sejatinya tidak terletak di medan perang, '
        'melainkan pada kebijaksanaan, kepemimpinan, sihir, keterampilan, '
        'atau tugas suci. Mereka mungkin tidak memimpin pertempuran, namun '
        'mitologi akan runtuh tanpa peran yang mereka emban.',
  ),
  guardian(
    label: 'Guardian',
    color: Color(0xFF78909C),
    description:
        "Supporting spirits, watchers, and lesser beings who keep "
        "mythology's world turning. They rarely take center stage, but "
        'the balance of every pantheon quietly depends on them.',
    descriptionId:
        'Roh pendukung, penjaga, dan makhluk kecil yang menjaga roda '
        'dunia mitologi tetap berputar. Mereka jarang menjadi pusat '
        'perhatian, namun keseimbangan setiap jajaran dewa diam-diam '
        'bergantung pada mereka.',
  );

  final String label;
  final Color color;
  final String description;
  final String descriptionId;

  const GodTier({
    required this.label,
    required this.color,
    required this.description,
    required this.descriptionId,
  });

  String localizedDescription(String lang) =>
      lang == 'id' ? descriptionId : description;
}

/// Tier assignments, keyed first by mythology then by exact god/being name
/// (must match [God.name] in the corresponding lib/data/*_gods.dart file).
/// Entries not present here (mostly cosmology/place entries like Yggdrasil
/// or Ragnarök) simply have no tier badge.
const Map<String, Map<String, GodTier>> _tiersByMythology = {
  'Nordic': {
    'Odin': GodTier.worldEnder,
    'Thor': GodTier.worldEnder,
    'Surtr': GodTier.worldEnder,
    'Fenrir': GodTier.worldEnder,
    'Jörmungandr': GodTier.worldEnder,
    'Ymir': GodTier.worldEnder,
    'Vidar': GodTier.worldEnder,
    'Freya': GodTier.legendary,
    'Freyr': GodTier.legendary,
    'Heimdall': GodTier.legendary,
    'Loki': GodTier.legendary,
    'Hel': GodTier.legendary,
    'Baldur': GodTier.legendary,
    'Norns': GodTier.legendary,
    'Vili & Vé': GodTier.legendary,
    'Tyr': GodTier.legendary,
    'Frigg': GodTier.legendary,
    'Skadi': GodTier.elite,
    'Hrungnir': GodTier.elite,
    'Utgard-Loki': GodTier.elite,
    'Nidhogg': GodTier.elite,
    'Draugr': GodTier.elite,
    'Ullr': GodTier.veteran,
    'Angrboda': GodTier.veteran,
    'Aegir & Rán': GodTier.veteran,
    'Valkyrie': GodTier.veteran,
    'Thrym': GodTier.veteran,
    'Njord': GodTier.noble,
    'Mimir': GodTier.noble,
    'Bragi': GodTier.noble,
    'Idun': GodTier.noble,
    'Forseti': GodTier.noble,
    'Sif': GodTier.noble,
    'Sleipnir': GodTier.noble,
    'Ratatoskr': GodTier.guardian,
    'Huginn & Muninn': GodTier.guardian,
    // Thiazi commands storm-wind wings and giant strength, comparable to
    // other elite-tier giants like Hrungnir and Utgard-Loki.
    'Thiazi': GodTier.elite,
    // Kills — and is killed by — Tyr himself at Ragnarök, a legendary-tier
    // god; a hound that mutually destroys a legendary combatant belongs at
    // that same level, not a tier below.
    'Garmr': GodTier.legendary,
    // Devouring the sun and moon at Ragnarök is a cosmic-scale feat on the
    // order of their father Fenrir's own destined kill of Odin — one step
    // below him since it's a single apocalyptic act rather than an
    // ever-present world-ending threat, but still far beyond ordinary combat.
    'Sköll & Hati': GodTier.elite,
    // Purely symbolic companions with no combat feats of their own — the
    // same role Huginn & Muninn play for Odin's mind, these two play for
    // his appetite, and that pair sits at guardian.
    'Geri & Freki': GodTier.guardian,
    // Thor's own sons, destined to inherit Mjolnir and survive Ragnarök —
    // strong but not yet at their father's level.
    'Magni & Móði': GodTier.veteran,
    // A magical mount, not a warrior — fast and dazzling but not built to fight.
    'Gullinbursti': GodTier.noble,
    // A giantess of great beauty with no combat feats, no wisdom or craft
    // role either — a passive figure in Freyr's story rather than a
    // noble-tier holder of sacred duty.
    'Gerðr': GodTier.guardian,
    // Blind and without any power of his own beyond the tragic accident
    // Loki engineered — a victim of fate, not a fighter.
    'Höðr': GodTier.guardian,
    // A grieving mortal-turned-goddess with no combat feats.
    'Nanna': GodTier.guardian,
  },
  'Greek': {
    'Chaos': GodTier.worldEnder,
    'Gaia': GodTier.worldEnder,
    'Uranus': GodTier.worldEnder,
    'Tartarus': GodTier.worldEnder,
    'Zeus': GodTier.worldEnder,
    'Poseidon': GodTier.worldEnder,
    'Hades': GodTier.worldEnder,
    'Cronus': GodTier.worldEnder,
    'Typhon': GodTier.worldEnder,
    'Nyx': GodTier.worldEnder,
    'Athena': GodTier.legendary,
    'Apollo': GodTier.legendary,
    'Artemis': GodTier.legendary,
    'Ares': GodTier.legendary,
    'Hera': GodTier.legendary,
    'Demeter': GodTier.legendary,
    'Dionysus': GodTier.legendary,
    'Hephaestus': GodTier.legendary,
    'Hermes': GodTier.legendary,
    'Aphrodite': GodTier.legendary,
    'Atlas': GodTier.legendary,
    'Prometheus': GodTier.legendary,
    'Oceanus': GodTier.legendary,
    'Hyperion': GodTier.legendary,
    'Rhea': GodTier.legendary,
    'Persephone': GodTier.legendary,
    'Hecate': GodTier.legendary,
    'Themis': GodTier.legendary,
    'Theia': GodTier.legendary,
    'Phoebe': GodTier.legendary,
    'Erinyes (Furies)': GodTier.legendary,
    'Echidna': GodTier.legendary,
    'Amphitrite': GodTier.legendary,
    'Heracles': GodTier.elite,
    'Perseus': GodTier.elite,
    'Theseus': GodTier.elite,
    'Achilles': GodTier.elite,
    'Odysseus': GodTier.elite,
    'Bellerophon': GodTier.elite,
    // Outwitted the Sphinx through pure intellect, not combat — a fellow
    // monster-defeater like Perseus/Theseus, but by riddle, not blade.
    'Oedipus': GodTier.elite,
    'Thanatos': GodTier.elite,
    'Iapetus': GodTier.elite,
    'Triton': GodTier.elite,
    'Nereus': GodTier.elite,
    'Proteus': GodTier.elite,
    'Hydra': GodTier.elite,
    'Chimera': GodTier.elite,
    'Minotaur': GodTier.elite,
    'Medusa': GodTier.elite,
    'Cyclops': GodTier.elite,
    'Cerberus': GodTier.elite,
    // Judge of the Underworld — commands real cosmic authority, but a
    // mortal-turned-judge rather than a full god of death like Hades.
    'Minos': GodTier.elite,
    'Hestia': GodTier.veteran,
    'Mnemosyne': GodTier.veteran,
    'Tethys': GodTier.veteran,
    'Thetis': GodTier.veteran,
    'Morpheus': GodTier.veteran,
    'Charon': GodTier.veteran,
    'Scylla & Charybdis': GodTier.veteran,
    // Leader of the Argonauts — relies heavily on his crew and Medea's
    // magic rather than personal might, unlike solo monster-slayers such
    // as Perseus or Theseus above.
    'Jason': GodTier.veteran,
    'Erebus': GodTier.noble,
    'Eros': GodTier.noble,
    'Hypnos': GodTier.noble,
    'Orpheus': GodTier.noble,
    'Sphinx': GodTier.noble,
    'Sirens': GodTier.noble,
    'Pegasus': GodTier.guardian,
    'Menoetius': GodTier.guardian,
    'Epimetheus': GodTier.guardian,
    // An ordinary youth with no combat ability whatsoever — his myth is a
    // cautionary tale, not a display of strength.
    'Icarus': GodTier.guardian,
    // A nuisance/tormentor rather than a true combat threat — defeated by
    // being chased off, not overpowered in a fight.
    'Harpies': GodTier.guardian,
    'Coeus': GodTier.veteran,
    'Crius': GodTier.veteran,
    // Second-generation sun/moon Titans — a step below their parents
    // Hyperion and Theia, who sit at legendary.
    'Helios': GodTier.elite,
    'Selene': GodTier.elite,
  },
  'Egyptian': {
    'Ra': GodTier.worldEnder,
    'Atum': GodTier.worldEnder,
    'Amun': GodTier.worldEnder,
    'Horus': GodTier.worldEnder,
    'Seth': GodTier.worldEnder,
    'Apep': GodTier.worldEnder,
    'Ptah': GodTier.worldEnder,
    'Osiris': GodTier.worldEnder,
    'Isis': GodTier.legendary,
    'Anubis': GodTier.legendary,
    'Sekhmet': GodTier.legendary,
    'Thoth': GodTier.legendary,
    'Aten': GodTier.legendary,
    'Khepri': GodTier.legendary,
    'Geb': GodTier.legendary,
    'Nut': GodTier.legendary,
    "Ma'at": GodTier.legendary,
    'Nephthys': GodTier.legendary,
    'Bastet': GodTier.elite,
    'Hathor': GodTier.elite,
    'Wepwawet': GodTier.elite,
    'Khonsu': GodTier.elite,
    'Wadjet': GodTier.elite,
    'Tefnut': GodTier.legendary,
    'Sobek': GodTier.elite,
    'Shu': GodTier.legendary,
    'Hapi': GodTier.veteran,
    'Min': GodTier.veteran,
    'Nefertem': GodTier.veteran,
    'Taweret': GodTier.veteran,
    'Bes': GodTier.veteran,
    'Seshat': GodTier.veteran,
    'Mnevis': GodTier.veteran,
    'Pharaoh': GodTier.noble,
    'Khnum': GodTier.noble,
    'Sokar': GodTier.noble,
    'Bennu': GodTier.noble,
    'Ammit': GodTier.guardian,
    'Serqet': GodTier.guardian,
    'Nekhbet': GodTier.elite,
    // Distinct from the Greek Sphinx above — this map is keyed per
    // mythology, so the Egyptian guardian needs its own entry or it falls
    // through to no tier badge at all.
    'Sphinx': GodTier.noble,
    // The primordial waters that preceded creation itself, on par with
    // Atum/Ptah/Ra as a foundational cosmic force rather than a mid-tier god.
    'Nun': GodTier.worldEnder,
    // Self-created and mother of Ra in some traditions — her own myth says
    // even Ra feared her enough that she could threaten to destroy and
    // replace him, so she belongs beside the other worldEnder-tier
    // Ennead-level forces, not a rank below the god she outmatches.
    'Neith': GodTier.worldEnder,
    // The primordial force of magic itself — without Heka, even Ra's own
    // words of creation carry no power. A force enabling every other god's
    // power, including a worldEnder's, cannot itself sit a tier lower.
    'Heka': GodTier.worldEnder,
    // A deified mortal whose true power is wisdom, medicine, and
    // architecture rather than combat — noble fits his sacred-duty role far
    // better than veteran, which implies tested fighting strength he never had.
    'Imhotep': GodTier.noble,
    'Menthu': GodTier.elite,
    // A minor but specific funerary goddess with no combat role.
    'Kebechet': GodTier.guardian,
    // Sacred-duty Nile deities maintaining Egypt's flood cycle, not tested
    // combatants — noble fits better than veteran's emphasis on fighting
    // experience, matching how the Four Sons of Horus below are scored.
    'Satis': GodTier.noble,
    'Anuket': GodTier.noble,
    'Four Sons of Horus': GodTier.noble,
    'Sopdu': GodTier.veteran,
    // Horus as a vulnerable child hidden in the marshes — no combat feats
    // of his own yet, unlike the adult Horus who tops this list.
    'Harpocrates': GodTier.guardian,
    'Tayet': GodTier.guardian,
  },
  'Hindu': {
    'Shiva': GodTier.worldEnder,
    'Vishnu': GodTier.worldEnder,
    'Brahma': GodTier.worldEnder,
    'Kali': GodTier.worldEnder,
    'Durga': GodTier.worldEnder,
    'Krishna': GodTier.worldEnder,
    'Kalki': GodTier.worldEnder,
    'Narasimha': GodTier.legendary,
    'Parvati': GodTier.legendary,
    'Lakshmi': GodTier.legendary,
    'Saraswati': GodTier.legendary,
    'Rama': GodTier.legendary,
    'Indra': GodTier.legendary,
    'Agni': GodTier.legendary,
    'Varuna': GodTier.legendary,
    'Surya': GodTier.legendary,
    'Kartikeya': GodTier.legendary,
    'Hanuman': GodTier.legendary,
    'Garuda': GodTier.legendary,
    'Ravana': GodTier.legendary,
    'Vayu': GodTier.legendary,
    'Parashurama': GodTier.legendary,
    'Vamana': GodTier.legendary,
    'Arjuna': GodTier.elite,
    'Karna': GodTier.elite,
    'Bhishma': GodTier.elite,
    'Yama': GodTier.legendary,
    'Kubera': GodTier.elite,
    'Kamadeva': GodTier.veteran,
    'Vishwakarma': GodTier.elite,
    'Nandi': GodTier.elite,
    'Asura': GodTier.elite,
    'Varaha': GodTier.legendary,
    'Matsya': GodTier.veteran,
    'Kurma': GodTier.veteran,
    'Chandra': GodTier.veteran,
    'Radha': GodTier.noble,
    'Ashwini Kumaras': GodTier.veteran,
    'Naga': GodTier.veteran,
    'Buddha': GodTier.noble,
    'Ganesha': GodTier.legendary,
    // The cosmic serpent who bears Vishnu and the weight of the entire
    // universe upon his thousand heads — a foundational cosmic support on
    // par with the primordial forces, not a mid-tier creature.
    'Sheshnaag': GodTier.worldEnder,
    // A giant with strength equal to a thousand elephants who single-
    // handedly devastated the Vanara army — combat-elite like Kumbhakarna's
    // own brother-in-arms Vishwamitra's mantra feats below, but purely physical.
    'Kumbhakarna': GodTier.elite,
    // A king-turned-Brahmarishi who created an entire galaxy of stars
    // through mantra power alone, rivaling Brahma's own creative authority —
    // among the very few mortal-born sages to approach that level.
    'Vishwamitra': GodTier.legendary,
    // Sita is an incarnation of Lakshmi herself, though the tier reflects
    // her mythological role rather than her divine essence — a figure whose
    // strength is unbreakable purity and inner resolve, not combat.
    'Sita': GodTier.noble,
    // Shesha's own incarnation as Rama's brother; a capable warrior who
    // fought Indrajit and nearly died, but still a step below the epic's
    // true legendary-tier figures like Rama and Hanuman.
    'Lakshmana': GodTier.elite,
    // The catalyst of the Kurukshetra War, but her power lies in resilience
    // and moral force rather than combat or magic.
    'Draupadi': GodTier.noble,
    // Compiler of the Vedas and author of the Mahabharata, dictating an
    // entire epic to Ganesha himself — a sage of immense standing, but a
    // scholar-sage rather than a combatant or cosmic force.
    'Vyasa': GodTier.noble,
    'Valmiki': GodTier.noble,
    // Ravana's brother who chose righteousness — wise and dutiful, but not
    // a fighter; his contribution was counsel and intelligence, not combat.
    'Vibhishana': GodTier.noble,
    // A trickster-instigator sage whose provocations shape events across
    // all three worlds, but he acts through cunning and words, not power.
    'Narada': GodTier.noble,
    // Monkey king and strategic leader of the Vanara armies, but explicitly
    // described in his own story as weaker in combat than Hanuman or Jambavan.
    'Sugriva': GodTier.veteran,
    // A giant eagle who fought Ravana himself in the sky and nearly turned
    // the tide before falling — genuine combat feats against a legendary
    // foe, even in defeat.
    'Jatayu': GodTier.elite,
    // The Vanara race collectively, whose most famous member Hanuman
    // reaches legendary — but the race's average combatant (per Sugriva's
    // own admission) falls well short of that, so this entry as a whole
    // sits at veteran.
    'Vanara': GodTier.veteran,
    // The Rakshasa race collectively — capable of matching gods in power
    // per their own myth, but the entry represents the race broadly rather
    // than its most powerful individual members (who are tiered separately).
    'Rakshasa': GodTier.elite,
    // Beautiful celestial dancers with no combat role — their power is
    // charm and artistry, not force.
    'Apsara': GodTier.guardian,
  },
  'Chinese': {
    'Pangu': GodTier.worldEnder,
    'Nu Wa': GodTier.worldEnder,
    'Jade Emperor': GodTier.worldEnder,
    'Sun Wukong': GodTier.worldEnder,
    'Erlang Shen': GodTier.worldEnder,
    'Queen Mother of the West': GodTier.legendary,
    'Fuxi': GodTier.legendary,
    'Taiyi': GodTier.legendary,
    'Nezha': GodTier.legendary,
    'Guan Yu': GodTier.legendary,
    'Dragon King of the East (Ao Guang)': GodTier.legendary,
    'Dragon King of the South (Ao Qin)': GodTier.legendary,
    'Dragon King of the West (Ao Run)': GodTier.legendary,
    'Dragon King of the North (Ao Shun)': GodTier.legendary,
    'Hou Yi': GodTier.legendary,
    "Chang'e": GodTier.noble,
    'Yanluo Wang': GodTier.legendary,
    'Hundun': GodTier.legendary,
    'He Bo': GodTier.legendary,
    'Black Tortoise': GodTier.elite,
    'Li Jing': GodTier.elite,
    'Zhao Gongming': GodTier.elite,
    'Zhong Kui': GodTier.elite,
    'Lu Dongbin': GodTier.elite,
    'Lei Gong': GodTier.elite,
    'Dian Mu': GodTier.elite,
    'Feng Bo': GodTier.elite,
    'Yu Shi': GodTier.elite,
    'Long (Dragon)': GodTier.elite,
    'Fenghuang': GodTier.noble,
    'Qilin': GodTier.noble,
    'Peng': GodTier.elite,
    'Pixiu': GodTier.elite,
    'Bixie': GodTier.elite,
    'White Tiger': GodTier.elite,
    'Azure Dragon': GodTier.elite,
    'Vermilion Bird': GodTier.elite,
    'Tang Sanzang': GodTier.veteran,
    'Zhu Bajie': GodTier.veteran,
    'Sha Wujing': GodTier.veteran,
    'Tu Di Gong': GodTier.veteran,
    'Wen Chang': GodTier.noble,
    'Tai Bai Jin Xing': GodTier.noble,
    'Judge Cui': GodTier.veteran,
    'Meng Po': GodTier.veteran,
    'Huli Jing': GodTier.veteran,
    'Taotie': GodTier.veteran,
    'Jiangshi': GodTier.veteran,
    'Mulan': GodTier.veteran,
    'Menshen': GodTier.noble,
    'Black Impermanence': GodTier.noble,
    'White Impermanence': GodTier.noble,
    'Ox-Head': GodTier.noble,
    'Horse-Face': GodTier.noble,
    'Eight Immortals': GodTier.noble,
    'Cai Shen': GodTier.noble,
    'Jigong': GodTier.noble,
    // Freed Sun Wukong from his imprisonment and orchestrated the entire
    // Journey to the West from behind the scenes — her narrative authority
    // sits above even a worldEnder-tier figure like Sun Wukong himself.
    'Guanyin': GodTier.worldEnder,
    // A mortal hero whose power was pure willpower and self-sacrifice, not
    // combat or magic — comparable to other veteran-tier mortal heroes
    // like Mulan.
    'Yu the Great': GodTier.veteran,
    // A deified mortal miracle-worker (walking on water, calming storms)
    // rather than a combatant — on par with other noble-tier deified
    // figures like Chang'e and Wen Chang.
    'Mazu': GodTier.noble,
    // A millennium-old snake spirit with high magic, capable of summoning
    // a water army to flood an entire city — stronger than Huli Jing's
    // fox-spirit trickery, warranting a tier above.
    'Bai Suzhen': GodTier.elite,
    // Founding progenitor who defeated the demon king Chi You in the
    // legendary Battle of Zhuolu and ascended to heaven with his entire
    // court — on par with fellow legendary-tier founding figures like Fuxi.
    'Yellow Emperor': GodTier.legendary,
  },
  'Japanese': {
    'Izanagi': GodTier.worldEnder,
    'Izanami': GodTier.worldEnder,
    'Amaterasu': GodTier.worldEnder,
    'Susanoo': GodTier.worldEnder,
    'Tsukuyomi': GodTier.legendary,
    'Takemikazuchi': GodTier.legendary,
    'Futsunushi': GodTier.legendary,
    'Ōkuninushi': GodTier.legendary,
    'Hachiman': GodTier.legendary,
    'Bishamonten': GodTier.legendary,
    'Marishiten': GodTier.legendary,
    'Ryujin': GodTier.legendary,
    'Watatsumi': GodTier.legendary,
    'Raijin': GodTier.legendary,
    'Fujin': GodTier.legendary,
    'Yamata no Orochi': GodTier.legendary,
    'Takamimusubi': GodTier.legendary,
    'Emma-O': GodTier.legendary,
    'Ame-no-Uzume': GodTier.noble,
    'Takeminakata': GodTier.elite,
    'Yamato Takeru': GodTier.elite,
    'Benkei': GodTier.elite,
    'Minamoto no Yoshitsune': GodTier.elite,
    'Oni': GodTier.elite,
    'Tengu': GodTier.elite,
    'Nue': GodTier.elite,
    'Gashadokuro': GodTier.elite,
    'Ebisu': GodTier.veteran,
    'Daikokuten': GodTier.veteran,
    'Benzaiten': GodTier.veteran,
    'Fukurokuju': GodTier.veteran,
    'Jurojin': GodTier.veteran,
    'Hotei': GodTier.veteran,
    'Momotaro': GodTier.veteran,
    'Kintaro': GodTier.veteran,
    'Kappa': GodTier.veteran,
    'Baku': GodTier.veteran,
    'Raiju': GodTier.veteran,
    'Jorōgumo': GodTier.veteran,
    'Yuki-onna': GodTier.veteran,
    'Tanuki': GodTier.veteran,
    'Konohanasakuya': GodTier.veteran,
    'Suijin': GodTier.noble,
    'Shinatsuhiko': GodTier.noble,
    'Kuraokami': GodTier.noble,
    'Urashima Taro': GodTier.noble,
    'Amenominakanushi': GodTier.noble,
    'Kamimusubi': GodTier.noble,
    'Umashiashikabihikoji': GodTier.noble,
    'Amenotokotachi': GodTier.noble,
    'Inari': GodTier.noble,
    'Shinigami': GodTier.noble,
    'Kitsune': GodTier.veteran,
    // His birth-fire killed Izanami, whose subsequent purification ritual
    // directly gave rise to Amaterasu, Tsukuyomi, and Susanoo — a
    // primordial force on par with fellow legendary-tier Yamata no Orochi.
    'Kagutsuchi': GodTier.legendary,
    // Direct grandson of Amaterasu, bearer of the three sacred imperial
    // treasures, and founder of the line that leads to Emperor Jimmu — on
    // par with fellow legendary-tier figures like Takamimusubi.
    'Ninigi-no-Mikoto': GodTier.legendary,
    // Dragon princess and great-grandmother of the imperial line, comparable
    // to fellow imperial-ancestor figure Konohanasakuya.
    'Toyotama-hime': GodTier.veteran,
    // A mortal (if divinely descended) conqueror who founded the imperial
    // line through military campaign — on par with fellow elite-tier
    // legendary human rulers like Yamato Takeru.
    'Emperor Jimmu': GodTier.elite,
    // A guide deity with no combat feats of his own, purely symbolic and
    // wisdom-oriented like fellow noble-tier Suijin.
    'Sarutahiko': GodTier.noble,
    // Chose peaceful surrender over combat entirely — his power is
    // political wisdom and self-sacrifice, not force.
    'Kotoshironushi': GodTier.noble,
    // A tiny god whose only feats are healing and medicine, no combat —
    // comparable to fellow noble-tier Kuraokami.
    'Sukunabikona': GodTier.noble,
    // A century-old cat yokai capable of terrorizing a household with
    // shapeshifting and ghost fire — comparable to fellow veteran-tier
    // yokai like Jorōgumo.
    'Bakeneko': GodTier.veteran,
    // An afflicted, often unwilling yokai whose curse is more body-horror
    // than genuine threat — comparable to fellow veteran-tier Yuki-onna.
    'Rokurokubi': GodTier.veteran,
  },
};

GodTier? tierOf(String mythology, String name) =>
    _tiersByMythology[mythology]?[name];

/// Every character in the Mythic Pop Culture catalog (lib/data/pop_culture_data.dart)
/// is a fictional game/film/novel reinterpretation rather than an entry from
/// real mythology, so they all share this single tier rather than being
/// ranked against [_tiersByMythology]'s authentic-myth entries.
const GodTier popCultureTier = GodTier.anomaly;

/// All god names of [mythology] that belong to [tier], in data order.
List<String> namesInTier(String mythology, GodTier tier) {
  final map = _tiersByMythology[mythology];
  if (map == null) return const [];
  return [for (final e in map.entries) if (e.value == tier) e.key];
}
