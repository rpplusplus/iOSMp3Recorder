//
//  TXXViewController.m
//  iOSMp3Recorder
//
//  Created by Xiaoxuan Tang on 12-12-5.
//  Copyright (c) 2012年 xiaoxuan Tang. All rights reserved.
//

#import "TXXViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface TXXViewController ()

@end

@implementation TXXViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    _sampleRate  = 44100;
    _quality     = AVAudioQualityLow;
    _formatIndex = [self formatIndexToEnum:0];
    _recording = _playing = _hasCAFFile = NO;
    if(session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [session setActive:YES error:nil];
}

- (NSInteger) formatIndexToEnum:(NSInteger) index
{
    //auto generate by python
    switch (index) {
        case 0: return kAudioFormatLinearPCM; break;
        case 1: return kAudioFormatAC3; break;
        case 2: return kAudioFormat60958AC3; break;
        case 3: return kAudioFormatAppleIMA4; break;
        case 4: return kAudioFormatMPEG4AAC; break;
        case 5: return kAudioFormatMPEG4CELP; break;
        case 6: return kAudioFormatMPEG4HVXC; break;
        case 7: return kAudioFormatMPEG4TwinVQ; break;
        case 8: return kAudioFormatMACE3; break;
        case 9: return kAudioFormatMACE6; break;
        case 10: return kAudioFormatULaw; break;
        case 11: return kAudioFormatALaw; break;
        case 12: return kAudioFormatQDesign; break;
        case 13: return kAudioFormatQDesign2; break;
        case 14: return kAudioFormatQUALCOMM; break;
        case 15: return kAudioFormatMPEGLayer1; break;
        case 16: return kAudioFormatMPEGLayer2; break;
        case 17: return kAudioFormatMPEGLayer3; break;
        case 18: return kAudioFormatTimeCode; break;
        case 19: return kAudioFormatMIDIStream; break;
        case 20: return kAudioFormatParameterValueStream; break;
        case 21: return kAudioFormatAppleLossless; break;
        case 22: return kAudioFormatMPEG4AAC_HE; break;
        case 23: return kAudioFormatMPEG4AAC_LD; break;
        case 24: return kAudioFormatMPEG4AAC_ELD; break;
        case 25: return kAudioFormatMPEG4AAC_ELD_SBR; break;
        case 26: return kAudioFormatMPEG4AAC_ELD_V2; break;
        case 27: return kAudioFormatMPEG4AAC_HE_V2; break;
        case 28: return kAudioFormatMPEG4AAC_Spatial; break;
        case 29: return kAudioFormatAMR; break;
        case 30: return kAudioFormatAudible; break; 
        case 31: return kAudioFormatiLBC; break; 
        case 32: return kAudioFormatDVIIntelIMA; break; 
        case 33: return kAudioFormatMicrosoftGSM; break; 
        case 34: return kAudioFormatAES3; break;
        default:
            return -1;
            break;
    }
}

- (NSInteger) getFileSize:(NSString*) path
{
    NSFileManager * filemanager = [[[NSFileManager alloc]init] autorelease];
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
            return  [theFileSize intValue];
        else
            return -1;
    }
    else
    {
        return -1;
    }
}

- (void) timerUpdate
{
    if (_recording)
    {
        int m = _recorder.currentTime / 60;
        int s = ((int) _recorder.currentTime) % 60;
        int ss = (_recorder.currentTime - ((int) _recorder.currentTime)) * 100;
        
        _duration.text = [NSString stringWithFormat:@"%.2d:%.2d %.2d", m, s, ss];
        NSInteger fileSize =  [self getFileSize:[NSTemporaryDirectory() stringByAppendingString:@"RecordedFile"]];
        
        _cafFileSize.text = [NSString stringWithFormat:@"%d kb", fileSize/1024];
    }
    if (_playing)
    {
        _progress.progress = _player.currentTime/_player.duration;
    }
    if (_playingMp3)
    {
        _mp3Progress.progress = _mp3Player.currentTime/_mp3Player.duration;
    }
}

- (void) toMp3
{
    NSString *cafFilePath =[NSTemporaryDirectory() stringByAppendingString:@"RecordedFile"];
    
    NSString *mp3FileName = @"Mp3File";
    mp3FileName = [mp3FileName stringByAppendingString:@".mp3"];
    NSString *mp3FilePath = [[NSHomeDirectory() stringByAppendingFormat:@"/Documents/"] stringByAppendingPathComponent:mp3FileName];
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([cafFilePath cStringUsingEncoding:1], "rb");  //source
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, _sampleRate);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        [self performSelectorOnMainThread:@selector(convertMp3Finish)
                               withObject:nil
                            waitUntilDone:YES];
    }
}

