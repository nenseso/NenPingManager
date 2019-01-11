//
//  NENPingManager.m
//  NENPingDemo
//
//  Created by minihao on 2019/1/4.
//  Copyright © 2019 minihao. All rights reserved.
//

#import "NENPingManager.h"

@interface NENAddressItem ()
@property (nonatomic, copy, readwrite) NSString *hostName;
@property (nonatomic, assign, readwrite) double delayMillSeconds;
@end

@implementation NENAddressItem

- (instancetype)initWithHostName:(NSString *)hostName
{
    if (self = [super init]) {
        self.hostName = hostName;
        self.delayTimes = [NSMutableArray array];
    }
    return self;
}

- (double)delayMillSeconds
{
    if (self.delayTimes.count) {
        double allDelayTime = 0;
        for (NSNumber *delayTime in self.delayTimes) {
            allDelayTime += delayTime.doubleValue;
        }
        return allDelayTime / self.delayTimes.count;
    }
    return 1000.0;
}

@end

@interface NENPingManager ()
@property (nonatomic, strong) NSMutableArray *singlePingerArray;
@end

@implementation NENPingManager

- (void)getFatestAddress:(NSArray *)addressList completionHandler:(CompletionHandler)completionHandler
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (addressList.count == 0) {
            NSLog(@"addressList can't be empty");
            return;
        }
        NSMutableArray *singlePingerArray = [NSMutableArray array];
        self.singlePingerArray = singlePingerArray;
        NSMutableArray *needRemoveAddressArray = [NSMutableArray array];
        NSMutableArray *resultArray = [NSMutableArray array];
        NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
        for (NSString *address in addressList) {
            [resultDict setObject:[NSNull null] forKey:address];
        }
        dispatch_group_t group = dispatch_group_create();
        
        for (NSString *address in addressList) {
            dispatch_group_enter(group);
            NENSinglePinger *singlePinger = [NENSinglePinger startWithHostName:address count:3 pingCallBack:^(NENPingItem *pingitem) {
                switch (pingitem.status) {
                    case NENSinglePingStatusDidStart:
                        break;
                    case NENSinglePingStatusDidFailToSendPacket:
                    {
                        [needRemoveAddressArray addObject:pingitem.hostName];
                        break;
                    }
                    case NENSinglePingStatusDidReceivePacket:
                    {
                        NENAddressItem *item = [resultDict objectForKey:pingitem.hostName];
                        if ([item isEqual:[NSNull null]]) {
                            item = [[NENAddressItem alloc] initWithHostName:pingitem.hostName];
                        }
                        [item.delayTimes addObject:@(pingitem.millSecondsDelay)];
                        [resultDict setObject:item forKey:pingitem.hostName];
                        if (![resultArray containsObject:item]) {
                            [resultArray addObject:item];
                        }
                        break;
                    }
                    case NENSinglePingStatusDidReceiveUnexpectedPacket:
                        break;
                    case NENSinglePingStatusDidTimeOut:
                    {
                        // 超时按1s计算
                        NENAddressItem *item = [resultDict objectForKey:pingitem.hostName];
                        if ([item isEqual:[NSNull null]]) {
                            item = [[NENAddressItem alloc] initWithHostName:pingitem.hostName];
                        }
                        [item.delayTimes addObject:@(1000.0)];
                        [resultDict setObject:item forKey:pingitem.hostName];
                        if (![resultArray containsObject:item]) {
                            [resultArray addObject:item];
                        }
                        break;
                    }
                    case NENSinglePingStatusDidError:
                    {
                        [needRemoveAddressArray addObject:pingitem.hostName];
                        dispatch_group_leave(group);
                        break;
                    }
                    case NENSinglePingStatusDidFinished:
                    {
                        NSLog(@"%@ 完成",pingitem.hostName);
                        dispatch_group_leave(group);
                        break;
                    }
                    default:
                        break;
                }
            }];
            [singlePingerArray addObject:singlePinger];
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            NSLog(@"计算延迟");
            for (NENAddressItem *item in resultArray) {
                if ( (item.delayTimes.count == 0 && ![needRemoveAddressArray containsObject:item.hostName]) ||
                    item.delayMillSeconds == 0) {
                    [needRemoveAddressArray addObject:item.hostName];
                }
            }
            
            for (NSString *removeHostName in needRemoveAddressArray) {
                [resultArray filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.hostName != %@",removeHostName]];
            }
            
            if (resultArray.count == 0) {
                completionHandler(nil,nil);
                return;
            }
            
            [resultArray sortUsingComparator:^NSComparisonResult(NENAddressItem * item1, NENAddressItem * item2) {
                return item1.delayMillSeconds > item2.delayMillSeconds;
            }];
            
            NSMutableArray *array = [NSMutableArray array];
            for (NENAddressItem *item in resultArray) {
                [array addObject:item.hostName];
            }
            NENAddressItem *item = resultArray.firstObject;
            NSLog(@"最快的地址速度是: %.2f ms",item.delayMillSeconds);
            completionHandler(item.hostName, [array copy]);
        });
    }];
}

@end
