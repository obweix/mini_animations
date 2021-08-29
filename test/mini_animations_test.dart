import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_animations/mini_animations.dart';

void main() {
  const MethodChannel channel = MethodChannel('mini_animations');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await MiniAnimations.platformVersion, '42');
  });
}
