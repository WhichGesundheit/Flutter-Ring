import 'package:flutter/material.dart';
import '../services/save_file_manager.dart';
import '../widgets/game_theme.dart';

class SaveManagerScreen extends StatefulWidget {
  final Function(int slot)? onLoadSave;
  final VoidCallback onNewGame;
  final bool showBackButton;
  final VoidCallback? onBack;

  const SaveManagerScreen({
    super.key,
    this.onLoadSave,
    required this.onNewGame,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  State<SaveManagerScreen> createState() => _SaveManagerScreenState();
}

class _SaveManagerScreenState extends State<SaveManagerScreen> {
  final SaveFileManager _saveManager = SaveFileManager();
  List<SaveSummary> _saves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSaves();
  }

  Future<void> _loadSaves() async {
    setState(() => _isLoading = true);
    _saves = await _saveManager.getAllSaveSummaries();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteSave(int slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: const Text(
          'Delete Save?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: GameColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _saveManager.deleteSlot(slot);
      await _loadSaves();
    }
  }

  Future<void> _renameSave(int slot, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: const Text('Rename Save', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter save name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: GameColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: GameColors.accent),
            ),
          ),
          autofocus: true,
          maxLength: 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text(
              'Save',
              style: TextStyle(color: GameColors.accent),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await _saveManager.renameSlot(slot, newName);
      await _loadSaves();
    }
  }

  Color _zoneColor(String zone) {
    switch (zone) {
      case 'town':
        return GameColors.success;
      case 'ruins':
        return GameColors.accent;
      case 'citadel':
        return GameColors.gold;
      default:
        return GameColors.warning;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        title: const Text('Save Slots'),
        backgroundColor: GameColors.surface,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: GameColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Save slots
                for (int i = 0; i < SaveFileManager.maxSlots; i++)
                  _buildSaveSlot(i),

                const SizedBox(height: 16),

                // New Game button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: widget.onNewGame,
                    label: const Text(
                      'NEW GAME',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSaveSlot(int slot) {
    final save = _saves.where((s) => s.slot == slot).firstOrNull;

    if (save == null) {
      // Empty slot
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GameColors.border.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.grey, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SLOT ${slot + 1}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Empty',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      );
    }

    // Filled slot
    final zoneColor = _zoneColor(save.currentZone);
    final days = save.hoursPassed ~/ 24;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: save.syncStatus == 'synced'
              ? GameColors.success.withValues(alpha: 0.5)
              : GameColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onLoadSave?.call(slot),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Slot icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: zoneColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${slot + 1}',
                        style: TextStyle(
                          color: zoneColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Save info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Save name
                        Text(
                          save.saveName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Character + class
                        Text(
                          '${save.playerName} · ${save.className}',
                          style: TextStyle(
                            color: GameColors.accent,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Sync status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: save.syncStatus == 'synced'
                          ? GameColors.success.withValues(alpha: 0.15)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          save.syncStatus == 'synced'
                              ? Icons.cloud_done
                              : Icons.phone_android,
                          size: 12,
                          color: save.syncStatus == 'synced'
                              ? GameColors.success
                              : Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          save.syncStatus == 'synced' ? 'Cloud' : 'Local',
                          style: TextStyle(
                            fontSize: 9,
                            color: save.syncStatus == 'synced'
                                ? GameColors.success
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Stats row
              Row(
                children: [
                  _buildStatChip(
                    Icons.access_time,
                    'Day $days',
                    GameColors.accent,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.location_on,
                    save.currentZone[0].toUpperCase() +
                        save.currentZone.substring(1),
                    zoneColor,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.favorite,
                    '${save.hp}/${save.maxHp}',
                    save.hp > save.maxHp * 0.5
                        ? GameColors.success
                        : GameColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.monetization_on,
                    '${save.credits}g',
                    GameColors.gold,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Footer row: time ago + actions
              Row(
                children: [
                  Text(
                    'Updated ${_formatTimeAgo(save.updatedAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const Spacer(),
                  // Rename
                  GestureDetector(
                    onTap: () => _renameSave(slot, save.saveName),
                    child: Icon(Icons.edit, size: 16, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 12),
                  // Delete
                  GestureDetector(
                    onTap: () => _deleteSave(slot),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: GameColors.danger.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Load arrow
                  Icon(Icons.chevron_right, color: Colors.grey[500]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
