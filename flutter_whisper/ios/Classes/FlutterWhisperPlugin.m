#import "FlutterWhisperPlugin.h"
#import "whisper.h"

#define NUM_BYTES_PER_BUFFER 16*1024
// callback used to process captured audio
void AudioInputCallback(void * inUserData,
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs);

@implementation FlutterWhisperPlugin{
    FlutterEventSink _eventSink;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_whisper"
                                     binaryMessenger:[registrar messenger]];
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:@"flutter_whisper/onStartListenning"
                                         binaryMessenger:[registrar messenger]];
    FlutterWhisperPlugin* instance = [[FlutterWhisperPlugin alloc] init];
    [eventChannel setStreamHandler:instance];
    
    [registrar addMethodCallDelegate:instance channel:channel];
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    if ([@"initialize" isEqualToString:call.method]) {
        NSLog(@"Initializing");
        [self initialize];
        
        result(@YES);
    }else if([@"start" isEqualToString:call.method]){
        [self toggleCapture:(self)];
    }
    
    else if([@"stop" isEqualToString:call.method]){
        [self stopCapturing];
    }
    
    else {
        result(FlutterMethodNotImplemented);
    }
}
- (void)setupAudioFormat:(AudioStreamBasicDescription*)format
{
    format->mSampleRate       = WHISPER_SAMPLE_RATE;
    format->mFormatID         = kAudioFormatLinearPCM;
    format->mFramesPerPacket  = 1;
    format->mChannelsPerFrame = 1;
    format->mBytesPerFrame    = 2;
    format->mBytesPerPacket   = 2;
    format->mBitsPerChannel   = 16;
    format->mReserved         = 0;
    format->mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger;
}
- (void)initialize {
    
    {
        // load the model
        NSString *modelPath = [[NSBundle bundleForClass: [FlutterWhisperPlugin class]] pathForResource:@"ggml-tiny.en" ofType:@"bin"];
        
        
        // check if the model exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:modelPath]) {
            NSLog(@"Model file not found");
            return;
        }
        
        NSLog(@"Loading model from %@", modelPath);
        
        // create ggml context
        
        struct whisper_context_params cparams = whisper_context_default_params();
#if TARGET_OS_SIMULATOR
        cparams.use_gpu = false;
        NSLog(@"Running on simulator, using CPU");
#endif
        stateInp.ctx = whisper_init_from_file_with_params([modelPath UTF8String], cparams);
        
        // check if the model was loaded successfully
        if (stateInp.ctx == NULL) {
            NSLog(@"Failed to load model");
            return;
        }
    }
    
    // initialize audio format and buffers
    {
        [self setupAudioFormat:&stateInp.dataFormat];
        
        stateInp.n_samples = 0;
        stateInp.audioBufferI16 = malloc(MAX_AUDIO_SEC*SAMPLE_RATE*sizeof(int16_t));
        stateInp.audioBufferF32 = malloc(MAX_AUDIO_SEC*SAMPLE_RATE*sizeof(float));
    }
    
    stateInp.isTranscribing = false;
    stateInp.isRealtime = true;
    
}
- (void)dealloc {
    // Release any allocated resources
    free(stateInp.audioBufferI16);
    free(stateInp.audioBufferF32);
}

-(void) stopCapturing {
    NSLog(@"Stop capturing");
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:&error];
    if (error) {
        NSLog(@"Error deactivating audio session: %@", error);
    }
    stateInp.isCapturing = false;
    
    AudioQueueStop(stateInp.queue, true);
    for (int i = 0; i < NUM_BUFFERS; i++) {
        AudioQueueFreeBuffer(stateInp.queue, stateInp.buffers[i]);
    }
    
    AudioQueueDispose(stateInp.queue, true);
}

- (void)toggleCapture:(id)sender {
    if (stateInp.isCapturing) {
        // stop capturing
        [self stopCapturing];
        
        return;
    }
    
    
    // initiate audio capturing
    NSLog(@"Start capturing");
    
    stateInp.isRealtime = true;
    NSLog(@"is real time %d", stateInp.isRealtime);
    stateInp.n_samples = 0;
    stateInp.vc = (__bridge void *)(self);
    
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&error];
    [audioSession setActive:YES error:&error];
    if (error) {
        NSLog(@"Error setting audio session category: %@", error);
    }
    
    OSStatus status = AudioQueueNewInput(&stateInp.dataFormat,
                                         AudioInputCallback,
                                         &stateInp,
                                         CFRunLoopGetCurrent(),
                                         kCFRunLoopCommonModes,
                                         0,
                                         &stateInp.queue);
    
    NSLog(@"status before %d", status);
    if (status == 0) {
        for (int i = 0; i < NUM_BUFFERS; i++) {
            AudioQueueAllocateBuffer(stateInp.queue, NUM_BYTES_PER_BUFFER, &stateInp.buffers[i]);
            AudioQueueEnqueueBuffer (stateInp.queue, stateInp.buffers[i], 0, NULL);
        }
        
        stateInp.isCapturing = true;
        status = AudioQueueStart(stateInp.queue, NULL);
       
        NSLog(@"status after %d", status);
    }
    
    NSLog(@"status before status %d", status);
    if (status != 0) {
        [self stopCapturing];
    }
    
}
- (void)onTranscribePrepare:(id)sender {
    NSLog( @"Processing - please wait ...");
    
    if (stateInp.isRealtime) {
        [self onRealtime:(id)sender];
    }
    
    if (stateInp.isCapturing) {
        [self stopCapturing];
    }
}

