import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/overlay_config.dart';
import '../providers/overlay_provider.dart' as manager;

class PermissionCards extends StatelessWidget {
  final manager.OverlayManagerState state;
  final manager.OverlayManagerNotifier notifier;

  const PermissionCards({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOverlayPermissionCard(),
        const SizedBox(height: 8),
        _buildAccessibilityPermissionCard(),
      ],
    );
  }

  Widget _buildOverlayPermissionCard() {
    if (state.hasPermission) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text(AppStrings.overlayPermissionGranted),
        ),
      );
    }

    return Card(
      color: Colors.orange.withOpacity(0.2),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: const Text(AppStrings.overlayPermissionRequired),
        trailing: ElevatedButton(
          onPressed: notifier.requestPermission,
          child: const Text('授权'),
        ),
      ),
    );
  }

  Widget _buildAccessibilityPermissionCard() {
    if (state.hasAccessibilityPermission) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text(AppStrings.accessibilityPermissionGranted),
          subtitle: Text('遮罩可覆盖状态栏图标'),
        ),
      );
    }

    return Card(
      color: Colors.orange.withOpacity(0.2),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: const Text(AppStrings.accessibilityPermissionRequired),
        subtitle: const Text('启用后遮罩可覆盖状态栏图标'),
        trailing: ElevatedButton(
          onPressed: notifier.requestAccessibilityPermission,
          child: const Text('授权'),
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final manager.OverlayManagerState state;

  const StatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final activeCount = state.activeOverlayIds.length;
    final totalCount = state.overlays.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusColumn(
              label: '运行状态',
              value: state.globalEnabled
                  ? AppStrings.overlayRunning
                  : AppStrings.overlayStopped,
              isActive: state.globalEnabled,
            ),
            _buildStatusColumn(
              label: '活动遮罩',
              value: '$activeCount / $totalCount',
              isActive: activeCount > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusColumn({
    required String label,
    required String value,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Row(
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
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: isActive ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class GlobalSwitchCard extends StatelessWidget {
  final manager.OverlayManagerState state;
  final manager.OverlayManagerNotifier notifier;

  const GlobalSwitchCard({
    super.key,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text('全局开关', style: AppTextStyles.titleLarge),
        subtitle: Text(
          state.globalEnabled
              ? AppStrings.overlayEnabled
              : AppStrings.overlayDisabled,
        ),
        value: state.globalEnabled,
        onChanged: state.hasPermission ? (_) => notifier.toggleGlobal() : null,
        activeTrackColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class OverlayListItem extends StatelessWidget {
  final OverlayConfig overlay;
  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const OverlayListItem({
    super.key,
    required this.overlay,
    required this.isActive,
    required this.onToggle,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRename,
    required this.onDelete,
  });

  String get _modeLabel {
    switch (overlay.mode) {
      case OverlayMode.static:
        return AppStrings.modeStatic;
      case OverlayMode.drift:
        return AppStrings.modeDrift;
      case OverlayMode.breathing:
        return AppStrings.modeBreathing;
      case OverlayMode.random:
        return AppStrings.modeRandom;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Switch(value: isActive, onChanged: (_) => onToggle()),
        title: Text(overlay.name),
        subtitle: Text(
          '${overlay.width.toInt()}% × ${overlay.height.toInt()}px | $_modeLabel',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'duplicate':
                onDuplicate();
                break;
              case 'rename':
                onRename();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('编辑')),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: ListTile(leading: Icon(Icons.copy), title: Text('复制')),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: ListTile(
                leading: Icon(Icons.text_fields),
                title: Text('重命名'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
