import 'dart:math';

import 'random_event.dart';
import 'status_effect.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// CAMP EVENTS – Triggered exclusively after camping
/// Each event has 3 choices with stat checks and good/bad outcomes
/// ═══════════════════════════════════════════════════════════════════════════════

class CampEventPool {
  static final Random _random = Random();

  static final List<RandomEvent> allCampEvents = [
    // ═══════════════════════════════════════════════════════════════════
    // 1. THE WHISPERING FIRE
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_whispering_fire',
      title: 'The Whispering Fire',
      artPlaceholder: '🔥',
      flavorText:
          'You build a campfire from salvaged circuit-wood. The flames burn '
          'with an unnatural blue hue, and whispers rise from the embers — '
          'fragments of deleted code speaking of forgotten techniques.',
      choices: [
        EventChoice(
          text: '⚔️ Listen to the combat whispers',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Combat Data Absorbed!',
              resultArt: '🔥',
              resultDescription:
                  'The fire channels ancient combat algorithms into your neural '
                  'interface. You feel your attack protocols upgrade.',
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
              resultTitle: 'Paranoid Visions!',
              resultArt: '😵',
              resultDescription:
                  'The whispers invade your mind with paranoid delusions. You '
                  'spend the rest of the night fighting imaginary enemies.',
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
          text: '🛡️ Use the fire for meditation',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Inner Peace Found',
              resultArt: '🧘',
              resultDescription:
                  'The fire\'s warmth fortifies your defenses. You emerge '
                  'with reinforced shielding protocols.',
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
              resultTitle: 'Fire Surge!',
              resultArt: '💥',
              resultDescription:
                  'The fire flares violently! A wave of heat damages your systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Ignore it and sleep',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Restful Night',
              resultArt: '😴',
              resultDescription:
                  'You block out the whispers and get some rest. The night passes uneventfully.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 2. THE NIGHT STALKER
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_night_stalker',
      title: 'The Night Stalker',
      artPlaceholder: '🐺',
      flavorText:
          'Something circles your camp in the darkness. Red eyes gleam between '
          'the data-trees, and claws click against metal ground. A predator '
          'studies you, waiting for the right moment.',
      choices: [
        EventChoice(
          text: '⚔️ Stand your ground and fight',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Predator Slain!',
              resultArt: '🐺',
              resultDescription:
                  'You charge the creature and drive it back. In its lair you '
                  'find a rare item it had hoarded.',
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
              resultTitle: 'Mauled!',
              resultArt: '🩸',
              resultDescription:
                  'The creature is too fast! It sinks its fangs into your '
                  'shoulder before retreating into the dark.',
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
          text: '🍀 Set a trap with bait',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Trap Sprung!',
              resultArt: '🪤',
              resultDescription:
                  'The creature falls for your trap! You find valuable loot '
                  'in its collar — it was someone\'s pet before it went feral.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Trap Avoided!',
              resultArt: '🐺',
              resultDescription:
                  'The creature is too clever for your trap. It strikes from '
                  'behind while you check your setup.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔥 Feed it and make peace',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Guardian Beast!',
              resultArt: '🤝',
              resultDescription:
                  'The creature accepts your offering and becomes your night '
                  'guardian. You sleep soundly with it watching.',
              effects: [
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
              resultTitle: 'Not Enough!',
              resultArt: '😤',
              resultDescription:
                  'The creature eats your food but still attacks. It wanted more.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(type: EventEffectType.goldChange, value: -15),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 3. THE WANDERING HEALER
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_wandering_healer',
      title: 'The Wandering Healer',
      artPlaceholder: '💊',
      flavorText:
          'A hooded figure emerges from the darkness, carrying a medical kit '
          'that glows with healing nanites. "I can help you," they say, '
          '"but nothing in the Ring is truly free."',
      choices: [
        EventChoice(
          text: '🛡️ Accept cautiously',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Healed and Blessed!',
              resultArt: '💚',
              resultDescription:
                  'The healer\'s nanites repair your systems and grant a '
                  'lasting blessing. They nod and vanish into the night.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 30),
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
              resultTitle: 'Robbed!',
              resultArt: '💰',
              resultDescription:
                  'While the healer "treats" you, their partner raids your '
                  'supplies. You wake up lighter in both HP and credits.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -50),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.weakened,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💰 Offer payment upfront',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Fair Trade!',
              resultArt: '💊',
              resultDescription:
                  'The healer accepts your payment and provides genuine treatment. '
                  'Your systems are restored to peak condition.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
                EventEffect(type: EventEffectType.hpChange, value: 40),
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
              resultTitle: 'Snake Oil!',
              resultArt: '🐍',
              resultDescription:
                  'The healer takes your money and gives you a worthless potion. '
                  'You feel cheated and nauseous.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Decline and send them away',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Night Continues',
              resultArt: '🚶',
              resultDescription:
                  'The healer shrugs and disappears into the shadows. '
                  'At least you still have your credits.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 4. THE GHOST CAMPSITE
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_ghost_campsite',
      title: 'The Ghost Campsite',
      artPlaceholder: '👻',
      flavorText:
          'You stumble upon an abandoned camp still warm. A flickering '
          'hologram of a person replays on loop — their last moments. '
          'Equipment lies scattered, as if they left in a hurry.',
      choices: [
        EventChoice(
          text: '⚔️ Claim the equipment',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Gear Secured!',
              resultArt: '⚔️',
              resultDescription:
                  'You grab the best gear before the hologram fades. The '
                  'previous owner won\'t be needing it anymore.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 25),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ghost Attack!',
              resultArt: '👻',
              resultDescription:
                  'The hologram turns hostile! The ghost\'s defense protocol '
                  'activates and lashes out at you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💻 Download their data logs',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Intel Acquired!',
              resultArt: '💻',
              resultDescription:
                  'You download the runner\'s area maps and intel. '
                  'Their knowledge improves your defensive protocols.',
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
              resultTitle: 'Data Trap!',
              resultArt: '🟣',
              resultDescription:
                  'The data logs are corrupted! A virus infects your systems.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.corruption,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🙏 Pay respects and leave',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Respectful Departure',
              resultArt: '🙏',
              resultDescription:
                  'You leave the camp untouched. Sometimes the right thing '
                  'to do is walk away.',
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
    // 5. THE CRYSTAL SPRING
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_crystal_spring',
      title: 'The Crystal Spring',
      artPlaceholder: '💎',
      flavorText:
          'A glowing pool of crystalline liquid shimmers in the darkness. '
          'The water refracts light into mesmerizing patterns, and a faint '
          'hum of healing nanites fills the air.',
      choices: [
        EventChoice(
          text: '🍀 Drink deeply',
          statCheck: StatCheck(statType: StatType.luck, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Permanently Enhanced!',
              resultArt: '💎',
              resultDescription:
                  'The crystal water rewrites your base code. Your maximum '
                  'capacity increases permanently.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 25),
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 2,
                  description: '+25 max HP (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Contaminated Water!',
              resultArt: '☠️',
              resultDescription:
                  'The water is tainted with data-toxins. You feel your '
                  'systems degrading rapidly.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Use it for external repair',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Armor Restored!',
              resultArt: '🛡️',
              resultDescription:
                  'You use the crystal water to repair and enhance your '
                  'external plating. Defense increased.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.resistanceBoost,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 15),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Chemical Reaction!',
              resultArt: '💥',
              resultDescription:
                  'The water reacts badly with your plating, causing damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '📸 Collect samples only',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Samples Collected!',
              resultArt: '📸',
              resultDescription:
                  'You bottle some of the water for later analysis. '
                  'Careful but unrewarding.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 20),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 6. THE OLD WAR MACHINE
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_war_machine',
      title: 'The Old War Machine',
      artPlaceholder: '🤖',
      flavorText:
          'A rusted automaton activates nearby, its joints screeching with '
          'corrosion. Red targeting lights sweep the area as it powers up, '
          'identifying you as a potential threat.',
      choices: [
        EventChoice(
          text: '🛡️ Disable and salvage',
          statCheck: StatCheck(statType: StatType.defense, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Salvage Master!',
              resultArt: '🤖',
              resultDescription:
                  'You find the access panel and shut it down. The old war '
                  'machine\'s parts are worth a fortune.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 70),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Combat Activated!',
              resultArt: '💥',
              resultDescription:
                  'The machine locks onto you and opens fire before you can '
                  'disable it.',
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
          text: '💻 Hack its combat AI',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'AI Hijacked!',
              resultArt: '💻',
              resultDescription:
                  'You override its combat AI and access its military-grade '
                  'supply cache.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
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
              resultTitle: 'Firewall Engaged!',
              resultArt: '🚫',
              resultDescription:
                  'The machine\'s firewall rejects your intrusion and retaliates.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Wait for it to power down',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Power Depleted!',
              resultArt: '😴',
              resultDescription:
                  'The machine runs out of power and shuts down. Its scrap '
                  'value is modest but free.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'It Found You First!',
              resultArt: '🤖',
              resultDescription:
                  'The machine finds your hiding spot before it powers down.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 7. THE MERCHANT'S DREAM
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_merchants_dream',
      title: 'The Merchant\'s Dream',
      artPlaceholder: '💭',
      flavorText:
          'In your sleep, a phantom merchant appears in your dreams. They '
          'whisper the location of a hidden cache, drawing a map in the air '
          'with luminous fingers. You wake with the coordinates burned into '
          'your memory.',
      choices: [
        EventChoice(
          text: '⚔️ Follow the dream coordinates',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cache Found!',
              resultArt: '💭',
              resultDescription:
                  'The dream was real! You find a hidden cache exactly where '
                  'the merchant said it would be.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 55),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Nightmare Trap!',
              resultArt: '😵',
              resultDescription:
                  'The coordinates lead to an ambush! The "merchant" was a '
                  'trap set by raiders.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.weakened,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Trust the dream and dig nearby',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Buried Treasure!',
              resultArt: '💰',
              resultDescription:
                  'You dig where the dream suggested and strike a buried '
                  'container full of credits.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 80),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Nothing There!',
              resultArt: '🕳️',
              resultDescription:
                  'You dig for hours but find nothing. The dream was just a dream.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Go back to sleep',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Deep Rest',
              resultArt: '😴',
              resultDescription:
                  'You let the dream fade and sleep peacefully. '
                  'Sometimes rest is the best reward.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 8. THE NEON OWL
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_neon_owl',
      title: 'The Neon Owl',
      artPlaceholder: '🦉',
      flavorText:
          'A bioluminescent owl lands on a branch above your camp. Its '
          'feathers pulse with neon light, and something shiny glints in '
          'its talons. It watches you with unnerving intelligence.',
      choices: [
        EventChoice(
          text: '🍀 Befriend it with food',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Gift from the Owl!',
              resultArt: '🦉',
              resultDescription:
                  'The owl accepts your offering and drops its shiny prize '
                  'at your feet — a rare data-crystal.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
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
              resultTitle: 'Supply Thief!',
              resultArt: '😤',
              resultDescription:
                  'The owl steals your food and raids your supplies while '
                  'you\'re distracted.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Try to catch it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 9),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Captured!',
              resultArt: '🦉',
              resultDescription:
                  'You catch the owl and claim its treasure. The data-crystal '
                  'is incredibly valuable.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Swooped!',
              resultArt: '🩸',
              resultDescription:
                  'The owl is furious! It dive-bombs you repeatedly with '
                  'razor-sharp talons before escaping.',
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
          text: '👁️ Watch it peacefully',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Owl\'s Blessing',
              resultArt: '🦉',
              resultDescription:
                  'The owl senses your peaceful nature. It hoots softly and '
                  'a sense of calm washes over you.',
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

    // ═══════════════════════════════════════════════════════════════════
    // 9. THE CURSED TOTEM
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_cursed_totem',
      title: 'The Cursed Totem',
      artPlaceholder: '🗿',
      flavorText:
          'A strange totem pulses with dark energy nearby. It\'s carved from '
          'some unknown material and covered in glowing runes. Dark energy '
          'radiates from it in waves, but within that darkness you sense power.',
      choices: [
        EventChoice(
          text: '🛡️ Attempt to cleanse it',
          statCheck: StatCheck(statType: StatType.defense, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Totem Cleansed!',
              resultArt: '🗿',
              resultDescription:
                  'You purify the totem\'s dark energy. The cleansed artifact '
                  'grants you power and reveals a hidden item within.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Dark Surge!',
              resultArt: '🟣',
              resultDescription:
                  'The totem resists your cleansing and channels dark energy '
                  'directly into your systems.',
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
          text: '⚔️ Destroy it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Destroyed!',
              resultArt: '💥',
              resultDescription:
                  'You shatter the totem. The explosion releases a shower '
                  'of valuable dark-crystals.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 60),
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
              resultTitle: 'Curse Reflected!',
              resultArt: '🔮',
              resultDescription:
                  'Your attack bounces off the totem and curses you instead.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Leave an offering',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Totem Pleased!',
              resultArt: '🗿',
              resultDescription:
                  'The totem accepts your offering and grants you a blessing '
                  'in return.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
                EventEffect(type: EventEffectType.goldChange, value: 20),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Offering Rejected!',
              resultArt: '🚫',
              resultDescription:
                  'The totem rejects your offering and drains some of your vitality.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 10. THE STARLIT MEDITATION
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_starlit_meditation',
      title: 'The Starlit Meditation',
      artPlaceholder: '🌌',
      flavorText:
          'The sky above the Ring clears for the first time in cycles. '
          'Billions of data-stars twinkle in impossible constellations. '
          'The beauty of it demands you stop and simply... be.',
      choices: [
        EventChoice(
          text: '⚔️ Meditate on combat',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Enlightenment!',
              resultArt: '🌌',
              resultDescription:
                  'In the silence between stars, you discover a deeper '
                  'understanding of your combat protocols. Your strength '
                  'grows permanently.',
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
              resultTitle: 'Lost in Thought!',
              resultArt: '😵',
              resultDescription:
                  'You meditate too deep and lose track of time. By the time '
                  'you snap back, you\'ve been exposed to the elements.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Meditate on protection',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Shield of Stars!',
              resultArt: '🛡️',
              resultDescription:
                  'The starlight channels into your defensive systems. '
                  'You feel invulnerable under the cosmic canopy.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
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
              resultTitle: 'Exposed!',
              resultArt: '💨',
              resultDescription:
                  'Your meditation leaves you open. A gust of data-wind '
                  'damages your unshielded systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Simply enjoy the view',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Cosmic Beauty',
              resultArt: '🌌',
              resultDescription:
                  'You watch the stars and feel at peace. In a world of '
                  'corruption, this moment of beauty is priceless.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 11. THE SINGING WIRES
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_singing_wires',
      title: 'The Singing Wires',
      artPlaceholder: '🎵',
      flavorText:
          'Overhead wires vibrate in the wind, producing an eerie melody. '
          'The sound resonates with your systems in unexpected ways.',
      choices: [
        EventChoice(
          text: '⚔️ Sync combat protocols to the rhythm',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Harmonic Strike!',
              resultArt: '🎵',
              resultDescription:
                  'The resonance enhances your attack frequency. Damage output increases.',
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
              resultTitle: 'Dissonance!',
              resultArt: '😵',
              resultDescription:
                  'The frequency clashes with your systems, causing internal damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Let the music shield you',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Sonic Shield!',
              resultArt: '🛡️',
              resultDescription:
                  'The vibrations create a protective resonance field around you.',
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
              resultTitle: 'Feedback!',
              resultArt: '💥',
              resultDescription:
                  'The shield frequency feedbacks and damages your systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Sleep through the noise',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Deep Sleep',
              resultArt: '😴',
              resultDescription: 'You block out the sound and sleep soundly.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 12. THE FIREWATCHER
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_firewatcher',
      title: 'The Firewatcher',
      artPlaceholder: '🔥',
      flavorText:
          'A figure made of living flame sits across from you, warming its '
          'hands on your campfire. It speaks in a voice like crackling embers.',
      choices: [
        EventChoice(
          text: '⚔️ Challenge the fire elemental',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Fire Mastered!',
              resultArt: '🔥',
              resultDescription:
                  'You absorb the fire elemental\'s power. Your attack burns brighter.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
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
              resultTitle: 'Burned!',
              resultArt: '🔥',
              resultDescription:
                  'The fire elemental engulfs you in flames before you can react.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.burn,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💬 Ask for its wisdom',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Fire Wisdom!',
              resultArt: '🔮',
              resultDescription:
                  'The elemental shares ancient knowledge encoded in flame.',
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
              resultTitle: 'Deceived!',
              resultArt: '😤',
              resultDescription:
                  'The elemental\'s words are lies designed to weaken you.',
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
          text: '🔥 Share your fire',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Fire Bond!',
              resultArt: '🤝',
              resultDescription:
                  'The elemental accepts your offering. It warms you through the night.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.regeneration,
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 13. THE DREAMING AUTOMATON
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_dreaming_automaton',
      title: 'The Dreaming Automaton',
      artPlaceholder: '🤖',
      flavorText:
          'A deactivated automaton sits in the darkness, its eyes dimly '
          'glowing as if dreaming. Fragments of data leak from its speakers.',
      choices: [
        EventChoice(
          text: '💻 Interface with its dream',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Dream Harvested!',
              resultArt: '💭',
              resultDescription:
                  'You extract valuable data from the automaton\'s dream cache.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 55),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Nightmare!',
              resultArt: '😵',
              resultDescription:
                  'The automaton\'s nightmare infects your consciousness.',
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
          text: '🔧 Repair it',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Automaton Awakened!',
              resultArt: '🤖',
              resultDescription:
                  'The automaton wakes up grateful. It shares its spare parts.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Short Circuit!',
              resultArt: '💥',
              resultDescription:
                  'Your repair attempt causes a short circuit that damages you both.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Ignore it and sleep',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Peaceful Night',
              resultArt: '😴',
              resultDescription:
                  'The automaton\'s quiet dreaming is almost soothing.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 14. THE DATA RAIN
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_data_rain',
      title: 'The Data Rain',
      artPlaceholder: '🌧️',
      flavorText:
          'Glowing droplets of data fall from an overhead conduit, creating '
          'a shimmering rain. Each drop contains a fragment of information.',
      choices: [
        EventChoice(
          text: '⚔️ Collect the valuable drops',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Collected!',
              resultArt: '🌧️',
              resultDescription:
                  'You catch the most valuable data-rain drops and decode them.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Corrupted Rain!',
              resultArt: '☠️',
              resultDescription:
                  'The data-rain is contaminated with viral fragments.',
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
          text: '🛡️ Use it to recharge',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Recharged!',
              resultArt: '⚡',
              resultDescription:
                  'The rain replenishes your energy reserves perfectly.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 25)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overcharged!',
              resultArt: '⚡',
              resultDescription:
                  'Too much energy floods in at once. Systems overload.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -8),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.paralyzed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Use it as white noise',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Soothing Rain',
              resultArt: '🌧️',
              resultDescription:
                  'The gentle patter lulls you into a deep, restful sleep.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 15. THE LOST SCOUT
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_lost_scout',
      title: 'The Lost Scout',
      artPlaceholder: '🧭',
      flavorText:
          'A scout stumbles into your camp, lost and injured. They carry '
          'a map showing shortcuts between sectors.',
      choices: [
        EventChoice(
          text: '💊 Help them recover',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Scout Recovered!',
              resultArt: '🧭',
              resultDescription:
                  'The scout shares their map and a healing kit in gratitude.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 20),
                EventEffect(type: EventEffectType.goldChange, value: 30),
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
              resultTitle: 'Infection!',
              resultArt: '☠️',
              resultDescription:
                  'Their injuries carry a contagious data-virus that spreads to you.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.poison,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🗺️ Trade supplies for the map',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Map Acquired!',
              resultArt: '🗺️',
              resultDescription:
                  'The scout accepts your trade and shares valuable intel.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
                EventEffect(type: EventEffectType.goldChange, value: 20),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Robbed!',
              resultArt: '💰',
              resultDescription:
                  'The scout was faking their injuries. They steal some supplies.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -35),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Send them away',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Gone',
              resultArt: '🧭',
              resultDescription:
                  'The scout limps away into the darkness, disappointed.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 16. THE CHROME MOSS
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_chrome_moss',
      title: 'The Chrome Moss',
      artPlaceholder: '🌿',
      flavorText:
          'Bioluminescent moss grows on nearby structures, casting an '
          'otherworldly green glow. It pulses with organic data-processing power.',
      choices: [
        EventChoice(
          text: '⚔️ Harvest aggressively',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Moss Harvested!',
              resultArt: '🌿',
              resultDescription:
                  'The moss contains rare biological processors worth a fortune.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spore Cloud!',
              resultArt: '🤧',
              resultDescription: 'Aggressive harvesting releases toxic spores.',
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
          text: '🛡️ Use it for healing',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Healed!',
              resultArt: '💚',
              resultDescription:
                  'The moss\'s natural nanites repair your damaged systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 25),
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
              resultTitle: 'Allergic Reaction!',
              resultArt: '🤧',
              resultDescription:
                  'Your systems reject the moss. You feel worse than before.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Let it grow',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Natural Beauty',
              resultArt: '🌿',
              resultDescription:
                  'The moss provides gentle light and warmth through the night.',
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

    // ═══════════════════════════════════════════════════════════════════
    // 17. THE WINDING PATH
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_winding_path',
      title: 'The Winding Path',
      artPlaceholder: '🛤️',
      flavorText:
          'A narrow path leads from your camp deeper into unexplored territory. '
          'Strange lights flicker in the distance.',
      choices: [
        EventChoice(
          text: '⚔️ Follow the path aggressively',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Path Discovery!',
              resultArt: '🛤️',
              resultDescription:
                  'The path leads to a hidden cache left by a previous explorer.',
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
                  'Creatures were waiting along the path. They attack from both sides.',
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
          text: '🛡️ Scout cautiously',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Exploration!',
              resultArt: '🔍',
              resultDescription:
                  'Your careful approach reveals hidden traps and a safe route to supplies.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
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
              resultTitle: 'Trap Sprung!',
              resultArt: '💥',
              resultDescription:
                  'Even your caution isn\'t enough. A trap catches you off guard.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Stay in camp',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Night',
              resultArt: '😴',
              resultDescription:
                  'You choose safety over curiosity. The night passes uneventfully.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 18. THE CAMPFIRE TALES
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'campfire_tales',
      title: 'Campfire Tales',
      artPlaceholder: '📖',
      flavorText:
          'As the fire crackles, you hear stories whispered by passing '
          'data-echoes — tales of legendary runners and their fates.',
      choices: [
        EventChoice(
          text: '⚔️ Absorb the combat stories',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Combat Wisdom!',
              resultArt: '📖',
              resultDescription:
                  'The stories reveal forgotten combat techniques. Your prowess grows.',
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
              resultTitle: 'Horror Stories!',
              resultArt: '😵',
              resultDescription:
                  'The tales of runners who failed haunt your dreams.',
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
          text: '🛡️ Listen to defensive wisdom',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Defensive Insight!',
              resultArt: '🛡️',
              resultDescription:
                  'The stories teach you how to avoid common traps and ambushes.',
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
              resultTitle: 'Paranoia!',
              resultArt: '😰',
              resultDescription:
                  'The tales of danger make you overly cautious and vulnerable.',
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
          text: '😴 Fall asleep listening',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Peaceful Dreams',
              resultArt: '📖',
              resultDescription:
                  'The stories lull you into a gentle sleep. You feel refreshed.',
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
    // 19. THE IRON BIRD
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_iron_bird',
      title: 'The Iron Bird',
      artPlaceholder: '🦅',
      flavorText:
          'A metallic bird lands nearby, its feathers made of razor-sharp '
          'data-plates. It holds something shiny in its beak.',
      choices: [
        EventChoice(
          text: '⚔️ Catch it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Iron Bird Caught!',
              resultArt: '🦅',
              resultDescription:
                  'You catch the bird and claim its treasure — a rare data-crystal.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Swooped!',
              resultArt: '🩸',
              resultDescription:
                  'The bird attacks with razor feathers before flying away.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Offer food to befriend',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Iron Bird Friend!',
              resultArt: '🦅',
              resultDescription:
                  'The bird accepts your offering and drops its treasure at your feet.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
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
              resultTitle: 'Food Thief!',
              resultArt: '😤',
              resultDescription:
                  'The bird steals your food and flies off without sharing.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '👁️ Watch it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bird Departed',
              resultArt: '🦅',
              resultDescription:
                  'The bird watches you for a moment, then flies away into the night.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 20. THE GHOST CAMPSITE
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_ground_tremor',
      title: 'Ground Tremor',
      artPlaceholder: '🌍',
      flavorText:
          'The ground beneath your camp shakes violently. Cracks appear '
          'in the surface, revealing ancient structures buried below.',
      choices: [
        EventChoice(
          text: '💪 Descend into the cracks',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Underground Discovery!',
              resultArt: '🌍',
              resultDescription:
                  'You find a sealed chamber with valuable pre-Ring artifacts.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Collapse!',
              resultArt: '💥',
              resultDescription:
                  'The cracks collapse. You\'re buried under rubble briefly before escaping.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Reinforce the ground',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Stabilized!',
              resultArt: '🛡️',
              resultDescription:
                  'You reinforce the ground. The cracks reveal salvageable components.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'More Tremors!',
              resultArt: '🌍',
              resultDescription:
                  'Your efforts trigger more seismic activity. The camp is damaged.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Move camp immediately',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Camp Relocated',
              resultArt: '🏃',
              resultDescription:
                  'You quickly move to safer ground. The tremor subsides.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 21. THE LUMINOUS DRAGONFLY
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_luminous_dragonfly',
      title: 'The Luminous Dragonfly',
      artPlaceholder: '🪰',
      flavorText:
          'A dragonfly made of pure light hovers before you, its wings '
          'leaving trails of sparkling data-particles.',
      choices: [
        EventChoice(
          text: '⚔️ Capture its light essence',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Light Captured!',
              resultArt: '✨',
              resultDescription:
                  'You capture the dragonfly\'s essence. It boosts your attack power.',
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
              resultTitle: 'Blinded!',
              resultArt: '😵',
              resultDescription:
                  'The dragonfly releases a blinding flash when cornered.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -8),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Let it heal you',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Light Healing!',
              resultArt: '💚',
              resultDescription:
                  'The dragonfly\'s light passes through you, mending your systems.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 25)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Light Overload!',
              resultArt: '⚡',
              resultDescription: 'Too much light energy floods your sensors.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '👁️ Watch it dance',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Mesmerized',
              resultArt: '🪰',
              resultDescription:
                  'The dragonfly dances in the air. Its beauty fills you with peace.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 22. THE ANCIENT TERMINAL
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_ancient_terminal',
      title: 'The Ancient Terminal',
      artPlaceholder: '💻',
      flavorText:
          'Half-buried in the earth, a pre-Ring terminal still flickers '
          'with power. Its screen displays a login prompt.',
      choices: [
        EventChoice(
          text: '💻 Attempt to hack it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Terminal Hacked!',
              resultArt: '💻',
              resultDescription:
                  'You bypass the security. The terminal contains blueprints for advanced gear.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Security Lockout!',
              resultArt: '🚫',
              resultDescription:
                  'The terminal\'s defense system activates and shocks you.',
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
          text: '🛡️ Safely extract data',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Extracted!',
              resultArt: '📊',
              resultDescription:
                  'You carefully pull data fragments from the terminal without triggering defenses.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Data Trap!',
              resultArt: '🟣',
              resultDescription:
                  'The data is corrupted. It infects your systems on contact.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.corruption,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Leave it alone',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Left Alone',
              resultArt: '💻',
              resultDescription:
                  'Some old technology is best left undisturbed.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 23. THE SMOKE SPIRIT
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_smoke_spirit',
      title: 'The Smoke Spirit',
      artPlaceholder: '💨',
      flavorText:
          'Smoke from your campfire coalesces into a humanoid shape. '
          'The spirit speaks in whispers of the past and future.',
      choices: [
        EventChoice(
          text: '⚔️ Command the spirit',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spirit Bonded!',
              resultArt: '💨',
              resultDescription:
                  'The spirit submits to your will and enhances your combat abilities.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
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
              resultTitle: 'Spirit Revolt!',
              resultArt: '💀',
              resultDescription:
                  'The spirit resists your command and lashes out with spectral energy.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.cursed,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💬 Listen to its prophecy',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Prophecy Received!',
              resultArt: '🔮',
              resultDescription:
                  'The spirit reveals a vision that guides your path. Luck increases.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
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
              resultTitle: 'False Vision!',
              resultArt: '😵',
              resultDescription:
                  'The spirit deceives you. Its false prophecy leads to trouble.',
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
          text: '🔥 Feed the fire more',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spirit Dissipated',
              resultArt: '🔥',
              resultDescription:
                  'The extra fuel disrupts the spirit. It fades back into smoke.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 24. THE MIRROR SURFACE
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_mirror_surface',
      title: 'The Mirror Surface',
      artPlaceholder: '🪞',
      flavorText:
          'A perfectly reflective pool of chrome-liquid sits near your camp. '
          'Your reflection moves independently, beckoning you closer.',
      choices: [
        EventChoice(
          text: '🌀 Reach into the mirror',
          statCheck: StatCheck(statType: StatType.luck, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Mirror Power!',
              resultArt: '🪞',
              resultDescription:
                  'Your alternate self shares their experience. Your power grows.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 3,
                  description: '+3 ATK (permanent)',
                ),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Mirror Trap!',
              resultArt: '😵',
              resultDescription:
                  'The mirror tries to pull you in. You barely escape, but the experience is disorienting.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.madness,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Use it for healing',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Mirror Healing!',
              resultArt: '💚',
              resultDescription:
                  'The mirror\'s energy flows into you, repairing damaged systems.',
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
              resultTitle: 'Mirror Drain!',
              resultArt: '🟣',
              resultDescription:
                  'The mirror drains some of your life force before you pull away.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Cover it up',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Covered',
              resultArt: '🪞',
              resultDescription:
                  'You drape a cloth over the mirror. Its influence ceases.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════════════════════
    // 25. THE QUIET HOUR
    // ═══════════════════════════════════════════════════════════════════
    RandomEvent(
      id: 'camp_quiet_hour',
      title: 'The Quiet Hour',
      artPlaceholder: '🌙',
      flavorText:
          'The Ring falls silent for one hour. No data flows, no signals '
          'transmit. In the absolute silence, you hear your own systems humming.',
      choices: [
        EventChoice(
          text: '⚔️ Use the silence to upgrade weapons',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Weapons Enhanced!',
              resultArt: '⚔️',
              resultDescription:
                  'The silence allows you to fine-tune your weapons to perfection.',
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
              resultTitle: 'Tuning Failure!',
              resultArt: '💥',
              resultDescription:
                  'The tuning process goes wrong. Your weapons misfire during the next combat.',
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
          text: '🛡️ Use the silence to reinforce armor',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Armor Reinforced!',
              resultArt: '🛡️',
              resultDescription:
                  'The silence lets you weld reinforcement plates with precision.',
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
              resultTitle: 'Welding Accident!',
              resultArt: '🩸',
              resultDescription:
                  'A welding accident damages your armor instead of reinforcing it.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Simply enjoy the peace',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Perfect Rest',
              resultArt: '🌙',
              resultDescription:
                  'For the first time, you experience true silence. You feel completely renewed.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 15),
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
    // ── 17. Midnight Transaction ──
    RandomEvent(
      id: 'midnight_transaction',
      title: 'Midnight Transaction',
      artPlaceholder: '💰',
      flavorText:
          'A shadowy figure approaches your camp. "I have information '
          'that could save your life," they whisper.',
      spawnWeight: 0.8,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💰 Pay 30 credits for info',
          statCheck: StatCheck(statType: StatType.luck, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Valuable Intel!',
              resultArt: '💰',
              resultDescription: 'The figure reveals a hidden merchant route.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Scammed!',
              resultArt: '😤',
              resultDescription: 'The information is worthless.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -30),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Threaten them',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Intimidated!',
              resultArt: '⚔️',
              resultDescription: 'Your threat works. Valuable intel in hand.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Ambush!',
              resultArt: '💥',
              resultDescription: 'Their backup attacks from the shadows.',
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
          text: '🚫 Send them away',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Dismissed',
              resultArt: '🚫',
              resultDescription: 'The figure retreats.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 18. Automated Repair Drone ──
    RandomEvent(
      id: 'repair_drone',
      title: 'Automated Repair Drone',
      artPlaceholder: '🔧',
      flavorText:
          'A small repair drone descends and waits for permission to begin repairs.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🔧 Let it repair your gear',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Gear Repaired!',
              resultArt: '🔧',
              resultDescription: 'The drone expertly repairs minor damage.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 12)],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Have it reinforce armor',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Armor Enhanced!',
              resultArt: '🛡️',
              resultDescription: 'The drone adds reinforcement plating.',
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
              resultArt: '💥',
              resultDescription:
                  'The drone malfunctions and damages your armor.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Let it guard while you sleep',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Guarded Rest',
              resultArt: '😴',
              resultDescription: 'The drone watches over you as you sleep.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 10)],
            ),
          ],
        ),
      ],
    ),

    // ── 19. Night Watchman ──
    RandomEvent(
      id: 'night_watchman',
      title: 'The Night Watchman',
      artPlaceholder: '👁️',
      flavorText:
          'A massive sentinel patrols near your camp. It hasn\'t noticed you yet.',
      spawnWeight: 0.7,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💻 Hack its patrol route',
          statCheck: StatCheck(statType: StatType.defense, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Hijacked!',
              resultArt: '💻',
              resultDescription:
                  'You reprogram the sentinel to guard your camp.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.shieldAura,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 10),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Alarm Triggered!',
              resultArt: '🚨',
              resultDescription: 'The sentinel detects your intrusion.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Ambush it for parts',
          statCheck: StatCheck(statType: StatType.attack, threshold: 8),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Sentinel Destroyed!',
              resultArt: '⚔️',
              resultDescription: 'Its components are valuable.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Outmatched!',
              resultArt: '💥',
              resultDescription: 'The sentinel injures you before you retreat.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Sleep through it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Unnoticed!',
              resultArt: '😴',
              resultDescription: 'The sentinel passes without detecting you.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 10)],
            ),
          ],
        ),
      ],
    ),

    // ── 20. Campfire Ghost Story ──
    RandomEvent(
      id: 'ghost_story',
      title: 'Campfire Ghost Story',
      artPlaceholder: '👻',
      flavorText:
          'Other runners share tales of "The Corrupted" — ghost-like entities.',
      spawnWeight: 1.0,
      minDay: 1,
      choices: [
        EventChoice(
          text: '👻 Listen carefully',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Knowledge Gained!',
              resultArt: '👻',
              resultDescription:
                  'The stories contain useful info about ghost enemies.',
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
              resultTitle: 'Paranoid!',
              resultArt: '😵',
              resultDescription: 'You spend the night paranoid.',
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
          text: '⚔️ Share your battle story',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Respect Earned!',
              resultArt: '⚔️',
              resultDescription: 'The runners share supplies with you.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Fall asleep mid-story',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Early Sleep',
              resultArt: '😴',
              resultDescription: 'At least you\'re well-rested.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 10)],
            ),
          ],
        ),
      ],
    ),

    // ── 21. The Wandering Cat ──
    RandomEvent(
      id: 'wandering_cat',
      title: 'The Wandering Cat',
      artPlaceholder: '🐱',
      flavorText:
          'A robotic cat with glowing eyes pads into your camp and settles by the fire.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🐱 Pet the cat',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Comforted!',
              resultArt: '🐱',
              resultDescription: 'The cat\'s purring heals minor damage.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 10),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Examine its tech',
          statCheck: StatCheck(statType: StatType.defense, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Tech Analysis!',
              resultArt: '🔧',
              resultDescription:
                  'You learn something new from its internal tech.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 20),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Scratched!',
              resultArt: '🐱',
              resultDescription: 'The cat doesn\'t like being examined.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍎 Share rations',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Friend Made!',
              resultArt: '🐱',
              resultDescription: 'The cat shares a small data-chip.',
              effects: [EventEffect(type: EventEffectType.itemGain)],
            ),
          ],
        ),
      ],
    ),

    // ── 22. Supply Drop ──
    RandomEvent(
      id: 'supply_drop',
      title: 'Supply Drop',
      artPlaceholder: '📦',
      flavorText:
          'A supply pod crashes nearby, its parachute tangled in the digital trees.',
      spawnWeight: 0.6,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💪 Break into the pod',
          statCheck: StatCheck(statType: StatType.attack, threshold: 5),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Military Supplies!',
              resultArt: '📦',
              resultDescription: 'The pod contains military-grade supplies.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Security Lock!',
              resultArt: '🚫',
              resultDescription: 'The pod\'s security system zaps you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔧 Hack the lock',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Pod Hacked!',
              resultArt: '🔓',
              resultDescription: 'Premium supplies inside.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Lockout!',
              resultArt: '🚫',
              resultDescription: 'The pod locks down permanently.',
              effects: [],
            ),
          ],
        ),
        EventChoice(
          text: '📋 Mark for later',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Location Noted!',
              resultArt: '📋',
              resultDescription: 'You mark the location for later.',
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

    // ── 23. The Dream ──
    RandomEvent(
      id: 'the_dream',
      title: 'The Dream',
      artPlaceholder: '💭',
      flavorText:
          'You dream of the Ring as it was before — a pristine digital paradise.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '💭 Embrace the dream',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Vision Clarity!',
              resultArt: '💭',
              resultDescription: 'The dream enhances your perception.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '⚔️ Fight the dream',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Nightmare Conquered!',
              resultArt: '⚔️',
              resultDescription: 'The resistance strengthens your will.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 1,
                  description: '+1 ATK (permanent)',
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Sleep deeper',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Deep Rest',
              resultArt: '😴',
              resultDescription: 'You sleep soundly through the night.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 15)],
            ),
          ],
        ),
      ],
    ),

    // ── 24. Perimeter Breach ──
    RandomEvent(
      id: 'perimeter_breach',
      title: 'Perimeter Breach',
      artPlaceholder: '🚨',
      flavorText:
          'Motion sensors detect movement. Multiple heat signatures closing in.',
      spawnWeight: 0.8,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Fight them off',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Attackers Repelled!',
              resultArt: '⚔️',
              resultDescription: 'Their gear is worth looting.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 40),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overwhelmed!',
              resultArt: '💥',
              resultDescription: 'You drive them off but take damage.',
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
          text: '🛡️ Fortify and hold',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Defense Held!',
              resultArt: '🛡️',
              resultDescription: 'They leave supplies behind.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Breached!',
              resultArt: '💥',
              resultDescription: 'They break through your defenses.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Set a trap',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Trap Sprung!',
              resultArt: '🍀',
              resultDescription: 'Easy loot from the trapped attackers.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 50),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Failed Trap!',
              resultArt: '💥',
              resultDescription:
                  'The trap only catches one. The rest swarm you.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 25. Wandering Bard ──
    RandomEvent(
      id: 'wandering_bard',
      title: 'The Wandering Bard',
      artPlaceholder: '🎶',
      flavorText: 'A runner with a makeshift instrument approaches your camp.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🎶 Request a song',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Inspiring Melody!',
              resultArt: '🎶',
              resultDescription: 'The bard plays a rousing tune.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.empowered,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 8),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💰 Tip them 15 credits',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Grateful Bard!',
              resultArt: '💰',
              resultDescription:
                  'The bard shares rumors about nearby treasure.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 25),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Enjoy the music and sleep',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Peaceful Rest',
              resultArt: '🎶',
              resultDescription: 'The music lulls you to sleep.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 12)],
            ),
          ],
        ),
      ],
    ),

    // ── 26. Campfire Training ──
    RandomEvent(
      id: 'campfire_training',
      title: 'Campfire Training',
      artPlaceholder: '⚔️',
      flavorText: 'Another runner challenges you to a friendly sparring match.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '⚔️ Accept the challenge',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Training Victory!',
              resultArt: '⚔️',
              resultDescription: 'Your combat skills improve.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 1,
                  description: '+1 ATK (permanent)',
                ),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spar Loss!',
              resultArt: '🩸',
              resultDescription: 'The runner is faster than expected.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: -8)],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Practice defense',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Defense Drills!',
              resultArt: '🛡️',
              resultDescription: 'Your defense improves.',
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
          text: '📚 Watch and learn',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Observation!',
              resultArt: '📚',
              resultDescription: 'You pick up useful tips.',
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

    // ── 27. Night Market ──
    RandomEvent(
      id: 'night_market',
      title: 'The Night Market',
      artPlaceholder: '🏪',
      flavorText: 'A pop-up market materializes nearby with rare goods.',
      spawnWeight: 0.6,
      minDay: 2,
      choices: [
        EventChoice(
          text: '💰 Browse the wares (20c)',
          statCheck: StatCheck(statType: StatType.luck, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Rare Purchase!',
              resultArt: '🏪',
              resultDescription: 'You find a rare item at a bargain.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -20),
                EventEffect(type: EventEffectType.itemGain),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overcharged!',
              resultArt: '😤',
              resultDescription: 'The vendor overcharges you for junk.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: -20),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🔍 Look for deals',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bargain Found!',
              resultArt: '🔍',
              resultDescription: 'You haggle and get a free sample.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 15),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Window shop only',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Window Shopping',
              resultArt: '🚶',
              resultDescription: 'The vendors share a free tip.',
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

    // ── 28. Healing Stream ──
    RandomEvent(
      id: 'healing_stream',
      title: 'The Healing Stream',
      artPlaceholder: '💧',
      flavorText:
          'You discover a stream of luminous data-water with healing properties.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '💧 Drink deeply',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Fully Healed!',
              resultArt: '💧',
              resultDescription: 'The water heals your wounds completely.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 25)],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Overdose!',
              resultArt: '😵',
              resultDescription:
                  'Too much data-water. Systems reject the excess.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -5),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '💧 Take a sip',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Refreshed!',
              resultArt: '💧',
              resultDescription: 'A small sip heals some damage.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 12)],
            ),
          ],
        ),
        EventChoice(
          text: '📦 Bottle some for later',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bottled!',
              resultArt: '📦',
              resultDescription: 'You bottle the healing water for later.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 29. The Chrome Moss ──
    RandomEvent(
      id: 'chrome_moss',
      title: 'The Chrome Moss',
      artPlaceholder: '🌿',
      flavorText:
          'Bioluminescent moss grows nearby, pulsing with organic data-processing power.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '⚔️ Harvest aggressively',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Moss Harvested!',
              resultArt: '🌿',
              resultDescription: 'Rare biological processors worth a fortune.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 45),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Spore Cloud!',
              resultArt: '🤧',
              resultDescription: 'Toxic spores released.',
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
          text: '🛡️ Use it for healing',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Healed!',
              resultArt: '💚',
              resultDescription: 'The moss\'s nanites repair your systems.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: 25),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.regeneration,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🚶 Let it grow',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Natural Beauty',
              resultArt: '🌿',
              resultDescription:
                  'The moss provides gentle light through the night.',
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

    // ── 30. The Winding Path ──
    RandomEvent(
      id: 'winding_path',
      title: 'The Winding Path',
      artPlaceholder: '🛤️',
      flavorText:
          'A narrow path leads from your camp deeper into unexplored territory.',
      spawnWeight: 1.0,
      minDay: 1,
      choices: [
        EventChoice(
          text: '⚔️ Follow the path',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Path Discovery!',
              resultArt: '🛤️',
              resultDescription: 'The path leads to a hidden cache.',
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
              resultDescription: 'Creatures attack from both sides.',
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
          text: '🛡️ Scout cautiously',
          statCheck: StatCheck(statType: StatType.defense, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Exploration!',
              resultArt: '🔍',
              resultDescription: 'You find hidden traps and supplies.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 30),
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
              resultTitle: 'Trap Sprung!',
              resultArt: '💥',
              resultDescription: 'A trap catches you off guard.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Stay in camp',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Safe Night',
              resultArt: '😴',
              resultDescription: 'The night passes uneventfully.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 31. The Iron Bird ──
    RandomEvent(
      id: 'iron_bird',
      title: 'The Iron Bird',
      artPlaceholder: '🦅',
      flavorText:
          'A metallic bird lands nearby, holding something shiny in its beak.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '⚔️ Catch it',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Iron Bird Caught!',
              resultArt: '🦅',
              resultDescription: 'You claim its rare data-crystal.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 30),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Swooped!',
              resultArt: '🩸',
              resultDescription: 'The bird attacks with razor feathers.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -12),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.bleeding,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🍀 Befriend it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bird Friend!',
              resultArt: '🦅',
              resultDescription: 'The bird drops its treasure at your feet.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.luckyBonus,
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '👁️ Watch it',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Bird Departed',
              resultArt: '🦅',
              resultDescription: 'The bird watches, then flies away.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 32. Ground Tremor ──
    RandomEvent(
      id: 'ground_tremor',
      title: 'Ground Tremor',
      artPlaceholder: '🌍',
      flavorText:
          'The ground shakes. Cracks appear, revealing ancient structures below.',
      spawnWeight: 0.8,
      minDay: 1,
      choices: [
        EventChoice(
          text: '💪 Descend into the cracks',
          statCheck: StatCheck(statType: StatType.attack, threshold: 7),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Underground Discovery!',
              resultArt: '🌍',
              resultDescription: 'You find a sealed chamber with artifacts.',
              effects: [
                EventEffect(type: EventEffectType.itemGain),
                EventEffect(type: EventEffectType.goldChange, value: 50),
              ],
            ),
          ],
          failureOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Collapse!',
              resultArt: '💥',
              resultDescription: 'The cracks collapse. You escape injured.',
              effects: [
                EventEffect(type: EventEffectType.hpChange, value: -18),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Reinforce the ground',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Stabilized!',
              resultArt: '🛡️',
              resultDescription: 'The cracks reveal salvageable components.',
              effects: [
                EventEffect(type: EventEffectType.goldChange, value: 35),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🏃 Move camp',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Camp Relocated',
              resultArt: '🏃',
              resultDescription: 'You move to safer ground.',
              effects: [],
            ),
          ],
        ),
      ],
    ),

    // ── 33. Luminous Dragonfly ──
    RandomEvent(
      id: 'luminous_dragonfly',
      title: 'The Luminous Dragonfly',
      artPlaceholder: '✨',
      flavorText:
          'A dragonfly of pure light hovers before you, leaving trails of data-particles.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '⚔️ Capture its light essence',
          statCheck: StatCheck(statType: StatType.attack, threshold: 6),
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Light Captured!',
              resultArt: '✨',
              resultDescription: 'Your attack power increases.',
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
              resultTitle: 'Blinded!',
              resultArt: '😵',
              resultDescription: 'The dragonfly releases a blinding flash.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.vulnerability,
                ),
                EventEffect(type: EventEffectType.hpChange, value: -8),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '🛡️ Let it heal you',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Light Healing!',
              resultArt: '💚',
              resultDescription: 'The light mends your systems.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 25)],
            ),
          ],
        ),
        EventChoice(
          text: '👁️ Watch it dance',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Mesmerized',
              resultArt: '✨',
              resultDescription: 'The dragonfly fills you with peace.',
              effects: [
                EventEffect(
                  type: EventEffectType.statusApply,
                  statusEffect: StatusEffectType.blessed,
                ),
                EventEffect(type: EventEffectType.hpChange, value: 10),
              ],
            ),
          ],
        ),
      ],
    ),

    // ── 16. The Campfire Melody ──
    RandomEvent(
      id: 'campfire_melody',
      title: 'The Campfire Melody',
      artPlaceholder: '🎵',
      flavorText:
          'As the campfire crackles, you hear a faint melody carried on '
          'the wind. The tune is hauntingly beautiful, resonating with your neural implants.',
      spawnWeight: 1.0,
      minDay: 0,
      choices: [
        EventChoice(
          text: '🎵 Hum along',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Harmonic Resonance!',
              resultArt: '🎵',
              resultDescription:
                  'Your humming creates a harmonic resonance that enhances your combat subroutines.',
              effects: [
                EventEffect(
                  type: EventEffectType.statBoost,
                  value: 1,
                  description: '+1 ATK (permanent)',
                ),
              ],
            ),
          ],
        ),
        EventChoice(
          text: '😴 Let it lull you to sleep',
          possibleOutcomes: [
            EventOutcome(
              weight: 1.0,
              resultTitle: 'Deep Rest',
              resultArt: '😴',
              resultDescription:
                  'The melody guides you into a deep, restorative sleep.',
              effects: [EventEffect(type: EventEffectType.hpChange, value: 15)],
            ),
          ],
        ),
      ],
    ),
  ];

  /// Pick a random camp event
  static RandomEvent getRandomCampEvent() {
    return allCampEvents[_random.nextInt(allCampEvents.length)];
  }
}