- (void)onRealtime:(id)sender {
    stateInp.isRealtime = !stateInp.isRealtime;
    
    NSLog(@"Realtime: %@", stateInp.isRealtime ? @"ON" : @"OFF");
}
- (void)onTranscribe:(id)sender {
    if (stateInp.isTranscribing) {
        return;
    }
    
    
    
    stateInp.isTranscribing = true;
    NSLog(@" // dispatch the model to a background threads");
    // dispatch the model to a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // process captured audio
        // convert I16 to F32
        for (int i = 0; i < self->stateInp.n_samples; i++) {
            self->stateInp.audioBufferF32[i] = (float)self->stateInp.audioBufferI16[i] / 32768.0f;
        }
        
        // run the model
        struct whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
        
        // get maximum number of threads on this device (max 8)
        const int max_threads = MIN(8, (int)[[NSProcessInfo processInfo] processorCount]);
        
        params.print_realtime   = true;
        params.print_progress   = false;
        params.print_timestamps = true;
        params.print_special    = false;
        params.translate        = false;
        params.language         = "en";
        params.n_threads        = max_threads;
        params.offset_ms        = 0;
        params.no_context       = true;
        params.single_segment   = self->stateInp.isRealtime;
        params.no_timestamps    = params.single_segment;
        
        
        whisper_reset_timings(self->stateInp.ctx);
        
        if (whisper_full(self->stateInp.ctx, params, self->stateInp.audioBufferF32, self->stateInp.n_samples) != 0) {
            
            NSLog(@"Failed to run the model");
            
            return;
        }
        
        
        
        
        
        // result text
        NSString *result = @"";
        
        int n_segments = whisper_full_n_segments(self->stateInp.ctx);
        for (int i = 0; i < n_segments; i++) {
            const char * text_cur = whisper_full_get_segment_text(self->stateInp.ctx, i);
            
            // append the text to the result
            result = [result stringByAppendingString:[NSString stringWithUTF8String:text_cur]];
        }
        NSLog(@"result is: %@", result);
        
        // dispatch the result to the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_eventSink) {
                self-> _eventSink(result);
            }
            self->stateInp.isTranscribing = false;
        });
    });
}
void AudioInputCallback(void * inUserData,
                        AudioQueueRef inAQ,
                        AudioQueueBufferRef inBuffer,
                        const AudioTimeStamp * inStartTime,
                        UInt32 inNumberPacketDescriptions,
                        const AudioStreamPacketDescription * inPacketDescs)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"In audio callback and runing on %@",  [NSThread currentThread]);
        StateInp * stateInp = (StateInp*)inUserData;
        
        if (!stateInp->isCapturing) {
            NSLog(@"Not capturing, ignoring audio");
            return;
        }
        
        const int n = inBuffer->mAudioDataByteSize / 2;
        
        NSLog(@"Captured %d new samples", n);
        
        if (stateInp->n_samples + n > MAX_AUDIO_SEC*SAMPLE_RATE) {
            NSLog(@"Too much audio data, ignoring");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                FlutterWhisperPlugin * vc = (__bridge FlutterWhisperPlugin *)(stateInp->vc);
                [vc stopCapturing];
            });
            
            return;
        }
        
        for (int i = 0; i < n; i++) {
            stateInp->audioBufferI16[stateInp->n_samples + i] = ((short*)inBuffer->mAudioData)[i];
        }
        
        stateInp->n_samples += n;
        
        // put the buffer back in the queue
        AudioQueueEnqueueBuffer(stateInp->queue, inBuffer, 0, NULL);
        
        if (stateInp->isRealtime) {
            // dispatch onTranscribe() to the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                FlutterWhisperPlugin * vc = (__bridge FlutterWhisperPlugin *)(stateInp->vc);
                [vc onTranscribe:nil];
            });
        }
    });
}

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self->_eventSink = events;
    NSLog(@"event channel started");
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self->_eventSink = nil;
    return nil;
}
@end

