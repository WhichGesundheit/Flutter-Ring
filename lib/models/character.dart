import 'item.dart';

class Character {
  final String name;
  final String className;
  int hp;
  int maxHp;
  int baseAttack;
  int credits;
  final Item startingItem;
  final List<SlotType> slotLayout;
  final String? imagePath;

  Character({
    required this.name,
    required this.className,
    required this.hp,
    required this.maxHp,
    required this.baseAttack,
    required this.credits,
    required this.startingItem,
    required this.slotLayout,
    this.imagePath,
  });

  int getEffectiveAttack(List<Item?> equippedSlots) {
    int totalAttack = baseAttack;
    for (var item in equippedSlots) {
      if (item != null) {
        totalAttack += item.attackBonus;
      }
    }
    return totalAttack;
  }

  Character clone() {
    return Character(
      name: name,
      className: className,
      hp: maxHp,
      maxHp: maxHp,
      baseAttack: baseAttack,
      credits: name == "Valerie" ? 10 : 45,
      startingItem: startingItem,
      slotLayout: List.from(slotLayout),
      imagePath: imagePath,
    );
  }
}
