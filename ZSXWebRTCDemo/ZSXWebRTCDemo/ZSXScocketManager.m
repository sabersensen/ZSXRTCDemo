//
//  ZSXScocketManager.m
//  ZSXWebRTCDemo
//
//  Created by 邹时新 on 2018/4/21.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import "ZSXScocketManager.h"
#import "GCDAsyncSocket.h" // for TCP

static  NSString * Khost = @"192.168.3.22";
static const uint16_t Kport = 6969;
static  NSString * KroomName = @"zsx";


@interface ZSXScocketManager()<GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *gcdSocket;
}

@end

@implementation ZSXScocketManager

+ (instancetype)share
{
    static dispatch_once_t onceToken;
    static ZSXScocketManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
        [instance initSocket];
    });
    return instance;
}

- (void)initSocket
{
    gcdSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}

- (void)joinRoom:(NSString *)roomName{
    //初始化加入房间的类型参数 room房间号
    NSDictionary *dic = @{@"eventName": @"__join", @"data": @{@"room": roomName}};
    
    //得到json的data
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    //发送加入房间的数据
    [gcdSocket writeData:data withTimeout:-1 tag:110];
}

#pragma mark - 对外的一些接口

//建立连接
- (BOOL)connect
{
    BOOL isConnectSuccess = [gcdSocket connectToHost:Khost onPort:Kport error:nil];
    if (isConnectSuccess) {
        [self joinRoom:KroomName];
    }
    return isConnectSuccess;
    
}

//断开连接
- (void)disConnect
{
    [gcdSocket disconnect];
}


//发送消息
- (void)sendMsg:(NSString *)msg

{
    NSData *data  = [msg dataUsingEncoding:NSUTF8StringEncoding];
    //第二个参数，请求超时时间
    [self sendData:data];
    
}

//发送
- (void)sendData:(NSData *)data{
    NSDictionary *dicJson=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

    NSDictionary *message = @{
                              @"eventName": @"__sendMsg",
                              @"data": dicJson,
                              };
    NSData *messageJSONObject =
    [NSJSONSerialization dataWithJSONObject:message
                                    options:NSJSONWritingPrettyPrinted
                                      error:nil];
    [gcdSocket writeData:messageJSONObject withTimeout:-1 tag:110];
}

//监听最新的消息
- (void)pullTheMsg
{
    //监听读数据的代理  -1永远监听，不超时，但是只收一次消息，
    //所以每次接受到消息还得调用一次
    [gcdSocket readDataWithTimeout:-1 tag:110];
    
}

#pragma mark - GCDAsyncSocketDelegate
//连接成功调用
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"连接成功,host:%@,port:%d",host,port);
    
    [self pullTheMsg];
    
    //心跳写在这...
}

//断开连接的时候调用
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    NSLog(@"断开连接,host:%@,port:%d",sock.localHost,sock.localPort);
    
    //断线重连写在这...
    
}

//写成功的回调
- (void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"写的回调,tag:%ld",tag);
}

//收到消息的回调
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"收到消息：%@",msg);
    
    [self.delegate scocketManager:self didReadData:data];
    
    [self pullTheMsg];
}

@end
