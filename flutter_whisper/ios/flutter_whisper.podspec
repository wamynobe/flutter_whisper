#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_whisper.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_whisper'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.requires_arc     = true
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*.m','Classes/whisper.cpp/coreml/*.m', 'Classes/whisper.cpp/coreml/*.mm','Classes/whisper.cpp/ggml-quants.c','Classes/whisper.cpp/ggml.c','Classes/whisper.cpp/ggml-alloc.c','Classes/whisper.cpp/ggml-backend.c','Classes/whisper.cpp/ggml-metal.m', 'Classes/whisper.cpp/ggml-metal.metal', 'Classes/whisper.cpp/coreml/*.h','Classes/whisper.cpp/coreml/whisper-decoder.h','Classes/whisper.cpp/coreml/whisper-encoder.h', 'Classes/whisper.cpp/coreml/whisper-encoder-impl.h', 'Classes/whisper.cpp/*.h',  'Classes/FlutterWhisperPlugin.h'
  s.resources  = 'Classes/ggml-tiny.en.bin'
  
  # s.public_header_files = 'Classes/whisper.cpp/*.h', 'Classes/whisper.cpp/coreml/*.h','Classes/whisper.cpp/whisper.h','Classes/whisper.cpp/ggml.h','Classes/whisper.cpp/ggml-metal.h','Classes/whisper.cpp/coreml/whisper-decoder.h','Classes/whisper.cpp/coreml/whisper-encoder.h', 'Classes/whisper.cpp/coreml/whisper-encoder-impl.h'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.subspec 'whisper' do |sp1|
    sp1.source_files = 'Classes/whisper.cpp/whisper.cpp'
    # sp1.public_header_files = 'Classes/whisper.cpp/whisper.h'
    sp1.compiler_flags = '-DWHISPER_USE_COREML -DWHISPER_COREML_ALLOW_FALLBACK -DGGML_USE_METAL'

  end
  s.subspec 'ggml' do |sp2|
    sp2.source_files = 'Classes/whisper.cpp/ggml.c'
    # sp2.public_header_files = 'Classes/whisper.cpp/ggml.h'
    sp2.compiler_flags = '-DGGML_USE_ACCELERATE -DGGML_USE_METAL'


  end
  s.subspec 'ggml-metal' do |sp3|
    sp3.source_files = 'Classes/whisper.cpp/ggml-metal.m'
    # sp3.public_header_files = 'Classes/whisper.cpp/ggml-metal.h'
    sp3.compiler_flags = '-framework Foundation -framework Metal -framework MetalKit -fno-objc-arc'

  end

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
