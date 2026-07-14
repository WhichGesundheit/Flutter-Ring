import 'package:flutter/material.dart';
import 'dart:math';
import '../models/character.dart';
import '../models/damage_type.dart';
import '../models/item.dart';
import '../models/enemy.dart';
import '../widgets/game_image.dart';
import '../widgets/game_theme.dart';

class BattleScreen extends StatefulWidget {
  final Character player;
  final List<Item?> equippedSlots;
  final Enemy enemy;

  /// Whether the player is being forced into this battle by a hyper-boss
  /// (the 7-day cycle event). Used to disable the "ENGAGE" button.
  final bool isHyperBoss;

  /// Returns a list of dropped items (can be empty).
  final Function(bool won, List<Item> drops) onEnd;

  const BattleScreen({
    super.key,
    required this.player,
    required this.equippedSlots,
    required this.enemy,
    required this.onEnd,
    this.isHyperBoss = false,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  bool isFighting = false;
  bool isPaused = false;
  bool _battleFinished = false;
  bool _battleWon = false;
  List<Item> _droppedGear = [];
  List<String> logs = [];

  // Compiled stats
  int netAttack = 0;
  int netBlock = 0;
  int netLifeSteal = 0;
  int netThorns = 0;
  double netCritChance = 0.0;
  int netLuck = 0;
  Map<DamageType, int> netBonusDamage = {};
  Map<DamageType, int> netResistances = {};

  int _combatDelay = 700;
  int _speedLevel = 0;

  int _totalDamageDealt = 0;
  int _totalDamageTaken = 0;
  int _criticalHits = 0;
  int _turns = 0;

  // Boss mechanic state
  int _poisonTurns = 0;
  int _poisonDamage = 0;
  int _bossShield = 0;
  DamageType _currentBossAttackType = DamageType.physical;
  int _frozenTurns = 0;

  // Player damage type effects (inflicted on enemy)
  int _enemyBurnTurns = 0;
  int _enemyBurnDamage = 0;
  int _enemyVenomTurns = 0;
  int _enemyVenomDamage = 0;
  int _enemyFrozenTurns = 0; // Ice: enemy misses attack
  int _enemySlowTurns = 0; // Physical: enemy ATK reduced
  int _enemyWeaknessTurns = 0; // Dark: enemy takes +20% damage

  @override
  void initState() {
    super.initState();
    _compileEquipmentStats();
    _currentBossAttackType = widget.enemy.attackType;
    if (widget.isHyperBoss) {
      logs.add("🚨⚡ HYPER BOSS ENGAGED: ${widget.enemy.name}!");
      logs.add("❌ NO RETREAT — this threat must be eliminated.");
    }
    if (widget.enemy.isBoss) {
      logs.add("🚨 BOSS ENCOUNTER: ${widget.enemy.name}!");
      logs.add(
        "⚠️ Type: ${_currentBossAttackType.icon} ${_currentBossAttackType.label}",
      );
      if (widget.enemy.immunities.isNotEmpty) {
        logs.add(
          "🛡️ Immune to: ${widget.enemy.immunities.map((d) => "${d.icon}${d.label}").join(", ")}",
        );
      }
      if (widget.enemy.mechanic != BossMechanic.none) {
        logs.add("💀 Special: ${_getMechanicName(widget.enemy.mechanic)}");
      }
    } else {
      logs.add("🚨 Grid Confrontation initiated against ${widget.enemy.name}!");
      logs.add(
        "⚔️ Enemy type: ${widget.enemy.attackType.icon} ${widget.enemy.attackType.label}",
      );
    }
    // Hyper boss: auto-start the fight (no opt-in screen).
    if (widget.isHyperBoss) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !isFighting && !_battleFinished) {
          triggerAsyncAutoBattleTicker();
        }
      });
    }
  }

  String _getMechanicName(BossMechanic mechanic) {
    switch (mechanic) {
      case BossMechanic.damageReflection:
        return 'Damage Reflection (${widget.enemy.mechanicValue}%)';
      case BossMechanic.burn:
        return 'Infernal Burn (+${widget.enemy.mechanicValue}/turn)';
      case BossMechanic.freeze:
        return 'Cryo Freeze (skip every ${widget.enemy.mechanicValue} turns)';
      case BossMechanic.chainStrike:
        return 'Chain Strike (2x every other turn)';
      case BossMechanic.poison:
        return 'Viral Poison (+${widget.enemy.mechanicValue}/turn for 3 turns)';
      case BossMechanic.drainMaxHp:
        return 'Void Drain (-${widget.enemy.mechanicValue} max HP)';
      case BossMechanic.heal:
        return 'Divine Regen (heals ${widget.enemy.mechanicValue}%/turn)';
      case BossMechanic.enrage:
        return 'Shadow Enrage (2x damage below 50% HP)';
      case BossMechanic.shiftingTypes:
        return 'Chaos Shift (changes element each turn)';
      case BossMechanic.shield:
        return 'Aegis Shield (absorbs ${widget.enemy.mechanicValue} damage)';
      case BossMechanic.none:
        return 'None';
    }
  }

  void _compileEquipmentStats() {
    netAttack = widget.player.baseAttack;
    for (var item in widget.equippedSlots) {
      if (item == null) continue;
      netAttack += item.effectiveAttackBonus;
      netBlock += item.effectiveDamageReduction;
      netLifeSteal += item.effectiveLifeSteal;
      netThorns += item.effectiveThorns;
      netCritChance += item.effectiveCritChance;
      netLuck += item.effectiveLuckBonus;

      // Compile bonus damage types
      item.effectiveBonusDamage.forEach((type, value) {
        netBonusDamage[type] = (netBonusDamage[type] ?? 0) + value;
      });

      // Compile resistances
      item.effectiveFlatResistance.forEach((type, value) {
        netResistances[type] = (netResistances[type] ?? 0) + value;
      });
    }

    // Luck adds to crit chance (+1% per luck point)
    netCritChance += netLuck * 0.01;
  }

  void _toggleSpeed() {
    setState(() {
      _speedLevel = (_speedLevel + 1) % 3;
      _combatDelay = [700, 350, 150][_speedLevel];
    });
  }

  void _togglePause() {
    setState(() => isPaused = !isPaused);
  }

  /// Process damage-over-time effects on the enemy (burn, venom)
  void _processEnemyStatusEffects() {
    // Burn tick (Fire)
    if (_enemyBurnTurns > 0) {
      widget.enemy.hp -= _enemyBurnDamage;
      _totalDamageDealt += _enemyBurnDamage;
      logs.add(
        "🔥 Scorched! Enemy takes $_enemyBurnDamage burn damage (${_enemyBurnTurns - 1} turns left)",
      );
      _enemyBurnTurns--;
    }

    // Venom tick (Poison)
    if (_enemyVenomTurns > 0) {
      widget.enemy.hp -= _enemyVenomDamage;
      _totalDamageDealt += _enemyVenomDamage;
      logs.add(
        "☠️ Venom tick! Enemy takes $_enemyVenomDamage toxin damage (${_enemyVenomTurns - 1} turns left)",
      );
      _enemyVenomTurns--;
    }
  }

  /// Roll for damage type effects after player attacks
  void _rollDamageTypeEffects(int damageDealt, Random random) {
    final activeBonus = netBonusDamage.entries
        .where((e) => !widget.enemy.immunities.contains(e.key))
        .toList();

    for (final entry in activeBonus) {
      final type = entry.key;
      final bonus = entry.value;
      if (bonus <= 0) continue;

      switch (type) {
        // ── PHYSICAL: Sunder – 30% chance to weaken enemy ATK by 20% for 2 turns ──
        case DamageType.physical:
          if (random.nextDouble() < 0.30) {
            _enemySlowTurns = 2;
            logs.add(
              "⚔️ SUnder! Enemy armor cracked — ATK weakened for 2 turns!",
            );
          }
          break;

        // ── FIRE: Ignite – 30% chance to burn for bonus/2 per turn for 3 turns ──
        case DamageType.fire:
          if (random.nextDouble() < 0.30) {
            final burnDmg = (bonus * 0.5).ceil();
            // Refresh duration, keep highest damage
            _enemyBurnTurns = 3;
            if (burnDmg > _enemyBurnDamage) _enemyBurnDamage = burnDmg;
            logs.add("🔥 IGNITED! Enemy burning for $burnDmg/turn (3 turns)!");
          }
          break;

        // ── ICE: Deep Freeze – 20% chance to freeze enemy for 1 turn ──
        case DamageType.ice:
          if (random.nextDouble() < 0.20 && _enemyFrozenTurns <= 0) {
            _enemyFrozenTurns = 1;
            logs.add(
              "❄️ DEEP FREEZE! Enemy crystallized — will miss next attack!",
            );
          }
          break;

        // ── LIGHTNING: Chain Strike – 25% chance to deal bonus again ──
        case DamageType.lightning:
          if (random.nextDouble() < 0.25) {
            int chainDmg = bonus;
            if (widget.enemy.resistance[type] != null) {
              chainDmg = (bonus * (1.0 - widget.enemy.resistance[type]!))
                  .round();
            }
            widget.enemy.hp -= chainDmg;
            _totalDamageDealt += chainDmg;
            logs.add(
              "⚡ CHAIN STRIKE! Arc deals $chainDmg bonus lightning damage!",
            );
          }
          break;

        // ── POISON: Venom – 35% chance to apply DoT for 3 turns ──
        case DamageType.poison:
          if (random.nextDouble() < 0.35) {
            final venomDmg = (bonus * 0.4).ceil();
            _enemyVenomTurns = 3;
            if (venomDmg > _enemyVenomDamage) _enemyVenomDamage = venomDmg;
            logs.add(
              "☠️ TOXIC BITE! Enemy injected with venom — $venomDmg/turn (3 turns)!",
            );
          }
          break;

        // ── VOID: Rift – 20% chance to deal 2× bonus this hit ──
        case DamageType.void_:
          if (random.nextDouble() < 0.20) {
            int riftDmg = bonus;
            if (widget.enemy.resistance[type] != null) {
              riftDmg = (bonus * (1.0 - widget.enemy.resistance[type]!))
                  .round();
            }
            widget.enemy.hp -= riftDmg;
            _totalDamageDealt += riftDmg;
            logs.add(
              "🌀 RIFT TORN! Reality shatters — +$riftDmg void burst damage!",
            );
          }
          break;

        // ── HOLY: Judgment – +50% bonus vs enemies >50% HP, heals bonus×0.25 ──
        case DamageType.holy:
          if (widget.enemy.hp > widget.enemy.maxHp * 0.5) {
            int smiteDmg = (bonus * 0.5).round();
            if (widget.enemy.resistance[type] != null) {
              smiteDmg = (smiteDmg * (1.0 - widget.enemy.resistance[type]!))
                  .round();
            }
            widget.enemy.hp -= smiteDmg;
            _totalDamageDealt += smiteDmg;
            logs.add(
              "✨ JUDGMENT! Holy smite deals +$smiteDmg to the unworthy!",
            );
          }
          final healAmount = (bonus * 0.25).ceil();
          if (healAmount > 0) {
            widget.player.hp = (widget.player.hp + healAmount).clamp(
              0,
              widget.player.maxHp,
            );
            logs.add("✨ Radiance heals you for +$healAmount HP");
          }
          break;

        // ── DARK: Leech – heals 35% of bonus, 15% chance Weakness ──
        case DamageType.dark:
          final healAmount = (bonus * 0.35).ceil();
          if (healAmount > 0) {
            widget.player.hp = (widget.player.hp + healAmount).clamp(
              0,
              widget.player.maxHp,
            );
            logs.add("🌑 DARK SIPHON! Drained +$healAmount HP from the enemy!");
          }
          if (random.nextDouble() < 0.15 && _enemyWeaknessTurns <= 0) {
            _enemyWeaknessTurns = 2;
            logs.add(
              "🌑 WEAKNESS applied! Enemy deals 20% less damage for 2 turns!",
            );
          }
          break;

        default:
          break;
      }
    }
  }

  /// Calculate damage dealt to enemy, factoring in damage types and resistances
  int _calculateDamageToEnemy(int baseDamage, bool isCrit) {
    int totalDamage = baseDamage;

    // Add bonus damage from damage types (reduced by enemy resistance)
    netBonusDamage.forEach((type, value) {
      if (widget.enemy.immunities.contains(type)) return; // Immune
      final resistance = widget.enemy.resistance[type] ?? 0.0;
      final effectiveDamage = (value * (1.0 - resistance)).round();
      totalDamage += effectiveDamage;
    });

    if (isCrit) totalDamage *= 2;
    return totalDamage;
  }

  /// Calculate damage dealt to player, factoring in resistances
  int _calculateDamageToPlayer(int rawDamage) {
    int totalDamage = rawDamage;

    // Apply flat resistances based on enemy attack type
    final playerResistance = netResistances[_currentBossAttackType] ?? 0;
    totalDamage -= playerResistance;

    return totalDamage.clamp(1, rawDamage);
  }

  void _applyBossMechanicOnPlayerTurn() {
    final enemy = widget.enemy;
    if (enemy.mechanic == BossMechanic.none) return;

    switch (enemy.mechanic) {
      case BossMechanic.damageReflection:
        // Handled in damage calculation
        break;
      case BossMechanic.burn:
        // Burn is applied when enemy attacks (handled in enemy turn)
        break;
      case BossMechanic.poison:
        if (_poisonTurns > 0) {
          widget.player.hp -= _poisonDamage;
          _totalDamageTaken += _poisonDamage;
          logs.add(
            "☠️ Poison tick: -$_poisonDamage HP (${_poisonTurns - 1} turns left)",
          );
          _poisonTurns--;
        }
        break;
      case BossMechanic.heal:
        final healAmount = (enemy.maxHp * enemy.mechanicValue / 100).round();
        enemy.hp = (enemy.hp + healAmount).clamp(0, enemy.maxHp);
        logs.add("✨ Seraph heals for $healAmount HP!");
        break;
      case BossMechanic.shield:
        if (_bossShield <= 0) {
          _bossShield = enemy.mechanicValue;
          logs.add(
            "🛡️ The Architect deploys a shield! (${_bossShield} absorption)",
          );
        }
        break;
      case BossMechanic.shiftingTypes:
        final types = DamageType.values;
        _currentBossAttackType = types[Random().nextInt(types.length)];
        logs.add(
          "🌀 Chaos shifts to ${_currentBossAttackType.icon} ${_currentBossAttackType.label}!",
        );
        break;
      default:
        break;
    }
  }

  Future<void> triggerAsyncAutoBattleTicker() async {
    if (isFighting) return;
    setState(() => isFighting = true);
    final random = Random();

    while (widget.enemy.hp > 0 && widget.player.hp > 0) {
      while (isPaused && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      await Future.delayed(Duration(milliseconds: _combatDelay));
      if (!mounted) return;

      setState(() {
        _turns++;

        // ── BOSS MECHANIC: Apply pre-attack effects ──
        _applyBossMechanicOnPlayerTurn();

        // ── ENEMY STATUS EFFECTS: Burn/Venom DoT ──
        _processEnemyStatusEffects();

        // Check if enemy died from DoT
        if (widget.enemy.hp <= 0) {
          widget.enemy.hp = 0;
          logs.add("✅ Combat targets neutralized.");
          isFighting = false;
          _onBattleEnd(true);
          return;
        }

        // ── FREEZE CHECK (Boss mechanic on player) ──
        if (widget.enemy.mechanic == BossMechanic.freeze &&
            _turns % widget.enemy.mechanicValue == 0) {
          _frozenTurns = 1;
          logs.add("❄️ FROZEN! You cannot attack this turn!");
        } else {
          _frozenTurns = 0;
        }

        // ── PLAYER ATTACK ──
        if (_frozenTurns <= 0) {
          bool isCritical = random.nextDouble() < netCritChance;
          int baseDamage = netAttack;
          int activeStrikePower = _calculateDamageToEnemy(
            baseDamage,
            isCritical,
          );

          // Boss shield absorption
          if (_bossShield > 0) {
            final absorbed = min(_bossShield, activeStrikePower);
            activeStrikePower -= absorbed;
            _bossShield -= absorbed;
            logs.add(
              "🛡️ Shield absorbs $absorbed damage!${_bossShield <= 0 ? ' Shield broken!' : ''}",
            );
          }

          widget.enemy.hp -= activeStrikePower;
          _totalDamageDealt += activeStrikePower;
          if (isCritical) _criticalHits++;

          String damageTypesStr = '';
          if (netBonusDamage.isNotEmpty) {
            final activeTypes = netBonusDamage.entries
                .where((e) => !widget.enemy.immunities.contains(e.key))
                .map((e) => "${e.key.icon}${e.value}")
                .join(" ");
            if (activeTypes.isNotEmpty) damageTypesStr = " [$activeTypes]";
          }

          logs.add(
            isCritical
                ? "💥 CRITICAL STRIKE! Dealt $activeStrikePower damage!$damageTypesStr"
                : "⚔️ You strike for $activeStrikePower damage.$damageTypesStr",
          );

          // Life steal
          if (netLifeSteal > 0 && widget.enemy.hp > 0) {
            widget.player.hp = (widget.player.hp + netLifeSteal).clamp(
              0,
              widget.player.maxHp,
            );
            logs.add("🩸 Life-Steal Sync: Restored +$netLifeSteal HP");
          }

          // Boss mechanic: Damage reflection
          if (widget.enemy.mechanic == BossMechanic.damageReflection &&
              activeStrikePower > 0) {
            final reflected =
                (activeStrikePower * widget.enemy.mechanicValue / 100).round();
            if (reflected > 0) {
              widget.player.hp -= reflected;
              _totalDamageTaken += reflected;
              logs.add("🪞 Reflection: -$reflected HP back to you!");
            }
          }

          // ── DAMAGE TYPE EFFECTS: Roll for unique per-type procs ──
          if (widget.enemy.hp > 0) {
            _rollDamageTypeEffects(activeStrikePower, random);
          }
        }

        if (widget.enemy.hp <= 0) {
          widget.enemy.hp = 0;
          logs.add("✅ Combat targets neutralized.");
          isFighting = false;
          _onBattleEnd(true);
          return;
        }

        // ── ENEMY ATTACK ──
        if (_enemyFrozenTurns > 0) {
          logs.add(
            "❄️ Enemy is FROZEN and cannot attack! (${_enemyFrozenTurns - 1} turns left)",
          );
          _enemyFrozenTurns--;
        } else {
          int rawEnemyAttack = widget.enemy.attack;

          // Apply Physical Sunder slow
          if (_enemySlowTurns > 0) {
            rawEnemyAttack = (rawEnemyAttack * 0.8).round();
            logs.add(
              "⚔️ Sunder active — enemy ATK reduced (${_enemySlowTurns - 1} turns left)",
            );
            _enemySlowTurns--;
          }

          // Apply Dark Weakness
          if (_enemyWeaknessTurns > 0) {
            rawEnemyAttack = (rawEnemyAttack * 0.8).round();
            logs.add(
              "🌑 Weakness active — enemy deals 20% less (${_enemyWeaknessTurns - 1} turns left)",
            );
            _enemyWeaknessTurns--;
          }

          int computedDamageToPlayer = _calculateDamageToPlayer(rawEnemyAttack);
          widget.player.hp -= computedDamageToPlayer;
          _totalDamageTaken += computedDamageToPlayer;
          logs.add(
            "🛡️ ${_currentBossAttackType.icon} Enemy attacks for $computedDamageToPlayer (${_currentBossAttackType.label}).",
          );
        }

        // Boss mechanic: Burn
        if (widget.enemy.mechanic == BossMechanic.burn) {
          widget.player.hp -= widget.enemy.mechanicValue;
          _totalDamageTaken += widget.enemy.mechanicValue;
          logs.add("🔥 Burn damage: -${widget.enemy.mechanicValue} HP");
        }

        // Boss mechanic: Chain Strike
        if (widget.enemy.mechanic == BossMechanic.chainStrike &&
            _turns % 2 == 0) {
          int chainDamage = _calculateDamageToPlayer(widget.enemy.attack);
          widget.player.hp -= chainDamage;
          _totalDamageTaken += chainDamage;
          logs.add("⚡ Chain Strike: -${chainDamage} additional damage!");
        }

        // Boss mechanic: Poison
        if (widget.enemy.mechanic == BossMechanic.poison && _turns == 1) {
          _poisonTurns = 3;
          _poisonDamage = widget.enemy.mechanicValue;
          logs.add(
            "☠️ You have been poisoned! -${_poisonDamage}/turn for 3 turns",
          );
        }

        // Boss mechanic: Drain Max HP
        if (widget.enemy.mechanic == BossMechanic.drainMaxHp) {
          widget.player.maxHp =
              (widget.player.maxHp - widget.enemy.mechanicValue).clamp(1, 999);
          logs.add("💀 Max HP drained! Now: ${widget.player.maxHp}");
        }

        // Boss mechanic: Enrage (double damage below 50%)
        if (widget.enemy.mechanic == BossMechanic.enrage &&
            widget.player.hp < widget.player.maxHp ~/ 2 &&
            _turns > 1) {
          int extraDamage = _calculateDamageToPlayer(widget.enemy.attack);
          widget.player.hp -= extraDamage;
          _totalDamageTaken += extraDamage;
          logs.add("😡 ENRAGE! Shadow Lord strikes again for $extraDamage!");
        }

        // Thorns
        if (netThorns > 0) {
          widget.enemy.hp -= netThorns;
          _totalDamageDealt += netThorns;
          logs.add("🌵 Thorns Matrix: Reflected $netThorns damage.");
        }

        // Check if enemy died from thorns
        if (widget.enemy.hp <= 0) {
          widget.enemy.hp = 0;
          logs.add("✅ Combat targets neutralized.");
          isFighting = false;
          _onBattleEnd(true);
          return;
        }

        // Auto-use consumables
        for (int i = 0; i < widget.equippedSlots.length; i++) {
          final item = widget.equippedSlots[i];
          if (item != null && item.isConsumable) {
            double currentHpPercent = widget.player.hp / widget.player.maxHp;
            double threshold = item.hpThreshold > 0 ? item.hpThreshold : 0.99;
            if (currentHpPercent < threshold) {
              int actualHeal = item.effectiveHealAmount;
              widget.player.hp = (widget.player.hp + actualHeal).clamp(
                0,
                widget.player.maxHp,
              );
              logs.add("🧪 AUTO-USE: ${item.name} used! +$actualHeal HP.");
              widget.equippedSlots[i] = null;
              _compileEquipmentStats();
              break;
            }
          }
        }

        if (widget.player.hp <= 0) {
          widget.player.hp = 0;
          logs.add("❌ System failure. Shutting down.");
          isFighting = false;
          _onBattleEnd(false);
        }
      });
    }

    // Safety: if we exited the loop and battle isn't finished, check if enemy is dead
    if (!_battleFinished && widget.enemy.hp <= 0) {
      widget.enemy.hp = 0;
      _onBattleEnd(true);
    }
  }

  /// Compute the loot drops for the just-defeated enemy.
  /// - For BOSS (non-hyper) enemies: drop ALL items in `potentialLoot`
  ///   (guaranteed full-pool drop).
  /// - For HYPER bosses: drop everything in `potentialLoot` (already
  ///   pre-populated with the hyper-specific legendary + extras).
  /// - For regular enemies: roll once, and if the roll returns null
  ///   (no drop), fall back to the first item from the loot pool so the
  ///   enemy always gives at least one item.
  List<Item> _computeDrops() {
    final pool = widget.enemy.potentialLoot;
    if (pool.isEmpty) return const [];
    if (widget.enemy.isBoss) {
      return List<Item>.from(pool);
    }
    // Luck increases drop chance by 2% per luck point
    final luckModifier = netLuck * 0.02;
    final rolled = Item.rollDrop(pool, luckModifier: luckModifier);
    if (rolled != null) return [rolled];
    return [pool.first];
  }

  void _onBattleEnd(bool won) {
    final drops = won ? _computeDrops() : <Item>[];

    setState(() {
      _battleFinished = true;
      _battleWon = won;
      _droppedGear = drops;
      if (won) {
        widget.player.credits += widget.enemy.goldReward;
      }
    });

    _showSummaryPopup(won, drops);
  }

  Color _rarityColor(Rarity r) {
    switch (r) {
      case Rarity.common:
        return Colors.grey;
      case Rarity.premium:
        return Colors.tealAccent;
      case Rarity.unique:
        return Colors.deepPurpleAccent;
      case Rarity.legendary:
        return Colors.amberAccent;
    }
  }

  void _showSummaryPopup(bool won, List<Item> drops) {
    final StringBuffer summary = StringBuffer();
    summary.write(won ? 'Victory!' : 'Defeated.');
    if (won) {
      summary.write('\n+${widget.enemy.goldReward} Credits');
      for (final d in drops) {
        summary.write('\n🎁 ${d.name} [${d.rarity.label.toUpperCase()}]');
      }
    }
    summary.write('\n\n📊 Turns: $_turns  |  Dealt: $_totalDamageDealt');
    summary.write('\n   Taken: $_totalDamageTaken  |  Crits: $_criticalHits');
    if (netLuck > 0) {
      summary.write('\n🍀 Luck: $netLuck');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: won
                ? GameColors.success.withValues(alpha: 0.5)
                : GameColors.danger.withValues(alpha: 0.5),
          ),
        ),
        title: Row(
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.error_outline,
              color: won ? GameColors.success : GameColors.danger,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                won
                    ? (widget.isHyperBoss
                          ? 'HYPER THREAT RESOLVED'
                          : 'THREAT RESOLVED')
                    : 'SYSTEM FAILURE',
                style: TextStyle(
                  color: won ? GameColors.success : GameColors.danger,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
            children: _buildSummarySpans(drops, won),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? GameColors.success : GameColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                "CONTINUE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildSummarySpans(List<Item> drops, bool won) {
    final List<TextSpan> spans = [];
    spans.add(
      TextSpan(
        text: won ? 'Victory!\n' : 'Defeated.\n',
        style: TextStyle(
          color: won ? GameColors.success : GameColors.danger,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    if (won) {
      spans.add(
        TextSpan(
          text: '+${widget.enemy.goldReward} Credits\n',
          style: const TextStyle(color: Colors.amberAccent),
        ),
      );
      for (final d in drops) {
        final color = _rarityColor(d.rarity);
        spans.add(
          TextSpan(
            text: '🎁 ${d.name} ',
            style: const TextStyle(color: Colors.white70),
          ),
        );
        spans.add(
          TextSpan(
            text: '[${d.rarity.label.toUpperCase()}]\n',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        );
      }
    }
    spans.add(
      TextSpan(
        text:
            '\n📊 Turns: $_turns  |  Dealt: $_totalDamageDealt\n'
            '   Taken: $_totalDamageTaken  |  Crits: $_criticalHits',
        style: const TextStyle(color: Colors.white70),
      ),
    );
    if (netLuck > 0) {
      spans.add(
        TextSpan(
          text: '\n🍀 Luck: $netLuck',
          style: const TextStyle(color: Colors.lightGreen),
        ),
      );
    }
    return spans;
  }

  void _exitBattle() {
    if (_battleWon) {
      widget.onEnd(true, _droppedGear);
    } else {
      widget.onEnd(false, const []);
    }
  }

  String get _speedLabel => ['1×', '2×', '4×'][_speedLevel];
  IconData get _speedIcon =>
      [Icons.play_arrow, Icons.fast_forward, Icons.bolt][_speedLevel];

  Widget _buildBottomButton() {
    if (_battleFinished) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _battleWon
                ? GameColors.success
                : GameColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          onPressed: _exitBattle,
          icon: Icon(_battleWon ? Icons.check_circle : Icons.arrow_back),
          label: Text(
            _battleWon ? "EXTRACT LOOT" : "RETREAT",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }
    if (!isFighting) {
      // Hyper bosses auto-start the fight, so no manual button is shown.
      final label = widget.isHyperBoss
          ? "ENGAGING HYPER BOSS…"
          : (widget.enemy.isBoss ? "ENGAGE BOSS" : "INITIALIZE COMBAT");
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isHyperBoss
                ? Colors.deepOrange
                : (widget.enemy.isBoss ? GameColors.gold : GameColors.primary),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          onPressed: widget.isHyperBoss ? null : triggerAsyncAutoBattleTicker,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: widget.isHyperBoss
                ? Colors.deepOrange
                : (widget.enemy.isBoss ? GameColors.gold : GameColors.primary),
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isPaused ? "PAUSED" : "COMBAT IN PROGRESS...",
          style: TextStyle(
            color: isPaused
                ? GameColors.warning
                : (widget.isHyperBoss
                      ? Colors.deepOrangeAccent
                      : (widget.enemy.isBoss
                            ? GameColors.gold
                            : GameColors.primary)),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDamageTypeRow() {
    if (netBonusDamage.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 12,
            ),
            const SizedBox(width: 4),
            ...netBonusDamage.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Tooltip(
                  message: '${e.key.label}: ${e.key.effectDescription}',
                  child: Text(
                    "${e.key.icon}${e.value}",
                    style: TextStyle(
                      color: e.key.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResistanceRow() {
    if (netResistances.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, color: Colors.cyan, size: 12),
            const SizedBox(width: 4),
            ...netResistances.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  "${e.key.icon}${e.value}",
                  style: TextStyle(
                    color: e.key.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        backgroundColor: widget.isHyperBoss
            ? Colors.deepOrange
            : GameColors.surface,
        title: Text(
          _battleFinished
              ? (_battleWon ? "Victory" : "Defeated")
              : "vs ${widget.enemy.name}",
        ),
        leading: _battleFinished
            ? IconButton(
                onPressed: _exitBattle,
                icon: const Icon(Icons.arrow_back_ios_new),
                tooltip: 'Back to Base',
              )
            : null,
        actions: [
          if (!_battleFinished)
            IconButton(
              onPressed: isFighting ? _toggleSpeed : null,
              icon: Icon(_speedIcon, color: GameColors.accent),
              tooltip: 'Speed: $_speedLabel',
            ),
          if (isFighting && !_battleFinished)
            IconButton(
              onPressed: _togglePause,
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: isPaused ? GameColors.success : GameColors.warning,
              ),
              tooltip: isPaused ? 'Resume' : 'Pause',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isHyperBoss)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                color: Colors.deepOrange.withValues(alpha: 0.25),
                child: const Text(
                  '⚡ HYPER BOSS — NO RETREAT ⚡',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
            // ── COMBATANT DISPLAY ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GameImage(
                          imagePath: widget.player.imagePath,
                          fallbackIcon: Icons.person,
                          size: 48,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.player.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        HpBar(
                          current: widget.player.hp,
                          max: widget.player.maxHp,
                          height: 8,
                          showNumbers: true,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isHyperBoss
                          ? Colors.deepOrange.withValues(alpha: 0.15)
                          : (widget.enemy.isBoss
                                ? GameColors.gold.withValues(alpha: 0.15)
                                : GameColors.primary.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isHyperBoss
                            ? Colors.deepOrange.withValues(alpha: 0.6)
                            : (widget.enemy.isBoss
                                  ? GameColors.gold.withValues(alpha: 0.4)
                                  : GameColors.primary.withValues(alpha: 0.4)),
                      ),
                    ),
                    child: Text(
                      widget.isHyperBoss
                          ? "HYPER"
                          : (widget.enemy.isBoss ? "BOSS" : "VS"),
                      style: TextStyle(
                        fontSize: 18,
                        color: widget.isHyperBoss
                            ? Colors.deepOrangeAccent
                            : (widget.enemy.isBoss
                                  ? GameColors.gold
                                  : GameColors.primary),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GameImage(
                          imagePath: widget.enemy.imagePath,
                          fallbackIcon: widget.enemy.isBoss
                              ? Icons.psychology
                              : Icons.adb,
                          size: 48,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.enemy.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.isHyperBoss
                                ? Colors.deepOrangeAccent
                                : (widget.enemy.isBoss
                                      ? GameColors.gold
                                      : null),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        HpBar(
                          current: widget.enemy.hp,
                          max: widget.enemy.maxHp,
                          height: 8,
                          showNumbers: true,
                        ),
                        if (widget.enemy.isBoss &&
                            widget.enemy.mechanic != BossMechanic.none)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _getMechanicName(widget.enemy.mechanic),
                              style: TextStyle(
                                color: GameColors.warning,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── STAT SUMMARY ──
            if (isFighting || _battleFinished)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: GameColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat(
                        Icons.flash_on,
                        '$netAttack',
                        'ATK',
                        GameColors.primary,
                      ),
                      _miniStat(
                        Icons.shield,
                        '$netBlock',
                        'DEF',
                        GameColors.accent,
                      ),
                      _miniStat(
                        Icons.bolt,
                        '${(netCritChance * 100).toInt()}%',
                        'CRIT',
                        GameColors.gold,
                      ),
                      if (_battleFinished)
                        _miniStat(
                          Icons.compare_arrows,
                          '$_turns',
                          'TURNS',
                          Colors.white70,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),

            // ── DAMAGE TYPES & RESISTANCES ──
            if (isFighting || _battleFinished) ...[
              _buildDamageTypeRow(),
              const SizedBox(height: 2),
              _buildResistanceRow(),
              const SizedBox(height: 4),
            ],

            // ── BATTLE LOG ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GameColors.border),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: logs.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        logs[i],
                        style: TextStyle(
                          color: logs[i].contains('💥')
                              ? GameColors.gold
                              : logs[i].contains('✅')
                              ? GameColors.success
                              : logs[i].contains('🧪')
                              ? GameColors.accent
                              : logs[i].contains('❌')
                              ? GameColors.danger
                              : logs[i].contains('🔥')
                              ? Colors.orangeAccent
                              : logs[i].contains('❄️')
                              ? Colors.cyanAccent
                              : logs[i].contains('☠️')
                              ? Colors.lightGreen
                              : logs[i].contains('💀')
                              ? Colors.deepPurpleAccent
                              : logs[i].contains('✨')
                              ? Colors.yellowAccent
                              : logs[i].contains('🌀')
                              ? Colors.purpleAccent
                              : Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── BOTTOM BUTTON ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBottomButton(),
            ),
          ],
        ),
      ),
    );
  }
}
