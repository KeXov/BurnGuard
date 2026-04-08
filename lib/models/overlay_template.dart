import 'package:burn_guard/models/overlay_config.dart';

class OverlayTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateOverlayItem> overlays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OverlayTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.overlays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OverlayTemplate.create({
    required String name,
    String? description,
    required List<OverlayConfig> configs,
  }) {
    final now = DateTime.now();
    final overlayItems = configs
        .map((config) => TemplateOverlayItem.fromConfig(config))
        .toList();

    return OverlayTemplate(
      id: 'template_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      overlays: overlayItems,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory OverlayTemplate.fromJson(Map<String, dynamic> json) {
    final overlayList = json['overlays'] as List? ?? [];
    final overlays = overlayList
        .map(
          (item) => TemplateOverlayItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return OverlayTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '未命名模板',
      description: json['description'] as String?,
      overlays: overlays,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'overlays': overlays.map((o) => o.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OverlayTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<TemplateOverlayItem>? overlays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OverlayTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      overlays: overlays ?? this.overlays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<OverlayConfig> toOverlayConfigs() {
    final configs = <OverlayConfig>[];
    for (int i = 0; i < overlays.length; i++) {
      final item = overlays[i];
      final uniqueId = 'overlay_${DateTime.now().millisecondsSinceEpoch}_$i';
      configs.add(item.toConfigWithId(id: uniqueId));
    }
    return configs;
  }

  int get overlayCount => overlays.length;
}

class TemplateOverlayItem {
  final String name;
  final OverlayConfigData configData;

  const TemplateOverlayItem({required this.name, required this.configData});

  factory TemplateOverlayItem.fromConfig(OverlayConfig config) {
    return TemplateOverlayItem(
      name: config.name,
      configData: OverlayConfigData.fromConfig(config),
    );
  }

  factory TemplateOverlayItem.fromJson(Map<String, dynamic> json) {
    return TemplateOverlayItem(
      name: json['name'] as String? ?? '未命名遮罩',
      configData: OverlayConfigData.fromJson(
        json['configData'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'configData': configData.toJson()};
  }

  OverlayConfig toConfigWithId({required String id}) {
    return configData.toConfigWithId(id: id, name: name);
  }

  OverlayConfig toConfig() {
    return configData.toConfig(name: name);
  }
}

class OverlayConfigData {
  final double x;
  final double y;
  final double width;
  final double height;
  final double opacity;
  final String color;
  final OverlayMode mode;
  final double borderRadius;
  final bool touchPassthrough;
  final int driftIntervalSeconds;
  final int driftPixels;

  const OverlayConfigData({
    this.x = 25,
    this.y = 80,
    this.width = 50,
    this.height = 500,
    this.opacity = 0.15,
    this.color = '#000000',
    this.mode = OverlayMode.static,
    this.borderRadius = 0,
    this.touchPassthrough = true,
    this.driftIntervalSeconds = 10,
    this.driftPixels = 5,
  });

  factory OverlayConfigData.fromConfig(OverlayConfig config) {
    return OverlayConfigData(
      x: config.x,
      y: config.y,
      width: config.width,
      height: config.height,
      opacity: config.opacity,
      color: config.color,
      mode: config.mode,
      borderRadius: config.borderRadius,
      touchPassthrough: config.touchPassthrough,
      driftIntervalSeconds: config.driftIntervalSeconds,
      driftPixels: config.driftPixels,
    );
  }

  factory OverlayConfigData.fromJson(Map<String, dynamic> json) {
    return OverlayConfigData(
      x: (json['x'] as num?)?.toDouble() ?? 25.0,
      y: (json['y'] as num?)?.toDouble() ?? 80.0,
      width: (json['width'] as num?)?.toDouble() ?? 50.0,
      height: (json['height'] as num?)?.toDouble() ?? 500.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 0.15,
      color: json['color'] as String? ?? '#000000',
      mode: OverlayMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => OverlayMode.static,
      ),
      borderRadius: (json['borderRadius'] as num?)?.toDouble() ?? 0,
      touchPassthrough: json['touchPassthrough'] as bool? ?? true,
      driftIntervalSeconds: json['driftIntervalSeconds'] as int? ?? 10,
      driftPixels: json['driftPixels'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'opacity': opacity,
      'color': color,
      'mode': mode.name,
      'borderRadius': borderRadius,
      'touchPassthrough': touchPassthrough,
      'driftIntervalSeconds': driftIntervalSeconds,
      'driftPixels': driftPixels,
    };
  }

  OverlayConfig toConfigWithId({required String id, required String name}) {
    return OverlayConfig(
      id: id,
      name: name,
      x: x,
      y: y,
      width: width,
      height: height,
      opacity: opacity,
      color: color,
      mode: mode,
      borderRadius: borderRadius,
      touchPassthrough: touchPassthrough,
      driftIntervalSeconds: driftIntervalSeconds,
      driftPixels: driftPixels,
    );
  }

  OverlayConfig toConfig({required String name}) {
    return OverlayConfig.create(name: name).copyWith(
      x: x,
      y: y,
      width: width,
      height: height,
      opacity: opacity,
      color: color,
      mode: mode,
      borderRadius: borderRadius,
      touchPassthrough: touchPassthrough,
      driftIntervalSeconds: driftIntervalSeconds,
      driftPixels: driftPixels,
    );
  }
}
