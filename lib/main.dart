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

  List<Item> inventory = [];
  List<Item?> equippedSlots = [];

  Enemy? activeEnemy;
  List<Item> shopItems = [];
  Item? foundLoot;
  String? _detectedGoldColumn;
  BossEncounterTracker bossTracker = BossEncounterTracker();
  MerchantManager merchantManager = MerchantManager();

  void changeScreen(String screenName) {
    setState(() => _currentScreen = screenName);
  }

  void mapsToZone(ZoneType targetZone) {
    final oldDay = hoursPassed ~/ 24;
    setState(() {
      currentZone = targetZone;
      hoursPassed += 12;
    });
    if ((hoursPassed ~/ 24) > oldDay) {
      merchantManager.rotateLocations();
    }
    syncPlayerStateToCloud();
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
        'status': (player!.hp <= 0 || hoursPassed >= 168) ? 'lost' : 'active',
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

    // Fixed: Added enclosing brackets to satisfy linter rule
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
          onChangeScreen: changeScreen,
        );
      case 'travel':
        return TravelScreen(
          hoursPassed: hoursPassed,
          currentZone: currentZone,
          player: player!,
          bossTracker: bossTracker,
          merchantManager: merchantManager,
          onZoneTravel: mapsToZone,
          onAction: (type, data, cost) {
            setState(() {
              hoursPassed += cost;
              if (type == 'Enemy') {
                activeEnemy = data;
                changeScreen('battle');
              } else if (type == 'Shop') {
                shopItems = data;
                changeScreen('shop');
              } else if (type == 'Loot') {
                foundLoot = data;
                changeScreen('loot');
              } else if (type == 'Heal') {
                player!.hp = player!.maxHp;
              }

              if (hoursPassed >= 168) {
                changeScreen('game_over');
              }
            });
            syncPlayerStateToCloud();
          },
          onCancel: () => changeScreen('main'),
        );
      case 'battle':
        return BattleScreen(
          player: player!,
          equippedSlots: equippedSlots,
          enemy: activeEnemy!,
          onEnd: (won, drop) {
            setState(() {
              hoursPassed += 2; // Fighting costs 2 hours
              if (won) {
                // Track weekly boss defeat
                if (activeEnemy!.isBoss) {
                  final currentDay = hoursPassed ~/ 24;
                  bossTracker.markDefeated(currentDay);
                }
                if (drop != null) {
                  inventory.add(drop);
                }
              }
            });
            syncInventoryToCloud();
            syncPlayerStateToCloud();
            if (hoursPassed >= 168) {
              changeScreen('game_over');
            } else {
              changeScreen(won ? 'main' : 'game_over');
            }
          },
        );
      case 'inventory':
        return InventoryScreen(
          player: player!,
          inventory: inventory,
          equippedSlots: equippedSlots,
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
      case 'loot':
        return LootScreen(
          loot: foundLoot!,
          onExtract: () {
            setState(() {
              inventory.add(foundLoot!);
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
              _currentScreen = 'character_select';
            });
          },
        );
      default:
        return const Scaffold(body: Center(child: Text("Routing breakdown.")));
    }
  }
}
