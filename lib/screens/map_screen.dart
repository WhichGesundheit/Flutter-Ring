import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../widgets/sphere_map_painter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MapScreen – horizontal layout: sphere left, info panel right
// Nodes on the sphere are clickable and show info on the right panel.
// ═══════════════════════════════════════════════════════════════════════════════
class MapScreen extends StatefulWidget {
  final ZoneType currentZone;
  final int currentDay;
  final Function(ZoneType target) onZoneTravel;
  final Set<ZoneType> exploredZones;

  const MapScreen({
    super.key,
    required this.currentZone,
    required this.currentDay,
    required this.onZoneTravel,
    this.exploredZones = const {},
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  double _angleX = 0.4;
  double _angleY = 0.0;
  double _scale = 1.0;
  double _baseScale = 1.0;
  ZoneType? _selectedZone;
  late final List<SphereNode> _nodes;
  late final AnimationController _autoRotateCtrl;
  final GlobalKey _sphereKey = GlobalKey();

  // ── Smooth zoom animation ──
  late final AnimationController _zoomAnimCtrl;
  double _zoomAnimStart = 1.0;
  double _zoomAnimEnd = 1.0;

  // ── Recenter animation ──
  late final AnimationController _centerAnimCtrl;
  double _centerStartAngleX = 0.0;
  double _centerStartAngleY = 0.0;
  double _centerTargetAngleX = 0.0;
  double _centerTargetAngleY = 0.0;

  // ── Merchant floating icon animation ──
  late final AnimationController _merchantAnimCtrl;

  // ── Tap detection state ──
  Offset? _dragStart;
  Offset? _lastFocalPoint;
  bool _isTapCandidate = false;

  @override
  void initState() {
    super.initState();
    _nodes = buildSphereNodes();
    _selectedZone = widget.currentZone;

    // Gentle auto-rotation
    _autoRotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _autoRotateCtrl.addListener(() {
      if (!_isDragging && mounted && !_centerAnimCtrl.isAnimating) {
        setState(() {
          _angleY += 0.0003;
        });
      }
    });

    _zoomAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _zoomAnimCtrl.addListener(() {
      final t = Curves.easeInOutCubic.transform(_zoomAnimCtrl.value);
      setState(() {
        _scale = _zoomAnimStart + (_zoomAnimEnd - _zoomAnimStart) * t;
      });
    });

    _centerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _centerAnimCtrl.addListener(() {
      final t = Curves.easeInOutCubic.transform(_centerAnimCtrl.value);
      setState(() {
        _angleX =
            _centerStartAngleX + (_centerTargetAngleX - _centerStartAngleX) * t;
        _angleY =
            _centerStartAngleY + (_centerTargetAngleY - _centerStartAngleY) * t;
      });
    });

    _merchantAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  bool _isDragging = false;

  @override
  void dispose() {
    _autoRotateCtrl.dispose();
    _zoomAnimCtrl.dispose();
    _centerAnimCtrl.dispose();
    _merchantAnimCtrl.dispose();
    super.dispose();
  }

  Set<ZoneType> get _adjacentZones {
    final currentConnections = Zone.worldMap[widget.currentZone]!.connections;
    return currentConnections.toSet();
  }

  void _onNodeTap(ZoneType zone) {
    setState(() => _selectedZone = zone);

    final isCurrent = zone == widget.currentZone;
    final isAdjacent = _isAdjacentToCurrent(zone);

    if (isCurrent) {
      // Already selected, just show info
      return;
    }

    if (isAdjacent) {
      // Smooth zoom in and rotate to center the destination node
      _zoomAnimStart = _scale;
      _zoomAnimEnd = 1.4;
      _zoomAnimCtrl.forward(from: 0.0);
      _centerNodeOnSphere(zone);
    }
  }

  void _recenterToCurrentNode() {
    _centerNodeOnSphere(widget.currentZone);
  }

  /// Rotates the sphere so that [zone] appears at the center (facing the viewer).
  void _centerNodeOnSphere(ZoneType zone) {
    final targetNode = _nodes.firstWhere(
      (n) => n.zoneType == zone,
      orElse: () => _nodes.first,
    );

    final nx = targetNode.x;
    final ny = targetNode.y;
    final nz = targetNode.z;

    final targetAngleX = math.atan2(ny, nz);
    final z1 = math.sqrt(ny * ny + nz * nz);
    final phi = math.atan2(z1, nx);
    const double targetX2 = 0.0;
    final targetAngleY = phi - math.acos(targetX2);

    _centerStartAngleX = _angleX;
    _centerStartAngleY = _angleY;
    _centerTargetAngleX = targetAngleX;
    _centerTargetAngleY = targetAngleY;
    _centerAnimCtrl.forward(from: 0.0);
  }

  Set<ZoneType> get _merchantZones => {};

  void _travelTo(ZoneType zone) {
    if (zone == widget.currentZone) return;
    if (!_isAdjacentToCurrent(zone)) return;

    widget.onZoneTravel(zone);
    if (mounted) Navigator.of(context).pop();
  }

  bool _isAdjacentToCurrent(ZoneType zone) =>
      Zone.worldMap[widget.currentZone]!.connections.contains(zone);

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final currentZoneData = Zone.worldMap[widget.currentZone]!;
    final selectedZoneData = _selectedZone != null
        ? Zone.worldMap[_selectedZone!]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(currentZoneData),

            // ── Main content: sphere left + info panel right ──
            Expanded(
              child: Row(
                children: [
                  // ── Left: 3D Sphere (60%) ──
                  Expanded(
                    flex: 6,
                    child: Stack(
                      children: [
                        // The sphere itself
                        Positioned.fill(
                          child: GestureDetector(
                            onScaleStart: (details) {
                              _baseScale = _scale;
                              _isDragging = true;
                              _dragStart = details.focalPoint;
                              _lastFocalPoint = details.focalPoint;
                              _isTapCandidate = true;
                            },
                            onScaleUpdate: (details) {
                              // If drag moved more than 10px, it's not a tap
                              if (_dragStart != null &&
                                  (details.focalPoint - _dragStart!).distance >
                                      10) {
                                _isTapCandidate = false;
                              }
                              _lastFocalPoint = details.focalPoint;
                              setState(() {
                                if (details.scale != 1.0) {
                                  _scale = (_baseScale * details.scale).clamp(
                                    0.5,
                                    2.5,
                                  );
                                }
                                _angleY += details.focalPointDelta.dx * 0.008;
                                _angleX -= details.focalPointDelta.dy * 0.008;
                                _angleX = _angleX.clamp(
                                  -math.pi / 2,
                                  math.pi / 2,
                                );
                              });
                            },
                            onScaleEnd: (details) {
                              _isDragging = false;
                              // Handle tap on sphere
                              if (_isTapCandidate) {
                                _handleSphereTap(details);
                              }
                            },
                            child: LayoutBuilder(
                              key: _sphereKey,
                              builder: (context, constraints) {
                                return CustomPaint(
                                  painter: SphereMapPainter(
                                    nodes: _nodes,
                                    currentZone: widget.currentZone,
                                    selectedZone: _selectedZone,
                                    currentDay: widget.currentDay,
                                    angleX: _angleX,
                                    angleY: _angleY,
                                    scale: _scale,
                                    exploredZones: widget.exploredZones,
                                    adjacentZones: _adjacentZones,
                                    merchantZones: _merchantZones,
                                    merchantAnimValue: _merchantAnimCtrl.value,
                                  ),
                                  size: Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // ── Center/Recenter button (left side) ──
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: _recenterToCurrentNode,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.cyanAccent.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.cyanAccent,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── Zoom slider (bottom) ──
                        Positioned(
                          left: 48,
                          right: 8,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.zoom_out,
                                  color: Colors.cyanAccent,
                                  size: 14,
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: Colors.cyanAccent,
                                      inactiveTrackColor: Colors.cyanAccent
                                          .withValues(alpha: 0.2),
                                      thumbColor: Colors.cyanAccent,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 12,
                                          ),
                                      trackHeight: 2,
                                      overlayColor: Colors.cyanAccent
                                          .withValues(alpha: 0.2),
                                    ),
                                    child: Slider(
                                      value: _scale,
                                      min: 0.5,
                                      max: 2.5,
                                      onChanged: (val) {
                                        setState(() {
                                          _scale = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.zoom_in,
                                  color: Colors.cyanAccent,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Right: Info Panel (40%) ──
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF111522),
                        border: Border(left: BorderSide(color: Colors.white10)),
                      ),
                      child: Column(
                        children: [
                          // Selected zone info
                          if (selectedZoneData != null)
                            _buildSelectedZonePanel(selectedZoneData),

                          // Zone list
                          Expanded(child: _buildZoneList()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Back button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                  label: const Text(
                    'BACK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SPHERE TAP HANDLING
  // ═══════════════════════════════════════════════════════════════════════════
  void _handleSphereTap(ScaleEndDetails details) {
    final RenderBox? renderBox =
        _sphereKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final globalPosition = _lastFocalPoint;
    if (globalPosition == null) return;
    // Convert global tap position to local coordinates for the sphere widget
    final tapPosition = renderBox.globalToLocal(globalPosition);
    final size = renderBox.size;

    final painter = SphereMapPainter(
      nodes: _nodes,
      currentZone: widget.currentZone,
      selectedZone: _selectedZone,
      currentDay: widget.currentDay,
      angleX: _angleX,
      angleY: _angleY,
      scale: _scale,
      exploredZones: widget.exploredZones,
      adjacentZones: _adjacentZones,
      merchantZones: _merchantZones,
      merchantAnimValue: _merchantAnimCtrl.value,
    );

    final hitZone = painter.hitTestNode(tapPosition, size, hitRadius: 30.0);
    if (hitZone != null) {
      _onNodeTap(hitZone);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(Zone currentZoneData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111522),
        border: Border(
          bottom: BorderSide(
            color: currentZoneData.color.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.public, color: currentZoneData.color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GALACTIC MAP',
                  style: TextStyle(
                    color: currentZoneData.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'CURRENT: ${currentZoneData.name.toUpperCase()} · DAY ${widget.currentDay}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.cyanAccent, size: 12),
                SizedBox(width: 4),
                Text(
                  'TAP NODES',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SELECTED ZONE INFO PANEL (top of right side)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSelectedZonePanel(Zone zone) {
    final isCurrent = zone.type == widget.currentZone;
    final isAdjacent = _isAdjacentToCurrent(zone.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zone.color.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: zone.color.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zone name + icon row
          Row(
            children: [
              Icon(zone.icon, color: zone.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zone.name.toUpperCase(),
                  style: TextStyle(
                    color: zone.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              // Badge
              if (isCurrent)
                _badge('CURRENT', zone.color)
              else if (isAdjacent)
                _badge('ADJACENT', Colors.cyanAccent)
              else
                _badge('DISTANT', Colors.orangeAccent),
            ],
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            zone.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Type + Settlement indicator
          Row(
            children: [
              _badge(
                zone.isSettlement ? 'SETTLEMENT' : 'DUNGEON',
                zone.isSettlement ? const Color(0xFF66CCFF) : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                '${zone.connections.length} connections',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          if (isCurrent)
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: zone.color.withValues(alpha: 0.85),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.touch_app, size: 16),
                label: Text(
                  'ACTION — ${zone.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            )
          else if (isAdjacent)
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: zone.color.withValues(alpha: 0.85),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.flight_takeoff, size: 16),
                label: Text(
                  'TRAVEL TO ${zone.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: () => _travelTo(zone.type),
              ),
            )
          else
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.route, size: 14),
                label: const Text(
                  'NO DIRECT ROUTE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: null,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZONE LIST (scrollable, bottom of right side)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildZoneList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.explore, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 6),
              const Text(
                'ALL SECTORS',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${ZoneType.values.length} total',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),

        // Scrollable zone list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: ZoneType.values.length,
            itemBuilder: (context, index) {
              final zoneType = ZoneType.values[index];
              final zone = Zone.worldMap[zoneType]!;
              final isSelected = _selectedZone == zoneType;
              final isCurrent = zoneType == widget.currentZone;
              final isAdjacent = _isAdjacentToCurrent(zoneType);

              return _buildZoneListItem(
                zone,
                isSelected,
                isCurrent,
                isAdjacent,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoneListItem(
    Zone zone,
    bool isSelected,
    bool isCurrent,
    bool isAdjacent,
  ) {
    final zoneColor = zone.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: isSelected
            ? zoneColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onNodeTap(zone.type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? zoneColor.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Node icon
                _buildSmallNodeIcon(zone, 18),
                const SizedBox(width: 8),
                // Name + type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? zoneColor : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Text(
                        zone.isSettlement ? 'Settlement' : 'Dungeon',
                        style: TextStyle(
                          color: zoneColor.withValues(alpha: 0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                if (isCurrent)
                  _badge('HERE', zoneColor)
                else if (isAdjacent)
                  _badge('GO', Colors.cyanAccent)
                else
                  _badge('${zone.connections.length}', Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallNodeIcon(Zone zone, double size) {
    final shape = getNodeShape(zone.type, zone.isSettlement);

    switch (shape) {
      case NodeShape.roundedSquare:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: zone.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: zone.color, width: 1.5),
          ),
          child: Icon(zone.icon, color: zone.color, size: size * 0.6),
        );
      case NodeShape.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: zone.color.withValues(alpha: 0.2),
              border: Border.all(color: zone.color, width: 1.5),
            ),
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Icon(zone.icon, color: zone.color, size: size * 0.55),
            ),
          ),
        );
      case NodeShape.hexagon:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: zone.color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: zone.color, width: 1.5),
          ),
          child: Icon(zone.icon, color: zone.color, size: size * 0.55),
        );
      case NodeShape.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: zone.color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: zone.color, width: 1.5),
          ),
          child: Icon(zone.icon, color: zone.color, size: size * 0.55),
        );
      case NodeShape.guardian:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFF1744).withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFF1744), width: 2.0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            zone.icon,
            color: const Color(0xFFFF1744),
            size: size * 0.55,
          ),
        );
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
