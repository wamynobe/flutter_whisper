#import <Flutter/Flutter.h>

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioQueue.h>

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define WHISPER_SAMPLE_RATE 16000
#define MAX_AUDIO_SEC 600
#define NUM_BUFFERS 3
#define SAMPLE_RATE 16000
typedef struct {
    AudioQueueRef queue;
    AudioQueueBufferRef buffers[NUM_BUFFERS];
    AudioStreamBasicDescription dataFormat;
    int16_t *audioBufferI16;
    float *audioBufferF32;
    int n_samples;
    bool isCapturing;
    bool isTranscribing;
    bool isRealtime;
    void *vc;
    struct whisper_context *ctx;
} StateInp;


@interface FlutterWhisperPlugin : NSObject<FlutterPlugin,  FlutterStreamHandler>{
    
    StateInp stateInp;
    FlutterEventChannel *eventChannel;
}


@end
