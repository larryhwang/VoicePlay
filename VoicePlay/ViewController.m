//
//  ViewController.m
//  VoicePlay
//
//  Created by Larry on 17/1/10.
//  Copyright © 2017年 Larry. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioSession.h>
#import "Definition.h"
#import "TTSConfig.h"
#import "PcmPlayer.h"
#import "PopupView.h"
#import <UserNotifications/UserNotifications.h>
#import "TTSConfig.h"
#import "AFNetworking.h"



void AudioServicesStopSystemSound(int);
void AudioServicesPlaySystemSoundWithVibration(int, id, NSDictionary *);

typedef NS_OPTIONS(NSInteger, SynthesizeType) {
    NomalType           = 5,//普通合成
    UriType             = 6, //uri合成
};

typedef NS_OPTIONS(NSInteger, Status) {
    NotStart            = 0,
    Playing             = 2, //高异常分析需要的级别
    Paused              = 4,
};


@interface ViewController ()<IFlySpeechSynthesizerDelegate,NSURLConnectionDataDelegate>

@property (nonatomic, strong) PcmPlayer *audioPlayer;
@property (nonatomic, strong) PopupView *popUpView;
@property (nonatomic, assign) BOOL isCanceled;
@property (nonatomic, assign) BOOL hasError;
@property (nonatomic, assign) BOOL isViewDidDisappear;
@property (nonatomic, assign) Status state;
@property (nonatomic, assign) SynthesizeType synType;
@property (nonatomic, strong) IFlySpeechSynthesizer * iFlySpeechSynthesizer;
@property (nonatomic,strong) NSTimer  *netReqTimer;
@property(nonatomic,copy)   NSString *VoiceTTS;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    UIButton *NetRqBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 20)];
    NetRqBtn.backgroundColor = [UIColor blueColor];
    NetRqBtn.titleLabel.text  = @"请求一次信息";
    NetRqBtn.center = self.view.center;
    [self.view addSubview:NetRqBtn];
    [NetRqBtn addTarget:self action:@selector(testNet) forControlEvents:UIControlEventTouchUpInside];
    

    
    //pcm播放器初始化
    _audioPlayer = [[PcmPlayer alloc] init];
    [self initSynthesizer];
    
    
    [self testNet];
    
    [self setTimer];

    

    
}


-(void)setTimer {
  self.netReqTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(testNet) userInfo:nil repeats:YES];
}


-(void)testNet {
    NSString *urtString = @"http://112.74.35.79/Request.php";
    NSURL *url = [NSURL URLWithString:urtString];    //字符串转URL
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithURL:url
                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                    NSDictionary *dataDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                                        if ([[dataDic objectForKey:@"sucess"] integerValue]==1) {
                                            NSLog(@"接受到数据");
                                            // 1、停止循环器
                                            [self.netReqTimer invalidate];
                                            //2、合成最后的播放字符串
                                            self.VoiceTTS = [dataDic objectForKey:@"data"];
//                                            self.VoiceTTS = @"1[p20000]A[p1000]C[p1000]F[p1000]F[p1000]B[p1000]2[p20000]B[p1000]B[p1000]F[p1000]A[p1000]C[p1000]10[p20000]A[p1000]A[p1000]C[p1000]C[p1000]B[p1000]19[p20000]B[p1000]B[p1000]C[p1000]A[p1000]C";
                                            
                                            self.VoiceTTS = [self cleanData:[dataDic objectForKey:@"data"]];
                                           [self testPlayVoice];
                                            //3. 开辟线程推送到AppWatch
                                            //    NSString* str= @"01[p100]2[p1000] [p500]  01[p100]2[p500] [p500]  02[p100]4[p500] [p500]   02[p100]4[p500] [p500]   03[p100]2[p500] [p500] 03[p100]2[p500]";

                                            //4.屏幕显示数据
                                        }else {
                                            NSLog(@"无数据");
                                        }
                                    
                                    }];
    // 启动任务
    [task resume];
}


-(void)testPlayVoice  {
    if (_audioPlayer != nil && _audioPlayer.isPlaying == YES) {
        [_audioPlayer stop];
    }
    
    _synType = NomalType;
    self.hasError = NO;
    [NSThread sleepForTimeInterval:0.05];
    [_popUpView removeFromSuperview];
    self.isCanceled = NO;
    
    _iFlySpeechSynthesizer.delegate = self;
    
    NSString* str= @"01[p100]2[p500] [p500]  01[p100]2[p500] [p500]  02[p100]4[p500] [p500]   02[p100]4[p500] [p500]   03[p100]2[p500] [p500] 03[p100]2[p500]";
    

    
    
    
    [_iFlySpeechSynthesizer startSpeaking:self.VoiceTTS];
    if (_iFlySpeechSynthesizer.isSpeaking) {
        _state = Playing;
    }
}



