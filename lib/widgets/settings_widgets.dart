import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/overlay_config.dart';
import 'common_widgets.dart';

class SizeSettingsCard extends StatelessWidget {
  final OverlayConfig config;
  final double screenWidth;
  final double screenHeight;
  final ValueChanged<OverlayConfig> onChanged;

  const SizeSettingsCard({
    super.key,
    required this.config,
    required this.screenWidth,
    required this.screenHeight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.sizeSettings,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildWidthSlider(),
            const SizedBox(height: AppDimensions.paddingSmall),
            _buildHeightSlider(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildOpacitySlider(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildBorderRadiusSlider(),
          ],
        ),
      ),
    );
  }

  Widget _buildWidthSlider() {
    return SliderWithButtons(
      label: '宽度',
      value: config.width,
      min: 0,
      max: 100,
      step: 1,
      unit: '%',
      onChanged: (value) {
        final newOverlayWidth = screenWidth * (value / 100);
        final newMaxX = (screenWidth - newOverlayWidth).clamp(
          0.0,
          double.infinity,
        );
        final newX = config.x.clamp(0.0, newMaxX);
        onChanged(config.copyWith(width: value, x: newX));
      },
    );
  }

  Widget _buildHeightSlider() {
    return SliderWithButtons(
      label: '高度',
      value: config.height,
      min: 0,
      max: AppDimensions.maxOverlayHeight,
      step: 1,
      unit: 'px',
      onChanged: (value) {
        final newMaxY = (screenHeight - value).clamp(0.0, double.infinity);
        final newY = config.y.clamp(0.0, newMaxY);
        onChanged(config.copyWith(height: value, y: newY));
      },
    );
  }

  Widget _buildOpacitySlider() {
    return SliderWithButtons(
      label: '透明度',
      value: config.opacity * 100,
      min: 0,
      max: 100,
      step: 1,
      unit: '%',
      onChanged: (value) => onChanged(config.copyWith(opacity: value / 100)),
    );
  }

  Widget _buildBorderRadiusSlider() {
    return SliderWithButtons(
      label: '圆角',
      value: config.borderRadius,
      min: 0,
      max: AppDimensions.maxBorderRadius,
      step: 1,
      unit: 'px',
      onChanged: (value) => onChanged(config.copyWith(borderRadius: value)),
    );
  }
}

class ColorSettingsCard extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorSettingsCard({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.colorSettings,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ColorPicker(
              selectedColor: selectedColor,
              onColorSelected: onColorSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class AnimationModeCard extends StatelessWidget {
  final OverlayMode selectedMode;
  final ValueChanged<OverlayMode> onModeChanged;

  const AnimationModeCard({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.animationMode,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            Wrap(
              spacing: AppDimensions.paddingSmall,
              runSpacing: AppDimensions.paddingSmall,
              children: [
                _buildModeChip(AppStrings.modeStatic, OverlayMode.static),
                _buildModeChip(AppStrings.modeDrift, OverlayMode.drift),
                _buildModeChip(AppStrings.modeBreathing, OverlayMode.breathing),
                _buildModeChip(AppStrings.modeRandom, OverlayMode.random),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, OverlayMode mode) {
    return ModeChip(
      label: label,
      isSelected: selectedMode == mode,
      onSelected: () => onModeChanged(mode),
    );
  }
}

class TouchPassthroughCard extends StatelessWidget {
  final bool touchPassthrough;
  final ValueChanged<bool> onChanged;

  const TouchPassthroughCard({
    super.key,
    required this.touchPassthrough,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text('触摸穿透'),
        subtitle: Text(
          touchPassthrough ? '允许触摸穿透遮罩' : '遮罩拦截触摸事件',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
        ),
        value: touchPassthrough,
        onChanged: onChanged,
      ),
    );
  }
}

class MovementControlsCard extends StatelessWidget {
  final OverlayConfig config;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback? onLongPressStartUp;
  final VoidCallback? onLongPressStartDown;
  final VoidCallback? onLongPressStartLeft;
  final VoidCallback? onLongPressStartRight;
  final VoidCallback onLongPressEnd;

  const MovementControlsCard({
    super.key,
    required this.config,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onMoveLeft,
    required this.onMoveRight,
    this.onLongPressStartUp,
    this.onLongPressStartDown,
    this.onLongPressStartLeft,
    this.onLongPressStartRight,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('位置调整', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildPositionInfo(),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildDirectionPad(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildPositionItem('X', config.x.toInt()),
        _buildPositionItem('Y', config.y.toInt()),
      ],
    );
  }

  Widget _buildPositionItem(String label, int value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text('$value px', style: AppTextStyles.titleMedium),
      ],
    );
  }

  Widget _buildDirectionPad(BuildContext context) {
    const buttonSize = AppDimensions.buttonSize;

    return Column(
      children: [
        _buildDirectionButton(
          icon: Icons.keyboard_arrow_up,
          onPressed: onMoveUp,
          onLongPressStart: onLongPressStartUp,
          onLongPressEnd: onLongPressEnd,
          size: buttonSize,
          context: context,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionButton(
              icon: Icons.keyboard_arrow_left,
              onPressed: onMoveLeft,
              onLongPressStart: onLongPressStartLeft,
              onLongPressEnd: onLongPressEnd,
              size: buttonSize,
              context: context,
            ),
            const SizedBox(width: 8),
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(
                  AppDimensions.borderRadiusMedium,
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Icon(
                Icons.open_with,
                size: AppDimensions.iconMedium,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 8),
            _buildDirectionButton(
              icon: Icons.keyboard_arrow_right,
              onPressed: onMoveRight,
              onLongPressStart: onLongPressStartRight,
              onLongPressEnd: onLongPressEnd,
              size: buttonSize,
              context: context,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildDirectionButton(
          icon: Icons.keyboard_arrow_down,
          onPressed: onMoveDown,
          onLongPressStart: onLongPressStartDown,
          onLongPressEnd: onLongPressEnd,
          size: buttonSize,
          context: context,
        ),
      ],
    );
  }

  Widget _buildDirectionButton({
    required IconData icon,
    required VoidCallback onPressed,
    VoidCallback? onLongPressStart,
    VoidCallback? onLongPressEnd,
    required double size,
    required BuildContext context,
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
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusMedium,
              ),
            ),
          ),
          child: Icon(icon, size: AppDimensions.iconMedium),
        ),
      ),
    );
  }
}
