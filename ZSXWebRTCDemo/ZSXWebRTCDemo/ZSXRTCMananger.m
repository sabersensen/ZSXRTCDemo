//
//  ZSXRTCMananger.m
//  ZSXWebRTCDemo
//
//  Created by 邹时新 on 2018/4/21.
//  Copyright © 2018年 zoushixin. All rights reserved.
//

#import "ZSXRTCMananger.h"
#import "ARDSignalingMessage.h"
#import "ZSXScocketManager.h"

static NSString * const kARDMediaStreamId = @"ARDAMS";
static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";
static NSString * const kARDVideoTrackKind = @"video";

@interface ZSXRTCMananger ()<RTCPeerConnectionDelegate>

@property (strong, nonatomic)   RTCPeerConnectionFactory            *peerConnectionFactory;
@property (nonatomic, strong)   RTCMediaConstraints                 *pcConstraints;
@property (nonatomic, strong)   RTCMediaConstraints                 *sdpConstraints;
@property (nonatomic, strong)   RTCMediaConstraints                 *videoConstraints;
@property (nonatomic, strong)   RTCPeerConnection                   *peerConnection;

@property (nonatomic, strong)   RTCEAGLVideoView                    *localVideoView;
@property (nonatomic, strong)   RTCEAGLVideoView                    *remoteVideoView;
@property (nonatomic, strong)   RTCVideoTrack                       *localVideoTrack;
@property (nonatomic, strong)   RTCVideoTrack                       *remoteVideoTrack;

@property (nonatomic, strong)   RTCAudioTrack                       *localAudioTrack;

@property (strong, nonatomic)   NSMutableArray                     *ICEServers;

@property (nonatomic,strong)    RTCMediaStream                     *localStream;


@end

@implementation ZSXRTCMananger

+ (instancetype)share{
    static dispatch_once_t onceToken;
    static ZSXRTCMananger *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

#pragma mark Private Methods

- (void)initRTC{
    
    RTCInitializeSSL();
    [self createPeerConnection];
    [self addTrackToLocalSteam];
//    [self.peerConnection addStream:self.localStream];
    [self createOffer];
}

- (void)getMsgData:(NSData *)data{

    NSDictionary *dicJson=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if ([[dicJson objectForKey:@"eventName"] isEqualToString:@"__sendMsg"]){
        NSDictionary *dataDic = [dicJson objectForKey:@"data"];
        if ([[dataDic objectForKey:@"type"] isEqualToString:@"offer"]) {
            RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:dataDic[@"sdp"]];
            __weak ZSXRTCMananger *weakSelf = self;
            [_peerConnection setRemoteDescription:remoteSdp
                                completionHandler:^(NSError *error) {
                                    ZSXRTCMananger *strongSelf = weakSelf;
                                    [strongSelf peerConnection:strongSelf.peerConnection
                             didSetSessionDescriptionWithError:error];
                                }];
            return;
        }
        if ([[dataDic objectForKey:@"type"] isEqualToString:@"answer"]) {
            RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:dataDic[@"sdp"]];
            __weak ZSXRTCMananger *weakSelf = self;
            [_peerConnection setRemoteDescription:remoteSdp
                                completionHandler:^(NSError *error) {
                                    ZSXRTCMananger *strongSelf = weakSelf;
                                    [strongSelf peerConnection:strongSelf.peerConnection
                             didSetSessionDescriptionWithError:error];
                                }];
            return;
        }
        if ([[dataDic objectForKey:@"type"] isEqualToString:@"candidate"]) {
            return;
        }
    }
}

/**
 创建点对点连接
 */
- (void)createPeerConnection{
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    config.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
    self.peerConnection = [self.peerConnectionFactory peerConnectionWithConfiguration:config constraints:self.pcConstraints delegate:self];
}

/**
 添加视频和音频轨道到本地流
 */
