class Item {
  final String id;
  final String name;
  final String description;
  final int cost; // For the shop
  final String statBonus;

  Item({
    required this.id,
    required this.name,
    this.description = '',
    this.cost = 0,
    this.statBonus = '',
  });
}

class Character {
  final String name;
  final String className;
  int hp;
  int maxHp;
  int attack;
  int gold;
  final Item startingItem;

  Character({
    required this.name,
    required this.className,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.gold,
    required this.startingItem,
  });
}
