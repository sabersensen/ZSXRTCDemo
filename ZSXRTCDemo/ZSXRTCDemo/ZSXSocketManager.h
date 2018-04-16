//
//  ZSXSocketManager.h
//  ZSXRTCDemo
//
//  Created by 邹时新 on 2018/4/16.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZSXSocketManager : NSObject

+ (instancetype)share;
- (void)connect;
- (void)disConnect;
- (void)sendMsg:(NSString *)msg;

@end
