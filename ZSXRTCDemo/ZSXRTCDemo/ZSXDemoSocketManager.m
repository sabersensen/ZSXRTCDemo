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

static  NSString * Khost = @"10.0.3.220";
static const uint16_t Kport = 6969;
static  NSString * KroomName = @"zsx";


@interface ZSXDemoSocketManager()<GCDAsyncSocketDelegate,RTCVideoCapturerDelegate,RTCPeerConnectionDelegate>
{
    GCDAsyncSocket *gcdSocket;
    RTCPeerConnectionFactory *_factory; //点对点工厂
    NSString *_myId;
    RTCMediaStream *_localStream;
}

/**
 ip
 */
@property (nonatomic,strong)NSMutableArray *connectionIdArray;
@property (nonatomic,strong)NSMutableDictionary *connectionDic;
@property (nonatomic,strong)NSMutableArray<RTCIceServer *> *ICEServers;
@property (nonatomic,strong)RTCPeerConnection *peerConnection;
@property (nonatomic,strong)RTCVideoTrack *_localvideoTrack;
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
//    BOOL isConnectSuccess = [gcdSocket acceptOnPort:Kport error:nil];
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
    NSDictionary *dic = @{@"eventName": @"__sendMsg", @"content": msg};
    //得到json的data
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
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
    if ([eventName isEqualToString:@"_peers"])
    {
        //得到data
        NSDictionary *dataDic = dic[@"data"];
        //得到所有的连接
        NSArray *connections = dataDic[@"connections"];
//        [self.connectionIdArray addObjectsFromArray:connections];
        //拿到给自己分配的ID
        _myId = dataDic[@"you"];
        if (!_factory) {
            RTCInitializeSSL();
            RTCDefaultVideoDecoderFactory *decoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];
            RTCDefaultVideoEncoderFactory *encoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];
            ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
            encoderFactory.preferredCodec = [settingsModel currentVideoCodecSettingFromStore];
            _factory = [[RTCPeerConnectionFactory alloc] init];
        }
        if (!_localStream) {
            [self createLocalStream];
        }
//        //创建连接
//        [self createPeerConnections];
//        // 添加
//        [self addStreams];
//
//        [self createOffers];
        [self createLocalPeerConnections];
        
        [self createLocalOffer];

    }
    [self pullTheMsg];
}

- (void)createLocalPeerConnections{
    RTCIceServer *service = [[RTCIceServer alloc] initWithURLStrings:self.connectionIdArray];
//    [self.ICEServers addObject:service];
    //用工厂来创建连接
    //    RTCPeerConnection *connection = [_factory peerConnectionWithICEServers:ICEServers constraints:[self peerConnectionConstraints] delegate:self];
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    
    config.iceServers = self.ICEServers;
//    config.sdpSemantics = RTCSdpSemanticsDefault;
    self.peerConnection = [_factory peerConnectionWithConfiguration:config constraints:constraints delegate:self];
    [self createMediaSenders];
};

- (void)createLocalOffer{
    
    [self.peerConnection offerForConstraints:[self defaultOfferConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        
    }];

}

- (void)createMediaSenders {
    RTCVideoTrack *track = (RTCVideoTrack *)([self videoTransceiver].receiver.track);
    [_delegate socketManager:self didReceiveRemoteVideoTrack:track];
}

- (RTCRtpTransceiver *)videoTransceiver {
    for (RTCRtpTransceiver *transceiver in _peerConnection.transceivers) {
        if (transceiver.mediaType == RTCRtpMediaTypeVideo) {
            return transceiver;
        }
    }
    return nil;
}

- (RTCMediaConstraints *)defaultMediaAudioConstraints {
    NSDictionary *mandatoryConstraints = @{};
    RTCMediaConstraints *constraints =
    [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                          optionalConstraints:nil];
    return constraints;
}


- (RTCMediaConstraints *)defaultOfferConstraints {
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio" : @"true",
                                           @"OfferToReceiveVideo" : @"true"
                                           };
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
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
    //添加音频轨迹
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
           
            if ([_delegate respondsToSelector:@selector(socketManager:didCreateLocalCapturer:)]) {
                [_delegate socketManager:self didCreateLocalCapturer:video];
            }

            //添加视频轨迹
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


/**
 创建点对点
 */
