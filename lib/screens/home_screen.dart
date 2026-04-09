import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burn_guard/providers/overlay_provider.dart' as manager;
import 'package:burn_guard/models/overlay_config.dart';
import 'package:burn_guard/models/overlay_template.dart';
import 'package:burn_guard/screens/overlay_settings_screen.dart';
import 'package:burn_guard/utils/permission_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final Set<String> _selectedOverlayIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref
          .read(manager.overlayManagerProvider.notifier)
          .checkAccessibilityPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        ref
            .read(manager.overlayManagerProvider.notifier)
            .checkAccessibilityPermission();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manager.overlayManagerProvider);
    final notifier = ref.read(manager.overlayManagerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '已选择 ${_selectedOverlayIds.length} 个'
              : 'BurnGuard',
        ),
        centerTitle: true,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  onPressed: _selectedOverlayIds.isEmpty
                      ? null
                      : () => _showSaveAsTemplateDialog(context, notifier),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddOverlayDialog(context, notifier),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) =>
                      _handleMenuAction(context, value, notifier),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'templates',
                      child: ListTile(
                        leading: Icon(Icons.bookmark),
                        title: Text('模板管理'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'battery',
                      child: ListTile(
                        leading: Icon(Icons.battery_alert),
                        title: Text('电池优化说明'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'about',
                      child: ListTile(
                        leading: Icon(Icons.info),
                        title: Text('关于'),
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPermissionCard(context, state, notifier),
            const SizedBox(height: 8),
            _buildAccessibilityCard(context, state, notifier),
            const SizedBox(height: 16),
            _buildStatusCard(context, state, notifier),
            const SizedBox(height: 16),
            _buildMainSwitch(context, state, notifier),
            const SizedBox(height: 16),
            if (_isSelectionMode) _buildSelectionBar(context, state),
            Expanded(child: _buildOverlaysList(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    manager.OverlayManagerState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                if (_selectedOverlayIds.length == state.overlays.length) {
                  _selectedOverlayIds.clear();
                } else {
                  _selectedOverlayIds.clear();
                  _selectedOverlayIds.addAll(state.overlays.map((o) => o.id));
                }
              });
            },
            child: Text(
              _selectedOverlayIds.length == state.overlays.length
                  ? '取消全选'
                  : '全选',
            ),
          ),
          Text(
            '长按遮罩进入选择模式',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    manager.OverlayManagerState state,
    manager.OverlayManagerNotifier notifier,
  ) {
    if (state.hasPermission) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('悬浮窗权限已授予'),
        ),
      );
    }

    return Card(
      color: Colors.orange.withValues(alpha: 0.2),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: const Text('需要悬浮窗权限'),
        trailing: ElevatedButton(
          onPressed: notifier.requestPermission,
          child: const Text('授权'),
        ),
      ),
    );
  }

  Widget _buildAccessibilityCard(
    BuildContext context,
    manager.OverlayManagerState state,
    manager.OverlayManagerNotifier notifier,
  ) {
    if (state.hasAccessibilityPermission) {
      return Card(
        color: Colors.green.withValues(alpha: 0.1),
        child: ListTile(
          leading: const Icon(Icons.accessibility_new, color: Colors.green),
          title: const Text('无障碍权限已启用'),
          subtitle: const Text('遮罩可覆盖状态栏图标'),
          trailing: TextButton(
            onPressed: () => notifier.checkAccessibilityPermission(),
            child: const Text('刷新'),
          ),
        ),
      );
    }

    if (state.accessibilityEnabledInSettings &&
        !state.hasAccessibilityPermission) {
      return Card(
        color: Colors.orange.withValues(alpha: 0.1),
        child: ListTile(
          leading: const Icon(Icons.warning, color: Colors.orange),
          title: const Text('无障碍服务需要重启'),
          subtitle: const Text('请在系统设置中关闭后再重新开启无障碍服务'),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await notifier.requestAccessibilityPermission();
              Future.delayed(const Duration(seconds: 1), () {
                notifier.checkAccessibilityPermission();
              });
            },
            child: const Text('去设置'),
          ),
        ),
      );
    }

    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.accessibility_new, color: Colors.blue),
        title: const Text('无障碍权限未启用'),
        subtitle: const Text('启用后遮罩可覆盖状态栏图标（可选）'),
        trailing: ElevatedButton(
          onPressed: () async {
            await notifier.requestAccessibilityPermission();
            Future.delayed(const Duration(seconds: 1), () {
              notifier.checkAccessibilityPermission();
            });
          },
          child: const Text('设置'),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    manager.OverlayManagerState state,
    manager.OverlayManagerNotifier notifier,
  ) {
    final activeCount = state.globalEnabled ? state.activeOverlayIds.length : 0;
    final totalCount = state.overlays.length;
    final hasAccessibilityIssue =
        state.accessibilityEnabledInSettings &&
        !state.hasAccessibilityPermission;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('运行状态', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasAccessibilityIssue
                            ? Colors.orange
                            : (state.globalEnabled
                                  ? Colors.green
                                  : Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasAccessibilityIssue
                          ? '需重启无障碍'
                          : (state.globalEnabled ? '运行中' : '已停止'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasAccessibilityIssue
                            ? Colors.orange
                            : (state.globalEnabled
                                  ? Colors.green
                                  : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('活动遮罩', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '$activeCount / $totalCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSwitch(
    BuildContext context,
    manager.OverlayManagerState state,
    manager.OverlayManagerNotifier notifier,
  ) {
    final hasAccessibilityIssue =
        state.accessibilityEnabledInSettings &&
        !state.hasAccessibilityPermission;

    String subtitle;
    if (hasAccessibilityIssue) {
      subtitle = '请先重启无障碍服务';
    } else if (state.globalEnabled) {
      subtitle = '所有遮罩已启动';
    } else {
      subtitle = '所有遮罩已停止';
    }

    return Card(
      child: SwitchListTile(
        title: const Text(
          '全局开关',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        value: state.globalEnabled,
        onChanged: state.hasPermission && !hasAccessibilityIssue
            ? (_) => notifier.toggleGlobal()
            : null,
        activeTrackColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildOverlaysList(
    BuildContext context,
    manager.OverlayManagerState state,
    manager.OverlayManagerNotifier notifier,
  ) {
    if (state.overlays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无遮罩',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddOverlayDialog(context, notifier),
              icon: const Icon(Icons.add),
              label: const Text('添加遮罩'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.overlays.length,
      itemBuilder: (context, index) {
        final overlay = state.overlays[index];
        final isActive = state.isOverlayActive(overlay.id);
        final isSelected = _selectedOverlayIds.contains(overlay.id);

        return Card(
          color: isSelected
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          child: ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedOverlayIds.add(overlay.id);
                        } else {
                          _selectedOverlayIds.remove(overlay.id);
                        }
                      });
                    },
                  )
                : Switch(
                    value: isActive,
                    onChanged: state.globalEnabled
                        ? (_) => notifier.toggleOverlay(overlay.id)
                        : null,
                  ),
            title: Text(overlay.name),
            subtitle: Text(
              '${overlay.width.toInt()}% × ${overlay.height.toInt()}px | ${_getModeLabel(overlay.mode)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: _isSelectionMode
                ? null
                : PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleOverlayAction(context, value, overlay, notifier),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('编辑'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('复制'),
                        ),
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
                          title: Text(
                            '删除',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
            onTap: _isSelectionMode
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedOverlayIds.remove(overlay.id);
                      } else {
                        _selectedOverlayIds.add(overlay.id);
                      }
                    });
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OverlaySettingsScreen(overlayId: overlay.id),
                      ),
                    );
                  },
            onLongPress: _isSelectionMode
                ? null
                : () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedOverlayIds.add(overlay.id);
                    });
                  },
          ),
        );
      },
    );
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedOverlayIds.clear();
    });
  }

  void _showAddOverlayDialog(
    BuildContext context,
    manager.OverlayManagerNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加遮罩'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '遮罩名称',
            hintText: '输入遮罩名称',
          ),
          onSubmitted: (value) {
            notifier.addOverlay(name: value.isEmpty ? null : value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.addOverlay();
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _handleOverlayAction(
    BuildContext context,
    String action,
    OverlayConfig overlay,
    manager.OverlayManagerNotifier notifier,
  ) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OverlaySettingsScreen(overlayId: overlay.id),
          ),
        );
        break;
      case 'duplicate':
        notifier.duplicateOverlay(overlay.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已复制遮罩')));
        break;
      case 'rename':
        _showRenameDialog(context, overlay, notifier);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, overlay, notifier);
        break;
    }
  }

  void _showRenameDialog(
    BuildContext context,
    OverlayConfig overlay,
    manager.OverlayManagerNotifier notifier,
  ) {
    final controller = TextEditingController(text: overlay.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名遮罩'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '遮罩名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.renameOverlay(overlay.id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    OverlayConfig overlay,
    manager.OverlayManagerNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除遮罩'),
        content: Text('确定要删除 "${overlay.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.deleteOverlay(overlay.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已删除遮罩')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _getModeLabel(OverlayMode mode) {
    switch (mode) {
      case OverlayMode.static:
        return '静态';
      case OverlayMode.drift:
        return '漂移';
      case OverlayMode.breathing:
        return '呼吸';
      case OverlayMode.random:
        return '随机';
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    manager.OverlayManagerNotifier notifier,
  ) {
    switch (action) {
      case 'templates':
        _showTemplatesDialog(context, notifier);
        break;
      case 'battery':
        PermissionHelper.showBatteryOptimizationDialog(context);
        break;
      case 'about':
        _showAboutDialog(context);
        break;
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BurnGuard',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.shield, size: 48),
      children: [
        const Text(
          'BurnGuard 是一款专业的 Android 防烧屏工具，'
          '通过智能遮罩技术保护您的 OLED 屏幕。\n\n'
          '功能特点：\n'
          '• 支持多个遮罩实例\n'
          '• 多种防烧屏模式\n'
          '• 可自定义遮罩参数\n'
          '• 模板保存与应用\n'
          '• 低功耗高性能\n'
          '• 简洁易用的界面\n'
          '• 支持无障碍服务覆盖状态栏',
        ),
      ],
    );
  }

  void _showSaveAsTemplateDialog(
    BuildContext context,
    manager.OverlayManagerNotifier notifier,
  ) {
    final state = ref.read(manager.overlayManagerProvider);
    final selectedOverlays = state.overlays
        .where((o) => _selectedOverlayIds.contains(o.id))
        .toList();

    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存为模板'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '将保存 ${selectedOverlays.length} 个遮罩到模板',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 100),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: selectedOverlays.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(Icons.layers, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedOverlays[index].name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '模板名称',
                hintText: '输入模板名称',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '模板描述（可选）',
                hintText: '输入模板描述',
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入模板名称')));
                return;
              }
              notifier.saveAsTemplate(
                overlayIds: _selectedOverlayIds.toList(),
                templateName: name,
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
              );
              Navigator.pop(context);
              _exitSelectionMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已保存 ${selectedOverlays.length} 个遮罩为模板'),
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showTemplatesDialog(
    BuildContext context,
    manager.OverlayManagerNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(manager.overlayManagerProvider);

          return AlertDialog(
            title: const Text('模板管理'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: state.templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无模板',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '长按遮罩选择多个并保存为模板',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.templates.length,
                      itemBuilder: (context, index) {
                        final template = state.templates[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(
                              Icons.bookmark,
                              color: Colors.blue,
                            ),
                            title: Text(template.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '包含 ${template.overlayCount} 个遮罩',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                if (template.description != null)
                                  Text(
                                    template.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            isThreeLine: template.description != null,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _handleTemplateAction(
                                context,
                                value,
                                template,
                                notifier,
                              ),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'apply',
                                  child: ListTile(
                                    leading: Icon(Icons.add_circle_outline),
                                    title: Text('应用模板'),
                                  ),
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
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      '删除',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showApplyTemplateDialog(
                                context,
                                template,
                                notifier,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleTemplateAction(
    BuildContext context,
    String action,
    OverlayTemplate template,
    manager.OverlayManagerNotifier notifier,
  ) {
    switch (action) {
      case 'apply':
        Navigator.pop(context);
        _showApplyTemplateDialog(context, template, notifier);
        break;
      case 'rename':
        _showRenameTemplateDialog(context, template, notifier);
        break;
      case 'delete':
        _showDeleteTemplateConfirmDialog(context, template, notifier);
        break;
    }
  }

  void _showApplyTemplateDialog(
    BuildContext context,
    OverlayTemplate template,
    manager.OverlayManagerNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('应用模板: ${template.name}'),
        content: Text(
          '将创建 ${template.overlayCount} 个遮罩\n创建后可在首页单独启用',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.createFromTemplate(templateId: template.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已从模板创建 ${template.overlayCount} 个遮罩')),
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showRenameTemplateDialog(
    BuildContext context,
    OverlayTemplate template,
    manager.OverlayManagerNotifier notifier,
  ) {
    final controller = TextEditingController(text: template.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名模板'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '模板名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入模板名称')));
                return;
              }
              notifier.renameTemplate(template.id, name);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已重命名模板')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTemplateConfirmDialog(
    BuildContext context,
    OverlayTemplate template,
    manager.OverlayManagerNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板'),
        content: Text(
          '确定要删除模板 "${template.name}" 吗？\n包含 ${template.overlayCount} 个遮罩配置。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              notifier.deleteTemplate(template.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已删除模板')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
