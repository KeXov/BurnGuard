import 'package:flutter_test/flutter_test.dart';
import 'package:burn_guard/models/overlay_config.dart';

void main() {
  group('OverlayConfig', () {
    test('should create config with default values', () {
      final config = OverlayConfig.create();

      expect(config.id, isNotEmpty);
      expect(config.name, contains('遮罩'));
      expect(config.x, equals(25.0));
      expect(config.y, equals(80.0));
      expect(config.width, equals(50.0));
      expect(config.height, equals(500.0));
      expect(config.opacity, equals(0.15));
      expect(config.color, equals('#000000'));
      expect(config.mode, equals(OverlayMode.static));
      expect(config.borderRadius, equals(0.0));
      expect(config.touchPassthrough, isTrue);
      expect(config.driftIntervalSeconds, equals(10));
      expect(config.driftPixels, equals(5));
      expect(config.isEnabled, isTrue);
    });

    test('should create config with custom name', () {
      final config = OverlayConfig.create(name: '测试遮罩');

      expect(config.name, equals('测试遮罩'));
    });

    test('should serialize to JSON correctly', () {
      final config = OverlayConfig(
        id: 'test_id',
        name: '测试',
        x: 10.0,
        y: 20.0,
        width: 80.0,
        height: 200.0,
        opacity: 0.5,
        color: '#FF0000',
        mode: OverlayMode.drift,
        borderRadius: 10.0,
        touchPassthrough: false,
        driftIntervalSeconds: 5,
        driftPixels: 3,
        isEnabled: false,
      );

      final json = config.toJson();

      expect(json['id'], equals('test_id'));
      expect(json['name'], equals('测试'));
      expect(json['x'], equals(10.0));
      expect(json['y'], equals(20.0));
      expect(json['width'], equals(80.0));
      expect(json['height'], equals(200.0));
      expect(json['opacity'], equals(0.5));
      expect(json['color'], equals('#FF0000'));
      expect(json['mode'], equals('drift'));
      expect(json['borderRadius'], equals(10.0));
      expect(json['touchPassthrough'], isFalse);
      expect(json['driftIntervalSeconds'], equals(5));
      expect(json['driftPixels'], equals(3));
      expect(json['isEnabled'], isFalse);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test_id_2',
        'name': '测试2',
        'x': 15.0,
        'y': 25.0,
        'width': 90.0,
        'height': 300.0,
        'opacity': 0.3,
        'color': '#00FF00',
        'mode': 'breathing',
        'borderRadius': 15.0,
        'touchPassthrough': true,
        'driftIntervalSeconds': 8,
        'driftPixels': 4,
        'isEnabled': true,
      };

      final config = OverlayConfig.fromJson(json);

      expect(config.id, equals('test_id_2'));
      expect(config.name, equals('测试2'));
      expect(config.x, equals(15.0));
      expect(config.y, equals(25.0));
      expect(config.width, equals(90.0));
      expect(config.height, equals(300.0));
      expect(config.opacity, equals(0.3));
      expect(config.color, equals('#00FF00'));
      expect(config.mode, equals(OverlayMode.breathing));
      expect(config.borderRadius, equals(15.0));
      expect(config.touchPassthrough, isTrue);
      expect(config.driftIntervalSeconds, equals(8));
      expect(config.driftPixels, equals(4));
      expect(config.isEnabled, isTrue);
    });

    test('should handle missing JSON fields with defaults', () {
      final json = <String, dynamic>{};

      final config = OverlayConfig.fromJson(json);

      expect(config.id, isNotEmpty);
      expect(config.name, equals('未命名遮罩'));
      expect(config.x, equals(25.0));
      expect(config.y, equals(80.0));
      expect(config.width, equals(50.0));
      expect(config.height, equals(500.0));
      expect(config.opacity, equals(0.15));
      expect(config.color, equals('#000000'));
      expect(config.mode, equals(OverlayMode.static));
    });

    test('should copy with new values', () {
      final original = OverlayConfig(
        id: 'original_id',
        name: 'Original',
        x: 10.0,
        y: 20.0,
      );

      final copied = original.copyWith(name: 'Copied', x: 30.0);

      expect(copied.id, equals('original_id'));
      expect(copied.name, equals('Copied'));
      expect(copied.x, equals(30.0));
      expect(copied.y, equals(20.0));
    });

    test('should preserve original values when copying', () {
      final original = OverlayConfig(
        id: 'test_id',
        name: 'Test',
        x: 10.0,
        y: 20.0,
        width: 50.0,
        height: 100.0,
      );

      final copied = original.copyWith();

      expect(copied.id, equals(original.id));
      expect(copied.name, equals(original.name));
      expect(copied.x, equals(original.x));
      expect(copied.y, equals(original.y));
      expect(copied.width, equals(original.width));
      expect(copied.height, equals(original.height));
    });

    test('should handle all overlay modes', () {
      expect(OverlayMode.values.length, equals(4));
      expect(OverlayMode.values, contains(OverlayMode.static));
      expect(OverlayMode.values, contains(OverlayMode.drift));
      expect(OverlayMode.values, contains(OverlayMode.breathing));
      expect(OverlayMode.values, contains(OverlayMode.random));
    });

    test('should serialize and deserialize all modes', () {
      for (final mode in OverlayMode.values) {
        final config = OverlayConfig(id: 'test_${mode.name}', mode: mode);
        final json = config.toJson();
        final deserialized = OverlayConfig.fromJson(json);
        expect(deserialized.mode, equals(mode));
      }
    });
  });
}
