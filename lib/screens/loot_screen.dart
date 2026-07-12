import 'package:flutter/material.dart';
import '../models/item.dart';
import 'inventory_screen.dart';

class LootScreen extends StatefulWidget {
  final Item loot;
  final VoidCallback onExtract;
  final VoidCallback onScrap;

  const LootScreen({
    super.key,
    required this.loot,
    required this.onExtract,
    required this.onScrap,
  });

  @override
  State<LootScreen> createState() => _LootScreenState();
}

class _LootScreenState extends State<LootScreen> {
  bool _isOpened = false;

  @override
  Widget build(BuildContext context) {
    List<String> stats = [];
    if (widget.loot.attackBonus > 0) {
      stats.add("+${widget.loot.attackBonus} ATK");
    }
    if (widget.loot.damageReduction > 0) {
      stats.add("+${widget.loot.damageReduction} Block");
    }
    if (widget.loot.lifeSteal > 0) {
      stats.add("+${widget.loot.lifeSteal} LifeSteal");
    }
    if (widget.loot.thorns > 0) {
      stats.add("+${widget.loot.thorns} Thorns");
    }
    if (widget.loot.critChance > 0) {
      stats.add("+${(widget.loot.critChance * 100).toInt()}% Crit");
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: !_isOpened
                  ? _buildClosedChestView()
                  : _buildOpenChestView(stats),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClosedChestView() {
    return Column(
      key: const ValueKey('closed_chest'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.amber.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.inventory_2, size: 100, color: Colors.amber),
        ),
        const SizedBox(height: 30),
        const Text(
          "ANOMALOUS DEBRIS CONTAINMENT",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          "Unidentified signature detected inside. Access terminal decryption keys to unseal.",
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.lock_open, color: Colors.black),
          label: const Text("DECRYPT & OPEN CHEST"),
          onPressed: () {
            setState(() {
              _isOpened = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOpenChestView(List<String> stats) {
    return Column(
      key: const ValueKey('open_chest'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: const Icon(
              Icons.unarchive,
              size: 100,
              color: Colors.greenAccent,
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          "DECRYPTION COMPLETE",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          widget.loot.name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        rarityBadge(widget.loot.rarity, fontSize: 12),
        const SizedBox(height: 4),
        Text(
          "SIGNATURE: ${widget.loot.type.name.toUpperCase()}",
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stats.join('  |  '),
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          widget.loot.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 15,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text(
            "EXTRACT ITEM (Backpack)",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: widget.onExtract,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amberAccent,
            side: const BorderSide(color: Colors.amberAccent, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.delete_sweep),
          label: Text(
            "SCRAP FOR PARTS (+${widget.loot.sellValue} Credits)",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: widget.onScrap,
        ),
      ],
    );
  }
}