- (void)addTrackToLocalSteam{
    // 添加音轨
//    [self.localStream addAudioTrack:[self.peerConnectionFactory audioTrackWithTrackId:kARDAudioTrackId]];
    [self.peerConnection addTrack:[self.peerConnectionFactory audioTrackWithTrackId:kARDAudioTrackId] streamIds:@[ kARDMediaStreamId]];

    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [deviceArray lastObject];
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
        NSLog(@"相机访问受限");
    else
    {
        if (device)
        {
            RTCVideoSource *videoSource = [self.peerConnectionFactory videoSource];
            RTCCameraVideoCapturer *video = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
            //添加视频轨迹
//            [self.localStream addVideoTrack:[self.peerConnectionFactory videoTrackWithSource:videoSource trackId:kARDVideoTrackId]];
            [self.peerConnection addTrack:[self.peerConnectionFactory videoTrackWithSource:videoSource trackId:kARDVideoTrackId] streamIds:@[ kARDMediaStreamId]];

            [self.delegate RTCManager:self didCreateLocalCapturer:video];
            RTCVideoTrack *track = (RTCVideoTrack *)([self videoTransceiver].receiver.track);
            [self.delegate RTCManager:self didReceiveRemoteVideoTrack:track];
        }
        else
            NSLog(@"该设备不能打开摄像头");
    }
}

- (RTCRtpTransceiver *)videoTransceiver {
    for (RTCRtpTransceiver *transceiver in _peerConnection.transceivers) {
        if (transceiver.mediaType == RTCRtpMediaTypeVideo) {
            return transceiver;
        }
    }
    return nil;
}


/**
 创建一个offer信令
 */
- (void)createOffer{
    __weak ZSXRTCMananger *weakSelf = self;
    [self.peerConnection offerForConstraints:self.sdpConstraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        ZSXRTCMananger *strongSelf = weakSelf;
        [strongSelf peerConnection:strongSelf.peerConnection didCreateSessionDescription:sdp error:error];
    }];
}

- (void)sendSignalingMessage:(ARDSignalingMessage *)message {
    NSData *data = [message JSONData];
    [[ZSXScocketManager share] sendData:data];
}
#pragma mark -

