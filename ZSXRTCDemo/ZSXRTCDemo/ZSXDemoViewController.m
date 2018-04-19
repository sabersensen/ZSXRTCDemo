//
//  ZSXDemoViewController.m
//  ZSXRTCDemo
//
//  Created by 邹时新 on 2018/4/18.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import "ZSXDemoViewController.h"
#import <WebRTC/WebRTC.h>
@interface ZSXDemoViewController ()

@end

@implementation ZSXDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    RTCEAGLVideoView *localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:self.view.frame];
    //标记本地的摄像头
    localVideoView.tag = 100;
//    _localVideoTrack = [stream.videoTracks lastObject];
//    [_localVideoTrack addRenderer:localVideoView];
    
    [self.view addSubview:localVideoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
