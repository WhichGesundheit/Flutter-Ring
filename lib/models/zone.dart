enum ZoneType { town, forest, deepCaves, wasteland, graveyard, citadel }

class Zone {
  final ZoneType type;
  final String name;
  final String description;
  final List<ZoneType> connections;

  const Zone({
    required this.type,
    required this.name,
    required this.description,
    required this.connections,
  });

  static Map<ZoneType, Zone> get worldMap => {
    ZoneType.town: const Zone(
      type: ZoneType.town,
      name: "Data-Town Hub",
      description:
          "A stable sector where neon-lit terminals hum with the trade of digital assets. Merchant nodes offer high-grade firmware and rest terminals provide a rare sanctuary for weary runners.",
      connections: [ZoneType.forest, ZoneType.wasteland],
    ),
    ZoneType.forest: const Zone(
      type: ZoneType.forest,
      name: "Binary Brush",
      description:
          "Thick fractal foliage that pulses with erratic rhythmic energy. Rogue logic-vines entwine with flora scripts, creating a dangerous canopy of shimmering data-leaves.",
      connections: [ZoneType.town, ZoneType.deepCaves, ZoneType.graveyard],
    ),
    ZoneType.deepCaves: const Zone(
      type: ZoneType.deepCaves,
      name: "Deep Memory Caves",
      description:
          "Subterranean archives echoing with the whispers of deleted history. Corrupted data-stalactites drip liquid processing power into pools of dark, unallocated memory.",
      connections: [ZoneType.forest],
    ),
    ZoneType.wasteland: const Zone(
      type: ZoneType.wasteland,
      name: "The Static Wasteland",
      description:
          "An endless horizon of white noise and scorched silicon. Electrical storms of pure interference tear through the sky, scouring the landscape of any unprotected code.",
      connections: [ZoneType.town, ZoneType.graveyard],
    ),
    ZoneType.graveyard: const Zone(
      type: ZoneType.graveyard,
      name: "Tech-Graveyard",
      description:
          "The skeletal remains of obsolete megastructures tower over piles of discarded hardware. Ghostly subroutines still haunt the rusted circuits of fallen titans.",
      connections: [ZoneType.forest, ZoneType.wasteland, ZoneType.citadel],
    ),
    ZoneType.citadel: const Zone(
      type: ZoneType.citadel,
      name: "The Apex Citadel",
      description:
          "A monolithic spire of obsidian glass piercing the upper atmosphere of the grid. This is the source of the control signals, guarded by the most advanced sentinels ever compiled.",
      connections: [ZoneType.graveyard],
    ),
  };
}
