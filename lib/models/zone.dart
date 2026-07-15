import 'package:flutter/material.dart';

enum ZoneType {
  town,
  forest,
  deepCaves,
  wasteland,
  graveyard,
  citadel,
  ruins,
  swamp,
  mountain,
  desert,
  library,
  factory,
  ocean,
  volcano,
  tower,
  abyss,
  // ── NEW ZONES ──
  neonBazaar,
  crystalMines,
  quantumRift,
  shadowMarket,
  voidShrine,
  chromeDocks,
  dataNexus,
  ghostTerminal,
  solarForge,
  neuralGarden,
  circuitMarshes,
  echoCaverns,
  plasmaFields,
  obsidianSpire,
  voidGate,
  // ── TIER 1 NEW SETTLEMENTS ──
  ironHarbor,
  chromeSpire,
  neonOasis,
  blackMarketHub,
  skyDock,
  // ── TIER 2 NEW MAIN-PATH DUNGEONS ──
  scorchedPipeline,
  rustCanyon,
  dataTorrent,
  decayedGrid,
  shatteredCore,
  // ── TIER 3 NEW OFF-BEATEN DUNGEONS ──
  forgottenServer,
  acidSprawl,
  hollowNetwork,
  staticRift,
  deadSignal,
  // ── TIER 4 NEW ENDGAME ZONES ──
  entropyWell,
  chromeLabyrinth,
  voidNexus,
  deepSpire,
  quantumSea,
}

class Zone {
  final ZoneType type;
  final String name;
  final String description;
  final List<ZoneType> connections;

  /// Relative position on the node map (0.0 – 1.0).
  final Offset mapPosition;

  /// Material icon shown on the node.
  final IconData icon;

  /// Accent color for the node and connection glow.
  final Color color;

  /// Minimum day required to unlock this zone (0 = always unlocked).
  final int unlockDay;

  /// Whether this zone is a settlement (has shop, rest, NPC actions).
  final bool isSettlement;

  const Zone({
    required this.type,
    required this.name,
    required this.description,
    required this.connections,
    required this.mapPosition,
    required this.icon,
    required this.color,
    this.unlockDay = 0,
    this.isSettlement = false,
  });

  /// Whether the zone is unlocked for a given current day.
  bool isUnlocked(int currentDay) => currentDay >= unlockDay;

