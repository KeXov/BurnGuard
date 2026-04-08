import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

class PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isGranted;
  final VoidCallback? onRequest;

  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.isGranted,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    if (isGranted) {
      return Card(
        child: ListTile(
          leading: Icon(icon, color: Colors.green),
          title: Text(title),
        ),
      );
    }

    return Card(
      color: Colors.orange.withOpacity(0.2),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: Text(title),
        trailing: ElevatedButton(onPressed: onRequest, child: const Text('授权')),
      ),
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final bool isActive;
  final String label;

  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: isActive ? Colors.green : Colors.grey),
        ),
      ],
    );
  }
}

class SliderWithButtons extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final ValueChanged<double> onChanged;

  const SliderWithButtons({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<SliderWithButtons> createState() => _SliderWithButtonsState();
}

class _SliderWithButtonsState extends State<SliderWithButtons> {
  late final ValueNotifier<double> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier<double>(widget.value);
  }

  @override
  void didUpdateWidget(SliderWithButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _valueNotifier.value = widget.value;
    }
  }

  @override
  void dispose() {
    _valueNotifier.dispose();
    super.dispose();
  }

  String _getDisplayValue(double value) {
    if (widget.unit == '%') {
      return '${value.toInt()}%';
    }
    return '${value.toInt()}${widget.unit}';
  }

  void _decrement() {
    final newValue = (widget.value - widget.step).clamp(widget.min, widget.max);
    _valueNotifier.value = newValue;
    widget.onChanged(newValue);
  }

  void _increment() {
    final newValue = (widget.value + widget.step).clamp(widget.min, widget.max);
    _valueNotifier.value = newValue;
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _valueNotifier,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.label}: ${_getDisplayValue(value)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.paddingSmall),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  iconSize: AppDimensions.iconSmall,
                  onPressed: value > widget.min ? _decrement : null,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                Expanded(
                  child: Slider(
                    value: value.clamp(widget.min, widget.max),
                    min: widget.min,
                    max: widget.max,
                    divisions: ((widget.max - widget.min) / widget.step)
                        .round(),
                    onChanged: (v) {
                      _valueNotifier.value = v;
                      widget.onChanged(v);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: AppDimensions.iconSmall,
                  onPressed: value < widget.max ? _increment : null,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class ColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.paddingSmall,
      runSpacing: AppDimensions.paddingSmall,
      children: AppColors.overlayColors.map((color) {
        final isSelected = selectedColor == color['value'];
        return GestureDetector(
          onTap: () => onColorSelected(color['value']!),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.parseColor(color['value']!),
              borderRadius: BorderRadius.circular(
                AppDimensions.borderRadiusSmall,
              ),
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
    );
  }
}

class ModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const ModeChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppDimensions.iconLarge, color: Colors.grey[400]),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: AppDimensions.paddingSmall),
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText!),
            ),
          ],
        ],
      ),
    );
  }
}
