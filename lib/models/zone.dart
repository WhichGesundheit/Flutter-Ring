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

  const Zone({
    required this.type,
    required this.name,
    required this.description,
    required this.connections,
    required this.mapPosition,
    required this.icon,
    required this.color,
    this.unlockDay = 0,
  });

  /// Whether the zone is unlocked for a given current day.
  bool isUnlocked(int currentDay) => currentDay >= unlockDay;

  static Map<ZoneType, Zone> get worldMap => {
    ZoneType.town: const Zone(
      type: ZoneType.town,
      name: "Data-Town Hub",
      description:
          "A stable sector where neon-lit terminals hum with the trade of digital assets. Merchant nodes offer high-grade firmware and rest terminals provide a rare sanctuary for weary runners.",
      connections: [
        ZoneType.forest,
        ZoneType.wasteland,
        ZoneType.ruins,
        ZoneType.swamp,
      ],
      mapPosition: Offset(0.50, 0.85),
      icon: Icons.account_balance,
      color: Color(0xFF00E676),
    ),
    ZoneType.forest: const Zone(
      type: ZoneType.forest,
      name: "Binary Brush",
      description:
          "Thick fractal foliage that pulses with erratic rhythmic energy. Rogue logic-vines entwine with flora scripts, creating a dangerous canopy of shimmering data-leaves.",
      connections: [
        ZoneType.town,
        ZoneType.deepCaves,
        ZoneType.graveyard,
        ZoneType.mountain,
      ],
      mapPosition: Offset(0.35, 0.65),
      icon: Icons.forest,
      color: Color(0xFF66BB6A),
      unlockDay: 0,
    ),
    ZoneType.deepCaves: const Zone(
      type: ZoneType.deepCaves,
      name: "Deep Memory Caves",
      description:
          "Subterranean archives echoing with the whispers of deleted history. Corrupted data-stalactites drip liquid processing power into pools of dark, unallocated memory.",
      connections: [ZoneType.forest, ZoneType.library, ZoneType.swamp],
      mapPosition: Offset(0.15, 0.45),
      icon: Icons.terrain,
      color: Color(0xFF7E57C2),
      unlockDay: 1,
    ),
    ZoneType.wasteland: const Zone(
      type: ZoneType.wasteland,
      name: "The Static Wasteland",
      description:
          "An endless horizon of white noise and scorched silicon. Electrical storms of pure interference tear through the sky, scouring the landscape of any unprotected code.",
      connections: [
        ZoneType.town,
        ZoneType.graveyard,
        ZoneType.desert,
        ZoneType.factory,
      ],
      mapPosition: Offset(0.65, 0.65),
      icon: Icons.broken_image,
      color: Color(0xFFFF7043),
      unlockDay: 1,
    ),
    ZoneType.graveyard: const Zone(
      type: ZoneType.graveyard,
      name: "Tech-Graveyard",
      description:
          "The skeletal remains of obsolete megastructures tower over piles of discarded hardware. Ghostly subroutines still haunt the rusted circuits of fallen titans.",
      connections: [
        ZoneType.forest,
        ZoneType.wasteland,
        ZoneType.citadel,
        ZoneType.ocean,
      ],
      mapPosition: Offset(0.50, 0.45),
      icon: Icons.warning_amber,
      color: Color(0xFFEF5350),
      unlockDay: 2,
    ),
    ZoneType.citadel: const Zone(
      type: ZoneType.citadel,
      name: "The Apex Citadel",
      description:
          "A monolithic spire of obsidian glass piercing the upper atmosphere of the grid. This is the source of the control signals, guarded by the most advanced sentinels ever compiled.",
      connections: [ZoneType.graveyard, ZoneType.tower, ZoneType.abyss],
      mapPosition: Offset(0.75, 0.25),
      icon: Icons.dns,
      color: Color(0xFFFFD600),
      unlockDay: 4,
    ),

    // ── NEW ZONES (10 additional) ──
    ZoneType.ruins: const Zone(
      type: ZoneType.ruins,
      name: "Ancient Ruins",
      description:
          "Crumbling data-temples from a forgotten era. Faded holographic murals depict civilizations that existed before the Ring was forged.",
      connections: [ZoneType.town, ZoneType.desert, ZoneType.volcano],
      mapPosition: Offset(0.25, 0.75),
      icon: Icons.account_balance,
      color: Color(0xFF8D6E63),
      unlockDay: 0,
    ),
    ZoneType.swamp: const Zone(
      type: ZoneType.swamp,
      name: "Data Swamp",
      description:
          "A quagmire of corrupted data streams and half-dissolved programs. Toxic binary residue bubbles to the surface in sickly green pools.",
      connections: [ZoneType.town, ZoneType.deepCaves, ZoneType.ocean],
      mapPosition: Offset(0.75, 0.75),
      icon: Icons.water,
      color: Color(0xFF2E7D32),
      unlockDay: 0,
    ),
    ZoneType.mountain: const Zone(
      type: ZoneType.mountain,
      name: "Frozen Peak",
      description:
          "A towering glacier of compressed data blocks. The extreme cold crystallizes any unprotected code, creating both beauty and peril.",
      connections: [ZoneType.forest, ZoneType.tower, ZoneType.volcano],
      mapPosition: Offset(0.15, 0.25),
      icon: Icons.terrain,
      color: Color(0xFF42A5F5),
      unlockDay: 2,
    ),
    ZoneType.desert: const Zone(
      type: ZoneType.desert,
      name: "Silicon Dunes",
      description:
          "Vast expanses of silicon particles stretched across an infinite plain. Sandstorms of microchips scour exposed surfaces raw.",
      connections: [ZoneType.wasteland, ZoneType.ruins, ZoneType.volcano],
      mapPosition: Offset(0.85, 0.55),
      icon: Icons.wb_sunny,
      color: Color(0xFFFFCA28),
      unlockDay: 2,
    ),
    ZoneType.library: const Zone(
      type: ZoneType.library,
      name: "The Infinite Library",
      description:
          "Endless shelves of encoded knowledge stretch into impossible geometries. Ancient algorithms whisper forgotten truths to those who listen.",
      connections: [ZoneType.deepCaves, ZoneType.tower],
      mapPosition: Offset(0.08, 0.15),
      icon: Icons.menu_book,
      color: Color(0xFF5C6BC0),
      unlockDay: 3,
    ),
    ZoneType.factory: const Zone(
      type: ZoneType.factory,
      name: "Decommissioned Factory",
      description:
          "Massive assembly lines that once built the Ring's infrastructure now run wild, producing corrupted artifacts and hostile automatons.",
      connections: [ZoneType.wasteland, ZoneType.abyss],
      mapPosition: Offset(0.92, 0.35),
      icon: Icons.precision_manufacturing,
      color: Color(0xFF78909C),
      unlockDay: 3,
    ),
    ZoneType.ocean: const Zone(
      type: ZoneType.ocean,
      name: "Deep Net Ocean",
      description:
          "A vast abyss of liquid data where deleted files drift like bioluminescent jellyfish. The deeper you go, the more dangerous the entities become.",
      connections: [ZoneType.graveyard, ZoneType.swamp, ZoneType.abyss],
      mapPosition: Offset(0.70, 0.15),
      icon: Icons.waves,
      color: Color(0xFF0277BD),
      unlockDay: 4,
    ),
    ZoneType.volcano: const Zone(
      type: ZoneType.volcano,
      name: "Core Meltdown",
      description:
          "A volcanic fissure where raw processing power erupts from the planet's digital core. The heat corrupts all but the strongest code.",
      connections: [
        ZoneType.ruins,
        ZoneType.mountain,
        ZoneType.desert,
        ZoneType.abyss,
      ],
      mapPosition: Offset(0.42, 0.10),
      icon: Icons.local_fire_department,
      color: Color(0xFFFF3D00),
      unlockDay: 5,
    ),
    ZoneType.tower: const Zone(
      type: ZoneType.tower,
      name: "Signal Tower",
      description:
          "A relay station that once broadcast control signals across the entire Ring. Electromagnetic pulses still crackle along its ancient antennae.",
      connections: [
        ZoneType.citadel,
        ZoneType.mountain,
        ZoneType.library,
        ZoneType.abyss,
      ],
      mapPosition: Offset(0.25, 0.05),
      icon: Icons.cell_tower,
      color: Color(0xFFAB47BC),
      unlockDay: 6,
    ),
    ZoneType.abyss: const Zone(
      type: ZoneType.abyss,
      name: "The Digital Abyss",
      description:
          "The deepest layer of the Ring's architecture. A place of absolute darkness where reality itself begins to unravel. Only the most prepared survive.",
      connections: [
        ZoneType.citadel,
        ZoneType.ocean,
        ZoneType.volcano,
        ZoneType.tower,
        ZoneType.factory,
      ],
      mapPosition: Offset(0.50, 0.00),
      icon: Icons.all_inclusive,
      color: Color(0xFF1A237E),
      unlockDay: 7,
    ),
  };
}
