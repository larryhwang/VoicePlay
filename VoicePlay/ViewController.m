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
@property(nonatomic,copy)   NSString *VoiceTTS;

@property (strong ,nonatomic) NSMutableData *ServerData;  //返回的数据

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
    
    
    
    
    //添加通知测试
  //  [self registerNotification:16];
    
    //pcm播放器初始化
    _audioPlayer = [[PcmPlayer alloc] init];
    [self initSynthesizer];
  //  [self testPlayVoice];   //播放声音
    
    [self testNet];
    
    //[self setTimer];
   // [self dataDeal];
    

    
}



-(void)dataDeal {
    NSString *string1 = @"012022031042054";  //15个
    NSMutableString *ResStr = [NSMutableString stringWithFormat:@"%@",string1];
    NSString *preTTSStr = @"";
    NSString *resString = nil;
    NSString *tempStr   = nil;
    int Total = (int)[string1 length];
    //01[p100]2[p500] [p500]
    for (int a=0; a<Total; a++) {
        if (a==0) {
            tempStr = [string1 substringToIndex:1];;
        } else {
            tempStr = [string1 substringWithRange:NSMakeRange(a, a)];
            
            NSString  *string3 = [string1 substringFromIndex:a];
            tempStr = [string3 substringToIndex:1];
        }
        NSLog(@"fangwei : %d ,%d %@",a,a,tempStr);
        preTTSStr = [preTTSStr stringByAppendingString:tempStr];
        if ((a+1)%3 ==0 && a!=0) {
            preTTSStr = [preTTSStr stringByAppendingString:@"[p500]"];
        } else {
            preTTSStr = [preTTSStr stringByAppendingString:@"[p100]"];
        }
    }
    NSLog(@"重组之后：%@",preTTSStr);
    self.VoiceTTS = preTTSStr;
    [self testPlayVoice];
}

-(void)setTimer {
  [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(testNet) userInfo:nil repeats:YES];
}


-(void)testNet {
   // NSString *urtString = @"http://www.weather.com.cn/data/sk/101010100.html";
     //NSString *urtString = @"112.74.35.79/index.html";
    //NSString *urtString = @"http://112.74.35.79/Request.php";
    NSString *urtString = @"http://127.0.0.1/Request.php";
    NSURL *url = [NSURL URLWithString:urtString];    //字符串转URL
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithURL:url
                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                        NSLog(@"返回的数据%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
                                        NSLog(@"%@",error);
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
    
   // NSString  *TS = [NSString stringWithFormat:@"惠州市峰华经纬科技有限公司"];
    
     NSString  *TS = [NSString stringWithFormat:@"Hello World"];
     
    
    
    
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
    NSString *textStr = NSLocalizedStringFromTable(@"0 <break time=”2000ms”/>2[p500]3 [p500] ",@"tts/tts",nil);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark netDelegate

// 1.得到接到服务器的响应第一个执行的方法，服务器要传送数据   初始化接受过来的数据
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
}

//2.接受服务器数据
-(void)connection:(NSURLConnection *) connection didReceiveData:(NSData *)data {
    [self.ServerData  appendData:data];    //不断接受数据，可能多次执行
}

//3.数据接受完成后，做后续处理
-(void) connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"has receive data");
    NSString *str = [[NSString alloc]initWithData:self.ServerData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",str);    //打印服务器返回信息
    
   // UIAlertView *alertView = self.ServerData = nil;   //清理数据
}

//4.获取网络错误时的信息
-(void)connection:(NSURLConnection *) connection diFailWithError : (NSError *) error{
    NSLog(@"网络请求错误:%@",error.localizedDescription);
}



@end
