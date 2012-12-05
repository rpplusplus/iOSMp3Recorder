//
//  TXXViewController.h
//  iOSMp3Recorder
//
//  Created by Xiaoxuan Tang on 12-12-5.
//  Copyright (c) 2012年 xiaoxuan Tang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include "lame.h"

@interface TXXViewController : UIViewController<AVAudioPlayerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    UIButton*                       _playBtn;
    UIButton*                       _encodeBtn;
    UIButton*                       _recordBtn;
    UIButton*                       _playMp3Btn;
    
    UILabel*                        _cafFileSize;
    UILabel*                        _mp3FileSize;
    UILabel*                        _duration;
    UILabel*                        _format;
    
    UISegmentedControl*             _sampleRateSegment;
    UISegmentedControl*             _qualityRateSegment;
    
    UIPickerView*                   _picker;
    
    AVAudioRecorder*                _recorder;
    AVAudioPlayer*                  _player;
    AVAudioPlayer*                  _mp3Player;
    
    UIProgressView*                 _progress;
    UIProgressView*                 _mp3Progress;
    
    BOOL                            _hasCAFFile;
    BOOL                            _recording;
    BOOL                            _playing;
    BOOL                            _hasMp3File;
    BOOL                            _playingMp3;
    
    NSURL*                          _recordedFile;
    CGFloat                         _sampleRate;
    AVAudioQuality                  _quality;
    NSInteger                       _formatIndex;
    NSTimer*                        _timer;
    UIAlertView*                    _alert;
    NSDate*                         _startDate;
}

@property (nonatomic, retain) IBOutlet UILabel*             cafFileSize;
@property (nonatomic, retain) IBOutlet UILabel*             mp3FileSize;
@property (nonatomic, retain) IBOutlet UILabel*             duration;
@property (nonatomic, retain) IBOutlet UILabel*             format;
@property (nonatomic, retain) IBOutlet UIButton*            recordBtn;
@property (nonatomic, retain) IBOutlet UIButton*            playBtn;
@property (nonatomic, retain) IBOutlet UIButton*            encodeBtn;
@property (nonatomic, retain) IBOutlet UIButton*            playMp3Btn;
@property (nonatomic, retain) IBOutlet UISegmentedControl*  sampleRateSegment;
@property (nonatomic, retain) IBOutlet UISegmentedControl*  qualityRateSegment;
@property (nonatomic, retain) IBOutlet UIProgressView*      progress;
@property (nonatomic, retain) IBOutlet UIProgressView*      mp3Progress;

- (IBAction) recordBtnClick:    (id)sender;
- (IBAction) playBtnClick:      (id)sender;
- (IBAction) encodeBtnClick:    (id)sender;
- (IBAction) chooseFormat:      (id)sender;
- (IBAction) removePicker:      (id)sender;
- (IBAction) sampleRateSgtClick:(id)sender;
- (IBAction) qualitySgtClick:   (id)sender;
- (IBAction) outputSgtClick:    (id)sender;
- (IBAction) playMp3BtnClick:   (id)sender;
@end
