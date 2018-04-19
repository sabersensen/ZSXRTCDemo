//
//  ZSXDemoSocketManager.h
//  ZSXRTCDemo
//
//  Created by 邹时新 on 2018/4/18.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>
@class ZSXDemoSocketManager;
@protocol ZSXDemoSocketManagerDelegate <NSObject>

@optional
- (void)socketManager:(ZSXDemoSocketManager *)manager setLocalStream:(RTCMediaStream *)stream userId:(NSString *)userId;
- (void)socketManager:(ZSXDemoSocketManager *)manager addRemoteStream:(RTCMediaStream *)stream userId:(NSString *)userId;
- (void)socketManager:(ZSXDemoSocketManager *)manager closeWithUserId:(NSString *)userId;

@end


@interface ZSXDemoSocketManager : NSObject

@property (nonatomic, weak)id<ZSXDemoSocketManagerDelegate> delegate;

+ (instancetype)share;

- (BOOL)connect;
- (void)disConnect;


- (void)sendMsg:(NSString *)msg;
- (void)pullTheMsg;
@end
