import 'dart:math';

import 'zone.dart';
import 'status_effect.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// RANDOM EVENTS – Triggered during travel between nodes
/// ═══════════════════════════════════════════════════════════════════════════════

/// Types of stats that can be checked
enum StatType { attack, luck, defense, hp }

/// A stat requirement for a choice
class StatCheck {
  final StatType statType;
  final int threshold;
  const StatCheck({required this.statType, required this.threshold});

  String get label {
    switch (statType) {
      case StatType.attack:
        return 'ATK';
      case StatType.luck:
        return 'LCK';
      case StatType.defense:
        return 'DEF';
      case StatType.hp:
        return 'HP';
    }
  }

  String get icon {
    switch (statType) {
      case StatType.attack:
        return '⚔️';
      case StatType.luck:
        return '🍀';
      case StatType.defense:
        return '🛡️';
      case StatType.hp:
        return '❤️';
    }
  }
}

/// Types of effects an event outcome can have
enum EventEffectType {
  goldChange,
  hpChange,
  maxHpChange,
  statusApply,
  statusCure,
  itemGain,
  statBoost,
  damageResistance,
}

/// A single effect applied by an event outcome
class EventEffect {
  final EventEffectType type;
  final int value;
  final StatusEffectType? statusEffect;
  final String? description;

  const EventEffect({
    required this.type,
    this.value = 0,
    this.statusEffect,
    this.description,
  });
}

/// A possible outcome from a choice
class EventOutcome {
  final double weight;
  final String resultTitle;
  final String resultArt;
  final String resultDescription;
  final List<EventEffect> effects;

  const EventOutcome({
    required this.weight,
    required this.resultTitle,
    this.resultArt = '❓',
    required this.resultDescription,
    this.effects = const [],
  });
}

/// A choice the player can make
class EventChoice {
  final String text;
  final List<EventOutcome> possibleOutcomes;
  final List<EventOutcome>? failureOutcomes;
  final StatCheck? statCheck;

  const EventChoice({
    required this.text,
    required this.possibleOutcomes,
    this.failureOutcomes,
    this.statCheck,
  });
}

/// A random event that can appear during travel
class RandomEvent {
  final String id;
  final String title;
  final String artPlaceholder;
  final String flavorText;
  final List<EventChoice> choices;
  final double spawnWeight;
  final int minDay;
  final List<ZoneType>? zoneRestrictions;

  const RandomEvent({
    required this.id,
    required this.title,
    this.artPlaceholder = '❓',
    required this.flavorText,
    required this.choices,
    this.spawnWeight = 1.0,
    this.minDay = 0,
    this.zoneRestrictions,
  });
}

/// Result of a D&D-style dice roll for a stat check.
class DiceRollResult {
  final EventOutcome outcome;
  final bool passed;
  final int d20;
  final int statModifier;
  final int luckModifier;
  final int totalRoll;
  final int dc;
  final StatType? statType;

  const DiceRollResult({
    required this.outcome,
    required this.passed,
    required this.d20,
    required this.statModifier,
    required this.luckModifier,
    required this.totalRoll,
    required this.dc,
    this.statType,
  });

