import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/character.dart';
import '../widgets/game_image.dart';
import '../widgets/game_theme.dart';

class CharacterSelectScreen extends StatelessWidget {
  final Function(Character) onSelect;
  CharacterSelectScreen({super.key, required this.onSelect});

  final List<Character> characters = [
    Character(
      name: "Valerie",
      className: "Dual-Wield Vanguard",
      imagePath: "assets/images/characters/valerie.png",
      hp: 65,
      maxHp: 65,
      baseAttack: 7,
      credits: 10,
      startingItem: Item(
        id: 'iron_sword',
        name: 'Iron Sword',
        type: SlotType.weapon,
        attackBonus: 3,
      ),
      slotLayout: [
        SlotType.head,
        SlotType.armor,
        SlotType.weapon,
        SlotType.weapon,
        SlotType.item,
        SlotType.item,
      ],
    ),
    Character(
      name: "Aethelgard",
      className: "Grand Scholar Spellsword",
      imagePath: "assets/images/characters/aethelgard.png",
      hp: 50,
      maxHp: 50,
      baseAttack: 5,
      credits: 45,
      startingItem: Item(
        id: 'focus_ring',
        name: 'Focus Ring',
        type: SlotType.item,
        attackBonus: 1,
        critChance: 0.20,
      ),
      slotLayout: [
        SlotType.head,
        SlotType.armor,
        SlotType.weapon,
        SlotType.item,
        SlotType.item,
        SlotType.item,
      ],
    ),
    Character(
      name: "Vex",
      className: "Voidblade Assassin",
      imagePath: "assets/images/characters/vex.png",
      hp: 40,
      maxHp: 40,
      baseAttack: 9,
      credits: 20,
      startingItem: Item(
        id: 'shadow_knife',
        name: 'Shadow Knife',
        type: SlotType.weapon,
        attackBonus: 4,
        critChance: 0.10,
      ),
      slotLayout: [
        SlotType.head,
        SlotType.armor,
        SlotType.weapon,
        SlotType.weapon,
        SlotType.weapon,
        SlotType.item,
      ],
    ),
    Character(
      name: "Bulwark",
      className: "Ironclad Sentinel",
      imagePath: "assets/images/characters/bulwark.png",
      hp: 85,
      maxHp: 85,
      baseAttack: 4,
      credits: 25,
      startingItem: Item(
        id: 'tower_shield',
        name: 'Tower Shield',
        type: SlotType.armor,
        damageReduction: 4,
      ),
      slotLayout: [
        SlotType.head,
        SlotType.armor,
        SlotType.armor,
        SlotType.weapon,
        SlotType.item,
        SlotType.item,
      ],
    ),
  ];

  // Character descriptions for better onboarding
  static const Map<String, String> _descriptions = {
    "Valerie":
        "Balanced fighter with dual weapon slots. High HP, moderate damage. Earns less credits but excels in sustained combat.",
    "Aethelgard":
        "Glass cannon with three item slots for maximum stat stacking. Low HP but devastating when built correctly. Starts rich.",
    "Vex":
        "Pure aggression with triple weapon slots. Lowest HP but highest base attack. For those who believe the best defense is a good offense.",
    "Bulwark":
        "The unbreakable wall. Highest HP with dual armor slots for extreme damage reduction. Slow but nearly impossible to kill.",
  };

  Color _classColor(String className) {
    if (className.contains('Vanguard')) return GameColors.primary;
    if (className.contains('Scholar')) return GameColors.accent;
    if (className.contains('Assassin')) return Colors.deepPurpleAccent;
    if (className.contains('Sentinel')) return GameColors.gold;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        title: const Text("Select Survivor Class"),
        backgroundColor: GameColors.surface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: characters.length,
        itemBuilder: (context, index) {
          final char = characters[index];
          final color = _classColor(char.className);
          final desc = _descriptions[char.name] ?? '';

          return Card(
            color: GameColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header row
                  Row(
                    children: [
                      GameImage(
                        imagePath: char.imagePath,
                        fallbackIcon: Icons.person,
                        size: 64,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              char.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              char.className,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    desc,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stat chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatChip(
                        icon: Icons.favorite,
                        label: '${char.hp} HP',
                        color: GameColors.success,
                      ),
                      StatChip(
                        icon: Icons.flash_on,
                        label: '${char.baseAttack} ATK',
                        color: GameColors.primary,
                      ),
                      StatChip(
                        icon: Icons.monetization_on,
                        label: '${char.credits}c',
                        color: GameColors.gold,
                      ),
                      StatChip(
                        icon: Icons.view_module,
                        label: '${char.slotLayout.length} Slots',
                        color: GameColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Slot layout
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      char.slotLayout
                          .map((s) => s.name.toUpperCase())
                          .join(" → "),
                      style: TextStyle(
                        fontSize: 9,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Starter: ${char.startingItem.name}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Deploy button
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                        shadowColor: color.withValues(alpha: 0.4),
                      ),
                      onPressed: () => onSelect(char.clone()),
                      child: const Text(
                        "DEPLOY VECTOR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
