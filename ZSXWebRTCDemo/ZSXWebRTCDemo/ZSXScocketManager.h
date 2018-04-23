//
//  ZSXScocketManager.h
//  ZSXWebRTCDemo
//
//  Created by 邹时新 on 2018/4/21.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ZSXScocketManager;
@protocol ZSXScocketManagerDelegate <NSObject>

- (void)scocketManager:(ZSXScocketManager *)manager didReadData:(NSData*)data;


@end

@interface ZSXScocketManager : NSObject

+ (instancetype)share;
- (void)connect;
- (void)disConnect;
- (void)sendMsg:(NSString *)msg;
- (void)sendData:(NSData *)data;

@property (nonatomic,weak)id <ZSXScocketManagerDelegate>delegate;


@end