  String get statLabel {
    switch (statType) {
      case StatType.attack:
        return 'ATK';
      case StatType.luck:
        return 'LCK';
      case StatType.defense:
        return 'DEF';
      case StatType.hp:
        return 'HP';
      case null:
        return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EVENT POOL – 20 unique events with stat checks and varying choices
// ═══════════════════════════════════════════════════════════════════════════════

class EventPool {
  static final Random _random = Random();

  static final List<RandomEvent> allEvents = [
    // ═══════════════════════════════════════════════════════════════════
    // EVENT POOL – 45 unique events with stat checks and varying choices
    // ═══════════════════════════════════════════════════════════════════

    // ── 1. THE ABANDONED TERMINAL ──
    RandomEvent(
      id: 'abandoned_terminal',
      title: 'The Abandoned Terminal',
      artPlaceholder: '💻',
      flavorText:
          'A glowing terminal hums with residual power, its screen flickering '
          'with cryptic symbols. Data streams cascade across the display.',
      spawnWeight: 1.2,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔌 Jack into the terminal',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Surge!',
              resultArt: '⚡',
              resultDescription:
                  'A torrent of data floods your neural interface. You extract '
                  'a piece of valuable equipment from the memory banks.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Viral Trap!',
              resultArt: '☠️',
              resultDescription:
                  'The terminal was a trap! Corrupted code floods your systems, '
                  'infecting your core with a persistent virus.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Salvage parts',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Salvaged!',
              resultArt: '🔩',
              resultDescription:
                  'You carefully extract useful components from the terminal. '
                  'The parts fetch a decent price.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave it alone',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe and Sound',
              resultArt: '✅',
              resultDescription:
                  'You wisely decide not to risk it. Some things are best left alone.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 2. DATA STORM ──
    RandomEvent(
      id: 'data_storm',
      title: 'Data Storm',
      artPlaceholder: '🌪️',
      flavorText:
          'Electrical storms of pure interference gather on the horizon. '
          'Lightning arcs between corrupted data clouds.',
      spawnWeight: 1.1,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🛡️ Brace for impact',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Endured!',
              resultArt: '💪',
              resultDescription:
                  'The storm hits hard but you withstand it. The raw energy '
                  'charges your systems, leaving you empowered.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overwhelmed!',
              resultArt: '💥',
              resultDescription:
                  'Your defenses crumble under the storm\'s assault. Raw voltage '
                  'courses through every circuit, causing severe damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -25),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏠 Find shelter',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Sheltered',
              resultArt: '🏠',
              resultDescription:
                  'You find a safe alcove and wait out the storm. You emerge unscathed.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '⚡ Ride the lightning',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lightning Rider!',
              resultArt: '⚡',
              resultDescription:
                  'Incredible! You channel the storm\'s energy, achieving '
                  'unprecedented speed and reflexes.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.hasted,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overloaded!',
              resultArt: '💥',
              resultDescription:
                  'The storm overwhelms your systems, causing severe damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -25),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 3. TOXIC SPILL ──
    RandomEvent(
      id: 'toxic_spill',
      title: 'Toxic Spill',
      artPlaceholder: '☢️',
      flavorText:
          'Pools of corrupted data ooze across the path ahead. The toxic '
          'substance bubbles and hisses, releasing noxious fumes.',
      spawnWeight: 1.1,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🏊 Wade through',
          statCheck: StatCheck(statType: StatType.defense, threshold: 4),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Resistant!',
              resultArt: '🛡️',
              resultDescription:
                  'Your reinforced plating shrugs off the worst of the toxins. '
                  'You find a useful item half-buried in the muck.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Contaminated!',
              resultArt: '☠️',
              resultDescription:
                  'The chemicals eat at your systems, leaving you poisoned.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔄 Go around',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Detour',
              resultArt: '🔄',
              resultDescription: 'You take the long way around but stay safe.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '🧪 Collect samples',
          statCheck: StatCheck(statType: StatType.luck, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Samples Collected!',
              resultArt: '🔰',
              resultDescription:
                  'Analysis reveals compounds that boost your damage resistance.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.resistanceBoost,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Toxic Exposure!',
              resultArt: '☢️',
              resultDescription:
                  'The samples contaminate your systems. You feel vulnerable.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 4. THE LOST DRONE ──
    RandomEvent(
      id: 'lost_drone',
      title: 'The Lost Drone',
      artPlaceholder: '🤖',
      flavorText:
          'A small maintenance drone hovers in place, its rotors spinning '
          'weakly. Its single optical sensor tracks you with desperate hope.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔧 Try to fix it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 4),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'A Friend Made',
              resultArt: '🤖',
              resultDescription:
                  'The drone whirs back to life and drops a component before zipping away.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Malfunction!',
              resultArt: '💥',
              resultDescription:
                  'The drone short-circuits and explodes, showering you with shrapnel.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '👋 Wave goodbye',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lonely Farewell',
              resultArt: '👋',
              resultDescription:
                  'You wave at the drone as you pass. Its sensor dims in acknowledgment.',
            ),
          ],
        ),
      ],
    ),

    // ── 5. THE OLD GRAFFITI ──
    RandomEvent(
      id: 'old_graffiti',
      title: 'The Old Graffiti',
      artPlaceholder: '🎨',
      flavorText:
          'Scratched into the wall of a data-tunnel, you find elaborate graffiti. '
          'A stylized skull with circuit-board patterns stares back at you.',
      spawnWeight: 1.1,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔍 Examine closely',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Hidden Message!',
              resultArt: '🗝️',
              resultDescription:
                  'Behind the graffiti, you find a hidden compartment with a '
                  'data-chip containing valuable coordinates.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Echoes of Runners Past',
              resultArt: '🖌️',
              resultDescription:
                  'You recognize the mark of "Phantom", a legendary runner who '
                  'vanished years ago. Their message: "The Abyss remembers."',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '📸 Take a mental snapshot',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Memory Archived',
              resultArt: '📸',
              resultDescription:
                  'You commit the image to memory. Street art in the Ring is rare.',
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // MID-EARLY GAME (minDay 1)
    // ═══════════════════════════════════════════════════════════════════

    // ── 6. WANDERING MERCHANT'S CORPSE ──
    RandomEvent(
      id: 'merchant_corpse',
      title: 'Wandering Merchant\'s Corpse',
      artPlaceholder: '💀',
      flavorText:
          'The remains of a traveling merchant lie slumped against a rusted wall. '
          'Their pack bulges with goods, but an eerie aura surrounds the body.',
      spawnWeight: 1.0,
      minDay: 1,
      choices: [
        EventChoice(
          text: '🎒 Take everything',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Jackpot!',
              resultArt: '💰',
              resultDescription:
                  'You deftly grab the goods without triggering the ward. Premium equipment and credits!',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 60),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cursed Loot!',
              resultArt: '🔮',
              resultDescription:
                  'A dark energy transfers to you. The merchant\'s curse rests upon your shoulders.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💰 Take only credits',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Find!',
              resultArt: '💰',
              resultDescription:
                  'You carefully extract the credits. A respectful and safe approach.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🙏 Leave a prayer',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Blessed!',
              resultArt: '✨',
              resultDescription:
                  'Your respect earns you a blessing. Lady luck smiles upon you.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 7. CORRUPTED COMPANION ──
    RandomEvent(
      id: 'corrupted_companion',
      title: 'Corrupted Companion',
      artPlaceholder: '🤖',
      flavorText:
          'A friendly NPC stumbles toward you, their eyes flickering with '
          'malicious code. They beg for help, gripping a weapon.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Fight the corruption',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Subdued!',
              resultArt: '⚔️',
              resultDescription:
                  'You overpower the corrupted companion. Grateful, they share their supplies.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ambushed!',
              resultArt: '🩸',
              resultDescription:
                  'The corrupted companion is too strong! Their attack tears through your defenses.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💊 Try to cure them',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cured!',
              resultArt: '💚',
              resultDescription:
                  'Your supplies purge the corruption. The companion shares their gear.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -20),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Failed Cure!',
              resultArt: '☠️',
              resultDescription:
                  'Your treatment fails and the companion lashes out.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Avoid them',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Avoided',
              resultArt: '🏃',
              resultDescription: 'You slip past, avoiding danger.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 8. GHOST SIGNAL ──
    RandomEvent(
      id: 'ghost_signal',
      title: 'Ghost Signal',
      artPlaceholder: '📡',
      flavorText:
          'A strange transmission crackles through your neural interface. '
          'The signal carries fragments of ancient code and promises of power.',
      spawnWeight: 0.8,
      minDay: 1,
      choices: [
        EventChoice(
          text: '📞 Answer the call',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Power Surge!',
              resultArt: '💪',
              resultDescription:
                  'The signal channels raw power into your systems. Your attack increases.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 3,
                  description: '+3 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Mind Corruption!',
              resultArt: '🌀',
              resultDescription:
                  'The signal was a virus! It causes madness that distorts your perception.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.madness,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚫 Block frequency',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Signal Blocked!',
              resultArt: '🛡️',
              resultDescription:
                  'You block the frequency and set up a defensive protocol.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Signal Overload!',
              resultArt: '💥',
              resultDescription:
                  'The signal overwhelms your blockers. Your systems take damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📊 Record and analyze',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Analyzed!',
              resultArt: '💰',
              resultDescription:
                  'You find valuable data fragments that can be sold.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 9. THE GAMBLER'S DEAL ──
    RandomEvent(
      id: 'gambler_deal',
      title: 'The Gambler\'s Deal',
      artPlaceholder: '🃏',
      flavorText:
          'A mysterious figure in a tattered coat approaches you. '
          '"Fancy a wager?" they whisper, producing a deck of shimmering cards.',
      spawnWeight: 1.0,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💰 Bet 50 credits',
          statCheck: StatCheck(statType: StatType.luck, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Winner!',
              resultArt: '💰',
              resultDescription:
                  'Your hand is lucky! The gambler reluctantly pays triple your bet.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 150),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Loser!',
              resultArt: '😢',
              resultDescription:
                  'The gambler\'s smile widens as they collect your credits.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -50),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '❤️ Bet HP',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Empowered!',
              resultArt: '💪',
              resultDescription:
                  'You win the wager! The gambler infuses you with power.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Weakened!',
              resultArt: '⬇️',
              resultDescription:
                  'You lose the bet. The gambler siphons your strength.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.weakened,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚫 Decline politely',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lucky Refusal!',
              resultArt: '🍀',
              resultDescription:
                  '"Your caution is its own reward." You feel unusually lucky.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 10. STRANGE CACHE ──
    RandomEvent(
      id: 'strange_cache',
      title: 'Strange Cache',
      artPlaceholder: '📦',
      flavorText:
          'A locked storage container sits half-buried in debris. Its surface '
          'is covered in warning symbols, but something valuable glints inside.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💪 Force it open',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cache Opened!',
              resultArt: '📦',
              resultDescription:
                  'You crack the lock and find premium equipment inside.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Security Trap!',
              resultArt: '🩸',
              resultDescription:
                  'The cache has a security system! Lasers slice through your armor.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔐 Pick the lock',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lock Picked!',
              resultArt: '🔓',
              resultDescription:
                  'Your careful work pays off. The cache contains useful supplies.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Tumblers Broken!',
              resultArt: '💔',
              resultDescription:
                  'Your tools break and the cache seals permanently. What a waste.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '📝 Map the location',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Location Noted!',
              resultArt: '🗺️',
              resultDescription:
                  'You document the cache for later. Your knowledge improves.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // MID-GAME (minDay 2)
    // ═══════════════════════════════════════════════════════════════════

    // ── 11. MYSTERIOUS SHRINE ──
    RandomEvent(
      id: 'mysterious_shrine',
      title: 'Mysterious Shrine',
      artPlaceholder: '⛩️',
      flavorText:
          'A glowing altar pulsates with ancient energy. Strange symbols '
          'shift and change when you\'re not looking directly at them.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💎 Offer 50 credits',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shrine Empowered!',
              resultArt: '🌟',
              resultDescription:
                  'The shrine pulses with brilliant light. You feel a surge of strength.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -50),
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 2,
                  description: '+2 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shrine Rejected!',
              resultArt: '🚫',
              resultDescription:
                  'The shrine rejects your offering. Dark energy lashes out.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -50),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🩸 Offer HP',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Blood Offering!',
              resultArt: '💚',
              resultDescription:
                  'The shrine draws your life force but rewards you with regenerative nanites.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.regeneration,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Walk away',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Unchanged',
              resultArt: '❓',
              resultDescription: 'You decide the risk isn\'t worth it.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 12. THE VOID ECHO ──
    RandomEvent(
      id: 'void_echo',
      title: 'The Void Echo',
      artPlaceholder: '🌀',
      flavorText:
          'A ripple in reality bends the air before you. Something speaks '
          'from beyond the threshold, its voice both everywhere and nowhere.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '🌀 Embrace the void',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Void Touched!',
              resultArt: '🌀',
              resultDescription:
                  'The void energy flows through you, granting terrible power.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Void Madness!',
              resultArt: '😵',
              resultDescription:
                  'The void overwhelms your mind. Reality fractures around you.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.madness,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Shield yourself',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Warded!',
              resultArt: '🛡️',
              resultDescription:
                  'Your shields deflect the void energy. You feel strengthened.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shield Breached!',
              resultArt: '💥',
              resultDescription: 'The void tears through your defenses.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -22),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📊 Analyze the rift',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Extracted!',
              resultArt: '💰',
              resultDescription:
                  'You extract valuable void data before the rift closes.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Corrupted!',
              resultArt: '🟣',
              resultDescription: 'The void data corrupts your systems.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Flee immediately',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Escaped!',
              resultArt: '🏃',
              resultDescription: 'You run before the rift can affect you.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 13. ROGUE TURRET ──
    RandomEvent(
      id: 'rogue_turret',
      title: 'Rogue Turret',
      artPlaceholder: '🔫',
      flavorText:
          'An automated defense turret swivels to track you. Its targeting '
          'laser paints a red dot on your chest. Warning klaxons blare.',
      spawnWeight: 0.9,
      minDay: 2,
      choices: [
        EventChoice(
          text: '🔧 Disable it',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Turret Disabled!',
              resultArt: '🔧',
              resultDescription:
                  'You find the access panel and shut down the turret. Inside: useful parts.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shot!',
              resultArt: '🩸',
              resultDescription:
                  'The turret fires before you can reach it. Plasma burns through your armor.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💻 Hack the control',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Hijacked!',
              resultArt: '💻',
              resultDescription:
                  'You take control of the turret and access its supply cache.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 55),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lockout!',
              resultArt: '🚫',
              resultDescription: 'The turret locks you out and opens fire.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🎯 Distract and bypass',
          statCheck: StatCheck(statType: StatType.luck, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bypassed!',
              resultArt: '🏃',
              resultDescription:
                  'You throw a decoy and slip past while the turret is confused.',
              effects: [],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Tagged!',
              resultArt: '🎯',
              resultDescription:
                  'The turret sees through your trick and tags you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 14. THE WANDERING TRADER ──
    RandomEvent(
      id: 'wandering_trader',
      title: 'The Wandering Trader',
      artPlaceholder: '🧳',
      flavorText:
          'A heavily-laden trader approaches cautiously. Their cart is piled '
          'with goods, and their eyes dart nervously across the landscape.',
      spawnWeight: 0.9,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💰 Trade 40 credits',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rare Find!',
              resultArt: '💎',
              resultDescription:
                  'The trader reveals a rare item from beneath a hidden compartment.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -40),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ripoff!',
              resultArt: '😤',
              resultDescription:
                  'The trader sells you a worthless piece of junk.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -40),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Rob the trader',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Robbery!',
              resultArt: '💰',
              resultDescription:
                  'The trader surrenders their best goods under threat.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Fight Back!',
              resultArt: '🩸',
              resultDescription:
                  'The trader is an ex-soldier! They fight back and wound you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💬 Chat peacefully',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Friendly Exchange',
              resultArt: '💬',
              resultDescription:
                  'The trader shares useful information about the area.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 15),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 15. DATA BLOOM ──
    RandomEvent(
      id: 'data_bloom',
      title: 'Data Bloom',
      artPlaceholder: '🌸',
      flavorText:
          'A cluster of data-flowers has bloomed from a corrupted server node. '
          'Their petals shimmer with encoded information.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '🌸 Harvest the bloom',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Harvested!',
              resultArt: '🌸',
              resultDescription:
                  'You carefully extract the data-flowers. They contain valuable equipment.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Thorned!',
              resultArt: '☠️',
              resultDescription:
                  'The flowers\' thorns inject toxic data into your systems.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📖 Study the data',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Knowledge Gained!',
              resultArt: '📖',
              resultDescription:
                  'Studying the bloom teaches you defensive techniques.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 2,
                  description: '+2 DEF (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Overload!',
              resultArt: '💥',
              resultDescription:
                  'The information floods your systems, leaving you vulnerable.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Left Alone',
              resultArt: '🚶',
              resultDescription: 'Some things are best left undisturbed.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // LATE GAME (minDay 3+)
    // ═══════════════════════════════════════════════════════════════════

    // ── 16. FORGOTTEN ARMORY ──
    RandomEvent(
      id: 'forgotten_armory',
      title: 'Forgotten Armory',
      artPlaceholder: '⚔️',
      flavorText:
          'Hidden behind a collapsed wall, you discover an ancient armory. '
          'Weapons hang on rusted racks, some still gleaming with enchantment.',
      spawnWeight: 0.6,
      minDay: 3,
      choices: [
        EventChoice(
          text: '⚔️ Take the best weapon',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Legendary Find!',
              resultArt: '👑',
              resultDescription:
                  'You claim a powerful weapon. The armory\'s defenses don\'t even trigger.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Defense Systems!',
              resultArt: '🩸',
              resultDescription:
                  'The armory\'s defense systems activate! Lasers slice through you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -22),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🧪 Take supplies',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Supplies Found!',
              resultArt: '🧪',
              resultDescription:
                  'You grab medical supplies and repair kits from the armory.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Booby Trapped!',
              resultArt: '💥',
              resultDescription:
                  'The supply crates are rigged with explosives.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -16),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📝 Map location',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Location Noted!',
              resultArt: '🗺️',
              resultDescription:
                  'Your improved knowledge increases your loot finding ability.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 17. TREASURE VAULT ──
    RandomEvent(
      id: 'treasure_vault',
      title: 'Treasure Vault',
      artPlaceholder: '🏦',
      flavorText:
          'A massive vault door stands partially ajar. Ancient locking mechanisms '
          'glitter with residual energy. Something valuable lies within.',
      spawnWeight: 0.7,
      minDay: 3,
      choices: [
        EventChoice(
          text: '💪 Force it open',
          statCheck: StatCheck(statType: StatType.attack, threshold: 10),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Vault Cracked!',
              resultArt: '👑',
              resultDescription:
                  'The vault yields! Inside lies legendary equipment.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Trap Triggered!',
              resultArt: '🩸',
              resultDescription:
                  'Security systems activate! Lasers leave deep wounds.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -25),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🖥️ Hack the lock',
          statCheck: StatCheck(statType: StatType.defense, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Vault Hacked!',
              resultArt: '🔓',
              resultDescription:
                  'Your skills bypass the security. Premium equipment inside.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Security Lockdown!',
              resultArt: '🚫',
              resultDescription: 'The vault locks down and electrocutes you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🗺️ Map the location',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Location Mapped!',
              resultArt: '🗺️',
              resultDescription: 'You document the vault for future reference.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 18. THE RING GUARDIAN ──
    RandomEvent(
      id: 'ring_guardian',
      title: 'The Ring Guardian',
      artPlaceholder: '👁️',
      flavorText:
          'A massive sentinel materializes from the Ring\'s architecture. '
          'Its single eye pulses with ancient authority. "Prove your worth."',
      spawnWeight: 0.5,
      minDay: 3,
      choices: [
        EventChoice(
          text: '⚔️ Challenge it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 10),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Worthy!',
              resultArt: '👑',
              resultDescription:
                  'The Guardian acknowledges your strength and grants you a massive reward.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 100),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Crushed!',
              resultArt: '💀',
              resultDescription: 'The Guardian swats you aside like an insect.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -30),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🤝 Negotiate',
          statCheck: StatCheck(statType: StatType.defense, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Terms Agreed!',
              resultArt: '🤝',
              resultDescription:
                  'The Guardian respects your diplomacy and shares a reward.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rejected!',
              resultArt: '🚫',
              resultDescription: 'The Guardian deems you unworthy and attacks.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🫣 Hide and wait',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Unnoticed!',
              resultArt: '🫣',
              resultDescription: 'The Guardian passes without detecting you.',
              effects: [],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Detected!',
              resultArt: '👁️',
              resultDescription: 'The Guardian spots you hiding and strikes.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 19. VOID RIFT ──
    RandomEvent(
      id: 'void_rift',
      title: 'Void Rift',
      artPlaceholder: '🕳️',
      flavorText:
          'A tear in the Ring\'s fabric crackles with unstable energy. '
          'Reality warps around its edges, and whispers pour from the void.',
      spawnWeight: 0.6,
      minDay: 4,
      choices: [
        EventChoice(
          text: '🕳️ Enter the rift',
          statCheck: StatCheck(statType: StatType.attack, threshold: 10),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Void Mastered!',
              resultArt: '🌀',
              resultDescription:
                  'You emerge from the rift transformed, with tremendous power.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 4,
                  description: '+4 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Consumed!',
              resultArt: '😵',
              resultDescription:
                  'The void nearly consumes you. You barely escape, but the corruption lingers.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.corruption,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔒 Try to seal it',
          statCheck: StatCheck(statType: StatType.defense, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rift Sealed!',
              resultArt: '🔒',
              resultDescription:
                  'You seal the rift. The Ring rewards your service with power.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
                EventEffect(type: EventEffectType.goldChange, value: 60),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Seal Broken!',
              resultArt: '💥',
              resultDescription: 'The rift explodes outward, damaging you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -25),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📊 Study from afar',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Void Data!',
              resultArt: '📊',
              resultDescription:
                  'You extract valuable data about the void without getting too close.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Void Gaze!',
              resultArt: '🟣',
              resultDescription:
                  'The void notices your observation and reaches out.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave immediately',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Retreated',
              resultArt: '🚶',
              resultDescription: 'You leave before the rift can affect you.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 20. THE ARCHITECT'S CACHE ──
    RandomEvent(
      id: 'architect_cache',
      title: 'The Architect\'s Cache',
      artPlaceholder: '🏛️',
      flavorText:
          'A sealed vault bearing the Architect\'s insignia. This is a relic '
          'from the Ring\'s creation. Tremendous power — or destruction — awaits.',
      spawnWeight: 0.4,
      minDay: 5,
      choices: [
        EventChoice(
          text: '🔓 Unlock with force',
          statCheck: StatCheck(statType: StatType.attack, threshold: 11),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Architect\'s Legacy!',
              resultArt: '👑',
              resultDescription:
                  'You crack the vault! Inside: legendary equipment and a fortune in credits.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 80),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Curse of the Architect!',
              resultArt: '🔮',
              resultDescription:
                  'The vault unleashes the Architect\'s final defense protocol.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.corruption,
                ),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Bypass the lock',
          statCheck: StatCheck(statType: StatType.defense, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Vault Bypassed!',
              resultArt: '🔧',
              resultDescription:
                  'Your technical skills bypass the lock. Useful supplies inside.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Defense Activated!',
              resultArt: '🤖',
              resultDescription:
                  'The vault\'s defense automaton activates and attacks.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -22),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💥 Destroy the cache',
          statCheck: StatCheck(statType: StatType.luck, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Scattered Riches!',
              resultArt: '💰',
              resultDescription:
                  'The explosion scatters credits and components everywhere. You gather what you can.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 120),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Backfire!',
              resultArt: '😵',
              resultDescription:
                  'The explosion backfires. The Architect\'s madness seeps into your mind.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.madness,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // ADDITIONAL EVENTS (21–45)
    // ═══════════════════════════════════════════════════════════════════

    // ── 21. THE RUSTED LOCKBOX ──
    RandomEvent(
      id: 'rusted_lockbox',
      title: 'The Rusted Lockbox',
      artPlaceholder: '🔐',
      flavorText:
          'A corroded lockbox juts from the rubble. Its digital tumbler '
          'still glows faintly, awaiting the correct sequence.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '💪 Smash it open',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Smashed!',
              resultArt: '💥',
              resultDescription:
                  'The lockbox shatters. Inside: a handful of credits and a data-chip.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Jammed!',
              resultArt: '😑',
              resultDescription:
                  'The lockbox absorbs your hit and locks permanently.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Guess the code',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lucky Guess!',
              resultArt: '🍀',
              resultDescription:
                  'The tumbler clicks open. Premium supplies inside!',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Wrong Code!',
              resultArt: '🚫',
              resultDescription:
                  'The lockbox emits a shock pulse for the wrong attempt.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: -8)],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Left Behind',
              resultArt: '🚶',
              resultDescription: 'Some locks are meant to stay closed.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 22. THE DRIFTING CARGO ──
    RandomEvent(
      id: 'drifting_cargo',
      title: 'The Drifting Cargo',
      artPlaceholder: '📦',
      flavorText:
          'A cargo container drifts through zero-gravity, its hull dented '
          'but intact. The shipping manifest shows high-value electronics.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '🔧 Pry it open',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cargo Secured!',
              resultArt: '📦',
              resultDescription:
                  'You breach the container and find pristine electronics.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Booby Trapped!',
              resultArt: '💣',
              resultDescription:
                  'The container explodes! Debris rips through your armor.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📦 Salvage exterior only',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Exterior Parts',
              resultArt: '📦',
              resultDescription:
                  'You strip useful panels from the hull. Modest but safe.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 20),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 23. THE CORRUPTED MERCHANT ──
    RandomEvent(
      id: 'corrupted_merchant',
      title: 'The Corrupted Merchant',
      artPlaceholder: '🧙',
      flavorText:
          'A hooded figure beckons you closer, their face half-obscured '
          'by a flickering holographic mask. "I have what you need," they hiss.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💰 Buy their wares (30c)',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rare Acquisition!',
              resultArt: '✨',
              resultDescription:
                  'The merchant reveals genuine rare equipment beneath the corruption.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cursed Deal!',
              resultArt: '🔮',
              resultDescription:
                  'The items crumble to dust. The merchant\'s laughter echoes as dark energy seeps in.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Demand a free sample',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Intimidated!',
              resultArt: '🛡️',
              resultDescription:
                  'Your aggressive posture forces the merchant to hand over a sample.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Slipped Away!',
              resultArt: '💨',
              resultDescription:
                  'The merchant vanishes into the shadows before you can react.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '🚫 Walk away',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Wise Choice',
              resultArt: '✅',
              resultDescription:
                  'You ignore the merchant. Their corrupted aura dissipates behind you.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 24. DATA LEAK ──
    RandomEvent(
      id: 'data_leak',
      title: 'Data Leak',
      artPlaceholder: '💧',
      flavorText:
          'A pipe bursts ahead, spraying luminous data-fluid across the '
          'pathway. The liquid contains fragments of valuable information.',
      spawnWeight: 1.1,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔍 Harvest the data',
          statCheck: StatCheck(statType: StatType.attack, threshold: 4),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Harvested!',
              resultArt: '💧',
              resultDescription:
                  'You capture the flowing data and decode valuable intel.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Corruption!',
              resultArt: '🟣',
              resultDescription:
                  'The data fluid corrodes your systems on contact.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏠 Wait for it to drain',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Drained',
              resultArt: '🏠',
              resultDescription:
                  'You wait patiently. The fluid drains and the path clears.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 25. THE PHANTOM PATROL ──
    RandomEvent(
      id: 'phantom_patrol',
      title: 'The Phantom Patrol',
      artPlaceholder: '👻',
      flavorText:
          'Ghostly security drones patrol the area in perfect formation. '
          'Their scanning beams sweep the ground in rhythmic patterns.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Engage the patrol',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Patrol Destroyed!',
              resultArt: '⚔️',
              resultDescription:
                  'You dismantle the drones. Their memory cores contain valuable data.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Outgunned!',
              resultArt: '🩸',
              resultDescription:
                  'The patrol overwhelms you with concentrated fire.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Time the gaps',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Slipped Through!',
              resultArt: '🏃',
              resultDescription:
                  'You find a gap in the patrol pattern and sneak past.',
              effects: [],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Detected!',
              resultArt: '🚨',
              resultDescription:
                  'Your timing is off. The patrol spots you and opens fire.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔄 Take the long way',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Detour Taken',
              resultArt: '🔄',
              resultDescription:
                  'You circle around the patrol. It takes longer but you stay safe.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 26. THE FADING SIGNAL ──
    RandomEvent(
      id: 'fading_signal',
      title: 'The Fading Signal',
      artPlaceholder: '📡',
      flavorText:
          'A weak distress signal pulses from a nearby sector. It\'s barely '
          'audible — someone, or something, is calling for help.',
      spawnWeight: 0.8,
      minDay: 0,
      choices: [
        EventChoice(
          text: '📞 Respond to the signal',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rescued!',
              resultArt: '💚',
              resultDescription:
                  'You find a stranded runner who rewards you with supplies and gratitude.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 35),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Trap!',
              resultArt: '☠️',
              resultDescription:
                  'The signal was bait. Raiders ambush you from the shadows.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(type: EventEffectType.goldChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚫 Ignore the signal',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Signal Lost',
              resultArt: '📡',
              resultDescription:
                  'The signal fades. Whether it was real or a trap, you\'ll never know.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 27. THE MIRROR POOL ──
    RandomEvent(
      id: 'mirror_pool',
      title: 'The Mirror Pool',
      artPlaceholder: '🪞',
      flavorText:
          'A perfectly still pool of liquid chrome reflects not your image, '
          'but a version of yourself from another timeline. It gestures toward you.',
      spawnWeight: 0.7,
      minDay: 2,
      choices: [
        EventChoice(
          text: '🌀 Reach into the pool',
          statCheck: StatCheck(statType: StatType.luck, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Timeline Merged!',
              resultArt: '🪞',
              resultDescription:
                  'Your alternate self shares their equipment and experience.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 2,
                  description: '+2 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Identity Crisis!',
              resultArt: '😵',
              resultDescription:
                  'The merge fails. Your consciousness fractures momentarily.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.madness,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Study from afar',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Knowledge Gained!',
              resultArt: '📖',
              resultDescription:
                  'Observing your alternate self teaches you new defensive techniques.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Gaze Trapped!',
              resultArt: '🪞',
              resultDescription:
                  'The pool pulls at your consciousness. You barely pull away.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Walk away',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Unchanged',
              resultArt: '🚶',
              resultDescription: 'Some reflections are best left undisturbed.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 28. THE POWER NODE ──
    RandomEvent(
      id: 'power_node',
      title: 'The Power Node',
      artPlaceholder: '⚡',
      flavorText:
          'A cracked power node leaks raw energy into the surrounding area. '
          'The air crackles with electricity, and nearby metal objects levitate.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '💪 Overload it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Energy Absorbed!',
              resultArt: '⚡',
              resultDescription:
                  'You channel the surge into your systems. Power levels increase.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overloaded!',
              resultArt: '💥',
              resultDescription:
                  'The node explodes. Electricity arcs across your body.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Harvest the component',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Component Salvaged!',
              resultArt: '🔧',
              resultDescription:
                  'You carefully extract the power core. It\'s worth a fortune.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shock!',
              resultArt: '⚡',
              resultDescription: 'The component shocks you when you touch it.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Give it a wide berth',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Passage',
              resultArt: '✅',
              resultDescription:
                  'You navigate around the dangerous area without incident.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 29. THE LOST CONVOY ──
    RandomEvent(
      id: 'lost_convoy',
      title: 'The Lost Convoy',
      artPlaceholder: '🚛',
      flavorText:
          'A convoy of abandoned data-transports stretches across the '
          'landscape. Their cargo holds are sealed but the doors show signs of forced entry.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💪 Break into the lead truck',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Convoy Looted!',
              resultArt: '🚛',
              resultDescription:
                  'The lead truck\'s cargo hold contains military-grade supplies.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ambush!',
              resultArt: '🩸',
              resultDescription:
                  'Raiders were hiding in the convoy! They attack immediately.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Search systematically',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Thorough Search!',
              resultArt: '🔧',
              resultDescription:
                  'Your methodical approach finds hidden compartments with valuables.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Nothing Useful',
              resultArt: '😑',
              resultDescription:
                  'The convoy was picked clean by previous scavengers.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Pass by',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Passed By',
              resultArt: '🚶',
              resultDescription: 'The convoy holds no interest for you today.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 30. THE ECHOING DRUM ──
    RandomEvent(
      id: 'echoing_drum',
      title: 'The Echoing Drum',
      artPlaceholder: '🥁',
      flavorText:
          'A rhythmic pulsing echoes from underground — like a heartbeat '
          'made of data. The ground vibrates with each beat.',
      spawnWeight: 0.7,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Follow the rhythm',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Heart of the Ring!',
              resultArt: '🥁',
              resultDescription:
                  'You find a data-cache pulsing with the rhythm. Inside: rare equipment.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rhythm Disrupted!',
              resultArt: '💥',
              resultDescription:
                  'Your interference causes a shockwave from the drum.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Meditate to the beat',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Harmonized!',
              resultArt: '🧘',
              resultDescription:
                  'The rhythm syncs with your systems. You feel reinforced.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.regeneration,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Dissonance!',
              resultArt: '😵',
              resultDescription:
                  'The rhythm clashes with your frequency, causing internal damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Move on quietly',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Silence',
              resultArt: '🤫',
              resultDescription:
                  'You pass without disturbing the ancient rhythm.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 31. THE GLITCH GARDEN ──
    RandomEvent(
      id: 'glitch_garden',
      title: 'The Glitch Garden',
      artPlaceholder: '🌺',
      flavorText:
          'Data-flowers grow in impossible colors, their petals displaying '
          'glitching patterns. Each flower seems to contain a different program.',
      spawnWeight: 0.8,
      minDay: 1,
      choices: [
        EventChoice(
          text: '🌸 Pick the red flower',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Power Bloom!',
              resultArt: '🌺',
              resultDescription:
                  'The red flower channels combat data into your systems.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 2,
                  description: '+2 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Thorn Prick!',
              resultArt: '☠️',
              resultDescription:
                  'The flower\'s thorn injects a virus into your system.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🌸 Pick the blue flower',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shield Bloom!',
              resultArt: '💙',
              resultDescription:
                  'The blue flower reinforces your defensive protocols.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Pollen Allergy!',
              resultArt: '🤧',
              resultDescription:
                  'The pollen irritates your systems. You feel weakened.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.weakened,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave the garden',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Garden Untouched',
              resultArt: '🌺',
              resultDescription:
                  'The glitch garden remains pristine as you pass.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 32. THE SECURITY SCANNER ──
    RandomEvent(
      id: 'security_scanner',
      title: 'The Security Scanner',
      artPlaceholder: '🔍',
      flavorText:
          'An ancient security scanner blocks the path. Its beam sweeps '
          'the area, and any unauthorized access triggers lethal countermeasures.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💻 Hack the scanner',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Scanner Hijacked!',
              resultArt: '💻',
              resultDescription:
                  'You override the scanner and access the security vault behind it.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lockdown!',
              resultArt: '🚫',
              resultDescription:
                  'The scanner locks down and fires a laser beam at you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -16),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Sneak past',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Unnoticed!',
              resultArt: '🍀',
              resultDescription:
                  'You time your movement perfectly and slip past the beam.',
              effects: [],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Tagged!',
              resultArt: '🎯',
              resultDescription:
                  'The scanner catches you mid-step and zaps you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔄 Find another route',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Alternate Path',
              resultArt: '🔄',
              resultDescription:
                  'You find a side passage that bypasses the scanner.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 33. THE MEMORY FRAGMENT ──
    RandomEvent(
      id: 'memory_fragment',
      title: 'The Memory Fragment',
      artPlaceholder: '💭',
      flavorText:
          'A floating data-crystal pulses with stored memories. As you '
          'approach, visions of the Ring\'s past flood your neural interface.',
      spawnWeight: 0.7,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💭 Absorb the memory',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Memory Absorbed!',
              resultArt: '💭',
              resultDescription:
                  'The ancient memory enhances your combat protocols significantly.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 3,
                  description: '+3 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Memory Overflow!',
              resultArt: '😵',
              resultDescription:
                  'The memory is too vast. Your systems overload from the influx.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.madness,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Filter and extract',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Filtered Data!',
              resultArt: '🛡️',
              resultDescription:
                  'You extract defensive knowledge from the memory safely.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.resistanceBoost,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Filter Bypassed!',
              resultArt: '💥',
              resultDescription:
                  'The memory overwhelms your filters. Raw data damages your systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -14),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave it floating',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Left Alone',
              resultArt: '💭',
              resultDescription:
                  'The memory fragment drifts away into the void.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 34. THE RUST GOLEM ──
    RandomEvent(
      id: 'rust_golem',
      title: 'The Rust Golem',
      artPlaceholder: '🗿',
      flavorText:
          'A massive construct of rusted metal and corroded circuits rises '
          'from the scrap heap. Its eyes glow with corrupted red light.',
      spawnWeight: 0.6,
      minDay: 3,
      choices: [
        EventChoice(
          text: '⚔️ Destroy it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Golem Shattered!',
              resultArt: '💥',
              resultDescription:
                  'You shatter the golem. Its core contains rare salvaged components.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 60),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Crushed!',
              resultArt: '🩸',
              resultDescription:
                  'The golem\'s massive fist slams into you before you can react.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -22),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💻 Shutdown command',
          statCheck: StatCheck(statType: StatType.defense, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shutdown!',
              resultArt: '💻',
              resultDescription:
                  'You find and execute the shutdown command. The golem powers down.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Access Denied!',
              resultArt: '🚫',
              resultDescription:
                  'The golem\'s firewall rejects your command and counterattacks.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -16),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Run away',
          statCheck: StatCheck(statType: StatType.luck, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Escaped!',
              resultArt: '🏃',
              resultDescription:
                  'The golem is too slow to catch you. You escape unscathed.',
              effects: [],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Slowed!',
              resultArt: '🩸',
              resultDescription:
                  'The golem clips you as you flee. Not a clean escape.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: -8)],
            ),
          ],
        ),
      ],
    ),

    // ── 35. THE DATA WATERFALL ──
    RandomEvent(
      id: 'data_waterfall',
      title: 'The Data Waterfall',
      artPlaceholder: '🌊',
      flavorText:
          'A cascading waterfall of raw data pours from a broken conduit '
          'high above. The falling data glows with embedded information.',
      spawnWeight: 0.9,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🏊 Dive through',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Diver!',
              resultArt: '🏊',
              resultDescription:
                  'You plunge through the waterfall and find a hidden cave behind it.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Crushed!',
              resultArt: '💥',
              resultDescription:
                  'The force of the data-flow pins you down. Bruising damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💧 Collect falling data',
          statCheck: StatCheck(statType: StatType.luck, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Collected!',
              resultArt: '💧',
              resultDescription:
                  'You catch fragments of valuable data as they fall.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Empty Handed!',
              resultArt: '😑',
              resultDescription:
                  'The data fragments dissolve before you can catch them.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Walk around',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Detour',
              resultArt: '🚶',
              resultDescription: 'You find a dry path around the waterfall.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 36. THE CIRCUIT SNAKE ──
    RandomEvent(
      id: 'circuit_snake',
      title: 'The Circuit Snake',
      artPlaceholder: '🐍',
      flavorText:
          'A serpentine automaton slithers through the wires around you. '
          'Its body is made of living circuits, and it eyes you with curiosity.',
      spawnWeight: 0.8,
      minDay: 1,
      choices: [
        EventChoice(
          text: '🍀 Befriend it',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Circuit Companion!',
              resultArt: '🐍',
              resultDescription:
                  'The snake accepts you and leads you to a hidden data-cache.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Venomous!',
              resultArt: '🐍',
              resultDescription:
                  'The snake bites you. Circuit-venom courses through your veins.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Capture it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Captured!',
              resultArt: '🐍',
              resultDescription:
                  'You catch the snake. Its body contains valuable circuit components.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bitten!',
              resultArt: '🩸',
              resultDescription: 'The snake strikes before you can grab it.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave it be',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Curious',
              resultArt: '🐍',
              resultDescription:
                  'The snake watches you leave with what might be disappointment.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 37. THE CHARGED CRYSTAL ──
    RandomEvent(
      id: 'charged_crystal',
      title: 'The Charged Crystal',
      artPlaceholder: '💎',
      flavorText:
          'A massive crystal hums with stored energy, casting prismatic '
          'light across the walls. It pulses in time with the Ring\'s core.',
      spawnWeight: 0.7,
      minDay: 2,
      choices: [
        EventChoice(
          text: '⚔️ Shatter it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Crystal Shattered!',
              resultArt: '💎',
              resultDescription:
                  'The crystal explodes into fragments. Each shard is worth a fortune.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 65),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Energy Burst!',
              resultArt: '💥',
              resultDescription:
                  'The crystal releases a burst of energy when struck.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Drain safely',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Energy Drained!',
              resultArt: '🛡️',
              resultDescription:
                  'You carefully drain the crystal\'s energy into your reserves.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 20)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overcharge!',
              resultArt: '⚡',
              resultDescription:
                  'The energy overwhelms your absorption capacity.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📝 Study its patterns',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Patterns Noted!',
              resultArt: '📝',
              resultDescription:
                  'The crystal\'s energy patterns improve your understanding of the Ring.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 38. THE SHADOW FIGURE ──
    RandomEvent(
      id: 'shadow_figure',
      title: 'The Shadow Figure',
      artPlaceholder: '👤',
      flavorText:
          'A dark silhouette stands motionless at the intersection. As you '
          'approach, it turns to face you — revealing a featureless void where a face should be.',
      spawnWeight: 0.7,
      minDay: 3,
      choices: [
        EventChoice(
          text: '⚔️ Challenge it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shadow Defeated!',
              resultArt: '⚔️',
              resultDescription:
                  'The shadow dissipates, leaving behind rare dark-crystals.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 70),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shadow Strike!',
              resultArt: '🩸',
              resultDescription:
                  'The shadow attacks first, draining your vitality.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🤝 Attempt communication',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shadow\'s Gift!',
              resultArt: '🤝',
              resultDescription:
                  'The shadow nods and bestows a dark blessing upon you.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.resistanceBoost,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rejection!',
              resultArt: '🚫',
              resultDescription:
                  'The shadow rejects your attempt and lashes out.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -14),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Flee',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Escaped!',
              resultArt: '🏃',
              resultDescription:
                  'The shadow watches as you retreat. It does not follow.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 39. THE FROZEN CACHE ──
    RandomEvent(
      id: 'frozen_cache',
      title: 'The Frozen Cache',
      artPlaceholder: '🧊',
      flavorText:
          'A container encased in ice blocks the path. Frost crystals '
          'cover its surface, and the temperature drops sharply nearby.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💪 Break the ice',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ice Shattered!',
              resultArt: '🧊',
              resultDescription:
                  'The ice cracks open. Inside: perfectly preserved equipment.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Frostbite!',
              resultArt: '🥶',
              resultDescription:
                  'The ice explodes outward, spraying freezing shards at you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.frozen,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Melt with heat',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Melted!',
              resultArt: '🔥',
              resultDescription:
                  'You carefully melt the ice and extract the contents safely.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Steam Burn!',
              resultArt: '💨',
              resultDescription: 'The rapid melting creates a steam explosion.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: -8)],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave frozen',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Frozen Still',
              resultArt: '🧊',
              resultDescription:
                  'The cache remains frozen. Perhaps another time.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 40. THE SIGNAL JAMMER ──
    RandomEvent(
      id: 'signal_jammer',
      title: 'The Signal Jammer',
      artPlaceholder: '📡',
      flavorText:
          'A device emits powerful interference, disrupting all nearby '
          'communications. Your neural interface crackles with static.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '🔧 Disable it',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Jammer Disabled!',
              resultArt: '📡',
              resultDescription:
                  'You shut down the jammer. Its components are surprisingly valuable.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Feedback Loop!',
              resultArt: '💥',
              resultDescription:
                  'The jammer creates a feedback loop that fries your systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💻 Repurpose it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Repurposed!',
              resultArt: '💻',
              resultDescription:
                  'You turn the jammer into a defensive tool. Enemies nearby are disrupted.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Malfunction!',
              resultArt: '🚫',
              resultDescription:
                  'The repurposing fails. The jammer emits a pulse that damages you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Push through',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Pushed Through',
              resultArt: '🏃',
              resultDescription: 'You endure the interference and press on.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 41. THE FLOATING MARKET ──
    RandomEvent(
      id: 'floating_market',
      title: 'The Floating Market',
      artPlaceholder: '🛒',
      flavorText:
          'Holographic vendors hover in the air, their stalls floating on '
          'anti-gravity platforms. They beckon with glowing signs and promises.',
      spawnWeight: 0.7,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💰 Buy a mystery box (25c)',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rare Find!',
              resultArt: '🎁',
              resultDescription:
                  'The mystery box contains a rare item and bonus credits!',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Empty Box!',
              resultArt: '📦',
              resultDescription:
                  'The box is empty. The vendor vanishes before you can complain.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -25),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Browse safely',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Window Shopping',
              resultArt: '🛒',
              resultDescription:
                  'You browse without buying. The vendors share a free sample.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Ignore them',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Passed By',
              resultArt: '🚶',
              resultDescription:
                  'The holographic vendors fade as you walk away.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 42. THE NEURAL SPIDER ──
    RandomEvent(
      id: 'neural_spider',
      title: 'The Neural Spider',
      artPlaceholder: '🕷️',
      flavorText:
          'A mechanical spider the size of a fist drops from above, its '
          'eight legs made of fiber-optic cable. It scans you with multiple red lenses.',
      spawnWeight: 0.8,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Crush it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spider Crushed!',
              resultArt: '🕷️',
              resultDescription:
                  'The spider shatters. Its neural core contains valuable data.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bite!',
              resultArt: '🕷️',
              resultDescription:
                  'The spider bites before you can react. Neural toxin enters your system.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Capture alive',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spider Captured!',
              resultArt: '🕷️',
              resultDescription:
                  'You capture the spider. Traders pay well for live specimens.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Escaped!',
              resultArt: '💨',
              resultDescription:
                  'The spider wriggles free and bites your hand in the process.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: -8)],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Let it pass',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spider Gone',
              resultArt: '🕷️',
              resultDescription: 'The spider scurries away into the shadows.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 43. THE CHROME OASIS ──
    RandomEvent(
      id: 'chrome_oasis',
      title: 'The Chrome Oasis',
      artPlaceholder: '🏝️',
      flavorText:
          'A small island of calm in the chaos. Chrome trees provide shade, '
          'and a cool breeze carries the scent of ozone. It feels almost... peaceful.',
      spawnWeight: 0.6,
      minDay: 2,
      choices: [
        EventChoice(
          text: '😴 Rest here',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Restful Pause!',
              resultArt: '🏝️',
              resultDescription:
                  'The oasis restores your energy. You find a hidden gift beneath a chrome tree.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 20),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Pest Attack!',
              resultArt: '🐛',
              resultDescription:
                  'The chrome trees harbor data-mites that attack while you rest.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔍 Explore the area',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Exploration!',
              resultArt: '🔍',
              resultDescription:
                  'The chrome trees contain stored data worth harvesting.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Move on',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Departed',
              resultArt: '🚶',
              resultDescription:
                  'You leave the oasis behind. The peace fades quickly.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 44. THE TERRAIN TRAP ──
    RandomEvent(
      id: 'terrain_trap',
      title: 'The Terrain Trap',
      artPlaceholder: '🕳️',
      flavorText:
          'The ground ahead is unstable. Hidden pressure plates and concealed '
          'pitfalls make every step potentially fatal.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔍 Map the traps',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Traps Mapped!',
              resultArt: '🗺️',
              resultDescription:
                  'You identify all the traps. Some contain useful items left by previous explorers.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Triggered!',
              resultArt: '💥',
              resultDescription:
                  'You miss a trap. The explosion sends you tumbling.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -14),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Sprint through',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Clean Run!',
              resultArt: '🏃',
              resultDescription:
                  'You sprint through without triggering a single trap. Impressive!',
              effects: [],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Tripped!',
              resultArt: '🩸',
              resultDescription:
                  'You trip on a pressure plate. The trap activates beneath you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔄 Go around',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Detour',
              resultArt: '🔄',
              resultDescription:
                  'You find a safe path around the trapped area.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 45. THE VOID WHISPER ──
    RandomEvent(
      id: 'void_whisper',
      title: 'The Void Whisper',
      artPlaceholder: '🌬️',
      flavorText:
          'A cold whisper carries through the air, speaking in a language '
          'that predates the Ring itself. The words coil around your consciousness.',
      spawnWeight: 0.6,
      minDay: 4,
      choices: [
        EventChoice(
          text: '🌀 Listen carefully',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Void Knowledge!',
              resultArt: '🌀',
              resultDescription:
                  'The whisper reveals forbidden knowledge. Your power increases dramatically.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 4,
                  description: '+4 ATK (permanent)',
                ),
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Void Madness!',
              resultArt: '😵',
              resultDescription:
                  'The whisper corrupts your thoughts. Void madness takes hold.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.madness,
                ),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Block the whisper',
          statCheck: StatCheck(statType: StatType.defense, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Whisper Blocked!',
              resultArt: '🛡️',
              resultDescription:
                  'You seal your mind against the void. The whisper bounces off your shields.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shield Breach!',
              resultArt: '💥',
              resultDescription:
                  'The whisper penetrates your defenses, causing neural damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Cover your ears',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ignored',
              resultArt: '🏃',
              resultDescription:
                  'You block out the whisper. It fades reluctantly into silence.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 46. THE DATA PARASITE ──
    RandomEvent(
      id: 'data_parasite',
      title: 'The Data Parasite',
      artPlaceholder: '🦠',
      flavorText:
          'A microscopic entity latches onto your neural port, feeding on '
          'your processing power. It whispers sweet nothings as it drains you.',
      spawnWeight: 0.8,
      minDay: 0,
      choices: [
        EventChoice(
          text: '⚔️ Purge it with force',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Parasite Destroyed!',
              resultArt: '🦠',
              resultDescription:
                  'You overload your systems to fry the parasite. The surge of '
                  'energy actually boosts your attack protocols.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 2,
                  description: '+2 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'System Damage!',
              resultArt: '💥',
              resultDescription:
                  'The purge damages your own systems in the process.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💡 Negotiate with it',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Symbiosis!',
              resultArt: '🦠',
              resultDescription:
                  'The parasite agrees to share its knowledge in exchange for '
                  'a small data fee. You gain credits and awareness.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Betrayed!',
              resultArt: '🦠',
              resultDescription:
                  'The parasite multiplies instead of negotiating.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
                EventEffect(type: EventEffectType.goldChange, value: -25),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Run it off',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shaken Off',
              resultArt: '🏃',
              resultDescription:
                  'You sprint until the parasite falls off. Exhausting but safe.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 47. THE CLOCKWORK ORACLE ──
    RandomEvent(
      id: 'clockwork_oracle',
      title: 'The Clockwork Oracle',
      artPlaceholder: '🔮',
      flavorText:
          'A massive mechanical head protrudes from the ground, gears turning '
          'inside its hollow skull. It speaks in riddles that hint at the future.',
      spawnWeight: 0.5,
      minDay: 1,
      choices: [
        EventChoice(
          text: '🔮 Ask about treasure',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Coordinates Revealed!',
              resultArt: '🔮',
              resultDescription:
                  'The oracle reveals the location of a hidden cache nearby.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 60),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'False Promise!',
              resultArt: '😵',
              resultDescription:
                  'The coordinates lead to a trap. The oracle laughs.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Ask about enemies',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Combat Insight!',
              resultArt: '⚔️',
              resultDescription:
                  'The oracle reveals weaknesses in nearby threats. You feel empowered.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Confusion!',
              resultArt: '😵',
              resultDescription:
                  'The riddles scramble your tactical subroutines.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.weakened,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Ask about defense',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shield Upgrade!',
              resultArt: '🛡️',
              resultDescription:
                  'The oracle downloads defensive schematics into your system.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 15),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overload!',
              resultArt: '💥',
              resultDescription: 'Too much data floods your defensive systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 48. THE RUST WORMS ──
    RandomEvent(
      id: 'rust_worms',
      title: 'The Rust Worms',
      artPlaceholder: '🐛',
      flavorText:
          'A swarm of metallic worms burrows through the corroded ground. '
          'They consume metal and data alike, leaving only dust behind.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '⚔️ Burn them with plasma',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Worms Incinerated!',
              resultArt: '🔥',
              resultDescription:
                  'The plasma cleanses the area. The worm husks contain trace minerals.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Swarmed!',
              resultArt: '🐛',
              resultDescription:
                  'The worms cling to your armor, corroding it before you shake them off.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Lure them into a trap',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Worm Catcher!',
              resultArt: '🐛',
              resultDescription:
                  'The swarm falls for your bait. Their cores are valuable.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bait Stolen!',
              resultArt: '🐛',
              resultDescription: 'The worms eat your bait and your supplies.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Sprint past them',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Dodged!',
              resultArt: '🏃',
              resultDescription:
                  'You leap over the swarm, taking minimal damage.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: -5)],
            ),
          ],
        ),
      ],
    ),

    // ── 49. THE PHANTOM CONVOY ──
    RandomEvent(
      id: 'phantom_convoy',
      title: 'The Phantom Convoy',
      artPlaceholder: '🚛',
      flavorText:
          'A convoy of spectral trucks roars past you, their engines screaming '
          'with digital echoes. One truck slows, its door opening to reveal '
          'crates of supplies inside.',
      spawnWeight: 0.7,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Board the lead truck',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Supplies Secured!',
              resultArt: '🚛',
              resultDescription:
                  'You leap aboard and grab what you can before the convoy fades.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Run Over!',
              resultArt: '💥',
              resultDescription:
                  'The phantom driver floors it. You take a direct hit.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Flag down the last truck',
          statCheck: StatCheck(statType: StatType.luck, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ride Along!',
              resultArt: '🚛',
              resultDescription:
                  'The phantom driver lets you ride. You arrive at a hidden depot.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ghosted!',
              resultArt: '👻',
              resultDescription:
                  'The truck phases through you, leaving you dizzy.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '👁️ Watch and record',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Recorded',
              resultArt: '👁️',
              resultDescription:
                  'You record the convoy\'s path. This intel could be valuable later.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 50. THE NEON BUTTERFLIES ──
    RandomEvent(
      id: 'neon_butterflies',
      title: 'The Neon Butterflies',
      artPlaceholder: '🦋',
      flavorText:
          'A cloud of bioluminescent butterflies swirls around you. Each '
          'wingbeat sends pulses of healing nanites through the air. But '
          'some species carry data-venom on their proboscis.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🦋 Let them land on you',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Healed!',
              resultArt: '🦋',
              resultDescription:
                  'The butterflies heal your wounds with their nanite dust.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 25),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Venom Stung!',
              resultArt: '🦋',
              resultDescription:
                  'A venomous butterfly stings you. Your systems rebel.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Shield yourself',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Nanite Harvest!',
              resultArt: '🛡️',
              resultDescription:
                  'You filter the nanites from the air, boosting your defenses.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Swarmed!',
              resultArt: '💥',
              resultDescription: 'The butterflies overwhelm your shields.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📸 Capture some for analysis',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Samples Collected!',
              resultArt: '📸',
              resultDescription:
                  'You catch a few butterflies. Their wings are worth good credits.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 51. THE DIGITAL SANDSTORM ──
    RandomEvent(
      id: 'digital_sandstorm',
      title: 'The Digital Sandstorm',
      artPlaceholder: '🌪️',
      flavorText:
          'A swirling vortex of corrupted data particles engulfs the area. '
          'Visibility drops to zero as pixelated sand erodes everything.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🛡️ Hunker down and shield',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Weathered!',
              resultArt: '🛡️',
              resultDescription:
                  'Your shielding holds. The storm deposits useful scrap around you.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Eroded!',
              resultArt: '💥',
              resultDescription: 'The sand strips away your outer plating.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Fight through it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Storm Surfer!',
              resultArt: '⚔️',
              resultDescription:
                  'You charge through the storm, emerging on the other side '
                  'with a trail of debris in your wake.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Disoriented!',
              resultArt: '😵',
              resultDescription:
                  'The storm throws you around, damaging your navigation.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.weakened,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Wait for it to pass',
          statCheck: StatCheck(statType: StatType.luck, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Storm Passed',
              resultArt: '☀️',
              resultDescription:
                  'The storm clears quickly. You spot something shiny in the aftermath.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 20),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Prolonged Exposure!',
              resultArt: '🌪️',
              resultDescription: 'The storm lingers longer than expected.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 52. THE LOBOTOMIZED DRONE ──
    RandomEvent(
      id: 'lobotomized_drone',
      title: 'The Lobotomized Drone',
      artPlaceholder: '🤖',
      flavorText:
          'A combat drone with its memory banks wiped circles overhead. It '
          'seems lost, scanning everything without attacking. Its weapon '
          'systems are still active.',
      spawnWeight: 0.8,
      minDay: 0,
      choices: [
        EventChoice(
          text: '💻 Reprogram it',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Drone Ally!',
              resultArt: '🤖',
              resultDescription:
                  'You access its command interface and reprogram it. The drone '
                  'becomes your temporary guardian.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 15),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Firewall Rejects!',
              resultArt: '🚫',
              resultDescription:
                  'The drone\'s firewall blocks your hack and retaliates.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Lure it to a trap',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Drone Salvaged!',
              resultArt: '🤖',
              resultDescription:
                  'The drone crashes into your trap. Its weapons and parts are valuable.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Trap Triggered!',
              resultArt: '💥',
              resultDescription:
                  'The drone detects the trap and fires at it — and at you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -14),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '👁️ Observe its patterns',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Catalogued',
              resultArt: '👁️',
              resultDescription:
                  'You record the drone\'s patrol patterns. Useful intel for later.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 53. THE CORROSION PRIEST ──
    RandomEvent(
      id: 'corrosion_priest',
      title: 'The Corrosion Priest',
      artPlaceholder: '⛪',
      flavorText:
          'A robed figure stands before a rusted altar, chanting to the god '
          'of entropy. Their body is half-consumed by corrosion, yet they '
          'seem at peace. They offer you a blessing — for a price.',
      spawnWeight: 0.5,
      minDay: 2,
      choices: [
        EventChoice(
          text: '🛡️ Accept the blessing',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Entropy Shielded!',
              resultArt: '⛪',
              resultDescription:
                  'The priest grants you immunity to decay. Your systems feel renewed.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 20),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cursed!',
              resultArt: '⛪',
              resultDescription:
                  'The blessing was a curse in disguise. Corruption seeps in.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Challenge the priest',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Priest Defeated!',
              resultArt: '⚔️',
              resultDescription:
                  'You overwhelm the priest. Their altar holds hidden treasures.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 65),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Corroded!',
              resultArt: '💥',
              resultDescription:
                  'The priest\'s entropy power corrodes your armor.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -20),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave an offering and move on',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Offering Accepted',
              resultArt: '⛪',
              resultDescription:
                  'The priest nods silently. You feel slightly lighter in the wallet '
                  'but lighter in spirit too.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -15),
                EventEffect(type: EventEffectType.hpChange, value: 10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 54. THE MEMORY THIEF ──
    RandomEvent(
      id: 'memory_thief',
      title: 'The Memory Thief',
      artPlaceholder: '🧩',
      flavorText:
          'A shadowy figure darts between the ruins, stealing data fragments '
          'from anyone nearby. You feel your own memories flickering as it '
          'draws closer.',
      spawnWeight: 0.7,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Intercept and fight',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Thief Caught!',
              resultArt: '🧩',
              resultDescription:
                  'You tackle the thief and recover stolen data — including extras.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Memories Stolen!',
              resultArt: '🧩',
              resultDescription:
                  'The thief is too fast. It steals a chunk of your combat data.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.weakened,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Guard your data',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Fortified!',
              resultArt: '🛡️',
              resultDescription:
                  'Your firewalls hold. The thief gives up and drops some of its haul.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Breached!',
              resultArt: '🧩',
              resultDescription:
                  'The thief cracks your defenses and takes what it wants.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Chase it with luck',
          statCheck: StatCheck(statType: StatType.luck, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lucky Catch!',
              resultArt: '🍀',
              resultDescription:
                  'The thief trips and spills its entire collection at your feet.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Escaped!',
              resultArt: '🧩',
              resultDescription:
                  'The thief vanishes into the shadows, laughing.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 55. THE FROZEN SHARD ──
    RandomEvent(
      id: 'frozen_shard',
      title: 'The Frozen Shard',
      artPlaceholder: '🧊',
      flavorText:
          'A crystalline shard floats in the air, radiating intense cold. '
          'The ground beneath it is covered in digital frost. Inside the '
          'shard, a light pulses like a heartbeat.',
      spawnWeight: 0.8,
      minDay: 0,
      choices: [
        EventChoice(
          text: '⚔️ Shatter the shard',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shard Smashed!',
              resultArt: '🧊',
              resultDescription:
                  'The shard explodes into a shower of frozen data crystals. '
                  'Each one is worth a fortune.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 55),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.resistanceBoost,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Frozen Solid!',
              resultArt: '🧊',
              resultDescription:
                  'The shard unleashes a blast of cold, freezing you solid.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.frozen,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💡 Absorb its energy',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Energy Absorbed!',
              resultArt: '💡',
              resultDescription:
                  'You channel the shard\'s energy into your systems. Maximum capacity increases.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 30),
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 2,
                  description: '+2 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'System Freeze!',
              resultArt: '🧊',
              resultDescription:
                  'The energy overload freezes your core systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📸 Collect a sample',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Sample Acquired',
              resultArt: '📸',
              resultDescription:
                  'You carefully chip off a piece. It\'s worth selling.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 20),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 56. THE ROGUE SIGNAL ──
    RandomEvent(
      id: 'rogue_signal',
      title: 'The Rogue Signal',
      artPlaceholder: '📡',
      flavorText:
          'An unencrypted broadcast pierces your comms. A distorted voice '
          'recites a string of coordinates, followed by laughter. The signal '
          'originates from a collapsed antenna tower nearby.',
      spawnWeight: 0.7,
      minDay: 1,
      choices: [
        EventChoice(
          text: '📡 Trace the signal',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Source Found!',
              resultArt: '📡',
              resultDescription:
                  'You trace the signal to a hidden relay with valuable data caches.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Signal Trap!',
              resultArt: '💥',
              resultDescription:
                  'The signal was a lure. An EMP blast hits you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Destroy the antenna',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Antenna Destroyed!',
              resultArt: '⚔️',
              resultDescription:
                  'You smash the antenna. The signal dies, and you salvage some parts.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Antenna Fights Back!',
              resultArt: '💥',
              resultDescription:
                  'Automated defenses activate when you approach.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚫 Ignore the signal',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Signal Dismissed',
              resultArt: '🚫',
              resultDescription:
                  'You mute the frequency. Some calls are better left unanswered.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 57. THE MERCHANT CARAVAN ──
    RandomEvent(
      id: 'merchant_caravan',
      title: 'The Merchant Caravan',
      artPlaceholder: '🐫',
      flavorText:
          'A heavily guarded merchant caravan winds through the data-wastes. '
          'The lead merchant waves and offers you a deal: fight off raiders '
          'in exchange for first pick of their wares.',
      spawnWeight: 0.6,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Accept the deal',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Raiders Defeated!',
              resultArt: '🐫',
              resultDescription:
                  'You fend off the raiders. The merchant rewards you generously.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overwhelmed!',
              resultArt: '💀',
              resultDescription:
                  'The raiders are too many. You fight them off but take heavy damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -22),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Guard the caravan instead',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Caravan Protected!',
              resultArt: '🛡️',
              resultDescription:
                  'Your defensive tactics keep the raiders at bay. The merchant shares supplies.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 20),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Flank Attack!',
              resultArt: '💥',
              resultDescription:
                  'Raiders hit your flank. The caravan escapes but you\'re left wounded.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Ask for a free sample',
          statCheck: StatCheck(statType: StatType.luck, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Charmed!',
              resultArt: '🍀',
              resultDescription:
                  'The merchant takes a liking to you and gives you a free item.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Turned Away!',
              resultArt: '😤',
              resultDescription: 'The merchant scoffs at your request.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 58. THE ELECTROMAGNETIC PULSE ──
    RandomEvent(
      id: 'emp_surge',
      title: 'The Electromagnetic Pulse',
      artPlaceholder: '⚡',
      flavorText:
          'A massive electromagnetic pulse erupts from a collapsed generator. '
          'Sparks fly and systems flicker. Your HUD goes haywire as the pulse '
          'washes over you.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🛡️ Absorb the energy',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Energy Harvested!',
              resultArt: '⚡',
              resultDescription:
                  'Your systems absorb the EMP, converting it into raw power.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'System Overload!',
              resultArt: '💥',
              resultDescription: 'The energy overwhelms your circuits.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Smash the generator',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Generator Smashed!',
              resultArt: '⚔️',
              resultDescription:
                  'You destroy the generator, stopping the pulse. Valuable parts scatter.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Secondary Burst!',
              resultArt: '⚡',
              resultDescription:
                  'Destroying the generator triggers a secondary pulse.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Retreat to safety',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Distance',
              resultArt: '🏃',
              resultDescription:
                  'You back away to a safe distance, avoiding the worst of the pulse.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 59. THE DATA SPRING ──
    RandomEvent(
      id: 'data_spring',
      title: 'The Data Spring',
      artPlaceholder: '⛲',
      flavorText:
          'A fountain of liquid data erupts from the ground, forming a '
          'mesmerizing geyser of glowing particles. The water hums with '
          'raw information, and drinking it could rewrite your code.',
      spawnWeight: 0.7,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💡 Drink from the spring',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Code Rewritten!',
              resultArt: '⛲',
              resultDescription:
                  'The data water integrates perfectly, enhancing your core systems.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 3,
                  description: '+3 ATK (permanent)',
                ),
                EventEffect(type: EventEffectType.hpChange, value: 15),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Corrupted!',
              resultArt: '☠️',
              resultDescription:
                  'The data is corrupted. It infects your systems.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.corruption,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Use it for external repairs',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Repairs Complete!',
              resultArt: '🛡️',
              resultDescription:
                  'You channel the data water to repair your external plating.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 20),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Chemical Burn!',
              resultArt: '💥',
              resultDescription:
                  'The data water reacts badly with your plating.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📸 Bottle some for later',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bottled!',
              resultArt: '📸',
              resultDescription:
                  'You collect samples of the data spring. Could be useful or sellable.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 60. THE GLITCHED TREASURE CHEST ──
    RandomEvent(
      id: 'glitched_chest',
      title: 'The Glitched Treasure Chest',
      artPlaceholder: '📦',
      flavorText:
          'A treasure chest flickers in and out of existence, its textures '
          'corrupted and glitching. It might contain legendary loot — or '
          'it might be a data trap designed to lure greedy runners.',
      spawnWeight: 0.8,
      minDay: 0,
      choices: [
        EventChoice(
          text: '💪 Force it open',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Loot Secured!',
              resultArt: '📦',
              resultDescription:
                  'You smash the chest open. The glitches resolve to reveal treasure.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Chest Explodes!',
              resultArt: '💥',
              resultDescription:
                  'The chest was rigged. It explodes in your face.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💡 Hack the lock',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Hacked!',
              resultArt: '💡',
              resultDescription:
                  'You bypass the glitch-lock and access the chest\'s contents safely.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 55),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Virus Downloaded!',
              resultArt: '🟣',
              resultDescription:
                  'The chest downloads a virus into your system.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.corruption,
                ),
                EventEffect(type: EventEffectType.goldChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Inspect carefully first',
          statCheck: StatCheck(statType: StatType.luck, threshold: 4),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Opening!',
              resultArt: '📦',
              resultDescription:
                  'Your caution pays off. You spot the trap and disarm it before opening.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'False Security!',
              resultArt: '😵',
              resultDescription:
                  'Your inspection gives you false confidence. The trap still triggers.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  /// Get a random event appropriate for the current day and zone.
  /// Returns null if no event triggers.
  static RandomEvent? rollForEvent({
    required int currentDay,
    required ZoneType currentZone,
    double baseChance = 0.35,
    double luckModifier = 0.0,
  }) {
    final adjustedChance = (baseChance + luckModifier * 0.01).clamp(0.0, 0.5);
    if (_random.nextDouble() > adjustedChance) return null;

    final eligible = allEvents.where((e) {
      if (currentDay < e.minDay) return false;
      if (e.zoneRestrictions != null &&
          !e.zoneRestrictions!.contains(currentZone)) {
        return false;
      }
      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    final totalWeight = eligible.fold<double>(
      0.0,
      (sum, e) => sum + e.spawnWeight,
    );
    var roll = _random.nextDouble() * totalWeight;

    for (final event in eligible) {
      roll -= event.spawnWeight;
      if (roll <= 0) return event;
    }

    return eligible.last;
  }

  /// Resolve a choice using D&D-style hidden dice roll.
  /// Rolls 1d20 + stat modifier + luck modifier vs DC (threshold).
  /// Returns a [DiceRollResult] with the outcome and roll details.
  static DiceRollResult resolveChoice(
    EventChoice choice,
    Map<StatType, int> playerStats,
  ) {
    if (choice.statCheck == null) {
      // No stat check — always succeeds with a trivial roll
      return DiceRollResult(
        outcome: _pickWeighted(choice.possibleOutcomes),
        passed: true,
        d20: 1,
        statModifier: 0,
        luckModifier: 0,
        totalRoll: 1,
        dc: 0,
        statType: choice.statCheck?.statType,
      );
    }

    final statType = choice.statCheck!.statType;
    final dc = choice.statCheck!.threshold;
    final playerStatValue = playerStats[statType] ?? 0;
    final playerLuckValue = playerStats[StatType.luck] ?? 0;

    // D&D-style modifier: floor(stat / 2) - 5 (but clamped so low stats aren't too punishing)
    final statModifier = (playerStatValue / 2).floor() - 3;
    final luckModifier = (playerLuckValue / 2).floor() - 3;

    // Roll 1d20
    final d20 = _random.nextInt(20) + 1;
    final totalRoll = d20 + statModifier + luckModifier;
    final passed = totalRoll >= dc;

    final outcome = passed
        ? _pickWeighted(choice.possibleOutcomes)
        : (choice.failureOutcomes != null
              ? _pickWeighted(choice.failureOutcomes!)
              : _pickWeighted(choice.possibleOutcomes));

    return DiceRollResult(
      outcome: outcome,
      passed: passed,
      d20: d20,
      statModifier: statModifier,
      luckModifier: luckModifier,
      totalRoll: totalRoll,
      dc: dc,
      statType: statType,
    );
  }

  static EventOutcome _pickWeighted(List<EventOutcome> outcomes) {
    final totalWeight = outcomes.fold<double>(0.0, (sum, o) => sum + o.weight);
    var roll = _random.nextDouble() * totalWeight;

    for (final outcome in outcomes) {
      roll -= outcome.weight;
      if (roll <= 0) return outcome;
    }

    return outcomes.last;
  }
}
