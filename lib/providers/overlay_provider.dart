import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burn_guard/models/overlay_config.dart';
import 'package:burn_guard/models/overlay_template.dart';
import 'package:burn_guard/services/overlay_service.dart';
import 'package:burn_guard/services/storage_service.dart';
import 'package:burn_guard/utils/logger.dart';

class OverlayManagerState {
  final List<OverlayConfig> overlays;
  final List<OverlayTemplate> templates;
  final Set<String> activeOverlayIds;
  final bool hasPermission;
  final bool hasAccessibilityPermission;
  final bool accessibilityEnabledInSettings;
  final bool globalEnabled;

  const OverlayManagerState({
    this.overlays = const [],
    this.templates = const [],
    this.activeOverlayIds = const {},
    this.hasPermission = false,
    this.hasAccessibilityPermission = false,
    this.accessibilityEnabledInSettings = false,
    this.globalEnabled = false,
  });

  OverlayManagerState copyWith({
    List<OverlayConfig>? overlays,
    List<OverlayTemplate>? templates,
    Set<String>? activeOverlayIds,
    bool? hasPermission,
    bool? hasAccessibilityPermission,
    bool? accessibilityEnabledInSettings,
    bool? globalEnabled,
  }) {
    return OverlayManagerState(
      overlays: overlays ?? this.overlays,
      templates: templates ?? this.templates,
      activeOverlayIds: activeOverlayIds ?? this.activeOverlayIds,
      hasPermission: hasPermission ?? this.hasPermission,
      hasAccessibilityPermission:
          hasAccessibilityPermission ?? this.hasAccessibilityPermission,
      accessibilityEnabledInSettings:
          accessibilityEnabledInSettings ?? this.accessibilityEnabledInSettings,
      globalEnabled: globalEnabled ?? this.globalEnabled,
    );
  }