/**
 对sdp做对应处理 必须在主线程中执行

 @param peerConnection 点对点控制器
 @param sdp sdp
 @param error 错误内容
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            return;
        }
        __weak ZSXRTCMananger *weakSelf = self;
        //为peerConnection设置localDescription，并发送信令给对方
        [_peerConnection setLocalDescription:sdp
                           completionHandler:^(NSError *error) {
                               ZSXRTCMananger *strongSelf = weakSelf;
                               [strongSelf peerConnection:strongSelf.peerConnection didSetSessionDescriptionWithError:error];
                           }];
        ARDSessionDescriptionMessage *message =
        [[ARDSessionDescriptionMessage alloc] initWithDescription:sdp];
        [self sendSignalingMessage:message];
//        [self setMaxBitrateForPeerConnectionVideoSender];
    });
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            return;
        }
        // If we're answering and we've just set the remote offer we need to create
        // an answer and set the local description.
        if (!self.peerConnection.localDescription) {
            RTCMediaConstraints *constraints = self.sdpConstraints;
            __weak ZSXRTCMananger *weakSelf = self;
            [_peerConnection answerForConstraints:constraints
                                completionHandler:^(RTCSessionDescription *sdp,
                                                    NSError *error) {
                                    ZSXRTCMananger *strongSelf = weakSelf;
                                    [strongSelf peerConnection:strongSelf.peerConnection
                                   didCreateSessionDescription:sdp
                                                         error:error];
                                }];
        }
    });
}



#pragma mark - RTCPeerConnectionDelegate

/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged{
    NSLog(@"didChangeSignalingState");
    switch (stateChanged) {
        case RTCSignalingStateStable:
        {
            NSLog(@"stateChanged = RTCSignalingStable");
        }
            break;
        case RTCSignalingStateClosed:
        {
            NSLog(@"stateChanged = RTCSignalingClosed");
        }
            break;
        case RTCSignalingStateHaveLocalOffer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveLocalOffer");
        }
            break;
        case RTCSignalingStateHaveRemoteOffer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveRemoteOffer");
        }
            break;
        case RTCSignalingStateHaveRemotePrAnswer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveRemotePrAnswer");
        }
            break;
        case RTCSignalingStateHaveLocalPrAnswer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveLocalPrAnswer");
        }
            break;
    }
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream{
    NSLog(@"didAddStream");
    NSLog(@"Received %lu video tracks and %lu audio tracks",
          (unsigned long)stream.videoTracks.count,
          (unsigned long)stream.audioTracks.count);
    if ([stream.videoTracks count]) {
        self.remoteVideoTrack = nil;
        [self.remoteVideoView renderFrame:nil];
        self.remoteVideoTrack = stream.videoTracks[0];
        [self.remoteVideoTrack addRenderer:self.remoteVideoView];
    }

}

/** Called when a remote peer closes a stream.
 *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream{
    NSLog(@"didRemoveStream");

}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection{
    NSLog(@"peerConnectionShouldNegotiate");

}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState{
    NSLog(@"didChangeIceConnectionState");
    switch (newState) {
        case RTCIceConnectionStateNew:
        {
            NSLog(@"newState = RTCICEConnectionNew");
        }
            break;
        case RTCIceConnectionStateChecking:
        {
            NSLog(@"newState = RTCICEConnectionChecking");
        }
            break;
        case RTCIceConnectionStateConnected:
        {
            NSLog(@"newState = RTCICEConnectionConnected");//15:56:56.698 15:56:57.570
        }
            break;
        case RTCIceConnectionStateCompleted:
        {
            NSLog(@"newState = RTCICEConnectionCompleted");//5:56:57.573
        }
            break;
        case RTCIceConnectionStateFailed:
        {
            NSLog(@"newState = RTCICEConnectionFailed");
        }
            break;
        case RTCIceConnectionStateDisconnected:
        {
            NSLog(@"newState = RTCICEConnectionDisconnected");
        }
            break;
        case RTCIceConnectionStateClosed:
        {
            NSLog(@"newState = RTCICEConnectionClosed");
        }
            break;
    }
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState{
    NSLog(@"didChangeIceGatheringState");
    switch (newState) {
        case RTCIceGatheringStateNew:
        {
            NSLog(@"newState = RTCICEGatheringNew");
        }
            break;
        case RTCIceGatheringStateGathering:
        {
            NSLog(@"newState = RTCICEGatheringGathering");
        }
            break;
        case RTCIceGatheringStateComplete:
        {
            NSLog(@"newState = RTCICEGatheringComplete");
        }
            break;
    }
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate{
    NSLog(@"didGenerateIceCandidate");
    dispatch_async(dispatch_get_main_queue(), ^{
        ARDICECandidateMessage *message =
        [[ARDICECandidateMessage alloc] initWithCandidate:candidate];
        [self sendSignalingMessage:message];
    });
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates{
    NSLog(@"didRemoveIceCandidates");
    dispatch_async(dispatch_get_main_queue(), ^{
        ARDICECandidateRemovalMessage *message =
        [[ARDICECandidateRemovalMessage alloc]
         initWithRemovedCandidates:candidates];
        [self sendSignalingMessage:message];
    });
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel{
    NSLog(@"didOpenDataChannel");
}


#pragma mark - Getter

- (RTCPeerConnectionFactory *)peerConnectionFactory{
    if (!_peerConnectionFactory) {
        _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    }
    return _peerConnectionFactory;
}

- (RTCMediaConstraints *)pcConstraints{
    if (!_pcConstraints) {
        NSDictionary *mandatoryConstraints = @{@"OfferToReceiveAudio":@"true",@"OfferToReceiveVideo":@"true"};
        NSDictionary *optionalConstraints = @{@"DtlsSrtpKeyAgreement" :@"false"};
        _pcConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:optionalConstraints];
    }
    return _pcConstraints;
}

- (RTCMediaConstraints *)sdpConstraints{
    if (!_sdpConstraints) {
        NSDictionary *sdpMandatoryConstraints = @{@"OfferToReceiveAudio":@"true",@"OfferToReceiveVideo":@"true"};
        _sdpConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:sdpMandatoryConstraints optionalConstraints:nil];
    }
    return _sdpConstraints;
}

- (RTCMediaConstraints *)videoConstraints{
    if (!_videoConstraints) {
        _videoConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
    }
    return _videoConstraints;
}

- (NSMutableArray *)ICEServers{
    if (!_ICEServers) {
        _ICEServers = [[NSMutableArray alloc] init];
    }
    return _ICEServers;
}

- (RTCMediaStream *)localStream{
    if (!_localStream) {
        _localStream = [self.peerConnectionFactory mediaStreamWithStreamId:kARDMediaStreamId];
    }
    return _localStream;
}




@end
