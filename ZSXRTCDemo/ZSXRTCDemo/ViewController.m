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

@interface ViewController ()<UITextFieldDelegate,ZSXDemoSocketManagerDelegate>


@property (weak, nonatomic) IBOutlet UITextField *text;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (nonatomic,strong)ZSXSocketManager *socketManager;
@property (nonatomic,strong)ZSXCocoaSocketManager *cocoaSocketManager;
@property (nonatomic,strong)ZSXDemoSocketManager *demoSocketManager;

@property (nonatomic,strong)RTCVideoTrack *localVideoTrack;

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
    RTCEAGLVideoView *localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    //标记本地的摄像头
    localVideoView.tag = 100;
    _localVideoTrack = [stream.videoTracks lastObject];
    [_localVideoTrack addRenderer:localVideoView];
    
    [self.view addSubview:localVideoView];
    
    NSLog(@"setLocalStream");
}

- (void)socketManager:(ZSXDemoSocketManager *)manager closeWithUserId:(NSString *)userId{
    
}

- (void)socketManager:(ZSXDemoSocketManager *)manager addRemoteStream:(RTCMediaStream *)stream userId:(NSString *)userId{
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
