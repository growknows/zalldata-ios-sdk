//
// ZAAppLifecycleUtilsTest.m
// ZallDataSDKTests
//
// Created by guo on 2021/11/15.
// Copyright © 2021 Zall Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <XCTest/XCTest.h>
#import "ZAAppLifecycle.h"

@interface ZAAppLifecycleUtilsTest : XCTestCase

@property (nonatomic, strong) ZAAppLifecycle *appLifecycle;

@end

@implementation ZAAppLifecycleUtilsTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.appLifecycle = [[ZAAppLifecycle alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.appLifecycle = nil;
}

- (void)testWillEnterForeground {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, ZAAppLifecycleStateInit);
}

- (void)testDidBecomeActive {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, ZAAppLifecycleStateStart);
}

- (void)testWillResignActive {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, ZAAppLifecycleStateInit);
}

- (void)testDidEnterBackground {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, ZAAppLifecycleStateEnd);
}

- (void)testWillTerminate {
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];
    XCTAssertEqual(self.appLifecycle.state, ZAAppLifecycleStateTerminate);
}

- (void)testDidFinishLaunching {
    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
        XCTAssertEqual(self.appLifecycle.state, ZAAppLifecycleStateInit);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidFinishLaunchingNotification object:nil];
        XCTAssertEqual(self.appLifecycle.state, ZAAppLifecycleStateStart);
    }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
