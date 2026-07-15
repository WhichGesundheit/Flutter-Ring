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
import 'models/camp_event.dart';
import 'models/status_effect.dart';

// Import Services
import 'services/save_file_manager.dart';
import 'services/cloud_sync_service.dart';
import 'services/auth_service.dart';

// Import Screens
import 'screens/login_screen.dart';
import 'screens/save_manager_screen.dart';
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
  String _currentScreen = 'login';
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
  BossEncounterTracker bossTracker = BossEncounterTracker();
  MerchantManager merchantManager = MerchantManager();
  NPCManager npcManager = NPCManager();

  // ── Pending event state ──
  RandomEvent? _pendingEvent;

  // ── Hyper-boss state ──
  int lastHyperBossDay = -1;
  bool _hyperBossQueued = false;

  // ── Shop refresh state ──
  int lastShopRefreshHour = -1000;

  // ── Merchant rotation state ──
  int lastMerchantRotationHour = -1000;

  // ── New Services ──
  final SaveFileManager _saveManager = SaveFileManager();
  late CloudSyncService _cloudSync;
  late AuthService _authService;

  // ── Current save state ──
  int? _currentSaveSlot;
  String _saveName = 'Untitled Save';

  @override
  void initState() {
    super.initState();
    _cloudSync = CloudSyncService(
      supabase: supabase,
      saveManager: _saveManager,
    );
    _authService = AuthService(supabase: supabase);
    _checkExistingSession();
  }

  /// Check if user has an existing auth session
  void _checkExistingSession() {
    final user = _authService.currentUser;
    if (user != null) {
      // Logged in user - go to save manager
      _currentScreen = 'save_manager';
    } else {
      // No session - show login
      _currentScreen = 'login';
    }
  }

  void changeScreen(String screenName) {
    setState(() => _currentScreen = screenName);
  }

  /// Auto-equip items from a list of drops if matching empty slots exist.
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

  /// Called after any `hoursPassed` change. Check for hyper boss.
  void _checkForHyperBoss() {
    final currentDay = hoursPassed ~/ 24;
    if (currentDay <= 0) return;
    if (currentDay % 7 != 0) return;
    if (currentDay == lastHyperBossDay) return;
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
      hoursPassed += 2;
    });
    merchantManager.rotateLocationsIfDue(hoursPassed);
    npcManager.rotateLocationsIfDue(hoursPassed);

    if (player != null) {
      player!.tickHourEffects();
      player!.processHourlyEffects();
      player!.removeExpiredEffects();
    }

    if (player != null && player!.hp <= 0) {
      player!.hp = 0;
      _autoSave();
      changeScreen('game_over');
      return;
    }

    _rollForRandomEvent(destinationZone: targetZone);
    _autoSave();
    _checkForHyperBoss();

    if (_pendingEvent != null) {
      changeScreen('event');
    }
  }

  void _rollForRandomEvent({ZoneType? destinationZone}) {
    if (player == null) return;
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

  RandomEvent? get pendingEvent => _pendingEvent;

  void consumePendingEvent() {
    _pendingEvent = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE SYSTEM – Local-first with optional cloud sync
  // ═══════════════════════════════════════════════════════════════════════════

  /// Build SaveData from current game state
  SaveData _buildSaveData({String? name}) {
    final now = DateTime.now();
    return SaveData(
      id: currentRunId ?? 'local_run_${now.millisecondsSinceEpoch}',
      saveName: name ?? _saveName,
      createdAt: now,
      updatedAt: now,
      status: (player?.hp ?? 0) <= 0 ? 'lost' : 'active',
      playerName: player?.name ?? 'Unknown',
      className: player?.className ?? 'Unknown',
      imagePath: player?.imagePath,
      hp: player?.hp ?? 0,
      maxHp: player?.maxHp ?? 0,
      baseAttack: player?.baseAttack ?? 0,
      credits: player?.credits ?? 0,
      hoursPassed: hoursPassed,
      currentZone: currentZone.name,
      equippedSlots: equippedSlots,
      inventory: inventory,
      slotLayout: player?.slotLayout.map((s) => s.name).toList() ?? [],
      lastHyperBossDay: lastHyperBossDay,
      lastShopRefreshHour: lastShopRefreshHour,
      lastMerchantRotationHour: lastMerchantRotationHour,
      bossDefeatedDays: bossTracker.defeatedBosses.toList(),
      activeStatusEffects: player?.activeStatusEffects ?? [],
      cloudRunId: currentRunId?.startsWith('local_') == true
          ? null
          : currentRunId,
      syncStatus: _authService.isLoggedIn ? 'pending_sync' : 'local_only',
    );
  }

  /// Load game state from SaveData
  void _loadFromSaveData(SaveData data, int slot) {
    final slotTypes = data.slotLayout
        .map((s) => SlotType.values.byName(s))
        .toList();

    // Find the first non-null equipped item as starting item reference
    Item startingRef = Item(id: 'none', name: 'None', type: SlotType.item);
    for (final item in data.equippedSlots) {
      if (item != null) {
        startingRef = item;
        break;
      }
    }

    // Resolve imagePath: prefer saved value, fallback to name-based lookup
    final resolvedImagePath =
        data.imagePath ?? _imagePathForName(data.playerName);

    setState(() {
      _currentSaveSlot = slot;
      _saveName = data.saveName;
      currentRunId = data.id;
      hoursPassed = data.hoursPassed;
      currentZone = ZoneType.values.byName(data.currentZone);

      player = Character(
        name: data.playerName,
        className: data.className,
        hp: data.hp,
        maxHp: data.maxHp,
        baseAttack: data.baseAttack,
        credits: data.credits,
        startingItem: startingRef,
        slotLayout: slotTypes,
        imagePath: resolvedImagePath,
        activeStatusEffects: data.activeStatusEffects,
      );

      equippedSlots = List<Item?>.from(data.equippedSlots);
      inventory = List<Item>.from(data.inventory);
      lastHyperBossDay = data.lastHyperBossDay;
      lastShopRefreshHour = data.lastShopRefreshHour;
      lastMerchantRotationHour = data.lastMerchantRotationHour;
      bossTracker = BossEncounterTracker();
      for (final day in data.bossDefeatedDays) {
        bossTracker.markDefeated(day);
      }
      merchantManager = MerchantManager();
      npcManager = NPCManager();
      _pendingEvent = null;
      _hyperBossQueued = false;
      shopItems = [];
    });
  }

  /// Auto-save to current slot (called on key game actions)
  Future<void> _autoSave() async {
    if (_currentSaveSlot == null) return;
    final data = _buildSaveData();
    await _saveManager.saveToSlot(_currentSaveSlot!, data);
  }

  /// Manual save (from main screen menu). Returns true on success.
  Future<bool> _manualSave() async {
    final data = _buildSaveData();
    if (_currentSaveSlot != null) {
      try {
        await _saveManager.saveToSlot(_currentSaveSlot!, data);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Fallback: map a character name to its known image asset path.
  static String? _imagePathForName(String name) {
    const map = {
      'Valerie': 'assets/images/characters/valerie.png',
      'Aethelgard': 'assets/images/characters/aethelgard.png',
      'Vex': 'assets/images/characters/vex.png',
      'Bulwark': 'assets/images/characters/bulwark.png',
    };
    return map[name];
  }

  /// Save to a new slot
  Future<void> _saveToNewSlot(int slot, String name) async {
    _currentSaveSlot = slot;
    _saveName = name;
    final data = _buildSaveData(name: name);
    await _saveManager.saveToSlot(slot, data);
  }

  /// Sync current save to cloud. Returns true on success.
  Future<bool> _syncToCloud() async {
    if (!_authService.isLoggedIn || _currentSaveSlot == null) return false;
    final data = _buildSaveData();
    return await _cloudSync.syncToCloudWithSlot(_currentSaveSlot!, data);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SCREEN FLOW HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleAuthenticated() {
    changeScreen('save_manager');
  }

  void _handleGuestPlay() {
    _authService.playAsGuest();
    changeScreen('save_manager');
  }

  void _handleLoadSave(int slot) async {
    final data = await _saveManager.loadFromSlot(slot);
    if (data == null) {
      // No save in this slot, start new game
      _currentSaveSlot = slot;
      _saveName = 'Save ${slot + 1}';
      changeScreen('character_select');
      return;
    }
    _loadFromSaveData(data, slot);
    changeScreen('main');
  }

  void _handleNewGame() {
    changeScreen('character_select');
  }

  void _handleStartNewRun(Character chosenChar) {
    final slot = _currentSaveSlot ?? 0;
    _saveName = chosenChar.name;

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
    });

    // Save to the selected slot
    _saveToNewSlot(slot, _saveName);
    changeScreen('main');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 'login':
        return LoginScreen(
          onAuthenticated: _handleAuthenticated,
          onGuestPlay: _handleGuestPlay,
        );
      case 'save_manager':
        return SaveManagerScreen(
          onLoadSave: _handleLoadSave,
          onNewGame: _handleNewGame,
          showBackButton: _authService.isLoggedIn,
          onBack: () => changeScreen('login'),
        );
      case 'character_select':
        return CharacterSelectScreen(onSelect: _handleStartNewRun);
      case 'main':
        return MainScreen(
          player: player!,
          hoursPassed: hoursPassed,
          currentZone: currentZone,
          equippedSlots: equippedSlots,
          onChangeScreen: changeScreen,
          onSave: _manualSave,
          onSyncCloud: _authService.isLoggedIn ? _syncToCloud : null,
          saveSlot: _currentSaveSlot,
          onQuitToTitle: () {
            _autoSave();
            changeScreen('save_manager');
          },
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
                shopItems = _getOrRefreshShopStock();
                changeScreen('shop');
              } else if (type == 'Gleed') {
                changeScreen('gleed');
              } else if (type == 'Loot') {
                foundLoot = data;
                changeScreen('loot');
              } else if (type == 'BuyItem') {
                if (inventory.length < maxInventorySize) {
                  inventory.add(data);
                }
              } else if (type == 'Heal') {
                player!.hp = player!.maxHp;
              } else if (type == 'Empty') {
                _rollForRandomEvent();
              } else if (type == 'Camp') {
                // Camping: trigger a camp event (100% chance)
                _pendingEvent = CampEventPool.getRandomCampEvent();
                // Process hour-based effects for camping time
                for (int i = 0; i < cost; i++) {
                  player!.tickHourEffects();
                  player!.processHourlyEffects();
                  player!.removeExpiredEffects();
                }
              }
            });
            _autoSave();
            _checkForHyperBoss();
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
              hoursPassed += 1;
              _hyperBossQueued = false;
              if (won) {
                if (activeEnemy!.isBoss) {
                  final currentDay = hoursPassed ~/ 24;
                  bossTracker.markDefeated(currentDay);
                }
                if (drops.isNotEmpty) {
                  final remaining = _autoEquipDrops(drops);
                  for (final item in remaining) {
                    if (inventory.length < maxInventorySize) {
                      inventory.add(item);
                    }
                  }
                }
              }
            });
            _autoSave();
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
            _autoSave();
            changeScreen('main');
          },
        );
      case 'shop':
        return ShopScreen(
          player: player!,
          items: shopItems,
          inventory: inventory,
          onExit: () {
            _autoSave();
            changeScreen('main');
          },
        );
      case 'gleed':
        return GleedScreen(
          player: player!,
          inventory: inventory,
          maxInventory: maxInventorySize,
          onExit: () {
            _autoSave();
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
            _autoSave();
            changeScreen('main');
          },
          onScrap: () {
            setState(() {
              player!.credits += foundLoot!.sellValue;
            });
            _autoSave();
            changeScreen('main');
          },
        );
      case 'event':
        return EventScreen(
          event: _pendingEvent!,
          playerCredits: player!.credits,
          playerHp: player!.hp,
          playerMaxHp: player!.effectiveMaxHp,
          playerAttack: player!.baseAttack + player!.statusAttackModifier,
          playerDefense: player!.statusDefenseModifier,
          playerLuck: player!.getEffectiveLuck(equippedSlots),
          playerInventory: inventory,
          maxInventory: maxInventorySize,
          onComplete: (result) {
            setState(() {
              player!.credits = (player!.credits + result.goldChange).clamp(
                0,
                99999,
              );

              player!.hp = (player!.hp + result.hpChange).clamp(
                0,
                player!.effectiveMaxHp,
              );

              if (result.statBoost > 0) {
                player!.baseAttack += result.statBoost;
              }

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

              for (final item in result.itemsGained) {
                if (inventory.length < maxInventorySize) {
                  inventory.add(item);
                }
              }

              if (player!.hp <= 0) {
                player!.hp = 0;
                _pendingEvent = null;
                _autoSave();
                changeScreen('game_over');
                return;
              }

              _pendingEvent = null;
            });
            _autoSave();
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
              _currentSaveSlot = null;
              _saveName = 'Untitled Save';
              _currentScreen = 'save_manager';
            });
          },
        );
      default:
        return const Scaffold(body: Center(child: Text("Routing breakdown.")));
    }
  }
}
