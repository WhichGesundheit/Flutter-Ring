import 'package:flutter/material.dart';
import '../models/random_event.dart';
import '../models/status_effect.dart';
import '../models/item.dart';
import '../widgets/game_theme.dart';

/// Screen that displays a random event with choices, then shows the result.
class EventScreen extends StatefulWidget {
  final RandomEvent event;
  final int playerCredits;
  final int playerHp;
  final int playerMaxHp;
  final int playerAttack;
  final int playerDefense;
  final int playerLuck;
  final List<Item> playerInventory;
  final int maxInventory;

  /// Callback when event is complete. Returns goldChange, hpChange,
  /// items gained, status effects to apply, and stat boosts.
  final Function(EventResult result) onComplete;

  const EventScreen({
    super.key,
    required this.event,
    required this.playerCredits,
    required this.playerHp,
    this.playerMaxHp = 100,
    this.playerAttack = 5,
    this.playerDefense = 0,
    this.playerLuck = 0,
    required this.playerInventory,
    required this.maxInventory,
    required this.onComplete,
  });

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class EventResult {
  final int goldChange;
  final int hpChange;
  final List<Item> itemsGained;
  final List<StatusEffectType> statusEffectsToApply;
  final int statBoost;
  final String? statDescription;

  const EventResult({
    this.goldChange = 0,
    this.hpChange = 0,
    this.itemsGained = const [],
    this.statusEffectsToApply = const [],
    this.statBoost = 0,
    this.statDescription,
  });
}

class _EventScreenState extends State<EventScreen>
    with SingleTickerProviderStateMixin {
  bool _showingResult = false;
  DiceRollResult? _diceResult;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Map<StatType, int> get _playerStats => {
    StatType.attack: widget.playerAttack,
    StatType.luck: widget.playerLuck,
    StatType.defense: widget.playerDefense,
    StatType.hp: widget.playerHp,
  };

  void _onChoiceSelected(EventChoice choice) {
    final result = EventPool.resolveChoice(choice, _playerStats);
    setState(() {
      _diceResult = result;
      _showingResult = true;
    });
    _animController.reset();
    _animController.forward();
  }

  void _onContinue() {
    if (_diceResult == null) return;

    final outcome = _diceResult!.outcome;
    int goldChange = 0;
    int hpChange = 0;
    List<Item> itemsGained = [];
    List<StatusEffectType> statusEffectsToApply = [];
    int statBoost = 0;
    String? statDescription;

    for (final effect in outcome.effects) {
      switch (effect.type) {
        case EventEffectType.goldChange:
          goldChange += effect.value;
          break;
        case EventEffectType.hpChange:
          hpChange += effect.value;
          break;
        case EventEffectType.statusApply:
          if (effect.statusEffect != null) {
            statusEffectsToApply.add(effect.statusEffect!);
          }
          break;
        case EventEffectType.itemGain:
          final pool = Item.chestLootPool;
          itemsGained.add(
            pool[DateTime.now().millisecondsSinceEpoch % pool.length],
          );
          break;
        case EventEffectType.statBoost:
          statBoost += effect.value;
          statDescription = effect.description;
          break;
        case EventEffectType.maxHpChange:
          hpChange += effect.value;
          break;
        case EventEffectType.statusCure:
          break;
        case EventEffectType.damageResistance:
          break;
      }
    }

    widget.onComplete(
      EventResult(
        goldChange: goldChange,
        hpChange: hpChange,
        itemsGained: itemsGained,
        statusEffectsToApply: statusEffectsToApply,
        statBoost: statBoost,
        statDescription: statDescription,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _showingResult ? _buildResultView() : _buildEventView(),
        ),
      ),
    );
  }

