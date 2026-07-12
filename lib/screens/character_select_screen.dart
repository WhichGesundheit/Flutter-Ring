import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/character.dart';
import '../widgets/game_image.dart';

class CharacterSelectScreen extends StatelessWidget {
  final Function(Character) onSelect;
  CharacterSelectScreen({super.key, required this.onSelect});

  final List<Character> characters = [
    Character(
      name: "Valerie",
      className: "Dual-Wield Vanguard",
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Survivor Class Blueprint")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: characters
                .map(
                  (char) => Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameImage(
                            imagePath: char.imagePath,
                            fallbackIcon: Icons.person,
                            size: 80,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            char.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            char.className,
                            style: TextStyle(
                              color: Colors.red[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            "Base Health Array: ${char.hp}/${char.maxHp} HP",
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Inherent Force Modifier: ${char.baseAttack} ATK",
                          ),
                          const SizedBox(height: 4),
                          Text("Starting Bankroll: ${char.credits} Credits"),
                          const SizedBox(height: 8),
                          const Divider(indent: 20, endIndent: 20),
                          const SizedBox(height: 8),
                          const Text(
                            "Matrix Slots Profile:",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            char.slotLayout
                                .map((s) => s.name.toUpperCase())
                                .join(" | "),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.black26,
                            child: Text(
                              "Starter Item: ${char.startingItem.name}",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 45),
                            ),
                            onPressed: () => onSelect(char.clone()),
                            child: const Text("Deploy Vector"),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
