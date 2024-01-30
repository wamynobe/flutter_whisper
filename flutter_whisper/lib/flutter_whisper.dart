import 'package:flutter_whisper_platform_interface/flutter_whisper_platform_interface.dart';

FlutterWhisperPlatform get _platform => FlutterWhisperPlatform.instance;

/// Returns the name of the current platform.
Future<String> getPlatformName() async {
  final platformName = await _platform.getPlatformName();
  if (platformName == null) throw Exception('Unable to get platform name.');
  return platformName;
}