  Widget _buildEventView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.amberAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.event.id.startsWith('camp_')
                      ? 'CAMP EVENT'
                      : 'RANDOM EVENT',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Art placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameColors.border),
            ),
            child: Center(
              child: Text(
                widget.event.artPlaceholder,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Event title
          Text(
            widget.event.title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Flavor text
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GameColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GameColors.border),
              ),
              child: Text(
                widget.event.flavorText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Choice buttons with stat check info
          ...widget.event.choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildChoiceButton(choice),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton(EventChoice choice) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: GameColors.surface,
          foregroundColor: Colors.white,
          side: BorderSide(color: GameColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => _onChoiceSelected(choice),
        child: Text(
          choice.text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    if (_diceResult == null) return const SizedBox.shrink();

    final result = _diceResult!;
    final outcome = result.outcome;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dice roll header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GameColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      result.passed ? Icons.check_circle : Icons.cancel,
                      color: result.passed
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      result.passed ? 'CHECK PASSED' : 'CHECK FAILED',
                      style: TextStyle(
                        color: result.passed
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (result.dc > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🎲 d20(${result.d20}) + ${result.statLabel}(${result.statModifier >= 0 ? '+' : ''}${result.statModifier}) + LCK(${result.luckModifier >= 0 ? '+' : ''}${result.luckModifier}) = ${result.totalRoll} vs DC ${result.dc}',
                      style: TextStyle(
                        color: result.passed
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Result art
          Center(
            child: Text(
              outcome.resultArt,
              style: const TextStyle(fontSize: 72),
            ),
          ),
          const SizedBox(height: 16),

          // Result title
          Text(
            outcome.resultTitle.toUpperCase(),
            style: TextStyle(
              color: _getResultColor(),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Result description
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GameColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getResultColor().withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                outcome.resultDescription,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Effects summary
          _buildEffectsSummary(),
          const SizedBox(height: 16),

          // Continue button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onContinue,
              child: const Text(
                'CONTINUE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsSummary() {
    final effects = _diceResult!.outcome.effects;
    if (effects.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EFFECTS:',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          ...effects.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _getEffectText(e),
                style: TextStyle(
                  color: _getEffectColor(e),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEffectText(EventEffect effect) {
    switch (effect.type) {
      case EventEffectType.goldChange:
        return '${effect.value >= 0 ? "+" : ""}${effect.value} Credits';
      case EventEffectType.hpChange:
        return '${effect.value >= 0 ? "+" : ""}${effect.value} HP';
      case EventEffectType.statusApply:
        return 'Status: ${effect.statusEffect?.label ?? "Unknown"}';
      case EventEffectType.itemGain:
        return 'Item acquired!';
      case EventEffectType.statBoost:
        return effect.description ?? '+${effect.value} stat';
      default:
        return effect.description ?? 'Unknown effect';
    }
  }

  Color _getEffectColor(EventEffect effect) {
    switch (effect.type) {
      case EventEffectType.goldChange:
        return effect.value >= 0 ? Colors.amberAccent : Colors.redAccent;
      case EventEffectType.hpChange:
        return effect.value >= 0 ? Colors.greenAccent : Colors.redAccent;
      case EventEffectType.statusApply:
        return Colors.cyanAccent;
      case EventEffectType.itemGain:
        return Colors.tealAccent;
      case EventEffectType.statBoost:
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  Color _getResultColor() {
    if (_diceResult == null) return Colors.white;
    final hasNegative = _diceResult!.outcome.effects.any(
      (e) =>
          (e.type == EventEffectType.hpChange && e.value < 0) ||
          (e.type == EventEffectType.goldChange && e.value < 0) ||
          (e.type == EventEffectType.statusApply),
    );
    final hasPositive = _diceResult!.outcome.effects.any(
      (e) =>
          (e.type == EventEffectType.hpChange && e.value > 0) ||
          (e.type == EventEffectType.goldChange && e.value > 0) ||
          (e.type == EventEffectType.itemGain) ||
          (e.type == EventEffectType.statBoost),
    );

    if (hasNegative && !hasPositive) return Colors.redAccent;
    if (hasPositive && !hasNegative) return Colors.greenAccent;
    if (hasPositive && hasNegative) return Colors.orangeAccent;
    return Colors.white70;
  }
}
