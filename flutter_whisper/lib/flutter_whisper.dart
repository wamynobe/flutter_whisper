import 'package:flutter_whisper_platform_interface/flutter_whisper_platform_interface.dart';

FlutterWhisperPlatform get _platform => FlutterWhisperPlatform.instance;

/// Returns the name of the current platform.
Future<String> getPlatformName() async {
  final platformName = await _platform.getPlatformName();
  if (platformName == null) throw Exception('Unable to get platform name.');
  return platformName;
}

/// init the whisper engine
Future<bool> initialize({
  void Function(dynamic)? onResult,
  void Function(dynamic)? onError,
}) async {
  return _platform.initialize(onResult: onResult, onError: onError);
}

/// start the whisper engine
Future<void> startListening({
  void Function(dynamic)? onResult,
  void Function(dynamic)? onError,
}) async {
  return _platform.startListening();
}
