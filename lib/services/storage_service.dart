import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burn_guard/models/overlay_config.dart';
import 'package:burn_guard/models/overlay_template.dart';
import 'package:burn_guard/utils/logger.dart';

class StorageService {
  static const String _overlaysKey = 'overlay_configs';
  static const String _activeOverlayIdsKey = 'active_overlay_ids';
  static const String _globalEnabledKey = 'global_enabled';
  static const String _templatesKey = 'overlay_templates';
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static final Map<String, _CacheEntry> _cache = {};
  static const String _tag = 'StorageService';

  static void clearCache() {
    _cache.clear();
    Logger.info('Cache cleared', _tag);
  }

  static void _setCache(String key, dynamic value) {
    _cache[key] = _CacheEntry(value, DateTime.now());
    Logger.debug('Cache set: $key', _tag);
  }

  static dynamic _getCache(String key) {
    final entry = _cache[key];
    if (entry == null) {
      return null;
    }
    if (DateTime.now().difference(entry.timestamp) > _cacheExpiry) {
      _cache.remove(key);
      Logger.debug('Cache expired: $key', _tag);
      return null;
    }
    Logger.debug('Cache hit: $key', _tag);
    return entry.value;
  }

  static Future<void> saveOverlays(List<OverlayConfig> overlays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = overlays.map((e) => e.toJson()).toList();
      await prefs.setString(_overlaysKey, jsonEncode(jsonList));
      _setCache(_overlaysKey, overlays);
      Logger.info('Saved ${overlays.length} overlays', _tag);
    } catch (e) {
      Logger.error('Failed to save overlays', _tag, e);
      rethrow;
    }
  }

  static Future<List<OverlayConfig>> loadOverlays() async {
    try {
      final cached = _getCache(_overlaysKey);
      if (cached != null) {
        return cached as List<OverlayConfig>;
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_overlaysKey);

      if (jsonString == null) {
        final defaultOverlays = [OverlayConfig.create(name: '默认遮罩')];
        _setCache(_overlaysKey, defaultOverlays);
        return defaultOverlays;
      }

      final jsonList = jsonDecode(jsonString) as List;
      final overlays = jsonList
          .map((json) => OverlayConfig.fromJson(json as Map<String, dynamic>))
          .toList();
      _setCache(_overlaysKey, overlays);
      Logger.info('Loaded ${overlays.length} overlays', _tag);
      return overlays;
    } catch (e) {
      Logger.error('Failed to load overlays', _tag, e);
      final defaultOverlays = [OverlayConfig.create(name: '默认遮罩')];
      _setCache(_overlaysKey, defaultOverlays);
      return defaultOverlays;
    }
  }

  static Future<void> saveOverlay(OverlayConfig overlay) async {
    try {
      final overlays = await loadOverlays();
      final index = overlays.indexWhere((o) => o.id == overlay.id);

      if (index >= 0) {
        overlays[index] = overlay;
      } else {
        overlays.add(overlay);
      }

      await saveOverlays(overlays);
      Logger.info('Saved overlay: ${overlay.id}', _tag);
    } catch (e) {
      Logger.error('Failed to save overlay', _tag, e);
      rethrow;
    }
  }

  static Future<void> deleteOverlay(String overlayId) async {
    try {
      final overlays = await loadOverlays();
      overlays.removeWhere((o) => o.id == overlayId);
      await saveOverlays(overlays);

      final activeIds = await loadActiveOverlayIds();
      activeIds.remove(overlayId);
      await saveActiveOverlayIds(activeIds);
      Logger.info('Deleted overlay: $overlayId', _tag);
    } catch (e) {
      Logger.error('Failed to delete overlay', _tag, e);
      rethrow;
    }
  }

  static Future<void> saveActiveOverlayIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeOverlayIdsKey, jsonEncode(ids.toList()));
      _setCache(_activeOverlayIdsKey, ids);
      Logger.info('Saved ${ids.length} active overlay IDs', _tag);
    } catch (e) {
      Logger.error('Failed to save active overlay IDs', _tag, e);
      rethrow;
    }
  }

  static Future<Set<String>> loadActiveOverlayIds() async {
    try {
      final cached = _getCache(_activeOverlayIdsKey);
      if (cached != null) {
        return cached as Set<String>;
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_activeOverlayIdsKey);

      if (jsonString == null) {
        _setCache(_activeOverlayIdsKey, <String>{});
        return {};
      }

      final list = jsonDecode(jsonString) as List;
      final ids = list.map((e) => e.toString()).toSet();
      _setCache(_activeOverlayIdsKey, ids);
      Logger.info('Loaded ${ids.length} active overlay IDs', _tag);
      return ids;
    } catch (e) {
      Logger.error('Failed to load active overlay IDs', _tag, e);
      _setCache(_activeOverlayIdsKey, <String>{});
      return {};
    }
  }

  static Future<void> saveGlobalEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_globalEnabledKey, enabled);
      _setCache(_globalEnabledKey, enabled);
      Logger.info('Saved global enabled: $enabled', _tag);
    } catch (e) {
      Logger.error('Failed to save global enabled', _tag, e);
      rethrow;
    }
  }

  static Future<bool> loadGlobalEnabled() async {
    try {
      final cached = _getCache(_globalEnabledKey);
      if (cached != null) {
        return cached as bool;
      }

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_globalEnabledKey) ?? false;
      _setCache(_globalEnabledKey, enabled);
      return enabled;
    } catch (e) {
      Logger.error('Failed to load global enabled', _tag, e);
      return false;
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_overlaysKey);
      await prefs.remove(_activeOverlayIdsKey);
      await prefs.remove(_globalEnabledKey);
      await prefs.remove(_templatesKey);
      clearCache();
      Logger.info('Cleared all data', _tag);
    } catch (e) {
      Logger.error('Failed to clear all data', _tag, e);
      rethrow;
    }
  }

  static Future<void> saveTemplates(List<OverlayTemplate> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = templates.map((e) => e.toJson()).toList();
      await prefs.setString(_templatesKey, jsonEncode(jsonList));
      _setCache(_templatesKey, templates);
      Logger.info('Saved ${templates.length} templates', _tag);
    } catch (e) {
      Logger.error('Failed to save templates', _tag, e);
      rethrow;
    }
  }

  static Future<List<OverlayTemplate>> loadTemplates() async {
    try {
      final cached = _getCache(_templatesKey);
      if (cached != null) {
        return cached as List<OverlayTemplate>;
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_templatesKey);

      if (jsonString == null) {
        _setCache(_templatesKey, <OverlayTemplate>[]);
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final templates = jsonList
          .map((json) => OverlayTemplate.fromJson(json as Map<String, dynamic>))
          .toList();
      _setCache(_templatesKey, templates);
      Logger.info('Loaded ${templates.length} templates', _tag);
      return templates;
    } catch (e) {
      Logger.error('Failed to load templates', _tag, e);
      _setCache(_templatesKey, <OverlayTemplate>[]);
      return [];
    }
  }

  static Future<void> saveTemplate(OverlayTemplate template) async {
    try {
      final templates = await loadTemplates();
      final index = templates.indexWhere((t) => t.id == template.id);

      if (index >= 0) {
        templates[index] = template;
      } else {
        templates.add(template);
      }

      await saveTemplates(templates);
      Logger.info('Saved template: ${template.id}', _tag);
    } catch (e) {
      Logger.error('Failed to save template', _tag, e);
      rethrow;
    }
  }

  static Future<void> deleteTemplate(String templateId) async {
    try {
      final templates = await loadTemplates();
      templates.removeWhere((t) => t.id == templateId);
      await saveTemplates(templates);
      Logger.info('Deleted template: $templateId', _tag);
    } catch (e) {
      Logger.error('Failed to delete template', _tag, e);
      rethrow;
    }
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}
