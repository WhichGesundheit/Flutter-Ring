import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:math';

// Import Models
import 'models/item.dart';
import 'models/character.dart';
import 'models/enemy.dart';
import 'models/boss.dart';
import 'models/merchant.dart';
import 'models/zone.dart';
import 'models/npc.dart';
import 'models/random_event.dart';
import 'models/status_effect.dart';

// Import Screens
import 'screens/start_screen.dart';
import 'screens/character_select_screen.dart';
import 'screens/main_screen.dart';
import 'screens/travel_screen.dart';
import 'screens/battle_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/loot_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/gleed_screen.dart';
import 'screens/event_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop Window Size Constraints (9:16 Aspect Ratio)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 800),
      minimumSize: Size(450, 800),
      maximumSize: Size(450, 800),
      center: true,
      title: 'Flutter Ring',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Lock mobile viewports strictly to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: 'https://egeklnnqiewhhpctxxws.supabase.co',
    publishableKey: 'sb_publishable_SToxLGqoyQWJIJGlq4CLng_p7Suocgy',
  );
  runApp(const FlutterRingGame());
}

class FlutterRingGame extends StatelessWidget {
  const FlutterRingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Ring',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.red[900],
      ),
      home: const GameController(),
    );
  }
}

class GameController extends StatefulWidget {
  const GameController({super.key});
  @override
  State<GameController> createState() => _GameControllerState();
}

class _GameControllerState extends State<GameController> {
  final supabase = Supabase.instance.client;
  String _currentScreen = 'start';
  Character? player;
  String? currentRunId;
  int hoursPassed = 0;
  ZoneType currentZone = ZoneType.town;

  static const int maxInventorySize = 10;
  List<Item> inventory = [];
  List<Item?> equippedSlots = [];

  Enemy? activeEnemy;
  List<Item> shopItems = [];
  Item? foundLoot;
  String? _detectedGoldColumn;
  BossEncounterTracker bossTracker = BossEncounterTracker();
  MerchantManager merchantManager = MerchantManager();
  NPCManager npcManager = NPCManager();

  // ── Pending event state ──
  RandomEvent? _pendingEvent;

  // ── Hyper-boss state ──
  /// Last day on which the hyper boss for that week was triggered.
  /// -1 means "never".
  int lastHyperBossDay = -1;

  /// When a hyper boss is queued and the player must immediately fight it.
  bool _hyperBossQueued = false;

  // ── Shop refresh state ──
  /// In-game hour at which the cached shop stock was last (re)generated.
  int lastShopRefreshHour = -1000;

  // ── Merchant rotation state ──
  /// In-game hour at which traveling merchants were last rotated.
  int lastMerchantRotationHour = -1000;

  void changeScreen(String screenName) {
    setState(() => _currentScreen = screenName);
  }

  /// Auto-equip items from a list of drops if matching empty slots exist.
  /// Returns the list of items that could NOT be auto-equipped (still in drops).
  List<Item> _autoEquipDrops(List<Item> drops) {
    final List<Item> remaining = [];
    for (final item in drops) {
      bool equipped = false;
      for (int i = 0; i < player!.slotLayout.length; i++) {
        if (player!.slotLayout[i] == item.type && equippedSlots[i] == null) {
          equippedSlots[i] = item;
          equipped = true;
          break;
        }
      }
      if (!equipped) {
        remaining.add(item);
      }
    }
    return remaining;
  }

  /// Generates a fresh pool of items for the settlement shop.
  List<Item> _generateShopStock() {
    final random = Random();
    final pool = List<Item>.from(Item.shopLootPool)..shuffle(random);
    final count = 4 + random.nextInt(3);
    return pool.take(count).toList();
  }

  /// Get the shop stock, regenerating it only if 24h have passed.
  List<Item> _getOrRefreshShopStock() {
    if (shopItems.isEmpty || (hoursPassed - lastShopRefreshHour) >= 24) {
      shopItems = _generateShopStock();
      lastShopRefreshHour = hoursPassed;
    }
    return shopItems;
  }

