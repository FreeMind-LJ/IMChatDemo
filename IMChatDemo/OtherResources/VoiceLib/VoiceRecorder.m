//
//  Mp3Recorder.m
//  BloodSugar
//
//  Created by PeterPan on 14-3-24.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import "VoiceRecorder.h"
#import "VoiceConverter.h"
#import <AVFoundation/AVFoundation.h>

@interface VoiceRecorder()<AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSString *path;
@end

@implementation VoiceRecorder

#pragma mark - Init Methods

- (id)initWithDelegate:(id<VoiceRecorderDelegate>)delegate
{
    if (self = [super init]) {
        _delegate = delegate;
        _path = [self wavPath];
    }
    return self;
}

- (void)setRecorder
{
    _recorder = nil;
    NSError *recorderSetupError = nil;
    NSURL *url = [NSURL fileURLWithPath:[self wavPath]];
    
    //录音设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
   
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:8000 ] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    _recorder = [[AVAudioRecorder alloc] initWithURL:url
                                            settings:recordSetting
                                               error:&recorderSetupError];
    if (recorderSetupError) {
        NSLog(@"%@",recorderSetupError);
    }
    _recorder.meteringEnabled = YES;
    _recorder.delegate = self;
    [_recorder prepareToRecord];
}

- (void)setSesstion
{
    _session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(_session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [_session setActive:YES error:nil];
}

#pragma mark - Public Methods
- (void)setSavePath:(NSString *)path
{
    self.path = path;
}

- (void)startRecord
{
    [self setSesstion];
    [self setRecorder];
    [_recorder record];
}


- (void)stopRecord
{
    double cTime = _recorder.currentTime;
    [_recorder stop];
    
    if (cTime > 1) {
        [self audio_wavtoAmr];
    }else {
        [_recorder deleteRecording];
        if ([_delegate respondsToSelector:@selector(failRecord)]) {
            [_delegate failRecord];
        }
    }
}

- (void)cancelRecord
{
    [_recorder stop];
    [_recorder deleteRecording];
}

- (void)deleteWavCache
{
    [self deleteFileWithPath:[self wavPath]];
}

- (void)deleteFileWithPath:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager removeItemAtPath:path error:nil])
    {
        NSLog(@"删除以前的mp3文件");
    }
}

#pragma mark - Convert Utils

- (void)audio_wavtoAmr
{
    NSString *wavFilePath = [self wavPath];
    
    if (_delegate && [_delegate respondsToSelector:@selector(beginConvert)]) {
        [_delegate beginConvert];
    }
    
    NSString *amrFilePath = [VoiceConverter wavToAmr:wavFilePath];
    
    [self deleteWavCache];
    
    if (_delegate && [_delegate respondsToSelector:@selector(endConvertWithData:)]) {
        NSData *voiceData = [NSData dataWithContentsOfFile:amrFilePath];
        [_delegate endConvertWithData:voiceData];
    }
    
}

#pragma mark - Path Utils
- (NSString *)wavPath
{
    NSString *wavPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.wav"];
    return wavPath;
}


@end