- (BOOL)shouldAutorotate{
    return NO;
}


#pragma mark - 设置合成参数
- (void)initSynthesizer
{
    TTSConfig *instance = [TTSConfig sharedInstance];
    if (instance == nil) {
        return;
    }
    
    //合成服务单例
    if (_iFlySpeechSynthesizer == nil) {
        _iFlySpeechSynthesizer = [IFlySpeechSynthesizer sharedInstance];
    }
    
    _iFlySpeechSynthesizer.delegate = self;
    
    //设置语速1-100
    [_iFlySpeechSynthesizer setParameter:instance.speed forKey:[IFlySpeechConstant SPEED]];
    
    //设置sml格式，支持词句停顿
    [_iFlySpeechSynthesizer setParameter:@"cssml" forKey:@"ttp"];
    
    //设置音量1-100
    [_iFlySpeechSynthesizer setParameter:instance.volume forKey:[IFlySpeechConstant VOLUME]];
    
    //设置音调1-100
    [_iFlySpeechSynthesizer setParameter:instance.pitch forKey:[IFlySpeechConstant PITCH]];
    
    //设置采样率
    [_iFlySpeechSynthesizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
    
    //[_iFlySpeechSynthesizer setParameter:<#(NSString *)#> forKey:[IFlySpeechConstant LANGUAGE_ENGLISH]]
    
    //设置发音人
    [_iFlySpeechSynthesizer setParameter:@"vimary" forKey:[IFlySpeechConstant VOICE_NAME]];
    //    云端支持发音人：小燕（xiaoyan）、小宇（xiaoyu）、凯瑟琳（Catherine）、
    //    亨利（henry）、玛丽（vimary）、小研（vixy）、小琪（vixq）、
    //    小峰（vixf）、小梅（vixm）、小莉（vixl）、小蓉（四川话）、
    //    小芸（vixyun）、小坤（vixk）、小强（vixqa）、小莹（vixying）、 小新（vixx）、楠楠（vinn）老孙（vils）<br>
    //    对于网络TTS的发音人角色，不同引擎类型支持的发音人不同，使用中请注意选择。
    //设置文本编码格式
    //   [_iFlySpeechSynthesizer setParameter:@"ASCII" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    
    
    NSDictionary* languageDic=@{@"Guli":@"text_uighur", //维语
                                @"XiaoYun":@"text_vietnam",//越南语
                                @"Abha":@"text_hindi",//印地语
                                @"Gabriela":@"text_spanish",//西班牙语
                                @"Allabent":@"text_russian",//俄语
                                @"Mariane":@"text_french"};//法语
    
    NSString* textNameKey=[languageDic valueForKey:instance.vcnName];
    NSString* textSample=nil;
    
    if(textNameKey && [textNameKey length]>0){
        textSample=NSLocalizedStringFromTable(textNameKey, @"tts/tts", nil);
    }else{
        textSample=NSLocalizedStringFromTable(@"text_chinese", @"tts/tts", nil);
        
    }
    
}


//JSON 转字典
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    
    if (jsonString == nil) {
        
        return nil;
        
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                         
                                                        options:NSJSONReadingMutableContainers
                         
                                                          error:&err];
    
    if(err) {
        
        NSLog(@"json解析失败：%@",err);
        
        return nil;
        
    }
    
    return dic;
    
}


//随机生成数组，用于听力训练
-(void)RandomTool {
    
}
    
    
-(NSString *)cleanData:(NSString *)rawData {
    //1ABCD10AACCD22BBDDC
    NSMutableString  *cleanData = [NSMutableString new];
    NSInteger alength = [rawData length];
    
    NSLog(@"Raw:%@",rawData);
    for (int i = 0; i<alength; i++) {
        char commitChar = [rawData characterAtIndex:i];
        NSString *temp;
        if(commitChar ==68) {
           temp = @"F";
        }else {
           temp = [rawData substringWithRange:NSMakeRange(i,1)];
        }
        
        if(commitChar>64) {
          //  NSLog(@"字母");
            [cleanData appendString:temp];
            [cleanData appendString:@"[p1300]"];
            
        }else if((commitChar>47)&&(commitChar<58)){
          //  NSLog(@"数字");
            [cleanData appendString:temp];
            if(i>0) {
                char preChar = [rawData characterAtIndex:(i - 1)];
                char nxtChar = [rawData characterAtIndex:(i + 1)];
                if(((nxtChar>47)&&(nxtChar<58))&&(preChar>64)) {  //如果下一个是数字，前者是字母 则不佳
                    
                }else {
                   [cleanData appendString:@"[p5000]"];
                }
            } else{  //end if(i-1)>0
                //首位的情况
                [cleanData appendString:@"[p5000]"];
            }
        }
    }
    
    NSLog(@"cleanData:%@",cleanData);
        return cleanData;
}
    
@end
