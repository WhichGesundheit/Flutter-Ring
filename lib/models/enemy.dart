import 'item.dart';

class Enemy {
  final String name;
  final String description;
  int hp;
  int maxHp;
  final int attack;
  final int goldReward;
  final List<Item> potentialLoot; // Pool of items this enemy could drop
  final String? imagePath;

  Enemy({
    required this.name,
    required this.description,
    required this.hp,
    required this.maxHp,
    required this.attack,
    this.goldReward = 15,
    this.potentialLoot = const [],
    this.imagePath,
  });

  factory Enemy.fromMap(Map<String, dynamic> map) {
    return Enemy(
      name: map['name'] ?? 'Unknown Disturbance',
      description: map['description'] ?? 'Anomalous signature.',
      hp: map['hp'] ?? 30,
      maxHp: map['hp'] ?? 30,
      attack: map['attack'] ?? 5,
      goldReward: map['goldReward'] ?? 15,
      potentialLoot: map['potentialLoot'] ?? [],
      imagePath: map['imagePath'],
    );
  }

  // Create a deep copy helper to ensure clean instantiations per battle encounter
  Enemy clone() {
    return Enemy(
      name: name,
      description: description,
      hp: hp,
      maxHp: maxHp,
      attack: attack,
      goldReward: goldReward,
      potentialLoot: List.from(potentialLoot),
      imagePath: imagePath,
    );
  }
}