  OverlayConfig? getOverlay(String id) {
    try {
      return overlays.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  OverlayTemplate? getTemplate(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  bool isOverlayActive(String id) {
    return activeOverlayIds.contains(id);
  }
}

class OverlayManagerNotifier extends StateNotifier<OverlayManagerState> {
  static const String _tag = 'OverlayProvider';

  OverlayManagerNotifier() : super(const OverlayManagerState()) {
    _init();
    _setupGlobalStateChangedHandler();
  }

  void _setupGlobalStateChangedHandler() {
    OverlayService.setGlobalStateChangedHandler((enabled) {
      Logger.info('Global state changed from tile: $enabled', _tag);
      state = state.copyWith(globalEnabled: enabled);
    });
    OverlayService.setupMethodCallHandler();
  }

  Future<void> _init() async {
    final hasPermissionsResult = await OverlayService.hasOverlayPermission();
    final isAccessibilityRunningResult =
        await OverlayService.isAccessibilityServiceRunning();
    final isAccessibilityInSettingsResult =
        await OverlayService.isAccessibilityEnabledInSettings();
    final overlays = await StorageService.loadOverlays();
    final templates = await StorageService.loadTemplates();
    final activeOverlayIds = await StorageService.loadActiveOverlayIds();
    final globalEnabled = await StorageService.loadGlobalEnabled();

    final hasPermission = hasPermissionsResult.isSuccess
        ? hasPermissionsResult.data!
        : false;

    final isAccessibilityRunning = isAccessibilityRunningResult.isSuccess
        ? isAccessibilityRunningResult.data!
        : false;

    final isAccessibilityInSettings = isAccessibilityInSettingsResult.isSuccess
        ? isAccessibilityInSettingsResult.data!
        : false;

    final hasAccessibilityIssue =
        isAccessibilityInSettings && !isAccessibilityRunning;

    state = state.copyWith(
      hasPermission: hasPermission,
      hasAccessibilityPermission: isAccessibilityRunning,
      accessibilityEnabledInSettings: isAccessibilityInSettings,
      overlays: overlays,
      templates: templates,
      activeOverlayIds: activeOverlayIds,
      globalEnabled: globalEnabled,
    );

    Logger.info(
      'Initialized: ${overlays.length} overlays, accessibilityRunning=$isAccessibilityRunning, inSettings=$isAccessibilityInSettings, hasIssue=$hasAccessibilityIssue',
      _tag,
    );

    if (hasAccessibilityIssue) {
      Logger.info('Accessibility service needs restart', _tag);
    } else if (globalEnabled && hasPermission) {
      await _syncAndRestoreOverlays(activeOverlayIds);
    }
  }

  Future<void> _syncAndRestoreOverlays(Set<String> expectedActiveIds) async {
    await OverlayService.ensureOverlaysRestored();

    final hasAccessibility = state.hasAccessibilityPermission;
    if (hasAccessibility) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final runningConfigsResult =
        await OverlayService.getRunningOverlayConfigs();
    final runningIds = <String>{};

    if (runningConfigsResult.isSuccess) {
      final runningConfigs = runningConfigsResult.data!;
      runningIds.addAll(runningConfigs.map((c) => c['id'] as String));
      Logger.info(
        'Currently running overlays from native: ${runningIds.length}',
        _tag,
      );
    }

    final needsRestore = expectedActiveIds.difference(runningIds);
    final needsStop = runningIds.difference(expectedActiveIds);

    for (final overlayId in needsStop) {
      Logger.info('Stopping unexpected overlay: $overlayId', _tag);
      await OverlayService.stopOverlay(overlayId);
    }

    for (final overlayId in needsRestore) {
      final overlay = state.overlays.firstWhere(
        (o) => o.id == overlayId,
        orElse: () => throw StateError('Overlay not found'),
      );
      Logger.info('Restoring overlay: $overlayId', _tag);
      final result = await OverlayService.startOverlay(overlay);
      if (result.isFailure) {
        Logger.error(
          'Failed to restore overlay ${overlay.id}: ${result.error}',
          _tag,
        );
      }
    }

    if (needsStop.isNotEmpty || needsRestore.isNotEmpty) {
      final newActiveIds = expectedActiveIds.intersection(runningIds);
      newActiveIds.addAll(needsRestore);

      state = state.copyWith(activeOverlayIds: newActiveIds);
      await StorageService.saveActiveOverlayIds(newActiveIds);
    }
  }

  Future<void> requestPermission() async {
    final result = await OverlayService.requestOverlayPermission();
    if (result.isSuccess) {
      state = state.copyWith(hasPermission: result.data);
      Logger.info('Permission request result: ${result.data}', _tag);
    } else {
      Logger.error('Permission request failed: ${result.error}', _tag);
    }
  }

  Future<void> requestAccessibilityPermission() async {
    await OverlayService.requestAccessibilityPermission();
  }

  Future<void> checkAccessibilityPermission() async {
    final isRunningResult =
        await OverlayService.isAccessibilityServiceRunning();
    final inSettingsResult =
        await OverlayService.isAccessibilityEnabledInSettings();

    final isRunning = isRunningResult.isSuccess ? isRunningResult.data! : false;
    final inSettings = inSettingsResult.isSuccess
        ? inSettingsResult.data!
        : false;

    state = state.copyWith(
      hasAccessibilityPermission: isRunning,
      accessibilityEnabledInSettings: inSettings,
    );

    Logger.info(
      'Accessibility check: running=$isRunning, inSettings=$inSettings',
      _tag,
    );
  }

  bool get needsAccessibilityRecovery {
    return state.accessibilityEnabledInSettings &&
        !state.hasAccessibilityPermission;
  }

  Future<void> addOverlay({String? name}) async {
    final newOverlay = OverlayConfig.create(name: name);
    final newOverlays = [...state.overlays, newOverlay];

    state = state.copyWith(overlays: newOverlays);
    await StorageService.saveOverlays(newOverlays);
    Logger.info('Added overlay: ${newOverlay.id}', _tag);
  }

  Future<void> updateOverlay(OverlayConfig overlay) async {
    final index = state.overlays.indexWhere((o) => o.id == overlay.id);

    if (index >= 0) {
      final newOverlays = List<OverlayConfig>.from(state.overlays);
      newOverlays[index] = overlay;

      state = state.copyWith(overlays: newOverlays);
      await StorageService.saveOverlays(newOverlays);
      Logger.info('Updated overlay: ${overlay.id}', _tag);

      if (state.activeOverlayIds.contains(overlay.id)) {
        final result = await OverlayService.updateOverlay(overlay);
        if (result.isFailure) {
          Logger.error(
            'Failed to update running overlay: ${result.error}',
            _tag,
          );
        }
      }
    }
  }

  Future<void> deleteOverlay(String overlayId) async {
    if (state.activeOverlayIds.contains(overlayId)) {
      final result = await OverlayService.stopOverlay(overlayId);
      if (result.isFailure) {
        Logger.error('Failed to stop overlay: ${result.error}', _tag);
      }
    }

    final newOverlays = state.overlays.where((o) => o.id != overlayId).toList();
    final newActiveIds = Set<String>.from(state.activeOverlayIds)
      ..remove(overlayId);

    state = state.copyWith(
      overlays: newOverlays,
      activeOverlayIds: newActiveIds,
    );

    await StorageService.deleteOverlay(overlayId);
    Logger.info('Deleted overlay: $overlayId', _tag);
  }

  Future<void> toggleOverlay(String overlayId) async {
    if (!state.globalEnabled) {
      Logger.info('Cannot toggle overlay: global is disabled', _tag);
      return;
    }

    final overlay = state.getOverlay(overlayId);
    if (overlay == null) return;

    final newActiveIds = Set<String>.from(state.activeOverlayIds);

    if (newActiveIds.contains(overlayId)) {
      final result = await OverlayService.stopOverlay(overlayId);
      if (result.isSuccess && result.data!) {
        newActiveIds.remove(overlayId);
        Logger.info('Stopped overlay: $overlayId', _tag);
      } else {
        Logger.error('Failed to stop overlay: ${result.error}', _tag);
      }
    } else {
      final result = await OverlayService.startOverlay(overlay);
      if (result.isSuccess && result.data!) {
        newActiveIds.add(overlayId);
        Logger.info('Started overlay: $overlayId', _tag);
      } else {
        Logger.error('Failed to start overlay: ${result.error}', _tag);
      }
    }

    state = state.copyWith(activeOverlayIds: newActiveIds);
    await StorageService.saveActiveOverlayIds(newActiveIds);
    await OverlayService.updateQuickTile();
  }

  Future<void> toggleGlobal() async {
    if (!state.hasPermission) {
      await requestPermission();
      if (!state.hasPermission) return;
    }

    final newGlobalEnabled = !state.globalEnabled;

    if (newGlobalEnabled) {
      await checkAccessibilityPermission();
      await _startActiveOverlays();
      await checkAccessibilityPermission();
      state = state.copyWith(globalEnabled: true);
      Logger.info('Global enabled', _tag);
    } else {
      await _stopAllOverlays();
      state = state.copyWith(globalEnabled: false);
      Logger.info('Global disabled', _tag);
    }

    await StorageService.saveGlobalEnabled(newGlobalEnabled);
    await OverlayService.updateQuickTile();
  }

  Future<void> _startActiveOverlays() async {
    for (final overlay in state.overlays) {
      if (state.activeOverlayIds.contains(overlay.id)) {
        final result = await OverlayService.startOverlay(overlay);
        if (result.isFailure) {
          Logger.error(
            'Failed to start overlay ${overlay.id}: ${result.error}',
            _tag,
          );
        }
      }
    }
  }

  Future<void> _stopAllOverlays() async {
    for (final overlayId in state.activeOverlayIds) {
      final result = await OverlayService.stopOverlay(overlayId);
      if (result.isFailure) {
        Logger.error(
          'Failed to stop overlay $overlayId: ${result.error}',
          _tag,
        );
      }
    }
  }

  Future<void> renameOverlay(String overlayId, String newName) async {
    final overlay = state.getOverlay(overlayId);
    if (overlay == null) return;

    await updateOverlay(overlay.copyWith(name: newName));
  }

  Future<void> duplicateOverlay(String overlayId) async {
    final overlay = state.getOverlay(overlayId);
    if (overlay == null) return;

    final newOverlay = OverlayConfig.create(name: '${overlay.name} (副本)')
        .copyWith(
          x: overlay.x + 20,
          y: overlay.y + 20,
          width: overlay.width,
          height: overlay.height,
          opacity: overlay.opacity,
          color: overlay.color,
          mode: overlay.mode,
          borderRadius: overlay.borderRadius,
          touchPassthrough: overlay.touchPassthrough,
          driftIntervalSeconds: overlay.driftIntervalSeconds,
          driftPixels: overlay.driftPixels,
        );

    final newOverlays = [...state.overlays, newOverlay];
    state = state.copyWith(overlays: newOverlays);
    await StorageService.saveOverlays(newOverlays);
    Logger.info('Duplicated overlay: ${overlay.id} -> ${newOverlay.id}', _tag);
  }

  Future<void> checkRunningStatus() async {
    final runningIds = <String>{};

    for (final overlay in state.overlays) {
      final result = await OverlayService.isOverlayRunning(overlay.id);
      if (result.isSuccess && result.data!) {
        runningIds.add(overlay.id);
      }
    }

    state = state.copyWith(activeOverlayIds: runningIds);
    Logger.info('Checked running status: ${runningIds.length} running', _tag);
  }

  Future<void> saveAsTemplate({
    required List<String> overlayIds,
    required String templateName,
    String? description,
  }) async {
    final configs = <OverlayConfig>[];
    for (final id in overlayIds) {
      final overlay = state.getOverlay(id);
      if (overlay != null) {
        configs.add(overlay);
      }
    }

    if (configs.isEmpty) {
      Logger.error('No valid overlays to save as template', _tag);
      return;
    }

    final template = OverlayTemplate.create(
      name: templateName,
      description: description,
      configs: configs,
    );

    final newTemplates = [...state.templates, template];
    state = state.copyWith(templates: newTemplates);
    await StorageService.saveTemplates(newTemplates);
    Logger.info(
      'Saved ${configs.length} overlays as template: ${template.id}',
      _tag,
    );
  }

  Future<void> createFromTemplate({required String templateId}) async {
    final template = state.getTemplate(templateId);
    if (template == null) {
      Logger.error('Template not found: $templateId', _tag);
      return;
    }

    final newOverlays = template.toOverlayConfigs();
    final allOverlays = [...state.overlays, ...newOverlays];
    state = state.copyWith(overlays: allOverlays);
    await StorageService.saveOverlays(allOverlays);
    Logger.info(
      'Created ${newOverlays.length} overlays from template: $templateId',
      _tag,
    );
  }

  Future<void> deleteTemplate(String templateId) async {
    final newTemplates = state.templates
        .where((t) => t.id != templateId)
        .toList();
    state = state.copyWith(templates: newTemplates);
    await StorageService.deleteTemplate(templateId);
    Logger.info('Deleted template: $templateId', _tag);
  }

  Future<void> renameTemplate(String templateId, String newName) async {
    final template = state.getTemplate(templateId);
    if (template == null) return;

    final updatedTemplate = template.copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );

    final newTemplates = state.templates.map((t) {
      return t.id == templateId ? updatedTemplate : t;
    }).toList();

    state = state.copyWith(templates: newTemplates);
    await StorageService.saveTemplates(newTemplates);
    Logger.info('Renamed template: $templateId', _tag);
  }
}

final overlayManagerProvider =
    StateNotifierProvider<OverlayManagerNotifier, OverlayManagerState>(
      (ref) => OverlayManagerNotifier(),
    );
