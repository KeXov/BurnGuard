enum OverlayMode { static, drift, breathing, random }

class OverlayConfig {
  final String id;
  final String name;
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

  const OverlayConfig({
    required this.id,
    this.name = '未命名遮罩',
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

  factory OverlayConfig.create({String? id, String? name}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return OverlayConfig(
      id: id ?? 'overlay_$timestamp',
      name: name ?? '遮罩 ${timestamp.toString().substring(8)}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
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

  factory OverlayConfig.fromJson(Map<String, dynamic> json) {
    return OverlayConfig(
      id:
          json['id'] as String? ??
          'overlay_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? '未命名遮罩',
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

  OverlayConfig copyWith({
    String? id,
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    double? opacity,
    String? color,
    OverlayMode? mode,
    double? borderRadius,
    bool? touchPassthrough,
    int? driftIntervalSeconds,
    int? driftPixels,
  }) {
    return OverlayConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      color: color ?? this.color,
      mode: mode ?? this.mode,
      borderRadius: borderRadius ?? this.borderRadius,
      touchPassthrough: touchPassthrough ?? this.touchPassthrough,
      driftIntervalSeconds: driftIntervalSeconds ?? this.driftIntervalSeconds,
      driftPixels: driftPixels ?? this.driftPixels,
    );
  }
}