  /// World map with overhauled progression.
  ///
  /// **Layout philosophy:**
  /// - Town is the starting hub. Two easy paths branch out (Forest / Wasteland).
  /// - After 1–2 nodes you reach a settlement (Ruins, then Citadel) for resupply.
  /// - Dungeons sit on dead-end branches off the beaten path.
  /// - Abyss is the final zone, only reachable from Volcano.
  static Map<ZoneType, Zone> get worldMap => {
    // ══════════════════════════════════════════════════════════════════════
    //  SETTLEMENTS (shop / rest / NPC)
    // ══════════════════════════════════════════════════════════════════════
    ZoneType.town: const Zone(
      type: ZoneType.town,
      name: "Data-Town Hub",
      description:
          "The starting settlement. Neon-lit terminals hum with trade, "
          "merchant nodes offer high-grade firmware, and rest terminals "
          "provide sanctuary for weary runners.",
      connections: [ZoneType.forest, ZoneType.wasteland],
      mapPosition: Offset(0.50, 0.90),
      icon: Icons.account_balance,
      color: Color(0xFF00E676),
      isSettlement: true,
    ),
    ZoneType.ruins: const Zone(
      type: ZoneType.ruins,
      name: "Rusthaven Outpost",
      description:
          "A fortified settlement built within crumbling data-temples. "
          "Merchants trade salvaged artifacts while guards patrol the "
          "ancient holographic walls.",
      connections: [ZoneType.wasteland, ZoneType.graveyard, ZoneType.desert],
      mapPosition: Offset(0.42, 0.62),
      icon: Icons.account_balance,
      color: Color(0xFF8D6E63),
      unlockDay: 1,
      isSettlement: true,
    ),
    ZoneType.citadel: const Zone(
      type: ZoneType.citadel,
      name: "Apex Citadel",
      description:
          "A monolithic spire of obsidian glass piercing the upper "
          "atmosphere. Advanced sentinels guard the last great settlement "
          "before the deep zones.",
      connections: [ZoneType.graveyard, ZoneType.volcano, ZoneType.ocean],
      mapPosition: Offset(0.42, 0.22),
      icon: Icons.dns,
      color: Color(0xFFFFD600),
      unlockDay: 4,
      isSettlement: true,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  MAIN-PATH DUNGEONS (on the highway between settlements)
    // ══════════════════════════════════════════════════════════════════════
    ZoneType.forest: const Zone(
      type: ZoneType.forest,
      name: "Binary Brush",
      description:
          "Thick fractal foliage pulsing with erratic energy. Rogue "
          "logic-vines tangle through a canopy of shimmering data-leaves.",
      connections: [
        ZoneType.town,
        ZoneType.deepCaves,
        ZoneType.graveyard,
        ZoneType.neuralGarden,
      ],
      mapPosition: Offset(0.28, 0.75),
      icon: Icons.forest,
      color: Color(0xFF66BB6A),
      unlockDay: 0,
    ),
    ZoneType.wasteland: const Zone(
      type: ZoneType.wasteland,
      name: "The Static Wasteland",
      description:
          "An endless horizon of white noise and scorched silicon. "
          "Electrical storms of pure interference scour the landscape.",
      connections: [ZoneType.town, ZoneType.ruins, ZoneType.swamp],
      mapPosition: Offset(0.72, 0.75),
      icon: Icons.broken_image,
      color: Color(0xFFFF7043),
      unlockDay: 0,
    ),
    ZoneType.graveyard: const Zone(
      type: ZoneType.graveyard,
      name: "Tech-Graveyard",
      description:
          "Skeletal remains of obsolete megastructures tower over piles "
          "of discarded hardware. Ghostly subroutines haunt the rusted circuits.",
      connections: [
        ZoneType.forest,
        ZoneType.ruins,
        ZoneType.citadel,
        ZoneType.ocean,
      ],
      mapPosition: Offset(0.42, 0.42),
      icon: Icons.warning_amber,
      color: Color(0xFFEF5350),
      unlockDay: 2,
    ),
    ZoneType.volcano: const Zone(
      type: ZoneType.volcano,
      name: "Core Meltdown",
      description:
          "A volcanic fissure where raw processing power erupts from the "
          "planet's digital core. The heat corrupts all but the strongest code.",
      connections: [ZoneType.citadel, ZoneType.abyss, ZoneType.solarForge],
      mapPosition: Offset(0.42, 0.10),
      icon: Icons.local_fire_department,
      color: Color(0xFFFF3D00),
      unlockDay: 5,
    ),
    ZoneType.abyss: const Zone(
      type: ZoneType.abyss,
      name: "The Digital Abyss",
      description:
          "The deepest layer of the Ring's architecture. Absolute darkness "
          "where reality itself begins to unravel. Only the most prepared survive.",
      connections: [ZoneType.volcano, ZoneType.quantumRift],
      mapPosition: Offset(0.42, 0.02),
      icon: Icons.all_inclusive,
      color: Color(0xFF1A237E),
      unlockDay: 7,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  OFF-BEATEN-PATH DUNGEONS (dead-end branches requiring detours)
    // ══════════════════════════════════════════════════════════════════════

    // ── Left branch: DeepCaves → Mountain → Library → Tower ──
    ZoneType.deepCaves: const Zone(
      type: ZoneType.deepCaves,
      name: "Deep Memory Caves",
      description:
          "Subterranean archives echoing with deleted history. Corrupted "
          "data-stalactites drip liquid processing power into dark pools.",
      connections: [ZoneType.forest, ZoneType.mountain, ZoneType.crystalMines],
      mapPosition: Offset(0.12, 0.58),
      icon: Icons.terrain,
      color: Color(0xFF7E57C2),
      unlockDay: 1,
    ),
    ZoneType.mountain: const Zone(
      type: ZoneType.mountain,
      name: "Frozen Peak",
      description:
          "A towering glacier of compressed data blocks. The extreme cold "
          "crystallizes unprotected code, creating beauty and peril.",
      connections: [ZoneType.deepCaves, ZoneType.library, ZoneType.echoCaverns],
      mapPosition: Offset(0.08, 0.38),
      icon: Icons.terrain,
      color: Color(0xFF42A5F5),
      unlockDay: 3,
    ),
    ZoneType.library: const Zone(
      type: ZoneType.library,
      name: "The Infinite Library",
      description:
          "Endless shelves of encoded knowledge stretch into impossible "
          "geometries. Ancient algorithms whisper forgotten truths.",
      connections: [ZoneType.mountain, ZoneType.tower],
      mapPosition: Offset(0.06, 0.18),
      icon: Icons.menu_book,
      color: Color(0xFF5C6BC0),
      unlockDay: 5,
    ),
    ZoneType.tower: const Zone(
      type: ZoneType.tower,
      name: "Signal Tower",
      description:
          "A relay station that once broadcast control signals across the "
          "entire Ring. Electromagnetic pulses still crackle along its antennae.",
      connections: [ZoneType.library, ZoneType.ocean, ZoneType.chromeDocks],
      mapPosition: Offset(0.08, 0.05),
      icon: Icons.cell_tower,
      color: Color(0xFFAB47BC),
      unlockDay: 6,
    ),

    // ── Right branch: Swamp → Factory → Desert ──
    ZoneType.swamp: const Zone(
      type: ZoneType.swamp,
      name: "Data Swamp",
      description:
          "A quagmire of corrupted data streams and half-dissolved programs. "
          "Toxic binary residue bubbles in sickly green pools.",
      connections: [
        ZoneType.wasteland,
        ZoneType.factory,
        ZoneType.circuitMarshes,
      ],
      mapPosition: Offset(0.82, 0.58),
      icon: Icons.water,
      color: Color(0xFF2E7D32),
      unlockDay: 1,
    ),
    ZoneType.factory: const Zone(
      type: ZoneType.factory,
      name: "Decommissioned Factory",
      description:
          "Massive assembly lines that once built the Ring's infrastructure "
          "now run wild, producing corrupted artifacts and hostile automatons.",
      connections: [ZoneType.swamp, ZoneType.desert],
      mapPosition: Offset(0.88, 0.35),
      icon: Icons.precision_manufacturing,
      color: Color(0xFF78909C),
      unlockDay: 3,
    ),
    ZoneType.desert: const Zone(
      type: ZoneType.desert,
      name: "Silicon Dunes",
      description:
          "Vast expanses of silicon particles stretched across an infinite "
          "plain. Sandstorms of microchips scour exposed surfaces raw.",
      connections: [ZoneType.ruins, ZoneType.factory],
      mapPosition: Offset(0.72, 0.40),
      icon: Icons.wb_sunny,
      color: Color(0xFFFFCA28),
      unlockDay: 3,
    ),

    // ── Cross-links ──
    ZoneType.ocean: const Zone(
      type: ZoneType.ocean,
      name: "Deep Net Ocean",
      description:
          "A vast abyss of liquid data where deleted files drift like "
          "bioluminescent jellyfish. Deeper = more dangerous entities.",
      connections: [ZoneType.graveyard, ZoneType.citadel, ZoneType.tower],
      mapPosition: Offset(0.22, 0.25),
      icon: Icons.waves,
      color: Color(0xFF0277BD),
      unlockDay: 3,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  NEW ZONES (15 existing unique places)
    // ══════════════════════════════════════════════════════════════════════

    // ── Neon Bazaar (settlement) ──
    ZoneType.neonBazaar: const Zone(
      type: ZoneType.neonBazaar,
      name: "Neon Bazaar",
      description:
          "A bustling underground marketplace lit by holographic neon signs. "
          "Merchants from every sector gather here to trade rare commodities.",
      connections: [
        ZoneType.wasteland,
        ZoneType.swamp,
        ZoneType.factory,
        ZoneType.blackMarketHub,
      ],
      mapPosition: Offset(0.85, 0.65),
      icon: Icons.store,
      color: Color(0xFFE91E63),
      unlockDay: 2,
      isSettlement: true,
    ),

    // ── Crystal Mines ──
    ZoneType.crystalMines: const Zone(
      type: ZoneType.crystalMines,
      name: "Crystal Mines",
      description:
          "Subterranean mines filled with glowing data-crystals. The deeper "
          "you go, the more valuable — and dangerous — the formations become.",
      connections: [
        ZoneType.deepCaves,
        ZoneType.mountain,
        ZoneType.neuralGarden,
      ],
      mapPosition: Offset(0.15, 0.48),
      icon: Icons.diamond,
      color: Color(0xFF00BCD4),
      unlockDay: 2,
    ),

    // ── Quantum Rift ──
    ZoneType.quantumRift: const Zone(
      type: ZoneType.quantumRift,
      name: "Quantum Rift",
      description:
          "A tear in the Ring's fabric where quantum computing bleeds into "
          "reality. Probability itself becomes a weapon here.",
      connections: [
        ZoneType.abyss,
        ZoneType.volcano,
        ZoneType.voidGate,
        ZoneType.entropyWell,
      ],
      mapPosition: Offset(0.55, 0.05),
      icon: Icons.blur_on,
      color: Color(0xFF9C27B0),
      unlockDay: 8,
    ),

    // ── Shadow Market (settlement) ──
    ZoneType.shadowMarket: const Zone(
      type: ZoneType.shadowMarket,
      name: "Shadow Market",
      description:
          "A hidden bazaar operating in the gaps between sectors. Anything "
          "can be bought here — for the right price. No questions asked.",
      connections: [
        ZoneType.graveyard,
        ZoneType.ocean,
        ZoneType.factory,
        ZoneType.dataNexus,
      ],
      mapPosition: Offset(0.32, 0.32),
      icon: Icons.nightlight,
      color: Color(0xFF607D8B),
      unlockDay: 4,
      isSettlement: true,
    ),

    // ── Void Shrine ──
    ZoneType.voidShrine: const Zone(
      type: ZoneType.voidShrine,
      name: "Void Shrine",
      description:
          "A sacred site where the void energy concentrates. Pilgrims come "
          "here to meditate, but the void always demands something in return.",
      connections: [ZoneType.abyss, ZoneType.volcano, ZoneType.voidGate],
      mapPosition: Offset(0.30, 0.04),
      icon: Icons.all_inclusive,
      color: Color(0xFF311B92),
      unlockDay: 9,
    ),

    // ── Chrome Docks ──
    ZoneType.chromeDocks: const Zone(
      type: ZoneType.chromeDocks,
      name: "Chrome Docks",
      description:
          "A sprawling port where data-ships dock to offload cargo. The "
          "chrome-plated structures gleam under artificial sunlight.",
      connections: [
        ZoneType.ocean,
        ZoneType.tower,
        ZoneType.shadowMarket,
        ZoneType.skyDock,
      ],
      mapPosition: Offset(0.15, 0.12),
      icon: Icons.sailing,
      color: Color(0xFFB0BEC5),
      unlockDay: 5,
    ),

    // ── Data Nexus ──
    ZoneType.dataNexus: const Zone(
      type: ZoneType.dataNexus,
      name: "Data Nexus",
      description:
          "The central hub where all data streams converge. Massive servers "
          "hum with the combined knowledge of the Ring's entire history.",
      connections: [
        ZoneType.library,
        ZoneType.shadowMarket,
        ZoneType.neonBazaar,
      ],
      mapPosition: Offset(0.58, 0.42),
      icon: Icons.device_hub,
      color: Color(0xFF2196F3),
      unlockDay: 5,
    ),

    // ── Ghost Terminal ──
    ZoneType.ghostTerminal: const Zone(
      type: ZoneType.ghostTerminal,
      name: "Ghost Terminal",
      description:
          "An abandoned command center haunted by residual AI consciousness. "
          "The terminals still process data from a world that no longer exists.",
      connections: [ZoneType.graveyard, ZoneType.tower, ZoneType.deadSignal],
      mapPosition: Offset(0.52, 0.28),
      icon: Icons.computer,
      color: Color(0xFF4CAF50),
      unlockDay: 4,
    ),

    // ── Solar Forge ──
    ZoneType.solarForge: const Zone(
      type: ZoneType.solarForge,
      name: "Solar Forge",
      description:
          "A massive solar-powered factory that once built the Ring's outer "
          "shell. Plasma rivers flow through its abandoned assembly lines.",
      connections: [
        ZoneType.volcano,
        ZoneType.desert,
        ZoneType.quantumRift,
        ZoneType.plasmaFields,
      ],
      mapPosition: Offset(0.75, 0.12),
      icon: Icons.wb_sunny,
      color: Color(0xFFFF9800),
      unlockDay: 6,
    ),

    // ── Neural Garden ──
    ZoneType.neuralGarden: const Zone(
      type: ZoneType.neuralGarden,
      name: "Neural Garden",
      description:
          "A tranquil zone where data grows like plants. Neural networks "
          "sprout from the ground, bearing fruits of pure information.",
      connections: [ZoneType.forest, ZoneType.deepCaves, ZoneType.crystalMines],
      mapPosition: Offset(0.22, 0.65),
      icon: Icons.eco,
      color: Color(0xFF8BC34A),
      unlockDay: 1,
    ),

    // ── Circuit Marshes ──
    ZoneType.circuitMarshes: const Zone(
      type: ZoneType.circuitMarshes,
      name: "Circuit Marshes",
      description:
          "A waterlogged wasteland of half-submerged circuit boards. Toxic "
          "coolant fluid pools between rusted components.",
      connections: [ZoneType.swamp, ZoneType.neonBazaar, ZoneType.acidSprawl],
      mapPosition: Offset(0.90, 0.48),
      icon: Icons.water,
      color: Color(0xFF795548),
      unlockDay: 3,
    ),

    // ── Echo Caverns ──
    ZoneType.echoCaverns: const Zone(
      type: ZoneType.echoCaverns,
      name: "Echo Caverns",
      description:
          "Caverns where sound behaves strangely — whispers from the past "
          "echo through crystalline chambers, carrying fragments of memory.",
      connections: [
        ZoneType.mountain,
        ZoneType.crystalMines,
        ZoneType.forgottenServer,
      ],
      mapPosition: Offset(0.05, 0.28),
      icon: Icons.terrain,
      color: Color(0xFF3F51B5),
      unlockDay: 4,
    ),

    // ── Plasma Fields ──
    ZoneType.plasmaFields: const Zone(
      type: ZoneType.plasmaFields,
      name: "Plasma Fields",
      description:
          "Open plains crackling with raw plasma energy. Lightning strikes "
          "are constant, and the air itself glows with charged particles.",
      connections: [
        ZoneType.desert,
        ZoneType.solarForge,
        ZoneType.scorchedPipeline,
      ],
      mapPosition: Offset(0.82, 0.22),
      icon: Icons.electric_bolt,
      color: Color(0xFFFF5722),
      unlockDay: 6,
    ),

    // ── Obsidian Spire ──
    ZoneType.obsidianSpire: const Zone(
      type: ZoneType.obsidianSpire,
      name: "Obsidian Spire",
      description:
          "A towering structure of black glass that pierces the clouds. "
          "Ancient defense systems still guard its upper reaches.",
      connections: [ZoneType.tower, ZoneType.quantumRift, ZoneType.voidGate],
      mapPosition: Offset(0.68, 0.03),
      icon: Icons.apartment,
      color: Color(0xFF212121),
      unlockDay: 8,
    ),

    // ── Void Gate (final zone) ──
    ZoneType.voidGate: const Zone(
      type: ZoneType.voidGate,
      name: "Void Gate",
      description:
          "The ultimate gateway to the void beyond the Ring. Here, reality "
          "fractures and only the most powerful runners survive.",
      connections: [
        ZoneType.quantumRift,
        ZoneType.obsidianSpire,
        ZoneType.voidShrine,
      ],
      mapPosition: Offset(0.85, 0.02),
      icon: Icons.exit_to_app,
      color: Color(0xFF000000),
      unlockDay: 10,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  TIER 1 — NEW SETTLEMENTS (5 new)
    // ══════════════════════════════════════════════════════════════════════
    ZoneType.ironHarbor: const Zone(
      type: ZoneType.ironHarbor,
      name: "Iron Harbor",
      description:
          "A fortified port settlement built from decommissioned warship hulls. "
          "Rugged traders and retired mercenaries offer their services here.",
      connections: [
        ZoneType.wasteland,
        ZoneType.neonBazaar,
        ZoneType.circuitMarshes,
      ],
      mapPosition: Offset(0.92, 0.72),
      icon: Icons.anchor,
      color: Color(0xFFCFD8DC),
      unlockDay: 2,
      isSettlement: true,
    ),
    ZoneType.chromeSpire: const Zone(
      type: ZoneType.chromeSpire,
      name: "Chrome Spire",
      description:
          "A gleaming tower of polished chrome rising from the desert. "
          "Elite engineers craft the finest augmentations money can buy.",
      connections: [
        ZoneType.desert,
        ZoneType.solarForge,
        ZoneType.plasmaFields,
      ],
      mapPosition: Offset(0.78, 0.30),
      icon: Icons.hardware,
      color: Color(0xFFE0E0E0),
      unlockDay: 4,
      isSettlement: true,
    ),
    ZoneType.neonOasis: const Zone(
      type: ZoneType.neonOasis,
      name: "Neon Oasis",
      description:
          "A hidden sanctuary bathed in perpetual neon glow. Travelers rest "
          "in bioluminescent pools while healers tend their wounds.",
      connections: [
        ZoneType.neuralGarden,
        ZoneType.forest,
        ZoneType.crystalMines,
      ],
      mapPosition: Offset(0.18, 0.55),
      icon: Icons.local_drink,
      color: Color(0xFF00E5FF),
      unlockDay: 3,
      isSettlement: true,
    ),
    ZoneType.blackMarketHub: const Zone(
      type: ZoneType.blackMarketHub,
      name: "Black Market Hub",
      description:
          "An encrypted marketplace that exists in a pocket of the Ring's "
          "architecture. Illegal augments and forbidden data traded freely.",
      connections: [
        ZoneType.neonBazaar,
        ZoneType.shadowMarket,
        ZoneType.hollowNetwork,
      ],
      mapPosition: Offset(0.70, 0.50),
      icon: Icons.shield,
      color: Color(0xFF263238),
      unlockDay: 5,
      isSettlement: true,
    ),
    ZoneType.skyDock: const Zone(
      type: ZoneType.skyDock,
      name: "Sky Dock",
      description:
          "A floating settlement tethered to the Ring's upper atmosphere. "
          "Airship captains and sky-runners barter for supplies and fuel.",
      connections: [
        ZoneType.chromeDocks,
        ZoneType.tower,
        ZoneType.obsidianSpire,
      ],
      mapPosition: Offset(0.10, 0.02),
      icon: Icons.flight,
      color: Color(0xFF80DEEA),
      unlockDay: 6,
      isSettlement: true,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  TIER 2 — NEW MAIN-PATH DUNGEONS (5 new)
    // ══════════════════════════════════════════════════════════════════════
    ZoneType.scorchedPipeline: const Zone(
      type: ZoneType.scorchedPipeline,
      name: "Scorched Pipeline",
      description:
          "An ancient data pipeline scorched by residual plasma leaks. "
          "Superheated data streams make traversal perilous but rewarding.",
      connections: [
        ZoneType.plasmaFields,
        ZoneType.solarForge,
        ZoneType.rustCanyon,
      ],
      mapPosition: Offset(0.85, 0.15),
      icon: Icons.local_fire_department,
      color: Color(0xFFFF6E40),
      unlockDay: 6,
    ),
    ZoneType.rustCanyon: const Zone(
      type: ZoneType.rustCanyon,
      name: "Rust Canyon",
      description:
          "A deep ravine carved by centuries of corroding data. Rusted "
          "remnants of ancient machines line the canyon walls.",
      connections: [
        ZoneType.scorchedPipeline,
        ZoneType.desert,
        ZoneType.decayedGrid,
      ],
      mapPosition: Offset(0.65, 0.20),
      icon: Icons.terrain,
      color: Color(0xFFBF360C),
      unlockDay: 5,
    ),
    ZoneType.dataTorrent: const Zone(
      type: ZoneType.dataTorrent,
      name: "Data Torrent",
      description:
          "A rushing river of raw data flows through a narrow canyon. "
          "Swim against the current to find hidden caches upstream.",
      connections: [ZoneType.forest, ZoneType.neuralGarden, ZoneType.deepCaves],
      mapPosition: Offset(0.20, 0.70),
      icon: Icons.water,
      color: Color(0xFF0097A7),
      unlockDay: 1,
    ),
    ZoneType.decayedGrid: const Zone(
      type: ZoneType.decayedGrid,
      name: "Decayed Grid",
      description:
          "A crumbling sector of the Ring where the foundational grid has "
          "begun to collapse. Gravity shifts unpredictably between sectors.",
      connections: [
        ZoneType.rustCanyon,
        ZoneType.graveyard,
        ZoneType.ghostTerminal,
      ],
      mapPosition: Offset(0.55, 0.35),
      icon: Icons.grid_off,
      color: Color(0xFF5D4037),
      unlockDay: 4,
    ),
    ZoneType.shatteredCore: const Zone(
      type: ZoneType.shatteredCore,
      name: "Shattered Core",
      description:
          "The remnants of a processing core that overloaded millennia ago. "
          "Shards of crystallized data float in zero-gravity pockets.",
      connections: [ZoneType.abyss, ZoneType.volcano, ZoneType.voidShrine],
      mapPosition: Offset(0.48, 0.06),
      icon: Icons.adjust,
      color: Color(0xFFB71C1C),
      unlockDay: 7,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  TIER 3 — NEW OFF-BEATEN DUNGEONS (5 new)
    // ══════════════════════════════════════════════════════════════════════
    ZoneType.forgottenServer: const Zone(
      type: ZoneType.forgottenServer,
      name: "Forgotten Server",
      description:
          "A massive server farm abandoned when the Ring was restructured. "
          "Legacy processes still run, guarding treasures of the old world.",
      connections: [
        ZoneType.echoCaverns,
        ZoneType.library,
        ZoneType.hollowNetwork,
      ],
      mapPosition: Offset(0.03, 0.20),
      icon: Icons.dns,
      color: Color(0xFF1565C0),
      unlockDay: 5,
    ),
    ZoneType.acidSprawl: const Zone(
      type: ZoneType.acidSprawl,
      name: "Acid Sprawl",
      description:
          "An industrial wasteland where chemical waste has corroded everything "
          "into twisted metal sculptures. Toxic fog limits visibility.",
      connections: [
        ZoneType.circuitMarshes,
        ZoneType.factory,
        ZoneType.neonBazaar,
      ],
      mapPosition: Offset(0.93, 0.42),
      icon: Icons.science,
      color: Color(0xFF9CCC65),
      unlockDay: 4,
    ),
    ZoneType.hollowNetwork: const Zone(
      type: ZoneType.hollowNetwork,
      name: "Hollow Network",
      description:
          "A vast underground network of hollow data-conduits. Echoes of "
          "deleted transmissions whisper through the empty channels.",
      connections: [
        ZoneType.blackMarketHub,
        ZoneType.forgottenServer,
        ZoneType.deadSignal,
      ],
      mapPosition: Offset(0.45, 0.28),
      icon: Icons.cable,
      color: Color(0xFF757575),
      unlockDay: 5,
    ),
    ZoneType.staticRift: const Zone(
      type: ZoneType.staticRift,
      name: "Static Rift",
      description:
          "A rift in the Ring's data-layer where static interference creates "
          "phantom duplicates. Fight yourself or outsmart your echo.",
      connections: [
        ZoneType.wasteland,
        ZoneType.rustCanyon,
        ZoneType.decayedGrid,
      ],
      mapPosition: Offset(0.60, 0.55),
      icon: Icons.signal_cellular_alt,
      color: Color(0xFFEC407A),
      unlockDay: 3,
    ),
    ZoneType.deadSignal: const Zone(
      type: ZoneType.deadSignal,
      name: "Dead Signal",
      description:
          "A zone where all signals go to die. No transmissions escape, "
          "no frequencies penetrate. Total digital silence.",
      connections: [
        ZoneType.ghostTerminal,
        ZoneType.hollowNetwork,
        ZoneType.obsidianSpire,
      ],
      mapPosition: Offset(0.40, 0.15),
      icon: Icons.signal_cellular_off,
      color: Color(0xFF455A64),
      unlockDay: 6,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  TIER 4 — NEW ENDGAME ZONES (5 new)
    // ══════════════════════════════════════════════════════════════════════
    ZoneType.entropyWell: const Zone(
      type: ZoneType.entropyWell,
      name: "Entropy Well",
      description:
          "A gravity well of pure entropy where data decomposes into its "
          "base components. The closer you get, the more reality unravels.",
      connections: [
        ZoneType.quantumRift,
        ZoneType.shatteredCore,
        ZoneType.voidGate,
      ],
      mapPosition: Offset(0.58, 0.02),
      icon: Icons.compress,
      color: Color(0xFF880E4F),
      unlockDay: 9,
    ),
    ZoneType.chromeLabyrinth: const Zone(
      type: ZoneType.chromeLabyrinth,
      name: "Chrome Labyrinth",
      description:
          "An ever-shifting maze of chrome corridors and mirrored walls. "
          "The labyrinth rearranges itself every cycle, trapping the unwary.",
      connections: [
        ZoneType.obsidianSpire,
        ZoneType.skyDock,
        ZoneType.voidGate,
      ],
      mapPosition: Offset(0.75, 0.05),
      icon: Icons.account_tree,
      color: Color(0xFFB0BEC5),
      unlockDay: 9,
    ),
    ZoneType.voidNexus: const Zone(
      type: ZoneType.voidNexus,
      name: "Void Nexus",
      description:
          "The convergence point of all void energies in the Ring. Reality "
          "is thinnest here, and the boundary between code and flesh blurs.",
      connections: [
        ZoneType.abyss,
        ZoneType.shatteredCore,
        ZoneType.entropyWell,
      ],
      mapPosition: Offset(0.35, 0.01),
      icon: Icons.all_inclusive,
      color: Color(0xFF4A148C),
      unlockDay: 10,
    ),
    ZoneType.deepSpire: const Zone(
      type: ZoneType.deepSpire,
      name: "Deep Spire",
      description:
          "A spire that descends rather than ascends, plunging into the "
          "Ring's deepest core. Ancient code pulses like a heartbeat.",
      connections: [
        ZoneType.voidNexus,
        ZoneType.deadSignal,
        ZoneType.entropyWell,
      ],
      mapPosition: Offset(0.48, 0.01),
      icon: Icons.swap_vert,
      color: Color(0xFF1A237E),
      unlockDay: 10,
    ),
    ZoneType.quantumSea: const Zone(
      type: ZoneType.quantumSea,
      name: "Quantum Sea",
      description:
          "An ocean of quantum probability where every possible reality "
          "exists simultaneously. Only those who can collapse the waveform survive.",
      connections: [
        ZoneType.quantumRift,
        ZoneType.voidGate,
        ZoneType.entropyWell,
      ],
      mapPosition: Offset(0.65, 0.01),
      icon: Icons.water,
      color: Color(0xFF006064),
      unlockDay: 11,
    ),
  };
}
