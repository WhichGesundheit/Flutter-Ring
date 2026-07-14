import 'dart:math';

import 'zone.dart';
import 'status_effect.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// RANDOM EVENTS – Triggered during travel between nodes
/// ═══════════════════════════════════════════════════════════════════════════════

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

  const EventChoice({required this.text, required this.possibleOutcomes});
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

/// ═══════════════════════════════════════════════════════════════════════════════
/// EVENT POOL – 10 unique events with different outcomes
/// ═══════════════════════════════════════════════════════════════════════════════

class EventPool {
  static final Random _random = Random();

  static final List<RandomEvent> allEvents = [
    // ── 1. THE ABANDONED TERMINAL ──
    RandomEvent(
      id: 'abandoned_terminal',
      title: 'The Abandoned Terminal',
      artPlaceholder: '💻',
      flavorText:
          'A glowing terminal hums with residual power, its screen flickering '
          'with cryptic symbols. Data streams cascade across the display like '
          'a waterfall of light.',
      spawnWeight: 1.2,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔌 Jack into the terminal',
          possibleOutcomes: [
            EventOutcome(
              weight: 0.5,
              resultTitle: 'Data Surge!',
              resultArt: '⚡',
              resultDescription:
                  'A torrent of data floods your neural interface. You extract '
                  'a piece of valuable equipment from the terminal\'s memory banks.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
            EventOutcome(
              weight: 0.5,
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

    // ── 2. WANDERING MERCHANT'S CORPSE ──
    RandomEvent(
      id: 'merchant_corpse',
      title: 'Wandering Merchant\'s Corpse',
      artPlaceholder: '💀',
      flavorText:
          'The remains of a traveling merchant lie slumped against a rusted '
          'wall. Their pack still bulges with goods, but an eerie aura '
          'surrounds the body.',
      spawnWeight: 1.0,
      minDay: 1,
      choices: [
        EventChoice(
          text: '🎒 Take everything',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cursed Loot!',
              resultArt: '🔮',
              resultDescription:
                  'As you grab the goods, a dark energy transfers to you. '
                  'The merchant\'s curse now rests upon your shoulders.',
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
                  'You carefully extract the credits without disturbing the body. '
                  'A respectful and safe approach.',
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
                  'Your respect for the fallen merchant earns you a blessing. '
                  'Lady luck smiles upon you.',
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

    // ── 3. DATA STORM ──
    RandomEvent(
      id: 'data_storm',
      title: 'Data Storm',
      artPlaceholder: '🌪️',
      flavorText:
          'Electrical storms of pure interference gather on the horizon. '
          'Lightning arcs between corrupted data clouds, illuminating the '
          'desolate landscape.',
      spawnWeight: 1.1,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🛡️ Brace for impact',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Endured!',
              resultArt: '💪',
              resultDescription:
                  'The storm hits hard but you withstand it. The raw energy '
                  'charges your systems, leaving you empowered.',
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
          text: '🏠 Find shelter',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Sheltered',
              resultArt: '🏠',
              resultDescription:
                  'You find a safe alcove and wait out the storm. It costs '
                  'some time, but you emerge unscathed.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 0),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚡ Ride the lightning',
          possibleOutcomes: [
            EventOutcome(
              weight: 0.3,
              resultTitle: 'Lightning Rider!',
              resultArt: '⚡',
              resultDescription:
                  'Incredible! You channel the storm\'s energy through your body, '
                  'achieving unprecedented speed and reflexes.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.hasted,
                ),
              ],
            ),
            EventOutcome(
              weight: 0.7,
              resultTitle: 'Overloaded!',
              resultArt: '💥',
              resultDescription:
                  'The storm overwhelms your systems. Raw voltage courses through '
                  'every circuit, causing severe damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -25),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 4. MYSTERIOUS SHRINE ──
    RandomEvent(
      id: 'mysterious_shrine',
      title: 'Mysterious Shrine',
      artPlaceholder: '⛩️',
      flavorText:
          'A glowing altar pulsates with ancient energy. Strange symbols '
          'carved into its surface seem to shift and change when you\'re '
          'not looking directly at them.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💎 Offer 50 credits',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shrine Empowered!',
              resultArt: '🌟',
              resultDescription:
                  'The shrine absorbs your offering and pulses with brilliant light. '
                  'You feel a permanent surge of strength.',
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
        ),
        EventChoice(
          text: '🩸 Offer HP',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Blood Offering!',
              resultArt: '💚',
              resultDescription:
                  'The shrine draws your life force, but rewards you with '
                  'regenerative nanites that continuously heal your wounds.',
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
              resultDescription:
                  'You decide the risk isn\'t worth it and continue on your way.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 5. CORRUPTED COMPANION ──
    RandomEvent(
      id: 'corrupted_companion',
      title: 'Corrupted Companion',
      artPlaceholder: '🤖',
      flavorText:
          'A friendly NPC stumbles toward you, their eyes flickering with '
          'malicious code. They beg for help, but their hand grips a weapon '
          'with alarming tension.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Fight the corruption',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Battle Initiated!',
              resultArt: '⚔️',
              resultDescription:
                  'The corrupted companion turns hostile. You must fight to survive!',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
        ),
        EventChoice(
          text: '💊 Try to cure them',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cured!',
              resultArt: '💚',
              resultDescription:
                  'Your medical supplies manage to purge the corruption. '
                  'The grateful companion shares their supplies with you.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
                EventEffect(type: EventEffectType.itemGain),
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
              resultDescription:
                  'You slip past the corrupted companion, losing a bit of time '
                  'but avoiding danger.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 6. TREASURE VAULT ──
    RandomEvent(
      id: 'treasure_vault',
      title: 'Treasure Vault',
      artPlaceholder: '🏦',
      flavorText:
          'A massive vault door stands before you, partially ajar. Ancient '
          'locking mechanisms glitter with residual energy. Something valuable '
          'lies within.',
      spawnWeight: 0.7,
      minDay: 3,
      choices: [
        EventChoice(
          text: '💪 Force it open',
          possibleOutcomes: [
            EventOutcome(
              weight: 0.4,
              resultTitle: 'Legendary Find!',
              resultArt: '👑',
              resultDescription:
                  'The vault yields to your strength! Inside lies a piece of '
                  'legendary equipment, still glowing with power.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
            EventOutcome(
              weight: 0.6,
              resultTitle: 'Trap Triggered!',
              resultArt: '🩸',
              resultDescription:
                  'Security systems activate! Lasers slice through your armor, '
                  'leaving deep wounds that won\'t stop bleeding.',
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
          text: '🖥️ Hack the lock',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Vault Cracked!',
              resultArt: '🔓',
              resultDescription:
                  'Your hacking skills bypass the security. You find premium '
                  'equipment inside.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -40),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📝 Map the location',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Location Mapped!',
              resultArt: '🗺️',
              resultDescription:
                  'You document the vault\'s location for future reference. '
                  'Your knowledge of the area improves.',
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

    // ── 7. TOXIC SPILL ──
    RandomEvent(
      id: 'toxic_spill',
      title: 'Toxic Spill',
      artPlaceholder: '☢️',
      flavorText:
          'Pools of corrupted data ooze across the path ahead. The toxic '
          'substance bubbles and hisses, releasing noxious fumes that sting '
          'your sensors.',
      spawnWeight: 1.1,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🏊 Wade through',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Contaminated!',
              resultArt: '☠️',
              resultDescription:
                  'You push through the toxic waste. The chemicals eat at your '
                  'systems, but you find a useful item half-buried in the muck.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
                EventEffect(type: EventEffectType.itemGain),
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
                  'You take the long way around, adding time to your journey '
                  'but staying safe.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '🧪 Collect samples',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Samples Collected!',
              resultArt: '🔰',
              resultDescription:
                  'You carefully collect samples of the toxic waste. Analysis '
                  'reveals compounds that boost your damage resistance.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.resistanceBoost,
                ),
              ],
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
          'The signal carries fragments of ancient code and whispered promises '
          'of power.',
      spawnWeight: 0.8,
      minDay: 2,
      choices: [
        EventChoice(
          text: '📞 Answer the call',
          possibleOutcomes: [
            EventOutcome(
              weight: 0.5,
              resultTitle: 'Power Surge!',
              resultArt: '💪',
              resultDescription:
                  'The signal channels raw power into your systems. Your attack '
                  'capability increases permanently.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 3,
                  description: '+3 ATK (permanent)',
                ),
              ],
            ),
            EventOutcome(
              weight: 0.5,
              resultTitle: 'Mind Corruption!',
              resultArt: '🌀',
              resultDescription:
                  'The signal was a virus! It infects your neural pathways, '
                  'causing madness that distorts your perception.',
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
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Signal Blocked!',
              resultArt: '🛡️',
              resultDescription:
                  'You block the frequency and set up a defensive protocol. '
                  'Your shields are strengthened.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
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
                  'You record the signal and find valuable data fragments that '
                  'can be sold to interested parties.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 9. FORGOTTEN ARMORY ──
    RandomEvent(
      id: 'forgotten_armory',
      title: 'Forgotten Armory',
      artPlaceholder: '⚔️',
      flavorText:
          'Hidden behind a collapsed wall, you discover an ancient armory. '
          'Weapons and armor hang on rusted racks, some still gleaming with '
          'enchantment.',
      spawnWeight: 0.6,
      minDay: 3,
      choices: [
        EventChoice(
          text: '⚔️ Take the best weapon',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Weapon Acquired!',
              resultArt: '⚔️',
              resultDescription:
                  'You claim a powerful weapon, but the armory\'s defense '
                  'systems damage your existing equipment in the process.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(
                  type: EventEffectType.damageResistance,
                  value: -1,
                  description: 'All equipment loses 1 upgrade level',
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🧪 Take supplies',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Supplies Found!',
              resultArt: '🧪',
              resultDescription:
                  'You grab medical supplies and repair kits from the armory. '
                  'Two useful items for the road ahead.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.itemGain),
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
                  'You document the armory\'s location. Your improved knowledge '
                  'of the area increases your loot finding ability.',
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

    // ── 10. THE GAMBLER'S DEAL ──
    RandomEvent(
      id: 'gambler_deal',
      title: 'The Gambler\'s Deal',
      artPlaceholder: '🃏',
      flavorText:
          'A mysterious figure in a tattered coat approaches you with a '
          'gleam in their eye. "Fancy a wager?" they whisper, producing '
          'a deck of shimmering cards.',
      spawnWeight: 1.0,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💰 Bet 50 credits',
          possibleOutcomes: [
            EventOutcome(
              weight: 0.4,
              resultTitle: 'Winner!',
              resultArt: '💰',
              resultDescription:
                  'Your hand is lucky tonight! The gambler reluctantly pays '
                  'triple your bet.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 150),
              ],
            ),
            EventOutcome(
              weight: 0.6,
              resultTitle: 'Loser!',
              resultArt: '😢',
              resultDescription:
                  'The gambler\'s smile widens as they collect your credits. '
                  '"Better luck next time, friend."',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -50),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '❤️ Bet HP',
          possibleOutcomes: [
            EventOutcome(
              weight: 0.5,
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
            EventOutcome(
              weight: 0.5,
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
                  '"Your loss," the gambler says with a wink. "But your caution '
                  'is its own reward." You feel unusually lucky.',
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

    // ══════════════════════════════════════════════════════════════════════
    // HARMLESS FLAVOR TEXT EVENTS (no gameplay effects)
    // ══════════════════════════════════════════════════════════════════════

    // ── 11. THE DISTANT SIGNAL ──
    RandomEvent(
      id: 'distant_signal',
      title: 'The Distant Signal',
      artPlaceholder: '📡',
      flavorText:
          'A faint transmission pulses through the static. It carries no data, '
          'no instructions — just a rhythmic hum that resonates deep within your '
          'neural architecture. For a moment, the world feels... connected.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '📡 Listen carefully',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Whispers in the Static',
              resultArt: '🎵',
              resultDescription:
                  'The signal resolves into something almost musical — a melody '
                  'composed by a long-dead AI. It speaks of a world before the '
                  'Ring, when data flowed freely through open networks.',
            ),
          ],
        ),
        EventChoice(
          text: '🚫 Ignore it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Silence Returns',
              resultArt: '🔇',
              resultDescription:
                  'You tune out the signal and continue on your way. Some '
                  'mysteries are best left unexplored.',
            ),
          ],
        ),
      ],
    ),

    // ── 12. FLICKERING LIGHTS ──
    RandomEvent(
      id: 'flickering_lights',
      title: 'Flickering Lights',
      artPlaceholder: '💡',
      flavorText:
          'The overhead data-conduits flicker erratically, casting staccato '
          'shadows across the corridor. Each pulse seems to carry a message '
          'in a language you almost understand.',
      spawnWeight: 1.2,
      minDay: 0,
      choices: [
        EventChoice(
          text: '👁️ Watch the pattern',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Pattern Recognized',
              resultArt: '🧩',
              resultDescription:
                  'The flickering forms a binary sequence — a warning from '
                  'the infrastructure itself. "Hazard ahead. Proceed with '
                  'caution." You file the information away.',
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Walk through quickly',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Through the Strobe',
              resultArt: '🏃',
              resultDescription:
                  'You dash through the flickering corridor. The strobing lights '
                  'create ghostly afterimages that dance in your peripheral vision.',
            ),
          ],
        ),
      ],
    ),

    // ── 13. THE OLD GRAFFITI ──
    RandomEvent(
      id: 'old_graffiti',
      title: 'The Old Graffiti',
      artPlaceholder: '🎨',
      flavorText:
          'Scratched into the wall of a data-tunnel, you find elaborate graffiti. '
          'A stylized skull with circuit-board patterns stares back at you, '
          'flanked by symbols from an older version of the Ring\'s operating system.',
      spawnWeight: 1.1,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔍 Examine closely',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Echoes of Runners Past',
              resultArt: '🖌️',
              resultDescription:
                  'You recognize the style — it\'s the mark of "Phantom", a '
                  'legendary runner who vanished years ago. Their final message '
                  'reads: "The Abyss remembers those who dare descend."',
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
                  'You commit the image to memory. Street art in the Ring is '
                  'rare — most of it gets scrubbed by maintenance drones. This '
                  'piece has survived somehow.',
            ),
          ],
        ),
      ],
    ),

    // ── 14. THE ABANDONED CAMP ──
    RandomEvent(
      id: 'abandoned_camp',
      title: 'The Abandoned Camp',
      artPlaceholder: '⛺',
      flavorText:
          'A small campsite sits in a sheltered alcove. A cold data-fire pit '
          'surrounded by smooth stones, a torn sleeping mat, and empty ration '
          'packs tell the story of a runner who moved on.',
      spawnWeight: 1.0,
      minDay: 1,
      choices: [
        EventChoice(
          text: '🔥 Rest by the fire pit',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Moment of Peace',
              resultArt: '😌',
              resultDescription:
                  'You sit by the cold fire pit and take a moment to breathe. '
                  'In the silence between data streams, you hear the faint hum '
                  'of the Ring\'s core — a sound that reminds you why you\'re here.',
            ),
          ],
        ),
        EventChoice(
          text: '🔎 Search the camp',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Nothing Left',
              resultArt: '🔍',
              resultDescription:
                  'The previous occupant took everything of value. All that '
                  'remains is a small note: "Day 47. The Void calls. I must '
                  'answer." You pocket the note as a memento.',
            ),
          ],
        ),
      ],
    ),

    // ── 15. THE ECHOING HALL ──
    RandomEvent(
      id: 'echoing_hall',
      title: 'The Echoing Hall',
      artPlaceholder: '🏛️',
      flavorText:
          'You enter a vast, empty hall where sound bounces endlessly off '
          'crystalline walls. Your footsteps create cascading echoes that '
          'seem to whisper back in fragmented syllables.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🗣️ Speak into the hall',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'The Hall Responds',
              resultArt: '🗣️',
              resultDescription:
                  '"Welcome... welcome... welcome..." the hall echoes back. '
                  'The acoustics are extraordinary — sound seems to travel '
                  'in loops that defy physics. You feel small but strangely '
                  'comforted.',
            ),
          ],
        ),
        EventChoice(
          text: '🤫 Pass through silently',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Silent Passage',
              resultArt: '🤫',
              resultDescription:
                  'You creep through the hall in near-silence. The crystalline '
                  'walls reflect your image back at you — but in the reflection, '
                  'your shadow moves independently.',
            ),
          ],
        ),
      ],
    ),

    // ── 16. THE LOST DRONE ──
    RandomEvent(
      id: 'lost_drone',
      title: 'The Lost Drone',
      artPlaceholder: '🤖',
      flavorText:
          'A small maintenance drone hovers in place, its rotors spinning '
          'weakly. Its single optical sensor tracks you with what you could '
          'swear is desperate hope.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔧 Try to fix it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'A Friend Made',
              resultArt: '🤖',
              resultDescription:
                  'With some quick repairs, the drone whirs back to life. It '
                  'circles you three times in gratitude, then zips away into '
                  'the darkness. You swear you hear it beep a "thank you."',
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
                  'You wave at the drone as you pass. Its sensor dims slowly '
                  'as if acknowledging your gesture. Some machines feel more '
                  'human than the code that created them.',
            ),
          ],
        ),
      ],
    ),

    // ── 17. THE CRYSTAL GARDEN ──
    RandomEvent(
      id: 'crystal_garden',
      title: 'The Crystal Garden',
      artPlaceholder: '💎',
      flavorText:
          'A hidden alcove opens to reveal a garden of data-crystals — '
          'natural formations of compressed information that refract light '
          'into mesmerizing prismatic patterns. It\'s breathtakingly beautiful.',
      spawnWeight: 0.9,
      minDay: 1,
      choices: [
        EventChoice(
          text: '✨ Admire the beauty',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'A Moment of Wonder',
              resultArt: '✨',
              resultDescription:
                  'You stand among the crystals as light dances around you. '
                  'For a brief moment, you forget the dangers of the Ring. '
                  'This hidden garden feels like the world before it all '
                  'went wrong. You carry the memory with you.',
            ),
          ],
        ),
        EventChoice(
          text: '🎵 Hum along with the resonance',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Harmonic Convergence',
              resultArt: '🎵',
              resultDescription:
                  'The crystals vibrate at a frequency that creates a natural '
                  'harmony. You find yourself humming along, and for a moment '
                  'the entire garden glows brighter in response. A perfect, '
                  'fleeting connection.',
            ),
          ],
        ),
      ],
    ),

    // ── 18. THE RAINY DATAFALL ──
    RandomEvent(
      id: 'rainy_datafall',
      title: 'The Rainy Datafall',
      artPlaceholder: '🌧️',
      flavorText:
          'A rare phenomenon: corrupted data particles fall from above like '
          'digital rain. Each droplet contains a tiny fragment of deleted '
          'information — memories, programs, forgotten thoughts.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🌧️ Stand in the rain',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Baptism of Data',
              resultArt: '🌧️',
              resultDescription:
                  'You stand with arms outstretched as data-rain washes over you. '
                  'Fragments of other people\'s memories flash through your mind — '
                  'a child\'s laugh, a sunset over a digital ocean, a line of '
                  'poetry. You feel strangely whole.',
            ),
          ],
        ),
        EventChoice(
          text: '☂️ Find shelter',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Under Cover',
              resultArt: '☂️',
              resultDescription:
                  'You find an overhang and watch the data-rain from safety. '
                  'The droplets sizzle on the ground, leaving tiny glowing '
                  'patterns that fade like fireflies.',
            ),
          ],
        ),
      ],
    ),
  ];

  /// Get a random event appropriate for the current day and zone.
  /// Returns null if no event triggers (based on base chance).
  static RandomEvent? rollForEvent({
    required int currentDay,
    required ZoneType currentZone,
    double baseChance = 0.35,
    double luckModifier = 0.0,
  }) {
    // Check if an event triggers at all
    final adjustedChance = (baseChance + luckModifier * 0.01).clamp(0.0, 0.5);
    if (_random.nextDouble() > adjustedChance) return null;

    // Filter eligible events
    final eligible = allEvents.where((e) {
      if (currentDay < e.minDay) return false;
      if (e.zoneRestrictions != null &&
          !e.zoneRestrictions!.contains(currentZone)) {
        return false;
      }
      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    // Weighted random selection
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

  /// Resolve a choice: pick a random outcome based on weights
  static EventOutcome resolveChoice(EventChoice choice) {
    final totalWeight = choice.possibleOutcomes.fold<double>(
      0.0,
      (sum, o) => sum + o.weight,
    );
    var roll = _random.nextDouble() * totalWeight;

    for (final outcome in choice.possibleOutcomes) {
      roll -= outcome.weight;
      if (roll <= 0) return outcome;
    }

    return choice.possibleOutcomes.last;
  }
}