- (void)createPeerConnections{
    
    [_connectionIdArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //根据连接ID去初始化 RTCPeerConnection 连接对象
        RTCPeerConnection *connection = [self createPeerConnection:obj];
        //设置这个ID对应的 RTCPeerConnection对象
        [self.connectionDic setObject:connection forKey:obj];
    }];
}


/**
 给对方 添加本地流
 */
- (void)addStreams{
    [_connectionDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, RTCPeerConnection *obj, BOOL * _Nonnull stop) {
        if (!_localStream)
        {
            [self createLocalStream];
        }
        [obj addStream:_localStream];
    }];
}


/**
 创建房间
 */
- (void)createOffers{
    //给每一个点对点连接，都去创建offer
    [_connectionDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, RTCPeerConnection *obj, BOOL * _Nonnull stop) {
//        _currentId = key;
//        _role = RoleCaller;
//        [obj createOfferWithDelegate:self constraints:[self offerOranswerConstraint]];
    }];
}


/**
 创建点对点

 @param connectionId 用户id 暂且用ip作为id
 @return RTCPeerConnection
 */
- (RTCPeerConnection *)createPeerConnection:(NSString *)connectionId
{
    //如果点对点工厂为空
    if (!_factory)
    {
        //先初始化工厂
        RTCInitializeSSL();
        _factory = [[RTCPeerConnectionFactory alloc] init];
    }
    
    
    RTCIceServer *service = [[RTCIceServer alloc] initWithURLStrings:self.connectionIdArray];
    [self.ICEServers addObject:service];
    //用工厂来创建连接
//    RTCPeerConnection *connection = [_factory peerConnectionWithICEServers:ICEServers constraints:[self peerConnectionConstraints] delegate:self];
    RTCMediaConstraints *constraints = [self defaultPeerConnectionConstraints];
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    
    config.iceServers = self.ICEServers;
    config.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
    RTCPeerConnection *connection = [_factory peerConnectionWithConfiguration:config constraints:constraints delegate:self];
    return connection;
}

- (void)capturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame{
    
}

#pragma mark - RTCPeerConnectionDelegate
// Callbacks for this delegate occur on non-main thread and need to be
// dispatched back to main queue as needed.

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged {
    RTCLog(@"Signaling state changed: %ld", (long)stateChanged);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream {
    RTCLog(@"Stream with %lu video tracks and %lu audio tracks was added.",
           (unsigned long)stream.videoTracks.count,
           (unsigned long)stream.audioTracks.count);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didStartReceivingOnTransceiver:(RTCRtpTransceiver *)transceiver {
    RTCMediaStreamTrack *track = transceiver.receiver.track;
    RTCLog(@"Now receiving %@ on track %@.", track.kind, track.trackId);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream {
    RTCLog(@"Stream was removed.");
}

- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
    RTCLog(@"WARNING: Renegotiation needed but unimplemented.");
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState {
    RTCLog(@"ICE state changed: %ld", (long)newState);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [_delegate appClient:self didChangeConnectionState:newState];
//    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState {
    RTCLog(@"ICE gathering state changed: %ld", (long)newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        ARDICECandidateMessage *message =
//        [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
//        [self sendSignalingMessage:message];
//    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        ARDICECandidateRemovalMessage *message =
//        [[ARDICECandidateRemovalMessage alloc]
//         initWithRemovedCandidates:candidates];
//        [self sendSignalingMessage:message];
//    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel {
}


#pragma mark - Getter and Setter

- (NSMutableArray *)connectionIdArray{
    if (!_connectionIdArray) {
        _connectionIdArray = [NSMutableArray new];
    }
    return _connectionIdArray;
}

- (NSMutableDictionary *)connectionDic{
    if (!_connectionDic) {
        _connectionDic = [NSMutableDictionary dictionary];
    }
    return _connectionDic;
}

- (NSMutableArray *)ICEServers{
    if (!_ICEServers) {
        _ICEServers = [NSMutableArray array];
    }
    return _ICEServers;
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    NSDictionary *mandatoryConstraints = @{@"OfferToReceiveAudio":@true,@"OfferToReceiveVideo":@true};
    NSDictionary *optionalConstraints = @{ @"DtlsSrtpKeyAgreement":@false };
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:optionalConstraints];
    
    return constraints;
}
@end
