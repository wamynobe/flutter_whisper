import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_whisper_platform_interface/flutter_whisper_platform_interface.dart';

class FlutterWhisperMock extends FlutterWhisperPlatform {
  static const mockPlatformName = 'Mock';

  @override
  Future<String?> getPlatformName() async => mockPlatformName;

  @override
  Future<void> initialize({
    void Function(dynamic)? onResult,
    void Function(dynamic)? onError,
  }) {
    // TODO: implement initialize
    throw UnimplementedError();
  }

  @override
  Future<void> startListening() {
    // TODO: implement startListening
    throw UnimplementedError();
  }

  @override
  Future<void> stopListening() {
    // TODO: implement stopListening
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FlutterWhisperPlatformInterface', () {
    late FlutterWhisperPlatform flutterWhisperPlatform;

    setUp(() {
      flutterWhisperPlatform = FlutterWhisperMock();
      FlutterWhisperPlatform.instance = flutterWhisperPlatform;
    });

    group('getPlatformName', () {
      test('returns correct name', () async {
        expect(
          await FlutterWhisperPlatform.instance.getPlatformName(),
          equals(FlutterWhisperMock.mockPlatformName),
        );
      });
    });
  });
}
