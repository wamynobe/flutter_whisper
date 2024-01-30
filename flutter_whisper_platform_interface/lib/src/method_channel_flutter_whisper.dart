import 'dart:developer';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:flutter_whisper_platform_interface/flutter_whisper_platform_interface.dart';

/// An implementation of [FlutterWhisperPlatform] that uses method channels.
class MethodChannelFlutterWhisper extends FlutterWhisperPlatform {
  /// The method channel used to interact with the native platform.
  static const _channelName = 'flutter_whisper';

  static const _methodChannel = MethodChannel(_channelName);
  bool _isReady = false;
  late final EventChannel _eventChannel;

  /// callback invoked when the result is sent from the native side
  void Function(dynamic)? onResult;

  /// callback invoked when cannot get data from the native side
  void Function(dynamic)? onError;

  /// {@macro initialize}
  @override
  Future<void> initialize({
    void Function(dynamic)? onResult,
    void Function(dynamic)? onError,
  }) async {
    this.onResult = onResult;
    this.onError = onError;

    if (_isReady) {
      return;
    }
    await _methodChannel.invokeMethod('init');
    _isReady = true;
  }

  /// {@macro startListening}
  @override
  Future<void> startListening() async {
    _eventChannel = const EventChannel('$_channelName/onStartListenning');
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        log('event -----------------------> : $event');
        onResult?.call(event);
      },
      onError: (Object error) {
        log('stream error ----------------------->: $error');
        onError?.call(error);
      },
    );
    await _methodChannel.invokeMethod('start');
  }

  /// {@macro stopListening}
  @override
  Future<void> stopListening() async {
    await _methodChannel.invokeMethod('stop');
  }

  @override
  Future<String?> getPlatformName() {
    return _methodChannel.invokeMethod<String>('getPlatformName');
  }

  /// true if the whisper engine is ready
  bool get isReady => _isReady;

  /// The [MethodChannel] used to interact with the native platform.
  @visibleForTesting
  MethodChannel get methodChannel => _methodChannel;
}
