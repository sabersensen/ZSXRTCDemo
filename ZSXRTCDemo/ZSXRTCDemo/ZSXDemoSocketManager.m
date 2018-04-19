//
//  ZSXDemoSocketManager.m
//  ZSXRTCDemo
//
//  Created by 邹时新 on 2018/4/18.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import "ZSXDemoSocketManager.h"
#import "GCDAsyncSocket.h" // for TCP
#import "ARDCaptureController.h"
#import "ARDSettingsModel.h"
#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

static  NSString * Khost = @"192.168.15.31";
static const uint16_t Kport = 6969;
static  NSString * KroomName = @"zsx";


@interface ZSXDemoSocketManager()<GCDAsyncSocketDelegate,RTCVideoCapturerDelegate>
{
    GCDAsyncSocket *gcdSocket;
    RTCPeerConnectionFactory *_factory; //点对点工厂
    NSString *_myId;
    RTCMediaStream *_localStream;
}

@end

@implementation ZSXDemoSocketManager

+ (instancetype)share
{
    static dispatch_once_t onceToken;
    static ZSXDemoSocketManager *instance = nil;
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

- (void)joinRoom:(NSString *)roomName{
    //初始化加入房间的类型参数 room房间号
    NSDictionary *dic = @{@"eventName": @"__join", @"data": @{@"room": roomName}};
    
    //得到json的data
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    //发送加入房间的数据
    [gcdSocket writeData:data withTimeout:-1 tag:110];
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
    [gcdSocket writeData:data withTimeout:-1 tag:110];
    
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

/**
 {"data":{"connections":["10.0.3.81:57807"],"you":"10.0.3.220:64956"},"eventName":"__peers"}
 you 则是自己的ip地址 connections 中都是对方的ip
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
    NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"收到消息：%@",msg);
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSString *eventName = dic[@"eventName"];
    if ([eventName isEqualToString:@"__peers"])
    {
        //得到data
        NSDictionary *dataDic = dic[@"data"];
        //得到所有的连接
        NSArray *connections = dataDic[@"connections"];
        //拿到给自己分配的ID
        _myId = dataDic[@"you"];
        if (!_factory) {
            _factory = [[RTCPeerConnectionFactory alloc] init];
        }
        if (!_localStream) {
            [self createLocalStream];
        }

    }
    [self pullTheMsg];
}

//分段去获取消息的回调
//- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
//{
//
//    NSLog(@"读的回调,length:%ld,tag:%ld",partialLength,tag);
//
//}

//为上一次设置的读取数据代理续时 (如果设置超时为-1，则永远不会调用到)
//-(NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
//{
//    NSLog(@"来延时，tag:%ld,elapsed:%f,length:%ld",tag,elapsed,length);
//    return 10;
//}

- (void)createLocalStream{
    _localStream = [_factory mediaStreamWithStreamId:@"ARDAMS"];
    //音频
    RTCAudioTrack *audioTrack = [_factory audioTrackWithTrackId:@"ARDAMSa0"];
    [_localStream addAudioTrack:audioTrack];
    //视频
    
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [deviceArray lastObject];
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"相机访问受限");
        if ([_delegate respondsToSelector:@selector(socketManager:setLocalStream:userId:)])
        {
            [_delegate socketManager:self setLocalStream:nil userId:_myId];
        }
    }
    else
    {
        if (device)
        {
            RTCVideoSource *videoSource = [_factory videoSource];
            [videoSource adaptOutputFormatToWidth:1280 height:720 fps:60];
            RTCCameraVideoCapturer *video = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
            ARDSettingsModel *settingModel = [[ARDSettingsModel alloc] init];
            
            ARDCaptureController *controller = [[ARDCaptureController alloc] initWithCapturer:video settings:settingModel];
            [controller startCapture];
//            NSArray *arr = [RTCCameraVideoCapturer supportedFormatsForDevice:device];
//            [video startCaptureWithDevice:device format:format fps:fps];

            RTCVideoTrack *videoTrack = [_factory videoTrackWithSource:videoSource trackId:@"ARDAMSv0"];

            [_localStream addVideoTrack:videoTrack];
            if ([_delegate respondsToSelector:@selector(socketManager:setLocalStream:userId:)])
            {
                [_delegate socketManager:self setLocalStream:_localStream userId:_myId];
            }
        
        }
        else
        {
            NSLog(@"该设备不能打开摄像头");
            if ([_delegate respondsToSelector:@selector(socketManager:setLocalStream:userId:)])
            {
                [_delegate socketManager:self setLocalStream:nil userId:_myId];
            }
        }
    }
}

- (void)capturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame{
    
}
@end
