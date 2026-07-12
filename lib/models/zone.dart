import 'package:flutter/material.dart';

enum ZoneType { town, forest, deepCaves, wasteland, graveyard, citadel }

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
      connections: [ZoneType.forest, ZoneType.wasteland],
      mapPosition: Offset(0.25, 0.82),
      icon: Icons.account_balance,
      color: Color(0xFF00E676),
    ),
    ZoneType.forest: const Zone(
      type: ZoneType.forest,
      name: "Binary Brush",
      description:
          "Thick fractal foliage that pulses with erratic rhythmic energy. Rogue logic-vines entwine with flora scripts, creating a dangerous canopy of shimmering data-leaves.",
      connections: [ZoneType.town, ZoneType.deepCaves, ZoneType.graveyard],
      mapPosition: Offset(0.30, 0.45),
      icon: Icons.forest,
      color: Color(0xFF66BB6A),
    ),
    ZoneType.deepCaves: const Zone(
      type: ZoneType.deepCaves,
      name: "Deep Memory Caves",
      description:
          "Subterranean archives echoing with the whispers of deleted history. Corrupted data-stalactites drip liquid processing power into pools of dark, unallocated memory.",
      connections: [ZoneType.forest],
      mapPosition: Offset(0.14, 0.14),
      icon: Icons.terrain,
      color: Color(0xFF7E57C2),
      unlockDay: 1,
    ),
    ZoneType.wasteland: const Zone(
      type: ZoneType.wasteland,
      name: "The Static Wasteland",
      description:
          "An endless horizon of white noise and scorched silicon. Electrical storms of pure interference tear through the sky, scouring the landscape of any unprotected code.",
      connections: [ZoneType.town, ZoneType.graveyard],
      mapPosition: Offset(0.75, 0.82),
      icon: Icons.broken_image,
      color: Color(0xFFFF7043),
      unlockDay: 1,
    ),
    ZoneType.graveyard: const Zone(
      type: ZoneType.graveyard,
      name: "Tech-Graveyard",
      description:
          "The skeletal remains of obsolete megastructures tower over piles of discarded hardware. Ghostly subroutines still haunt the rusted circuits of fallen titans.",
      connections: [ZoneType.forest, ZoneType.wasteland, ZoneType.citadel],
      mapPosition: Offset(0.70, 0.45),
      icon: Icons.warning_amber,
      color: Color(0xFFEF5350),
      unlockDay: 2,
    ),
    ZoneType.citadel: const Zone(
      type: ZoneType.citadel,
      name: "The Apex Citadel",
      description:
          "A monolithic spire of obsidian glass piercing the upper atmosphere of the grid. This is the source of the control signals, guarded by the most advanced sentinels ever compiled.",
      connections: [ZoneType.graveyard],
      mapPosition: Offset(0.86, 0.14),
      icon: Icons.dns,
      color: Color(0xFFFFD600),
      unlockDay: 4,
    ),
  };
}
