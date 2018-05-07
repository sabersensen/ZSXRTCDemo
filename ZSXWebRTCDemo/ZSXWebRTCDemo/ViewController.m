//
//  ViewController.m
//  ZSXWebRTCDemo
//
//  Created by 邹时新 on 2018/4/21.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import "ViewController.h"
#import <WebRTC/WebRTC.h>
#import "ZSXRTCMananger.h"
#import "ZSXScocketManager.h"
#import "ARDCaptureController.h"
#import "ARDSettingsModel.h"
@interface ViewController ()<ZSXRTCManangerDelegate,ZSXScocketManagerDelegate>
@property (nonatomic,strong)RTCCameraPreviewView *localVideoView;
@property(nonatomic, strong) __kindof UIView<RTCVideoRenderer> *remoteVideoView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)onConnectClick:(id)sender {
    [ZSXScocketManager share].delegate = self;
    [[ZSXScocketManager share] connect];


}
- (IBAction)onCallClick:(id)sender {
    ZSXRTCMananger *rtc = [ZSXRTCMananger share];
    rtc.delegate = self;
    [rtc initRTC];
    [rtc createOffer];
}
- (IBAction)onConnectOfferClick:(id)sender {
    ZSXRTCMananger *rtc = [ZSXRTCMananger share];
    rtc.delegate = self;
    [rtc initRTC];
}



#pragma mark - ZSXRTCManangerDelegate

- (void)RTCManager:(ZSXRTCMananger *)manager didCreateLocalCapturer:(RTCCameraVideoCapturer *)localCapturer{
    // 为视频流渲染视图
    self.localVideoView.captureSession = localCapturer.captureSession;
    ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
    ARDCaptureController *captureController =
    [[ARDCaptureController alloc] initWithCapturer:localCapturer settings:settingsModel];
    [captureController startCapture];
    [self.view insertSubview:self.localVideoView atIndex:0];
}

- (void)RTCManager:(ZSXRTCMananger *)manager didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack{
    [self.remoteVideoView renderFrame:nil];
    [remoteVideoTrack addRenderer:self.remoteVideoView];
}

#pragma mark - ZSXScocketManagerDelegate

- (void)scocketManager:(ZSXScocketManager *)manager didReadData:(NSData *)data{
    ZSXRTCMananger *rtc = [ZSXRTCMananger share];
    [rtc getMsgData:data];
}

#pragma mark - Getter

- (RTCCameraPreviewView *)localVideoView{
    if (!_localVideoView) {
        _localVideoView = [[RTCCameraPreviewView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    }
    return _localVideoView;
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
        [self.view insertSubview:_remoteVideoView atIndex:1];
    }
    return _remoteVideoView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
