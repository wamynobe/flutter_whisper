import 'dart:developer';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:flutter_whisper_platform_interface/flutter_whisper_platform_interface.dart';

/// An implementation of [FlutterWhisperPlatform] that uses method channels.
class MethodChannelFlutterWhisper extends FlutterWhisperPlatform {
  static const _channelName = 'flutter_whisper';

  static const _methodChannel = MethodChannel(_channelName);
  bool _isReady = false;
  late final EventChannel _eventChannel;

  /// callback invoked when the result is sent from the native side
  void Function(dynamic)? onResult;

  /// callback invoked when cannot get data from the native side
  void Function(dynamic)? onError;

  @override
  Future<bool> initialize({
    void Function(dynamic)? onResult,
    void Function(dynamic)? onError,
  }) async {
    this.onResult = onResult;
    this.onError = onError;
    _eventChannel = const EventChannel('$_channelName/onStartListenning');

    if (_isReady) {
      return true;
    }
    final isInitialized = await _methodChannel.invokeMethod('initialize');
    _isReady = true;
    return isInitialized as bool;
  }

  @override
  Future<void> startListening() async {
    if (!_isReady) {
      throw Exception(
        '''Whisper engine is not ready. Please call initialize first.''',
      );
    }
    log('''start listening on channel----------------------->: ${_eventChannel.name}''');
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        onResult?.call(event);
      },
      onError: (Object error) {
        onError?.call(error);
      },
    );
    await _methodChannel.invokeMethod('start');
  }

  @override
  Future<void> stopListening() async {
    _isReady = false;
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
