import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'save_file_manager.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// CLOUD SYNC SERVICE – Batched cloud sync using JSONB game_state
/// ═══════════════════════════════════════════════════════════════════════════════

class CloudSyncService {
  final SupabaseClient _supabase;
  final SaveFileManager _saveManager;

  CloudSyncService({
    required SupabaseClient supabase,
    required SaveFileManager saveManager,
  }) : _supabase = supabase,
       _saveManager = saveManager;

  /// Check if user is authenticated
  bool get _isAuthenticated => _supabase.auth.currentUser != null;

  /// Sync a save to cloud (single upsert per save action)
  /// Returns true on success, false on failure.
  Future<bool> syncToCloud(SaveData data) async {
    if (!_isAuthenticated) {
      debugPrint('CloudSync: Not authenticated, skipping sync');
      return false;
    }

    try {
      final user = _supabase.auth.currentUser!;

      // 1. Upsert game_runs with full game_state JSONB
      final runPayload = {
        'user_id': user.id,
        'current_day': data.hoursPassed ~/ 24,
        'player_hp': data.hp,
        'player_max_hp': data.maxHp,
        'player_gold': data.credits,
        'status': data.status,
        'current_zone': data.currentZone,
        'save_name': data.saveName,
        'player_name': data.playerName,
        'class_name': data.className,
        'game_state': data.toJson(),
        'last_synced_at': DateTime.now().toIso8601String(),
      };

      String runId;

      if (data.cloudRunId != null) {
        // Update existing run
        await _supabase
            .from('game_runs')
            .update(runPayload)
            .eq('id', data.cloudRunId!);
        runId = data.cloudRunId!;
      } else {
        // Insert new run
        final runData = await _supabase
            .from('game_runs')
            .insert(runPayload)
            .select('id')
            .single();
        runId = runData['id'] as String;
      }

      // 2. Upsert player_saves metadata
      await _supabase.from('player_saves').upsert({
        'user_id': user.id,
        'save_name': data.saveName,
        'save_slot_index': 0, // Will be updated by caller
        'cloud_run_id': runId,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. Update local save with cloud IDs
      data.cloudRunId = runId;
      data.syncStatus = 'synced';
      data.lastSyncedAt = DateTime.now();

      debugPrint('CloudSync: Successfully synced save "${data.saveName}"');
      return true;
    } catch (e) {
      debugPrint('CloudSync: Error syncing to cloud: $e');
      data.syncStatus = 'pending_sync';
      return false;
    }
  }

  /// Pull all saves from cloud
  Future<List<SaveData>> pullFromCloud() async {
    if (!_isAuthenticated) return [];

    try {
      final user = _supabase.auth.currentUser!;

      // Get all game_runs for this user with game_state
      final runs = await _supabase
          .from('game_runs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final saves = <SaveData>[];
      for (final run in runs) {
        final gameState = run['game_state'];
        if (gameState != null) {
          try {
            final save = SaveData.fromJson(gameState as Map<String, dynamic>);
            save.cloudRunId = run['id'] as String;
            save.syncStatus = 'synced';
            saves.add(save);
          } catch (e) {
            debugPrint('CloudSync: Error parsing cloud save: $e');
          }
        }
      }

      return saves;
    } catch (e) {
      debugPrint('CloudSync: Error pulling from cloud: $e');
      return [];
    }
  }

  /// Delete a cloud save
  Future<bool> deleteCloudSave(String cloudRunId) async {
    if (!_isAuthenticated) return false;

    try {
      // Delete run_inventory first (if old schema still has data)
      await _supabase.from('run_inventory').delete().eq('run_id', cloudRunId);

      // Delete player_saves reference
      await _supabase
          .from('player_saves')
          .delete()
          .eq('cloud_run_id', cloudRunId);

      // Delete game_runs
      await _supabase.from('game_runs').delete().eq('id', cloudRunId);

      debugPrint('CloudSync: Deleted cloud save $cloudRunId');
      return true;
    } catch (e) {
      debugPrint('CloudSync: Error deleting cloud save: $e');
      return false;
    }
  }

  /// Sync a local save to cloud with slot info
  Future<bool> syncToCloudWithSlot(int slot, SaveData data) async {
    if (!_isAuthenticated) return false;

    try {
      final user = _supabase.auth.currentUser!;

      // Upsert game_runs
      final runPayload = {
        'user_id': user.id,
        'current_day': data.hoursPassed ~/ 24,
        'player_hp': data.hp,
        'player_max_hp': data.maxHp,
        'player_gold': data.credits,
        'status': data.status,
        'current_zone': data.currentZone,
        'save_name': data.saveName,
        'player_name': data.playerName,
        'class_name': data.className,
        'game_state': data.toJson(),
        'last_synced_at': DateTime.now().toIso8601String(),
      };

      String runId;

      if (data.cloudRunId != null) {
        await _supabase
            .from('game_runs')
            .update(runPayload)
            .eq('id', data.cloudRunId!);
        runId = data.cloudRunId!;
      } else {
        final runData = await _supabase
            .from('game_runs')
            .insert(runPayload)
            .select('id')
            .single();
        runId = runData['id'] as String;
      }

      // Upsert player_saves with correct slot
      await _supabase.from('player_saves').upsert({
        'user_id': user.id,
        'save_name': data.saveName,
        'save_slot_index': slot,
        'cloud_run_id': runId,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,save_slot_index');

      // Update local
      data.cloudRunId = runId;
      data.syncStatus = 'synced';
      data.lastSyncedAt = DateTime.now();
      await _saveManager.saveToSlot(slot, data);
      await _saveManager.updateSyncStatus(slot, 'synced');

      return true;
    } catch (e) {
      debugPrint('CloudSync: Error in syncToCloudWithSlot: $e');
      return false;
    }
  }
}