  /// Called after any `hoursPassed` change. If the player just rolled over
  /// to a multiple-of-7 day (7, 14, 21, …) and the hyper boss for that
  /// week hasn't been engaged yet, force the player into battle with it.
  void _checkForHyperBoss() {
    final currentDay = hoursPassed ~/ 24;
    if (currentDay <= 0) return;
    if (currentDay % 7 != 0) return;
    if (currentDay == lastHyperBossDay) return;
    // Already in battle – don't override.
    if (_currentScreen == 'battle') return;

    lastHyperBossDay = currentDay;
    final boss = WeeklyBosses.getHyperBossForWeek(currentDay ~/ 7);
    setState(() {
      activeEnemy = boss;
      _hyperBossQueued = true;
      _currentScreen = 'battle';
    });
  }

  void mapsToZone(ZoneType targetZone) {
    setState(() {
      currentZone = targetZone;
      hoursPassed += 2; // travel now costs 2h
    });
    merchantManager.rotateLocationsIfDue(hoursPassed);
    npcManager.rotateLocationsIfDue(hoursPassed);

    // Process status effect hourly ticks
    if (player != null) {
      player!.tickHourEffects();
      player!.processHourlyEffects();
      player!.removeExpiredEffects();
    }

    // Check if player died from status effects during travel
    if (player != null && player!.hp <= 0) {
      player!.hp = 0;
      syncPlayerStateToCloud();
      changeScreen('game_over');
      return;
    }

    // Roll for random event during travel (skip if destination is a settlement)
    _rollForRandomEvent(destinationZone: targetZone);

    syncPlayerStateToCloud();
    _checkForHyperBoss();

    // Show pending random event if one was rolled
    if (_pendingEvent != null) {
      changeScreen('event');
    }
  }

  void _rollForRandomEvent({ZoneType? destinationZone}) {
    if (player == null) return;
    // Don't trigger events when traveling to settlements (town, ruins, citadel)
    if (destinationZone != null) {
      final destData = Zone.worldMap[destinationZone];
      if (destData != null && destData.isSettlement) return;
    }
    final currentDay = hoursPassed ~/ 24;
    final luckMod = player!.getEffectiveLuck(equippedSlots).toDouble();
    final event = EventPool.rollForEvent(
      currentDay: currentDay,
      currentZone: currentZone,
      luckModifier: luckMod,
    );
    if (event != null) {
      _pendingEvent = event;
    }
  }

  /// Check if there's a pending event to show
  RandomEvent? get pendingEvent => _pendingEvent;

  /// Consume the pending event (set to null after showing)
  void consumePendingEvent() {
    _pendingEvent = null;
  }

  void _initLocalRun(Character chosenChar) {
    int startingSlotIdx = max(
      0,
      chosenChar.slotLayout.indexOf(chosenChar.startingItem.type),
    );
    setState(() {
      player = chosenChar;
      currentRunId = 'local_run_${DateTime.now().millisecondsSinceEpoch}';
      equippedSlots = List.filled(chosenChar.slotLayout.length, null);
      equippedSlots[startingSlotIdx] = chosenChar.startingItem;
      bossTracker = BossEncounterTracker();
      merchantManager = MerchantManager();
      npcManager = NPCManager();
      _pendingEvent = null;
      lastHyperBossDay = -1;
      _hyperBossQueued = false;
      lastShopRefreshHour = -1000;
      lastMerchantRotationHour = -1000;
      shopItems = [];
      changeScreen('main');
    });
  }

