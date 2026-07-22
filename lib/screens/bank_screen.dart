import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/game_theme.dart';

/// Bank investment data stored at save-slot level (shared between characters).
class BankData {
  int balance;
  List<BankInvestment> investments;

  BankData({this.balance = 0, List<BankInvestment>? investments})
    : investments = investments ?? [];

  Map<String, dynamic> toJson() => {
    'balance': balance,
    'investments': investments.map((i) => i.toJson()).toList(),
  };

  factory BankData.fromJson(Map<String, dynamic> json) {
    return BankData(
      balance: json['balance'] as int? ?? 0,
      investments:
          (json['investments'] as List?)
              ?.map((e) => BankInvestment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BankInvestment {
  String tier; // "safe", "low", "medium", "high"
  int amount;
  int startDay;
  bool isClaimed;

  BankInvestment({
    required this.tier,
    required this.amount,
    required this.startDay,
    this.isClaimed = false,
  });

  Map<String, dynamic> toJson() => {
    'tier': tier,
    'amount': amount,
    'startDay': startDay,
    'isClaimed': isClaimed,
  };

  factory BankInvestment.fromJson(Map<String, dynamic> json) {
    return BankInvestment(
      tier: json['tier'] as String,
      amount: json['amount'] as int,
      startDay: json['startDay'] as int,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }

  double get dailyReturn {
    switch (tier) {
      case 'safe':
        return 0.06;
      case 'low':
        return 0.10;
      case 'medium':
        return 0.25;
      case 'high':
        return 0.65;
      default:
        return 0.06;
    }
  }

  double get lossChance {
    switch (tier) {
      case 'safe':
        return 0.0;
      case 'low':
        return 0.05;
      case 'medium':
        return 0.15;
      case 'high':
        return 0.30;
      default:
        return 0.0;
    }
  }

  double get lossPercent {
    switch (tier) {
      case 'safe':
        return 0.0;
      case 'low':
        return 0.10;
      case 'medium':
        return 0.25;
      case 'high':
        return 0.50;
      default:
        return 0.0;
    }
  }

  String get tierLabel {
    switch (tier) {
      case 'safe':
        return 'Safe';
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      default:
        return tier;
    }
  }

  Color get tierColor {
    switch (tier) {
      case 'safe':
        return Colors.green;
      case 'low':
        return Colors.blueAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'high':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

class BankScreen extends StatefulWidget {
  final BankData bank;
  final int playerCredits;
  final int currentDay;
  final Function(BankData) onBankChanged;
  final Function(int) onCreditsChanged;
  final VoidCallback onBack;
  final bool isFloating;

  const BankScreen({
    super.key,
    required this.bank,
    required this.playerCredits,
    required this.currentDay,
    required this.onBankChanged,
    required this.onCreditsChanged,
    required this.onBack,
    this.isFloating = false,
  });

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  Widget _buildBankContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance card
          _buildBalanceCard(),
          const SizedBox(height: 16),
          // Deposit/Withdraw
          _buildDepositWithdraw(),
          const SizedBox(height: 16),
          // Investment tiers
          _buildInvestmentTiers(),
          const SizedBox(height: 16),
          // Active investments
          _buildActiveInvestments(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFloating) {
      return Container(
        decoration: BoxDecoration(
          color: GameColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: GameColors.gold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Floating header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GameColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: GameColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance,
                    color: GameColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Bank',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBankContent()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        backgroundColor: GameColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: widget.onBack,
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, color: GameColors.gold, size: 18),
            SizedBox(width: 8),
            Text('Bank'),
          ],
        ),
      ),
      body: _buildBankContent(),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'BANK BALANCE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.bank.balance} Credits',
            style: TextStyle(
              color: GameColors.gold,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your wallet: ${widget.playerCredits}c',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositWithdraw() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'DEPOSIT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _showDepositDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.remove, size: 16),
            label: const Text(
              'WITHDRAW',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _showWithdrawDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentTiers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'INVESTMENT TIERS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        _buildTierCard(
          'safe',
          'Safe',
          '6% daily return, no risk',
          Colors.green,
          0.06,
          0.0,
        ),
        const SizedBox(height: 8),
        _buildTierCard(
          'low',
          'Low Risk',
          '10% daily, 5% chance of 10% loss',
          Colors.blueAccent,
          0.10,
          0.05,
        ),
        const SizedBox(height: 8),
        _buildTierCard(
          'medium',
          'Medium Risk',
          '25% daily, 15% chance of 25% loss',
          Colors.orangeAccent,
          0.25,
          0.15,
        ),
        const SizedBox(height: 8),
        _buildTierCard(
          'high',
          'High Risk',
          '65% daily, 30% chance of 50% loss',
          Colors.redAccent,
          0.65,
          0.30,
        ),
      ],
    );
  }

  Widget _buildTierCard(
    String tier,
    String label,
    String desc,
    Color color,
    double dailyRate,
    double lossChance,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${(dailyRate * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showInvestDialog(tier, label, color),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'INVEST',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveInvestments() {
    final active = widget.bank.investments.where((i) => !i.isClaimed).toList();
    if (active.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GameColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Text(
            'No active investments',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVE INVESTMENTS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        for (final inv in active) _buildInvestmentRow(inv),
      ],
    );
  }

  Widget _buildInvestmentRow(BankInvestment inv) {
    final daysHeld = widget.currentDay - inv.startDay;
    final dailyReturn = (inv.amount * inv.dailyReturn).toInt();
    final totalReturn = dailyReturn * daysHeld;
    final currentValue = inv.amount + totalReturn;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: inv.tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: inv.tierColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${(inv.dailyReturn * 100).toInt()}%',
                style: TextStyle(
                  color: inv.tierColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.tierLabel,
                  style: TextStyle(
                    color: inv.tierColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${inv.amount}c invested · ${daysHeld}d · +${totalReturn}c',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _claimInvestment(inv),
            style: ElevatedButton.styleFrom(
              backgroundColor: GameColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              'CLAIM ${currentValue}c',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: const Text(
          'Deposit Credits',
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Wallet: ${widget.playerCredits}c',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Amount to deposit',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: GameColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: GameColors.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickAmountButtons(
                  context: ctx,
                  controller: controller,
                  maxAmount: widget.playerCredits,
                  setDialogState: setDialogState,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0 && amount <= widget.playerCredits) {
                setState(() {
                  widget.bank.balance += amount;
                  widget.onCreditsChanged(-amount);
                });
                widget.onBankChanged(widget.bank);
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Deposit',
              style: TextStyle(color: GameColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: const Text(
          'Withdraw Credits',
          style: TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bank: ${widget.bank.balance}c',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Amount to withdraw',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: GameColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: GameColors.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickAmountButtons(
                  context: ctx,
                  controller: controller,
                  maxAmount: widget.bank.balance,
                  setDialogState: setDialogState,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0 && amount <= widget.bank.balance) {
                setState(() {
                  widget.bank.balance -= amount;
                  widget.onCreditsChanged(amount);
                });
                widget.onBankChanged(widget.bank);
                Navigator.pop(ctx);
              }
            },
            child: const Text(
              'Withdraw',
              style: TextStyle(color: GameColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvestDialog(String tier, String label, Color color) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: Text('Invest in $label', style: TextStyle(color: color)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bank balance: ${widget.bank.balance}c',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Amount to invest',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: GameColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: color),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickAmountButtons(
                  context: ctx,
                  controller: controller,
                  maxAmount: widget.bank.balance,
                  setDialogState: setDialogState,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0 && amount <= widget.bank.balance) {
                setState(() {
                  widget.bank.balance -= amount;
                  widget.bank.investments.add(
                    BankInvestment(
                      tier: tier,
                      amount: amount,
                      startDay: widget.currentDay,
                    ),
                  );
                });
                widget.onBankChanged(widget.bank);
                Navigator.pop(ctx);
              }
            },
            child: Text('Invest', style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  void _claimInvestment(BankInvestment inv) {
    final random = Random();
    final daysHeld = widget.currentDay - inv.startDay;
    final dailyReturn = (inv.amount * inv.dailyReturn).toInt();
    final totalReturn = dailyReturn * daysHeld;

    int finalAmount = inv.amount + totalReturn;

    // Check for loss
    if (random.nextDouble() < inv.lossChance) {
      finalAmount = (inv.amount * (1 - inv.lossPercent)).toInt();
    }

    setState(() {
      inv.isClaimed = true;
      // Claimed credits go to bank balance, not player wallet
      widget.bank.balance += finalAmount;
    });
    widget.onBankChanged(widget.bank);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Claimed ${finalAmount}c → bank balance from ${inv.tierLabel} investment!',
        ),
        backgroundColor: GameColors.success,
      ),
    );
  }

  /// Build quick amount buttons (50%, 80%, MAX) for dialogs
  Widget _buildQuickAmountButtons({
    required BuildContext context,
    required TextEditingController controller,
    required int maxAmount,
    required StateSetter setDialogState,
  }) {
    return Row(
      children: [
        _buildQuickButton('50%', maxAmount ~/ 2, controller),
        const SizedBox(width: 8),
        _buildQuickButton('80%', (maxAmount * 0.8).floor(), controller),
        const SizedBox(width: 8),
        _buildQuickButton('MAX', maxAmount, controller),
      ],
    );
  }

  Widget _buildQuickButton(
    String label,
    int amount,
    TextEditingController controller,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: amount > 0
            ? () {
                controller.text = amount.toString();
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: GameColors.gold,
          side: BorderSide(color: GameColors.gold.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
