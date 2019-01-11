//
//  ViewController.m
//  NENPingDemo
//
//  Created by minihao on 2019/1/4.
//  Copyright © 2019 minihao. All rights reserved.
//

#import "ViewController.h"
#import "NENPingManager.h"
@interface ViewController ()
@property (nonatomic, strong) NENPingManager* pingManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    NSArray *hostNameArray = @[
                               @"www.bilibili.com",
                               @"www.baidu.com",
                               @"www.youku.com",
                               @"www.hao123.com"
                               ];
    self.pingManager = [[NENPingManager alloc] init];
    [self.pingManager getFatestAddress:hostNameArray completionHandler:^(NSString *hostName, NSArray *sortedAddress) {
        NSLog(@"fastest IP: %@",hostName);
    }];
}


@end
