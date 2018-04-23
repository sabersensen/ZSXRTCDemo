//
//  ViewController.m
//  ZSXRTCDemo
//
//  Created by 邹时新 on 2018/4/16.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import "ViewController.h"
#import "ZSXSocketManager.h"
#import "ZSXCocoaSocketManager.h"
#import "ZSXDemoSocketManager.h"
#import <WebRTC/WebRTC.h>
#import "ARDCaptureController.h"
#import "ARDSettingsModel.h"
@interface ViewController ()<UITextFieldDelegate,ZSXDemoSocketManagerDelegate>


@property (weak, nonatomic) IBOutlet UITextField *text;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (nonatomic,strong)ZSXSocketManager *socketManager;
@property (nonatomic,strong)ZSXCocoaSocketManager *cocoaSocketManager;
@property (nonatomic,strong)ZSXDemoSocketManager *demoSocketManager;

@property (nonatomic,strong)RTCVideoTrack *localVideoTrack;
@property (nonatomic,strong)RTCCameraPreviewView *localVideoView;

@property(nonatomic, strong) __kindof UIView<RTCVideoRenderer> *remoteVideoView;
@end

@implementation ViewController
- (IBAction)onConnectClick:(id)sender {
//    [self.socketManager connect];
//    [_cocoaSocketManager connect];
    [_demoSocketManager connect];

}

- (IBAction)onSendClick:(id)sender {
    [self.view endEditing:YES];
//    [self.socketManager sendMsg:_text.text];
//    [_cocoaSocketManager sendMsg:_text.text];

    [_demoSocketManager sendMsg:_text.text];

}

- (IBAction)onCloseClick:(id)sender {
//    [self.socketManager disConnect];
    [_demoSocketManager disConnect];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _text.delegate = self;
//    _socketManager = [ZSXSocketManager share];
//    _cocoaSocketManager = [ZSXCocoaSocketManager share];
    _demoSocketManager = [ZSXDemoSocketManager share];
    _demoSocketManager.delegate = self;
}

#pragma mark -

- (void)socketManager:(ZSXDemoSocketManager *)manager setLocalStream:(RTCMediaStream *)stream userId:(NSString *)userId{
    
    //标记本地的摄像头
//    _localVideoView.tag = 100;
//    _localVideoTrack = [stream.videoTracks lastObject];
//    [_localVideoTrack addRenderer:_localVideoView];
    
    [self.view addSubview:_localVideoView];
    
    NSLog(@"setLocalStream");
}

- (void)socketManager:(ZSXDemoSocketManager *)manager didCreateLocalCapturer:(RTCCameraVideoCapturer *)localCapturer{
    // 为视频流渲染视图
    _localVideoView = [[RTCCameraPreviewView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    _localVideoView.captureSession = localCapturer.captureSession;
    ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
    ARDCaptureController *captureController =
    [[ARDCaptureController alloc] initWithCapturer:localCapturer settings:settingsModel];
    [captureController startCapture];
    
}

- (void)socketManager:(ZSXDemoSocketManager *)manager closeWithUserId:(NSString *)userId{
    
}

- (void)socketManager:(ZSXDemoSocketManager *)manager addRemoteStream:(RTCMediaStream *)stream userId:(NSString *)userId{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)socketManager:(ZSXDemoSocketManager *)manager didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack{
    
//    [remoteVideoTrack removeRenderer:self.remoteVideoView];
//    remoteVideoTrack = nil;
    [self.remoteVideoView renderFrame:nil];
    [remoteVideoTrack addRenderer:self.remoteVideoView];
}

- (UIView<RTCVideoRenderer> *)remoteVideoView{
    if (!_remoteVideoView) {
#if defined(RTC_SUPPORTS_METAL)
        _remoteVideoView = [[RTCMTLVideoView alloc] initWithFrame:CGRectZero];
#else
        RTCEAGLVideoView *remoteView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
        remoteView.delegate = self;
        _remoteVideoView = remoteView;
#endif
        _remoteVideoView.frame = self.view.frame;
        [self.view addSubview:_remoteVideoView];
    }
    return _remoteVideoView;
}


@end
