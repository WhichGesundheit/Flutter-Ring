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
      mapPosition: Offset(0.50, 0.92),
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
      mapPosition: Offset(0.45, 0.58),
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
      mapPosition: Offset(0.45, 0.20),
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
      connections: [ZoneType.town, ZoneType.deepCaves, ZoneType.graveyard],
      mapPosition: Offset(0.30, 0.75),
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
      mapPosition: Offset(0.70, 0.75),
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
      mapPosition: Offset(0.45, 0.40),
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
      connections: [ZoneType.citadel, ZoneType.abyss],
      mapPosition: Offset(0.45, 0.08),
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
      connections: [ZoneType.volcano],
      mapPosition: Offset(0.45, 0.00),
      icon: Icons.all_inclusive,
      color: Color(0xFF1A237E),
      unlockDay: 7,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  OFF-BEATEN-PATH DUNGEONS (dead-end branches requiring detours)
    // ══════════════════════════════════════════════════════════════════════

    // ── Left branch: DeepCaves → Mountain → Library → Tower (dead end) ──
    ZoneType.deepCaves: const Zone(
      type: ZoneType.deepCaves,
      name: "Deep Memory Caves",
      description:
          "Subterranean archives echoing with deleted history. Corrupted "
          "data-stalactites drip liquid processing power into dark pools.",
      connections: [ZoneType.forest, ZoneType.mountain],
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
      connections: [ZoneType.deepCaves, ZoneType.library],
      mapPosition: Offset(0.08, 0.35),
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
      mapPosition: Offset(0.05, 0.15),
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
      connections: [ZoneType.library, ZoneType.ocean],
      mapPosition: Offset(0.08, 0.03),
      icon: Icons.cell_tower,
      color: Color(0xFFAB47BC),
      unlockDay: 6,
    ),

    // ── Right branch: Swamp → Factory (dead end) ──
    ZoneType.swamp: const Zone(
      type: ZoneType.swamp,
      name: "Data Swamp",
      description:
          "A quagmire of corrupted data streams and half-dissolved programs. "
          "Toxic binary residue bubbles in sickly green pools.",
      connections: [ZoneType.wasteland, ZoneType.factory],
      mapPosition: Offset(0.82, 0.55),
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
      mapPosition: Offset(0.88, 0.30),
      icon: Icons.precision_manufacturing,
      color: Color(0xFF78909C),
      unlockDay: 3,
    ),

    // ── Off-beaten from Ruins: Desert → Factory (cross-link) ──
    ZoneType.desert: const Zone(
      type: ZoneType.desert,
      name: "Silicon Dunes",
      description:
          "Vast expanses of silicon particles stretched across an infinite "
          "plain. Sandstorms of microchips scour exposed surfaces raw.",
      connections: [ZoneType.ruins, ZoneType.factory],
      mapPosition: Offset(0.72, 0.38),
      icon: Icons.wb_sunny,
      color: Color(0xFFFFCA28),
      unlockDay: 3,
    ),

    // ── Off-beaten from Graveyard: Ocean → Tower (cross-link) ──
    ZoneType.ocean: const Zone(
      type: ZoneType.ocean,
      name: "Deep Net Ocean",
      description:
          "A vast abyss of liquid data where deleted files drift like "
          "bioluminescent jellyfish. Deeper = more dangerous entities.",
      connections: [ZoneType.graveyard, ZoneType.citadel, ZoneType.tower],
      mapPosition: Offset(0.25, 0.25),
      icon: Icons.waves,
      color: Color(0xFF0277BD),
      unlockDay: 3,
    ),

    // ══════════════════════════════════════════════════════════════════════
    //  NEW ZONES (15 additional unique places)
    // ══════════════════════════════════════════════════════════════════════

    // ── Neon Bazaar (settlement) ──
    ZoneType.neonBazaar: const Zone(
      type: ZoneType.neonBazaar,
      name: "Neon Bazaar",
      description:
          "A bustling underground marketplace lit by holographic neon signs. "
          "Merchants from every sector gather here to trade rare commodities.",
      connections: [ZoneType.wasteland, ZoneType.swamp, ZoneType.factory],
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
      connections: [ZoneType.deepCaves, ZoneType.mountain],
      mapPosition: Offset(0.15, 0.45),
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
      connections: [ZoneType.abyss, ZoneType.volcano, ZoneType.voidGate],
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
      connections: [ZoneType.graveyard, ZoneType.ocean, ZoneType.factory],
      mapPosition: Offset(0.35, 0.32),
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
      connections: [ZoneType.abyss, ZoneType.volcano],
      mapPosition: Offset(0.35, 0.03),
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
      connections: [ZoneType.ocean, ZoneType.tower, ZoneType.shadowMarket],
      mapPosition: Offset(0.15, 0.18),
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
      mapPosition: Offset(0.60, 0.45),
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
      connections: [ZoneType.graveyard, ZoneType.tower],
      mapPosition: Offset(0.55, 0.28),
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
      connections: [ZoneType.volcano, ZoneType.desert, ZoneType.quantumRift],
      mapPosition: Offset(0.75, 0.10),
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
      mapPosition: Offset(0.22, 0.68),
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
      connections: [ZoneType.swamp, ZoneType.neonBazaar],
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
      connections: [ZoneType.mountain, ZoneType.crystalMines],
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
      connections: [ZoneType.desert, ZoneType.solarForge],
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
      mapPosition: Offset(0.70, 0.02),
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
      connections: [ZoneType.quantumRift, ZoneType.obsidianSpire],
      mapPosition: Offset(0.85, 0.00),
      icon: Icons.exit_to_app,
      color: Color(0xFF000000),
      unlockDay: 10,
    ),
  };
}
