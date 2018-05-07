//
//  ZSXRTCMananger.h
//  ZSXWebRTCDemo
//
//  Created by 邹时新 on 2018/4/21.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

@class ZSXRTCMananger;
@protocol ZSXRTCManangerDelegate <NSObject>

- (void)RTCManager:(ZSXRTCMananger *)manager didCreateLocalCapturer:(RTCCameraVideoCapturer *)localCapturer;

- (void)RTCManager:(ZSXRTCMananger *)manager didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack;


@end

@interface ZSXRTCMananger : NSObject

+ (instancetype)share;

- (void)initRTC;
- (void)createOffer;
- (void)getMsgData:(NSData *)data;
@property (nonatomic,weak)id <ZSXRTCManangerDelegate>delegate;

@end
