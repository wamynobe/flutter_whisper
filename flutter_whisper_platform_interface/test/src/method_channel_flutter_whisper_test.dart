import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whisper_platform_interface/src/method_channel_flutter_whisper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kPlatformName = 'platformName';

  group('$MethodChannelFlutterWhisper', () {
    late MethodChannelFlutterWhisper methodChannelFlutterWhisper;
    final log = <MethodCall>[];

    setUp(() async {
      methodChannelFlutterWhisper = MethodChannelFlutterWhisper();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannelFlutterWhisper.methodChannel,
        (methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'getPlatformName':
              return kPlatformName;
            default:
              return null;
          }
        },
      );
    });

    tearDown(log.clear);

    test('getPlatformName', () async {
      final platformName = await methodChannelFlutterWhisper.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(platformName, equals(kPlatformName));
    });
  });
}