- (void) convertMp3Finish
{
    [_alert dismissWithClickedButtonIndex:0 animated:YES];
    
    _alert = [[UIAlertView alloc] init];
    [_alert setTitle:@"Finish"];
    [_alert setMessage:[NSString stringWithFormat:@"Conversion takes %fs", [[NSDate date] timeIntervalSinceDate:_startDate]]];
    [_startDate release];
    [_alert addButtonWithTitle:@"OK"];
    [_alert setCancelButtonIndex: 0];
    [_alert show];
    [_alert release];
    
    _hasMp3File = YES;
    [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    NSInteger fileSize =  [self getFileSize:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", @"Mp3File.mp3"]];
    _mp3FileSize.text = [NSString stringWithFormat:@"%d kb", fileSize/1024];
}

#pragma mark - IBAction

- (IBAction) removePicker:(id)sender
{
    [_picker removeFromSuperview];
    _picker = nil;
}

- (IBAction) recordBtnClick:(id)sender
{
    if (!_recording)
    {
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithFloat: _sampleRate],                  AVSampleRateKey,
                                  [NSNumber numberWithInt: _formatIndex],                   AVFormatIDKey,
                                  [NSNumber numberWithInt: 2],                              AVNumberOfChannelsKey,
                                  [NSNumber numberWithInt: _quality],                       AVEncoderAudioQualityKey,
                                  nil];
        
        _recordedFile = [[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"RecordedFile"]]retain];
        NSError* error;
        _recorder = [[AVAudioRecorder alloc] initWithURL:_recordedFile settings:settings error:&error];
        NSLog(@"%@", [error description]);
       if (error)
       {
           UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                           message:@"your device doesn't support your setting"
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles: nil];
           [alert show];
           [alert release];
           return;
       }
        _recording = YES;
        [_recorder prepareToRecord];
        _recorder.meteringEnabled = YES;
        [_recorder record];
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:.01f
                                                  target:self
                                                selector:@selector(timerUpdate)
                                                userInfo:nil
                                                 repeats:YES];
        [_recordBtn setTitle:@"Stop Record" forState:UIControlStateNormal];
    }
    else
    {
        [_recordBtn setTitle:@"Start Record" forState:UIControlStateNormal];
        _recording = NO;
        
        [_timer invalidate];
        _timer = nil;
        
        if (_recorder != nil )
        {
            _hasCAFFile = YES;
            _playBtn.enabled = YES;
        }
        [_recorder stop];
        [_recorder release];
        _recorder = nil;
    }
}

- (IBAction) playBtnClick:(UIButton*) sender
{
    if (_playingMp3 || _recording) return;
    
    if (_playing)
    {
        [_timer invalidate];
        _playing = NO;
        [sender setTitle:@"CAFPlay" forState:UIControlStateNormal];
        [_player pause];
    }
    else
    {
        if (_hasCAFFile)
        {
            if (_player == nil)
            {
                
                NSError *playerError;
                _player = [[AVAudioPlayer alloc] initWithContentsOfURL:_recordedFile error:&playerError];
                _player.meteringEnabled = YES;
                if (_player == nil)
                {
                    NSLog(@"ERror creating player: %@", [playerError description]);
                }
                _player.delegate = self;
            }
            _playing = YES;
            [_player play];
            _timer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                      target:self
                                                    selector:@selector(timerUpdate)
                                                    userInfo:nil
                                                     repeats:YES];
            [sender setTitle:@"CAFPause" forState:UIControlStateNormal];
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Sorry"
                                                            message:@"Please Record a File First"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
            [alert release];
        }
    }
}

- (IBAction) encodeBtnClick:(id)sender
{
    if (_hasCAFFile && !_recording && !_playing)
    {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        _alert = [[UIAlertView alloc] init];
        [_alert setTitle:@"Waiting.."];

        UIActivityIndicatorView* activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

        if (_formatIndex != [self formatIndexToEnum:0])
        {
            _alert.message = @"attetion: I've just tested the linearPCM to Mp3, I'm not sure your format will be OK. Have a good luck.";
            activity.frame = CGRectMake(140, 150, CGRectGetWidth(_alert.frame), CGRectGetHeight(_alert.frame));
        }
        else
        {
            activity.frame = CGRectMake(140,
                                        80,
                                        CGRectGetWidth(_alert.frame),
                                        CGRectGetHeight(_alert.frame));
        }
        
        [_alert addSubview:activity];
        [activity startAnimating];
        [activity release];

        [_alert show];
        [_alert release];
        _startDate = [[NSDate date] retain];
        [NSThread detachNewThreadSelector:@selector(toMp3) toTarget:self withObject:nil];
    }
}

- (IBAction) chooseFormat:(id)sender
{
    _picker = [[UIPickerView alloc] init];
    
    _picker.frame = CGRectMake(0,
                              CGRectGetHeight(self.view.frame) - CGRectGetHeight(_picker.frame),
                              CGRectGetWidth(_picker.frame),
                              CGRectGetHeight(_picker.frame));
    _picker.dataSource = self;
    _picker.delegate = self;
    _picker.showsSelectionIndicator = YES;

    [self.view addSubview: _picker];
    [_picker release];
}

