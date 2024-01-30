import 'package:flutter_whisper_platform_interface/src/method_channel_flutter_whisper.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of flutter_whisper must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `FlutterWhisper`.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
/// this interface will be broken
/// by newly added [FlutterWhisperPlatform] methods.
abstract class FlutterWhisperPlatform extends PlatformInterface {
  /// Constructs a FlutterWhisperPlatform.
  FlutterWhisperPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWhisperPlatform _instance = MethodChannelFlutterWhisper();

  /// The default instance of [FlutterWhisperPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterWhisper].
  static FlutterWhisperPlatform get instance => _instance;

  /// {@template initialize}
  /// init the whisper engine
  /// {@endtemplate}
  Future<void> initialize();

  /// {@template startListening}
  /// init recording and start listening
  /// {@endtemplate}
  Future<void> startListening();

  /// {@template stopListening}
  /// release record resource and stop listening
  /// {@endtemplate}
  Future<void> stopListening();

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [FlutterWhisperPlatform] when they register themselves.
  static set instance(FlutterWhisperPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Return the current platform name.
  Future<String?> getPlatformName();
}
