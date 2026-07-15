import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/status_effect.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// SAVE DATA – Complete game state for a single save slot
/// ═══════════════════════════════════════════════════════════════════════════════

class SaveData {
  final String id;
  String saveName;
  final DateTime createdAt;
  DateTime updatedAt;
  String status; // "active", "won", "lost"

  // Player State
  final String playerName;
  final String className;
  final String? imagePath;
  int hp;
  int maxHp;
  int baseAttack;
  int credits;

  // Game Progress
  int hoursPassed;
  String currentZone;

  // Equipment & Inventory (serialized)
  List<Item?> equippedSlots;
  List<Item> inventory;
  List<String> slotLayout;

  // Boss & Merchant State
  int lastHyperBossDay;
  int lastShopRefreshHour;
  int lastMerchantRotationHour;
  List<int> bossDefeatedDays;

  // Status Effects
  List<StatusEffect> activeStatusEffects;

  // Cloud Sync
  String? cloudRunId;
  String syncStatus; // "local_only", "synced", "pending_sync"
  DateTime? lastSyncedAt;

  SaveData({
    required this.id,
    required this.saveName,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    required this.playerName,
    required this.className,
    this.imagePath,
    required this.hp,
    required this.maxHp,
    required this.baseAttack,
    required this.credits,
    required this.hoursPassed,
    required this.currentZone,
    required this.equippedSlots,
    required this.inventory,
    required this.slotLayout,
    this.lastHyperBossDay = -1,
    this.lastShopRefreshHour = -1000,
    this.lastMerchantRotationHour = -1000,
    this.bossDefeatedDays = const [],
    this.activeStatusEffects = const [],
    this.cloudRunId,
    this.syncStatus = 'local_only',
    this.lastSyncedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'saveName': saveName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status,
    'playerName': playerName,
    'className': className,
    'imagePath': imagePath,
    'hp': hp,
    'maxHp': maxHp,
    'baseAttack': baseAttack,
    'credits': credits,
    'hoursPassed': hoursPassed,
    'currentZone': currentZone,
    'equippedSlots': equippedSlots.map((item) => item?.toJson()).toList(),
    'inventory': inventory.map((item) => item.toJson()).toList(),
    'slotLayout': slotLayout,
    'lastHyperBossDay': lastHyperBossDay,
    'lastShopRefreshHour': lastShopRefreshHour,
    'lastMerchantRotationHour': lastMerchantRotationHour,
    'bossDefeatedDays': bossDefeatedDays,
    'activeStatusEffects': activeStatusEffects.map((e) => e.toJson()).toList(),
    'cloudRunId': cloudRunId,
    'syncStatus': syncStatus,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
  };

  factory SaveData.fromJson(Map<String, dynamic> json) => SaveData(
    id: json['id'] as String,
    saveName: json['saveName'] as String? ?? 'Untitled Save',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    status: json['status'] as String? ?? 'active',
    playerName: json['playerName'] as String,
    className: json['className'] as String,
    imagePath: json['imagePath'] as String?,
    hp: json['hp'] as int,
    maxHp: json['maxHp'] as int,
    baseAttack: json['baseAttack'] as int,
    credits: json['credits'] as int,
    hoursPassed: json['hoursPassed'] as int,
    currentZone: json['currentZone'] as String,
    equippedSlots: (json['equippedSlots'] as List)
        .map((e) => e != null ? Item.fromJson(e as Map<String, dynamic>) : null)
        .toList(),
    inventory: (json['inventory'] as List)
        .map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList(),
    slotLayout: (json['slotLayout'] as List).cast<String>(),
    lastHyperBossDay: json['lastHyperBossDay'] as int? ?? -1,
    lastShopRefreshHour: json['lastShopRefreshHour'] as int? ?? -1000,
    lastMerchantRotationHour: json['lastMerchantRotationHour'] as int? ?? -1000,
    bossDefeatedDays: (json['bossDefeatedDays'] as List?)?.cast<int>() ?? [],
    activeStatusEffects:
        (json['activeStatusEffects'] as List?)
            ?.map((e) => StatusEffect.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    cloudRunId: json['cloudRunId'] as String?,
    syncStatus: json['syncStatus'] as String? ?? 'local_only',
    lastSyncedAt: json['lastSyncedAt'] != null
        ? DateTime.parse(json['lastSyncedAt'] as String)
        : null,
  );
}

/// Lightweight summary for the save manager UI
class SaveSummary {
  final int slot;
  final String saveName;
  final String playerName;
  final String className;
  final int currentDay;
  final int hoursPassed;
  final int hp;
  final int maxHp;
  final int credits;
  final String currentZone;
  final DateTime updatedAt;
  final String syncStatus;

  SaveSummary({
    required this.slot,
    required this.saveName,
    required this.playerName,
    required this.className,
    required this.currentDay,
    required this.hoursPassed,
    required this.hp,
    required this.maxHp,
    required this.credits,
    required this.currentZone,
    required this.updatedAt,
    required this.syncStatus,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// SAVE FILE MANAGER – Handles local save/load using SharedPreferences
/// ═══════════════════════════════════════════════════════════════════════════════

class SaveFileManager {
  static const int maxSlots = 5;
  static const String _savePrefix = 'flutter_ring_save_';
  static const String _saveIndexKey = 'flutter_ring_save_index';
  static const String _lastSlotKey = 'flutter_ring_last_slot';

  /// Save complete game state to a slot
  Future<void> saveToSlot(int slot, SaveData data) async {
    if (slot < 0 || slot >= maxSlots) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(data.toJson());
    await prefs.setString('$_savePrefix$slot', jsonStr);
    await _updateSaveIndex(slot, data);
    await prefs.setInt(_lastSlotKey, slot);
  }

  /// Load game state from a slot
  Future<SaveData?> loadFromSlot(int slot) async {
    if (slot < 0 || slot >= maxSlots) return null;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_savePrefix$slot');
    if (jsonStr == null) return null;
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SaveData.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Delete a save slot
  Future<void> deleteSlot(int slot) async {
    if (slot < 0 || slot >= maxSlots) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_savePrefix$slot');
    await _removeFromSaveIndex(slot);
  }

  /// Rename a save
  Future<void> renameSlot(int slot, String newName) async {
    if (slot < 0 || slot >= maxSlots) return;
    final data = await loadFromSlot(slot);
    if (data == null) return;
    data.saveName = newName;
    data.updatedAt = DateTime.now();
    await saveToSlot(slot, data);
  }

  /// Get all save summaries (metadata only, not full state)
  Future<List<SaveSummary>> getAllSaveSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_saveIndexKey);
    if (indexJson == null) return [];

    try {
      final indexList = jsonDecode(indexJson) as List;
      return indexList.map((e) {
        final map = e as Map<String, dynamic>;
        return SaveSummary(
          slot: map['slot'] as int,
          saveName: map['saveName'] as String? ?? 'Untitled',
          playerName: map['playerName'] as String? ?? 'Unknown',
          className: map['className'] as String? ?? 'Unknown',
          currentDay: map['currentDay'] as int? ?? 0,
          hoursPassed: map['hoursPassed'] as int? ?? 0,
          hp: map['hp'] as int? ?? 0,
          maxHp: map['maxHp'] as int? ?? 0,
          credits: map['credits'] as int? ?? 0,
          currentZone: map['currentZone'] as String? ?? 'town',
          updatedAt: DateTime.parse(map['updatedAt'] as String),
          syncStatus: map['syncStatus'] as String? ?? 'local_only',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the most recently used slot
  Future<int?> getLastUsedSlot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSlotKey);
  }

  /// Check if any saves exist
  Future<bool> hasAnySaves() async {
    final summaries = await getAllSaveSummaries();
    return summaries.isNotEmpty;
  }

  /// Update the save index (lightweight metadata for quick listing)
  Future<void> _updateSaveIndex(int slot, SaveData data) async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_saveIndexKey);
    List<Map<String, dynamic>> indexList = [];

    if (indexJson != null) {
      try {
        indexList = (jsonDecode(indexJson) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (e) {
        indexList = [];
      }
    }

    // Remove existing entry for this slot
    indexList.removeWhere((e) => e['slot'] == slot);

    // Add updated entry
    indexList.add({
      'slot': slot,
      'saveName': data.saveName,
      'playerName': data.playerName,
      'className': data.className,
      'currentDay': data.hoursPassed ~/ 24,
      'hoursPassed': data.hoursPassed,
      'hp': data.hp,
      'maxHp': data.maxHp,
      'credits': data.credits,
      'currentZone': data.currentZone,
      'updatedAt': data.updatedAt.toIso8601String(),
      'syncStatus': data.syncStatus,
    });

    // Sort by slot
    indexList.sort((a, b) => (a['slot'] as int).compareTo(b['slot'] as int));

    await prefs.setString(_saveIndexKey, jsonEncode(indexList));
  }

  /// Remove an entry from the save index
  Future<void> _removeFromSaveIndex(int slot) async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_saveIndexKey);
    if (indexJson == null) return;

    try {
      List<Map<String, dynamic>> indexList = (jsonDecode(indexJson) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      indexList.removeWhere((e) => e['slot'] == slot);
      await prefs.setString(_saveIndexKey, jsonEncode(indexList));
    } catch (e) {
      // Ignore parse errors
    }
  }

  /// Update sync status in the index
  Future<void> updateSyncStatus(int slot, String syncStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_saveIndexKey);
    if (indexJson == null) return;

    try {
      List<Map<String, dynamic>> indexList = (jsonDecode(indexJson) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (final entry in indexList) {
        if (entry['slot'] == slot) {
          entry['syncStatus'] = syncStatus;
          break;
        }
      }
      await prefs.setString(_saveIndexKey, jsonEncode(indexList));
    } catch (e) {
      // Ignore
    }
  }
}
