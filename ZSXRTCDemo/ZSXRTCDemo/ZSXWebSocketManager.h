//
//  ZSXWebSocketManager.h
//  ZSXRTCDemo
//
//  Created by 邹时新 on 2018/4/18.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    disConnectByUser ,
    disConnectByServer,
} DisConnectType;

@interface ZSXWebSocketManager : NSObject

+ (instancetype)share;

- (void)connect;
- (void)disConnect;

- (void)sendMsg:(NSString *)msg;

- (void)ping;

@end