- (IBAction) sampleRateSgtClick:(id)sender
{
    if (_sampleRateSegment.selectedSegmentIndex == 0)
        _sampleRate = 44100.0;
    else
        _sampleRate = 11025.0;
}

- (IBAction) qualitySgtClick:(id)sender
{
    switch (_qualityRateSegment.selectedSegmentIndex) {
        case 0:
            _quality = AVAudioQualityMin;
            break;
        case 1:
            _quality = AVAudioQualityLow;
            break;
        case 2:
            _quality = AVAudioQualityMedium;
            break;
        case 3:
            _quality = AVAudioQualityHigh;
            break;
        case 4:
            _quality = AVAudioQualityMax;
            break;
        default:
            break;
    }
}

- (IBAction) outputSgtClick:(UISegmentedControl*) sender
{
    if (sender.selectedSegmentIndex == 0)
    {
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    }
    else
    {
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    }
}

- (IBAction) playMp3BtnClick:(id)sender
{
    if (_recording || _playing || !_hasMp3File || !_hasCAFFile) return;
    if (_playingMp3)
    {
        [_timer invalidate];
        _playingMp3 = NO;
        [sender setTitle:@"Mp3Play" forState:UIControlStateNormal];
        [_mp3Player pause];
    }
    else
    {
        if (_mp3Player == nil)
        {
            
            NSError *playerError;
            _mp3Player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@", @"Mp3File.mp3"]]
                                                             error:&playerError];
            _mp3Player.meteringEnabled = YES;
            if (_mp3Player == nil)
            {
                NSLog(@"ERror creating player: %@", [playerError description]);
            }
            _mp3Player.delegate = self;
        }
        _playingMp3 = YES;
        [_mp3Player play];
        _timer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                  target:self
                                                selector:@selector(timerUpdate)
                                                userInfo:nil
                                                 repeats:YES];
        [sender setTitle:@"Mp3Pause" forState:UIControlStateNormal];
    }
}

#pragma mark  - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 34;
}
#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    //auto generate by python
    switch (row) {
        case 0: return @"LinearPCM"; break;
        case 1: return @"AC3"; break;
        case 2: return @"60958AC3"; break;
        case 3: return @"AppleIMA4"; break;
        case 4: return @"MPEG4AAC"; break;
        case 5: return @"MPEG4CELP"; break;
        case 6: return @"MPEG4HVXC"; break;
        case 7: return @"MPEG4TwinVQ"; break;
        case 8: return @"MACE3"; break;
        case 9: return @"MACE6"; break;
        case 10: return @"ULaw"; break;
        case 11: return @"ALaw"; break;
        case 12: return @"QDesign"; break;
        case 13: return @"QDesign2"; break;
        case 14: return @"QUALCOMM"; break;
        case 15: return @"MPEGLayer1"; break;
        case 16: return @"MPEGLayer2"; break;
        case 17: return @"MPEGLayer3"; break;
        case 18: return @"TimeCode"; break;
        case 19: return @"MIDIStream"; break;
        case 20: return @"ParameterValueStream"; break;
        case 21: return @"AppleLossless"; break;
        case 22: return @"MPEG4AAC_HE"; break;
        case 23: return @"MPEG4AAC_LD"; break;
        case 24: return @"MPEG4AAC_ELD"; break;
        case 25: return @"MPEG4AAC_ELD_SBR"; break;
        case 26: return @"MPEG4AAC_ELD_V2"; break;
        case 27: return @"MPEG4AAC_HE_V2"; break;
        case 28: return @"MPEG4AAC_Spatial"; break;
        case 29: return @"AMR"; break;
        case 30: return @"Audible"; break;
        case 31: return @"iLBC"; break;
        case 32: return @"DVIIntelIMA"; break;
        case 33: return @"MicrosoftGSM"; break;
        case 34: return @"AES3"; break;
        default: return @""; break;
    }
}

- (void) pickerView:(UIPickerView *)pickerView
       didSelectRow:(NSInteger)row
        inComponent:(NSInteger)component
{
    _format.text = [self pickerView:_picker titleForRow:row forComponent:component];
    _formatIndex = [self formatIndexToEnum:row];
}
#pragma mark - AVAudioPlayerDelegate
- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (_mp3Player == player)
    {
        [_playMp3Btn setTitle:@"MP3Play" forState:UIControlStateNormal];
        [_timer invalidate];
        _timer = nil;
        _playingMp3 = NO;
    }
    else
    {
        [_playBtn setTitle:@"CAFPlay" forState:UIControlStateNormal];
        [_timer invalidate];
        _timer = nil;
        _playing = NO;
    }
}
@end
