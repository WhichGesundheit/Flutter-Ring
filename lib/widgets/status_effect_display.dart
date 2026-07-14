import 'package:flutter/material.dart';
import '../models/status_effect.dart';

/// Displays status effects as colored square icons beside the character portrait.
/// Icons stack top-to-bottom and resize to accommodate more effects.
/// Tapping an icon shows detailed info. Max 20 icons shown.
class StatusEffectDisplay extends StatelessWidget {
  final List<StatusEffect> effects;
  final double maxHeight;
  final double iconSize;

  const StatusEffectDisplay({
    super.key,
    required this.effects,
    this.maxHeight = 200,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) return const SizedBox.shrink();

    final displayEffects = effects.take(20).toList();
    final count = displayEffects.length;

    // Calculate icon size based on count to fit within maxHeight
    final double spacing = 4.0;
    final double totalSpacing = spacing * (count - 1).clamp(0, count);
    double calculatedSize = (maxHeight - totalSpacing) / count;
    double effectiveSize = calculatedSize.clamp(14.0, iconSize);

    return GestureDetector(
      onTap: () => _showAllEffectsInfo(context, displayEffects),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < displayEffects.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i < displayEffects.length - 1 ? spacing : 0,
                ),
                child: _StatusEffectIcon(
                  effect: displayEffects[i],
                  size: effectiveSize,
                  onTap: () => _showEffectInfo(context, displayEffects[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEffectInfo(BuildContext context, StatusEffect effect) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: effect.color.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Text(effect.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    effect.name,
                    style: TextStyle(
                      color: effect.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: effect.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      effect.isPositive ? 'BENEFICIAL' : 'HARMFUL',
                      style: TextStyle(
                        color: effect.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration
            _InfoRow(
              label: 'Duration',
              value: effect.durationString,
              color: Colors.white70,
            ),
            const SizedBox(height: 8),

            // Cure method
            if (effect.cureMethod != CureMethod.battleOnly)
              _InfoRow(
                label: 'Cure',
                value: effect.cureDescription ?? effect.cureMethod.label,
                color: Colors.tealAccent,
              ),
            if (effect.cureMethod != CureMethod.battleOnly)
              const SizedBox(height: 8),

            // Kill-based cure progress
            if (effect.cureMethod == CureMethod.killSpecificEnemy)
              _InfoRow(
                label: 'Progress',
                value:
                    '${effect.currentCureProgress}/${effect.requiredCureCount}',
                color: Colors.orangeAccent,
              ),
            if (effect.cureMethod == CureMethod.killSpecificEnemy)
              const SizedBox(height: 8),

            const Divider(color: Colors.white10),
            const SizedBox(height: 4),

            // Stat modifiers
            if (effect.attackModifier != 0)
              _StatModifier(label: 'ATK', value: effect.attackModifier),
            if (effect.defenseModifier != 0)
              _StatModifier(label: 'DEF', value: effect.defenseModifier),
            if (effect.critChanceModifier != 0.0)
              _StatModifier(
                label: 'CRIT',
                value: (effect.critChanceModifier * 100).round(),
                isPercent: true,
              ),
            if (effect.luckModifier != 0.0)
              _StatModifier(label: 'LUCK', value: effect.luckModifier.round()),
            if (effect.damagePerTurn > 0)
              _StatModifier(
                label: 'DoT',
                value: -effect.damagePerTurn,
                isDamage: true,
              ),
            if (effect.healPerTurn > 0)
              _StatModifier(
                label: 'HoT',
                value: effect.healPerTurn,
                isHeal: true,
              ),
            if (effect.damageTakenModifier != 1.0)
              _InfoRow(
                label: 'Dmg Taken',
                value: '${((effect.damageTakenModifier - 1.0) * 100).round()}%',
                color: Colors.redAccent,
              ),
            if (effect.lifeStealModifier != 0.0)
              _StatModifier(
                label: 'LifeSteal',
                value: effect.lifeStealModifier.round(),
              ),
            if (effect.maxHpModifier != 0)
              _StatModifier(label: 'MaxHP', value: effect.maxHpModifier),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showAllEffectsInfo(BuildContext context, List<StatusEffect> effects) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24),
        ),
        title: const Text(
          'ACTIVE EFFECTS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: effects.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (_, i) {
              final effect = effects[i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: effect.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: effect.color.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      effect.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                title: Text(
                  effect.name,
                  style: TextStyle(
                    color: effect.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  effect.durationString,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEffectInfo(context, effect);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _StatusEffectIcon extends StatelessWidget {
  final StatusEffect effect;
  final double size;
  final VoidCallback onTap;

  const _StatusEffectIcon({
    required this.effect,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: effect.color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: effect.color.withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: effect.color.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: effect.icon.length <= 2
              ? Text(effect.icon, style: TextStyle(fontSize: size * 0.5))
              : Text(effect.icon, style: TextStyle(fontSize: size * 0.5)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatModifier extends StatelessWidget {
  final String label;
  final int value;
  final bool isPercent;
  final bool isDamage;
  final bool isHeal;

  const _StatModifier({
    required this.label,
    required this.value,
    this.isPercent = false,
    this.isDamage = false,
    this.isHeal = false,
  });

  @override
  Widget build(BuildContext context) {
    final String displayValue;
    final Color color;

    if (isPercent) {
      displayValue = '${value > 0 ? "+" : ""}$value%';
      color = value >= 0 ? Colors.greenAccent : Colors.redAccent;
    } else if (isDamage) {
      displayValue = '$value/turn';
      color = Colors.redAccent;
    } else if (isHeal) {
      displayValue = '+$value/turn';
      color = Colors.greenAccent;
    } else {
      displayValue = '${value > 0 ? "+" : ""}$value';
      color = value >= 0 ? Colors.greenAccent : Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            displayValue,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
