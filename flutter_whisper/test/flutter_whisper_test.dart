import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whisper/flutter_whisper.dart';
import 'package:flutter_whisper_platform_interface/flutter_whisper_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterWhisperPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FlutterWhisperPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterWhisper', () {
    late FlutterWhisperPlatform flutterWhisperPlatform;

    setUp(() {
      flutterWhisperPlatform = MockFlutterWhisperPlatform();
      FlutterWhisperPlatform.instance = flutterWhisperPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name when platform implementation exists',
          () async {
        const platformName = '__test_platform__';
        when(
          () => flutterWhisperPlatform.getPlatformName(),
        ).thenAnswer((_) async => platformName);

        final actualPlatformName = await getPlatformName();
        expect(actualPlatformName, equals(platformName));
      });

      test('throws exception when platform implementation is missing',
          () async {
        when(
          () => flutterWhisperPlatform.getPlatformName(),
        ).thenAnswer((_) async => null);

        expect(getPlatformName, throwsException);
      });
    });
  });
}
