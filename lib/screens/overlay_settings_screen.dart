import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burn_guard/providers/overlay_provider.dart';
import 'package:burn_guard/models/overlay_config.dart';
import 'package:burn_guard/services/overlay_service.dart';

class OverlaySettingsScreen extends ConsumerStatefulWidget {
  final String overlayId;

  const OverlaySettingsScreen({super.key, required this.overlayId});

  @override
  ConsumerState<OverlaySettingsScreen> createState() =>
      _OverlaySettingsScreenState();
}

class _OverlaySettingsScreenState extends ConsumerState<OverlaySettingsScreen> {
  Timer? _debounceTimer;
  Timer? _longPressTimer;
  double _screenWidth = 0;
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadScreenSize();
  }

  Future<void> _loadScreenSize() async {
    final result = await OverlayService.getScreenSize();
    if (mounted && result.isSuccess) {
      setState(() {
        _screenWidth = result.data!['width'] ?? 0;
        _screenHeight = result.data!['height'] ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _longPressTimer?.cancel();
    super.dispose();
  }

  _MovementBounds _calculateMovementBounds(OverlayConfig config) {
    final screenWidth = _screenWidth > 0
        ? _screenWidth
        : MediaQuery.of(context).size.width;
    final screenHeight = _screenHeight > 0
        ? _screenHeight
        : MediaQuery.of(context).size.height;

    final overlayWidth = screenWidth * (config.width / 100);
    final overlayHeight = config.height;

    final maxX = (screenWidth - overlayWidth).clamp(0.0, double.infinity);
    final maxY = (screenHeight - overlayHeight).clamp(0.0, double.infinity);

    return _MovementBounds(
      minX: 0.0,
      maxX: maxX,
      minY: 0.0,
      maxY: maxY,
      currentX: config.x,
      currentY: config.y,
    );
  }

  void _moveOverlay(
    OverlayConfig config,
    OverlayManagerNotifier notifier,
    double dx,
    double dy,
  ) {
    final bounds = _calculateMovementBounds(config);

    final newX = (config.x + dx).clamp(bounds.minX, bounds.maxX);
    final newY = (config.y + dy).clamp(bounds.minY, bounds.maxY);

    notifier.updateOverlay(config.copyWith(x: newX, y: newY));
  }

  void _startLongPress(
    OverlayConfig config,
    OverlayManagerNotifier notifier,
    double dx,
    double dy,
  ) {
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final state = ref.read(overlayManagerProvider);
      final currentConfig = state.getOverlay(widget.overlayId);
      if (currentConfig != null) {
        _moveOverlay(currentConfig, notifier, dx, dy);
      }
    });
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _resetPosition(OverlayConfig config, OverlayManagerNotifier notifier) {
    notifier.updateOverlay(config.copyWith(x: 0, y: 0));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(overlayManagerProvider);
    final notifier = ref.read(overlayManagerProvider.notifier);
    final config = state.getOverlay(widget.overlayId);

    if (config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('遮罩设置')),
        body: const Center(child: Text('遮罩不存在')),
      );
    }

    final bounds = _calculateMovementBounds(config);

    return Scaffold(
      appBar: AppBar(title: Text(config.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPositionSection(context, config, notifier, bounds),
          const SizedBox(height: 16),
          _buildSizeSection(context, config, notifier),
          const SizedBox(height: 16),
          _buildColorSection(context, config, notifier),
          const SizedBox(height: 16),
          _buildAnimationSection(context, config, notifier),
          const SizedBox(height: 16),
          _buildTouchSection(context, config, notifier),
        ],
      ),
    );
  }

  Widget _buildPositionSection(
    BuildContext context,
    OverlayConfig config,
    OverlayManagerNotifier notifier,
    _MovementBounds bounds,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '位置调整',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '使用方向键微调位置，每次移动 10 像素',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildDirectionControls(context, config, notifier, bounds),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionControls(
    BuildContext context,
    OverlayConfig config,
    OverlayManagerNotifier notifier,
    _MovementBounds bounds,
  ) {
    const step = 10.0;
    const fastStep = 30.0;
    const buttonSize = 56.0;

    final canMoveUp = bounds.currentY > bounds.minY;
    final canMoveDown = bounds.currentY < bounds.maxY;
    final canMoveLeft = bounds.currentX > bounds.minX;
    final canMoveRight = bounds.currentX < bounds.maxX;

    return Column(
      children: [
        _buildDirectionButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: canMoveUp
              ? () => _moveOverlay(config, notifier, 0, -step)
              : null,
          onLongPressStart: canMoveUp
              ? () => _startLongPress(config, notifier, 0, -fastStep)
              : null,
          onLongPressEnd: _stopLongPress,
          size: buttonSize,
          enabled: canMoveUp,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: canMoveLeft
                  ? () => _moveOverlay(config, notifier, -step, 0)
                  : null,
              onLongPressStart: canMoveLeft
                  ? () => _startLongPress(config, notifier, -fastStep, 0)
                  : null,
              onLongPressEnd: _stopLongPress,
              size: buttonSize,
              enabled: canMoveLeft,
            ),
            const SizedBox(width: 8),
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.open_with,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
            _buildDirectionButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: canMoveRight
                  ? () => _moveOverlay(config, notifier, step, 0)
                  : null,
              onLongPressStart: canMoveRight
                  ? () => _startLongPress(config, notifier, fastStep, 0)
                  : null,
              onLongPressEnd: _stopLongPress,
              size: buttonSize,
              enabled: canMoveRight,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildDirectionButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: canMoveDown
              ? () => _moveOverlay(config, notifier, 0, step)
              : null,
          onLongPressStart: canMoveDown
              ? () => _startLongPress(config, notifier, 0, fastStep)
              : null,
          onLongPressEnd: _stopLongPress,
          size: buttonSize,
          enabled: canMoveDown,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _resetPosition(config, notifier),
          icon: const Icon(Icons.replay, size: 18),
          label: const Text('重置到左上角'),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '当前位置',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '可移动范围',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'X: ${bounds.currentX.toInt()}px',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'X: 0-${bounds.maxX.toInt()}px',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Y: ${bounds.currentY.toInt()}px',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Y: 0-${bounds.maxY.toInt()}px',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    VoidCallback? onLongPressStart,
    VoidCallback? onLongPressEnd,
    required double size,
    required bool enabled,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onLongPressStart: onLongPressStart != null
            ? (_) => onLongPressStart()
            : null,
        onLongPressEnd: onLongPressEnd != null ? (_) => onLongPressEnd() : null,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: enabled
                ? null
                : Theme.of(context).disabledColor.withOpacity(0.12),
            foregroundColor: enabled ? null : Theme.of(context).disabledColor,
          ),
          child: Icon(icon, size: 28),
        ),
      ),
    );
  }

  Widget _buildSizeSection(
    BuildContext context,
    OverlayConfig config,
    OverlayManagerNotifier notifier,
  ) {
    final screenWidth = _screenWidth > 0
        ? _screenWidth
        : MediaQuery.of(context).size.width;
    final screenHeight = _screenHeight > 0
        ? _screenHeight
        : MediaQuery.of(context).size.height;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '尺寸设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSliderWithButtons(
              label: '宽度',
              value: config.width,
              min: 0,
              max: 100,
              step: 1,
              unit: '%',
              displayValue: '${config.width.toInt()}%',
              onChanged: (value) {
                final newOverlayWidth = screenWidth * (value / 100);
                final newMaxX = (screenWidth - newOverlayWidth).clamp(
                  0.0,
                  double.infinity,
                );
                final newX = config.x.clamp(0.0, newMaxX);

                notifier.updateOverlay(config.copyWith(width: value, x: newX));
              },
            ),
            const SizedBox(height: 16),
            _buildSliderWithButtons(
              label: '高度',
              value: config.height,
              min: 0,
              max: 300,
              step: 1,
              unit: 'px',
              displayValue: '${config.height.toInt()}px',
              onChanged: (value) {
                final newMaxY = (screenHeight - value).clamp(
                  0.0,
                  double.infinity,
                );
                final newY = config.y.clamp(0.0, newMaxY);

                notifier.updateOverlay(config.copyWith(height: value, y: newY));
              },
            ),
            const SizedBox(height: 16),
            _buildSliderWithButtons(
              label: '透明度',
              value: config.opacity * 100,
              min: 0,
              max: 100,
              step: 1,
              unit: '%',
              displayValue: '${(config.opacity * 100).toInt()}%',
              onChanged: (value) {
                notifier.updateOverlay(config.copyWith(opacity: value / 100));
              },
            ),
            const SizedBox(height: 16),
            _buildSliderWithButtons(
              label: '圆角',
              value: config.borderRadius,
              min: 0,
              max: 100,
              step: 1,
              unit: 'px',
              displayValue: '${config.borderRadius.toInt()}px',
              onChanged: (value) {
                notifier.updateOverlay(config.copyWith(borderRadius: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderWithButtons({
    required String label,
    required double value,
    required double min,
    required double max,
    required double step,
    required String unit,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label: $displayValue', style: const TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > min
                  ? () {
                      final newValue = (value - step).clamp(min, max);
                      onChanged(newValue);
                    }
                  : null,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: ((max - min) / step).round(),
                onChanged: onChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: value < max
                  ? () {
                      final newValue = (value + step).clamp(min, max);
                      onChanged(newValue);
                    }
                  : null,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSection(
    BuildContext context,
    OverlayConfig config,
    OverlayManagerNotifier notifier,
  ) {
    final colors = [
      {'name': '黑色', 'value': '#000000'},
      {'name': '深灰', 'value': '#1a1a1a'},
      {'name': '灰色', 'value': '#4a4a4a'},
      {'name': '深蓝', 'value': '#0a1a2a'},
      {'name': '深紫', 'value': '#1a0a2a'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '颜色选择',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                final isSelected = config.color == color['value'];
                return GestureDetector(
                  onTap: () {
                    notifier.updateOverlay(
                      config.copyWith(color: color['value'] as String),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _parseColor(color['value'] as String),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationSection(
    BuildContext context,
    OverlayConfig config,
    OverlayManagerNotifier notifier,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '动画模式',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildModeOption(
              '静态',
              '固定不动',
              OverlayMode.static,
              config,
              notifier,
            ),
            _buildModeOption('漂移', '定时移动', OverlayMode.drift, config, notifier),
            _buildModeOption(
              '呼吸',
              '透明度变化',
              OverlayMode.breathing,
              config,
              notifier,
            ),
            _buildModeOption(
              '随机',
              '随机变化',
              OverlayMode.random,
              config,
              notifier,
            ),
            if (config.mode != OverlayMode.static) ...[
              const SizedBox(height: 16),
              Text('间隔: ${config.driftIntervalSeconds} 秒'),
              Slider(
                value: config.driftIntervalSeconds.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                onChanged: (value) {
                  notifier.updateOverlay(
                    config.copyWith(driftIntervalSeconds: value.toInt()),
                  );
                },
              ),
              Text('幅度: ${config.driftPixels} 像素'),
              Slider(
                value: config.driftPixels.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) {
                  notifier.updateOverlay(
                    config.copyWith(driftPixels: value.toInt()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    String title,
    String subtitle,
    OverlayMode mode,
    OverlayConfig config,
    OverlayManagerNotifier notifier,
  ) {
    return RadioListTile<OverlayMode>(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: mode,
      groupValue: config.mode,
      onChanged: (value) {
        if (value != null) {
          notifier.updateOverlay(config.copyWith(mode: value));
        }
      },
    );
  }

  Widget _buildTouchSection(
    BuildContext context,
    OverlayConfig config,
    OverlayManagerNotifier notifier,
  ) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('触摸穿透'),
            subtitle: const Text('允许触摸事件穿透遮罩'),
            value: config.touchPassthrough,
            onChanged: (value) {
              notifier.updateOverlay(config.copyWith(touchPassthrough: value));
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '状态栏覆盖',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Y=0 可覆盖状态栏\n'
                  '• 高度=屏幕高度可覆盖全屏\n'
                  '• 开启触摸穿透后可操作状态栏',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}

class _MovementBounds {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double currentX;
  final double currentY;

  const _MovementBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.currentX,
    required this.currentY,
  });
}