  // --- SUPABASE ENGINE ACTIONS ---
  Future<void> startNewRunInCloud(Character chosenChar) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _initLocalRun(chosenChar);
      return;
    }
    try {
      Map<String, dynamic> payload = {
        'user_id': user.id,
        'current_day': hoursPassed ~/ 24,
        'player_hp': chosenChar.hp,
        'player_max_hp': chosenChar.maxHp,
        'status': 'active',
        'current_zone': currentZone.name,
      };

      dynamic runData;
      try {
        final testPayload = Map<String, dynamic>.from(payload)
          ..['player_gold'] = chosenChar.credits;
        runData = await supabase
            .from('game_runs')
            .insert(testPayload)
            .select()
            .single();
        _detectedGoldColumn = 'player_gold';
      } catch (e) {
        debugPrint("Failed with player_gold: $e. Trying with gold...");
        try {
          final testPayload = Map<String, dynamic>.from(payload)
            ..['gold'] = chosenChar.credits;
          runData = await supabase
              .from('game_runs')
              .insert(testPayload)
              .select()
              .single();
          _detectedGoldColumn = 'gold';
        } catch (e2) {
          debugPrint("Failed with gold: $e2. Trying without gold column...");
          runData = await supabase
              .from('game_runs')
              .insert(payload)
              .select()
              .single();
          _detectedGoldColumn = 'none';
        }
      }

      final String runId = runData['id'];
      int startingSlotIdx = max(
        0,
        chosenChar.slotLayout.indexOf(chosenChar.startingItem.type),
      );

      await supabase.from('run_inventory').insert({
        'run_id': runId,
        'item_id': chosenChar.startingItem.id,
        'slot_position': startingSlotIdx,
      });

      setState(() {
        player = chosenChar;
        currentRunId = runId;
        equippedSlots = List.filled(chosenChar.slotLayout.length, null);
        equippedSlots[startingSlotIdx] = chosenChar.startingItem;
        lastHyperBossDay = -1;
        _hyperBossQueued = false;
        lastShopRefreshHour = -1000;
        lastMerchantRotationHour = -1000;
        shopItems = [];
        changeScreen('main');
      });
    } catch (e) {
      debugPrint("Cloud Sync Error in startNewRun: $e");
      _initLocalRun(chosenChar);
    }
  }

  Future<void> syncPlayerStateToCloud() async {
    if (currentRunId == null ||
        player == null ||
        currentRunId!.startsWith('local_run_')) {
      return;
    }
    try {
      Map<String, dynamic> payload = {
        'player_hp': player!.hp,
        'current_day': hoursPassed ~/ 24,
        'status': (player!.hp <= 0) ? 'lost' : 'active',
        'current_zone': currentZone.name,
      };

      if (_detectedGoldColumn == 'player_gold') {
        payload['player_gold'] = player!.credits;
      } else if (_detectedGoldColumn == 'gold') {
        payload['gold'] = player!.credits;
      } else if (_detectedGoldColumn == null) {
        try {
          final probePayload = Map<String, dynamic>.from(payload)
            ..['player_gold'] = player!.credits;
          await supabase
              .from('game_runs')
              .update(probePayload)
              .eq('id', currentRunId!);
          _detectedGoldColumn = 'player_gold';
          return;
        } catch (_) {
          try {
            final probePayload = Map<String, dynamic>.from(payload)
              ..['gold'] = player!.credits;
            await supabase
                .from('game_runs')
                .update(probePayload)
                .eq('id', currentRunId!);
            _detectedGoldColumn = 'gold';
            return;
          } catch (_) {
            _detectedGoldColumn = 'none';
          }
        }
      }

      await supabase.from('game_runs').update(payload).eq('id', currentRunId!);
    } catch (e) {
      debugPrint("Error syncing player state: $e");
    }
  }

  Future<void> syncInventoryToCloud() async {
    if (currentRunId == null || currentRunId!.startsWith('local_run_')) return;

    await supabase.from('run_inventory').delete().eq('run_id', currentRunId!);
    List<Map<String, dynamic>> payload = [];

    for (int i = 0; i < equippedSlots.length; i++) {
      if (equippedSlots[i] != null) {
        payload.add({
          'run_id': currentRunId,
          'item_id': equippedSlots[i]!.id,
          'slot_position': i,
        });
      }
    }
    for (int i = 0; i < inventory.length; i++) {
      payload.add({
        'run_id': currentRunId,
        'item_id': inventory[i].id,
        'slot_position': 20 + i,
      });
    }

    if (payload.isNotEmpty) {
      await supabase.from('run_inventory').insert(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 'start':
        return StartScreen(onStart: () => changeScreen('character_select'));
      case 'character_select':
        return CharacterSelectScreen(onSelect: startNewRunInCloud);
      case 'main':
        return MainScreen(
          player: player!,
          hoursPassed: hoursPassed,
          currentZone: currentZone,
          equippedSlots: equippedSlots,
          onChangeScreen: changeScreen,
        );
      case 'travel':
        return TravelScreen(
          hoursPassed: hoursPassed,
          currentZone: currentZone,
          player: player!,
          bossTracker: bossTracker,
          merchantManager: merchantManager,
          npcManager: npcManager,
          onZoneTravel: mapsToZone,
          onAction: (type, data, cost) {
            setState(() {
              hoursPassed += cost;
              if (type == 'Enemy') {
                activeEnemy = data;
                changeScreen('battle');
              } else if (type == 'Shop') {
                // Settlement shop: refresh only every 24h, otherwise
                // re-use the cached stock.
                shopItems = _getOrRefreshShopStock();
                changeScreen('shop');
              } else if (type == 'Gleed') {
                changeScreen('gleed');
              } else if (type == 'Loot') {
                foundLoot = data;
                changeScreen('loot');
              } else if (type == 'BuyItem') {
                // Directly add purchased item to inventory
                if (inventory.length < maxInventorySize) {
                  inventory.add(data);
                }
              } else if (type == 'Heal') {
                player!.hp = player!.maxHp;
              } else if (type == 'Empty') {
                // Roll for random event during local exploration
                _rollForRandomEvent();
              }
            });
            syncPlayerStateToCloud();
            // Check for hyper boss after every time advance.
            _checkForHyperBoss();
            // Show pending random event if one was rolled
            if (_pendingEvent != null) {
              changeScreen('event');
            }
          },
          onCancel: () => changeScreen('main'),
        );
      case 'battle':
        return BattleScreen(
          player: player!,
          equippedSlots: equippedSlots,
          enemy: activeEnemy!,
          isHyperBoss: _hyperBossQueued,
          onEnd: (won, drops) {
            setState(() {
              hoursPassed += 1; // Battle now costs 1h
              _hyperBossQueued = false;
              if (won) {
                // Track weekly boss defeat (regular or hyper)
                if (activeEnemy!.isBoss) {
                  final currentDay = hoursPassed ~/ 24;
                  bossTracker.markDefeated(currentDay);
                }
                if (drops.isNotEmpty) {
                  // Auto-equip drops into empty matching slots
                  final remaining = _autoEquipDrops(drops);
                  // Add remaining to inventory (respect limit)
                  for (final item in remaining) {
                    if (inventory.length < maxInventorySize) {
                      inventory.add(item);
                    }
                  }
                }
              }
            });
            syncInventoryToCloud();
            syncPlayerStateToCloud();
            if (!won) {
              changeScreen('game_over');
            } else {
              changeScreen('main');
            }
          },
        );
      case 'inventory':
        return InventoryScreen(
          player: player!,
          inventory: inventory,
          equippedSlots: equippedSlots,
          currentZone: currentZone,
          onBack: () {
            syncInventoryToCloud();
            syncPlayerStateToCloud();
            changeScreen('main');
          },
        );
      case 'shop':
        return ShopScreen(
          player: player!,
          items: shopItems,
          inventory: inventory,
          onExit: () {
            syncPlayerStateToCloud();
            syncInventoryToCloud();
            changeScreen('main');
          },
        );
      case 'gleed':
        return GleedScreen(
          player: player!,
          inventory: inventory,
          maxInventory: maxInventorySize,
          onExit: () {
            syncPlayerStateToCloud();
            syncInventoryToCloud();
            changeScreen('main');
          },
          onCureStatus: () {
            setState(() {
              player!.attemptGamblingCure();
            });
          },
        );
      case 'loot':
        return LootScreen(
          loot: foundLoot!,
          inventoryCount: inventory.length,
          maxInventory: maxInventorySize,
          onExtract: () {
            setState(() {
              // Auto-equip if matching empty slot exists
              bool equipped = false;
              for (int i = 0; i < player!.slotLayout.length; i++) {
                if (player!.slotLayout[i] == foundLoot!.type &&
                    equippedSlots[i] == null) {
                  equippedSlots[i] = foundLoot!;
                  equipped = true;
                  break;
                }
              }
              if (!equipped) {
                inventory.add(foundLoot!);
              }
            });
            syncInventoryToCloud();
            changeScreen('main');
          },
          onScrap: () {
            setState(() {
              player!.credits += foundLoot!.sellValue;
            });
            syncPlayerStateToCloud();
            changeScreen('main');
          },
        );
      case 'event':
        return EventScreen(
          event: _pendingEvent!,
          playerCredits: player!.credits,
          playerHp: player!.hp,
          playerInventory: inventory,
          maxInventory: maxInventorySize,
          onComplete: (result) {
            setState(() {
              // Apply gold change
              player!.credits = (player!.credits + result.goldChange).clamp(
                0,
                99999,
              );

              // Apply HP change
              player!.hp = (player!.hp + result.hpChange).clamp(
                0,
                player!.effectiveMaxHp,
              );

              // Apply stat boosts (permanent attack increase)
              if (result.statBoost > 0) {
                player!.baseAttack += result.statBoost;
              }

              // Apply status effects
              for (final effectType in result.statusEffectsToApply) {
                switch (effectType) {
                  case StatusEffectType.poison:
                    player!.addStatusEffect(StatusEffectFactory.poison());
                    break;
                  case StatusEffectType.burn:
                    player!.addStatusEffect(StatusEffectFactory.burn());
                    break;
                  case StatusEffectType.bleeding:
                    player!.addStatusEffect(StatusEffectFactory.bleeding());
                    break;
                  case StatusEffectType.cursed:
                    player!.addStatusEffect(StatusEffectFactory.cursed());
                    break;
                  case StatusEffectType.weakened:
                    player!.addStatusEffect(StatusEffectFactory.weakened());
                    break;
                  case StatusEffectType.frozen:
                    player!.addStatusEffect(StatusEffectFactory.frozen());
                    break;
                  case StatusEffectType.paralyzed:
                    player!.addStatusEffect(StatusEffectFactory.paralyzed());
                    break;
                  case StatusEffectType.corruption:
                    player!.addStatusEffect(StatusEffectFactory.corruption());
                    break;
                  case StatusEffectType.vulnerability:
                    player!.addStatusEffect(
                      StatusEffectFactory.vulnerability(),
                    );
                    break;
                  case StatusEffectType.madness:
                    player!.addStatusEffect(StatusEffectFactory.madness());
                    break;
                  case StatusEffectType.regeneration:
                    player!.addStatusEffect(StatusEffectFactory.regeneration());
                    break;
                  case StatusEffectType.shieldAura:
                    player!.addStatusEffect(StatusEffectFactory.shieldAura());
                    break;
                  case StatusEffectType.blessed:
                    player!.addStatusEffect(StatusEffectFactory.blessed());
                    break;
                  case StatusEffectType.empowered:
                    player!.addStatusEffect(StatusEffectFactory.empowered());
                    break;
                  case StatusEffectType.hasted:
                    player!.addStatusEffect(StatusEffectFactory.hasted());
                    break;
                  case StatusEffectType.luckyBonus:
                    player!.addStatusEffect(StatusEffectFactory.luckyBonus());
                    break;
                  case StatusEffectType.resistanceBoost:
                    player!.addStatusEffect(
                      StatusEffectFactory.resistanceBoost(),
                    );
                    break;
                  case StatusEffectType.lifeStealAura:
                    player!.addStatusEffect(
                      StatusEffectFactory.lifeStealAura(),
                    );
                    break;
                }
              }

              // Apply item gains
              for (final item in result.itemsGained) {
                if (inventory.length < maxInventorySize) {
                  inventory.add(item);
                }
              }

              // Check if player died from event
              if (player!.hp <= 0) {
                player!.hp = 0;
                _pendingEvent = null;
                syncPlayerStateToCloud();
                changeScreen('game_over');
                return;
              }

              // Consume the event and return to main
              _pendingEvent = null;
            });
            syncPlayerStateToCloud();
            syncInventoryToCloud();
            changeScreen('main');
          },
        );
      case 'game_over':
        return GameOverScreen(
          player: player,
          hoursPassed: hoursPassed,
          onRestart: () {
            setState(() {
              player = null;
              currentRunId = null;
              inventory = [];
              equippedSlots = [];
              hoursPassed = 0;
              currentZone = ZoneType.town;
              bossTracker = BossEncounterTracker();
              merchantManager = MerchantManager();
              npcManager = NPCManager();
              _pendingEvent = null;
              lastHyperBossDay = -1;
              _hyperBossQueued = false;
              lastShopRefreshHour = -1000;
              lastMerchantRotationHour = -1000;
              shopItems = [];
              _currentScreen = 'character_select';
            });
          },
        );
      default:
        return const Scaffold(body: Center(child: Text("Routing breakdown.")));
    }
  }
}
