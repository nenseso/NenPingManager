//
//  NENSinglePinger.h
//  NENPingDemo
//
//  Created by minihao on 2019/1/4.
//  Copyright © 2019 minihao. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NENPingItem;
typedef void(^PingCallBack)(NENPingItem *pingitem);

typedef NS_ENUM(NSUInteger, NENSinglePingStatus) {
    NENSinglePingStatusDidStart,
    NENSinglePingStatusDidFailToSendPacket,
    NENSinglePingStatusDidReceivePacket,
    NENSinglePingStatusDidReceiveUnexpectedPacket,
    NENSinglePingStatusDidTimeOut,
    NENSinglePingStatusDidError,
    NENSinglePingStatusDidFinished,
};

@interface NENPingItem : NSObject
/// 主机名
@property (nonatomic, copy) NSString *hostName;
/// 单次耗时
@property (nonatomic, assign) double millSecondsDelay;
/// 当前ping状态
@property (nonatomic, assign) NENSinglePingStatus status;

@end

@interface NENSinglePinger : NSObject

+ (instancetype)startWithHostName:(NSString *)hostName count:(NSInteger)count pingCallBack:(PingCallBack)pingCallBack;

- (instancetype)initWithHostName:(NSString *)hostName count:(NSInteger)count pingCallBack:(PingCallBack)pingCallBack;

@end


