//
//  NENSinglePinger.m
//  NENPingDemo
//
//  Created by minihao on 2019/1/4.
//  Copyright © 2019 minihao. All rights reserved.
//

#import "NENSinglePinger.h"
#import "SimplePing.h"

@implementation NENPingItem

@end

@interface NENSinglePinger () <SimplePingDelegate>

@property (nonatomic, copy) NSString *hostName;
@property (nonatomic, strong) SimplePing *pinger;
@property (nonatomic, strong) NSTimer *sendTimer;
/// packet send time array
@property (nonatomic, strong) NSMutableArray <NSDate *>*startDateArray;
/// index of packet send time array
@property (nonatomic, assign) NSInteger dateSendIndex;
@property (nonatomic, copy) PingCallBack pingCallBack;
/// send times
@property (nonatomic, assign) NSInteger count;
/// need ping count
@property (nonatomic, assign) NSInteger needPingCount;
/// receive packets or delay perform count
@property (nonatomic, assign) NSInteger receivedOrDelayCount;

@end

@implementation NENSinglePinger

- (instancetype)initWithHostName:(NSString *)hostName count:(NSInteger)count pingCallBack:(PingCallBack)pingCallBack
{
    if (self = [super init]) {
        self.hostName = hostName;
        self.count = count;
        self.needPingCount = count;
        self.startDateArray = [NSMutableArray array];
        self.pingCallBack = pingCallBack;
        self.pinger = [[SimplePing alloc] initWithHostName:hostName];
        self.pinger.addressStyle = SimplePingAddressStyleAny;
        self.pinger.delegate = self;
        [self.pinger start];
    }
    return self;
}

+ (instancetype)startWithHostName:(NSString *)hostName count:(NSInteger)count pingCallBack:(PingCallBack)pingCallBack
{
    return [[self alloc] initWithHostName:hostName count:count pingCallBack:pingCallBack];
}

#pragma mark - Private Methods
/// stop ping service
- (void)stop
{
    NSLog(@"%@ stop",self.hostName);
    [self cleanWithStatus:NENSinglePingStatusDidFinished];
}

/// ping delay
- (void)timeOut
{
    if (self.sendTimer) {
        NSLog(@"%@ timeout",self.hostName);
        self.receivedOrDelayCount++;
        NENPingItem *pingItem = [[NENPingItem alloc] init];
        pingItem.hostName = self.hostName;
        pingItem.status = NENSinglePingStatusDidTimeOut;
        if(self.pingCallBack){
            self.pingCallBack(pingItem);
        }

        if (self.receivedOrDelayCount == self.needPingCount) {
            [self stop];
        }
    }
}

/// ping failure
- (void)fail
{
    NSLog(@"%@ fail",self.hostName);
    [self cleanWithStatus:NENSinglePingStatusDidError];
}

- (void)cleanWithStatus:(NENSinglePingStatus)status
{
    NENPingItem *pingItem = [[NENPingItem alloc] init];
    pingItem.hostName = self.hostName;
    pingItem.status = status;
    self.pingCallBack(pingItem);
    
    [self.pinger stop];
    self.pinger = nil;
    
    [self.sendTimer invalidate];
    self.sendTimer = nil;
    
    [self cancelRunLoopPerformTimeOut];
    
    if (status == NENSinglePingStatusDidFailToSendPacket) {
        [self.startDateArray removeLastObject];
    } else {
        [self.startDateArray removeAllObjects];
    }
}

- (void)sendPing
{
    if (self.count < 1) {
        return;
    }
    self.count --;
    [self.startDateArray addObject:[NSDate date]];
    [self.pinger sendPingWithData:nil];
    [self performSelector:@selector(timeOut) withObject:self afterDelay:1.0];
}

- (void)cancelRunLoopPerformTimeOut
{
    // 无法取消?
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeOut) object:nil];
}

#pragma mark - Ping Delegate
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    NSLog(@"start ping %@",self.hostName);
    [self sendPing];
    NSAssert(self.sendTimer == nil, @"timer can't be nil");
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.sendTimer forMode:NSDefaultRunLoopMode];
    
    NENPingItem *pingItem = [[NENPingItem alloc] init];
    pingItem.hostName = self.hostName;
    pingItem.status = NENSinglePingStatusDidStart;
    if(self.pingCallBack){
        self.pingCallBack(pingItem);
    }
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
{
    [self cancelRunLoopPerformTimeOut];
    NSLog(@"%@ %@",self.hostName, error.localizedDescription);
    [self fail];
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    [self cancelRunLoopPerformTimeOut];
    NSLog(@"%@ %hu send packet success",self.hostName, sequenceNumber);
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber error:(NSError *)error
{
    [self cancelRunLoopPerformTimeOut];
    NSLog(@"%@ %hu send packet failed: %@",self.hostName, sequenceNumber, error.localizedDescription);
    [self cleanWithStatus:NENSinglePingStatusDidFailToSendPacket];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet sequenceNumber:(uint16_t)sequenceNumber
{
    [self cancelRunLoopPerformTimeOut];
    double millSecondsDelay = 0;
    if (self.startDateArray.count <= self.dateSendIndex) {
        millSecondsDelay = 1.f;
    } else {
        millSecondsDelay = [[NSDate date] timeIntervalSinceDate:self.startDateArray[self.dateSendIndex]] * 1000;
    }
    self.dateSendIndex++;
    self.receivedOrDelayCount++;
    NSLog(@"%@ %hu received, size=%lu time=%.2f",self.hostName, sequenceNumber, (unsigned long)packet.length, millSecondsDelay);
    NENPingItem *pingItem = [[NENPingItem alloc] init];
    pingItem.hostName = self.hostName;
    pingItem.status = NENSinglePingStatusDidReceivePacket;
    pingItem.millSecondsDelay = millSecondsDelay;
    self.pingCallBack(pingItem);
    
    if (self.receivedOrDelayCount == self.needPingCount) {
        [self stop];
    }
    
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    [self cancelRunLoopPerformTimeOut];
}


@end
