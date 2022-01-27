//
//  ZallDataSDKTests.m
//  ZallDataSDKTests
//
//  Created by guo on 2019/3/12.
//  Copyright © 2015-2020 Zall Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "ZAConfigOptions.h"
#import "ZallDataSDK.h"

#import "ZADatabase.h"

@interface ZallDataSDKTests : XCTestCase
@property (nonatomic, weak) ZallDataSDK *zallAnalytics;
@end

@interface ZallDataSDK()
@property (atomic, strong) ZADatabase *messageQueue;
@end

@implementation ZallDataSDKTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.zallAnalytics = [ZallDataSDK sharedInstance];
    if (!self.zallAnalytics) {
        ZAConfigOptions *options =[ZAConfigOptions configWithServerURL:@"" launchOptions:nil];
        [ZallDataSDK completeConfigOption:options];
        self.zallAnalytics = [ZallDataSDK sharedInstance];
    }
}

- (void)tearDown {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"
    [self.zallAnalytics trackEventCallback:nil];
#pragma clang diagnostic pop
    self.zallAnalytics = nil;
}

#pragma mark - fix bug
/**
 不支持多线程初始化，由 v1.11.5 修改支持 $AppStart 事件公共属性引入，v1.11.7 新增子线程初始化
 
 在使用异步线程初始化 SDK 时，会导致 application:didFinishLaunchingWithOptions: 方法运行结束后才初始化 SDK
 由于 SDK 中，通过监听 UIApplicationDidFinishLaunchingNotification 触发 $AppStart 事件
 */
- (void)testMultiThreadInitializedSDK {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ZAConfigOptions *options = [ZAConfigOptions configWithServerURL:@"" launchOptions:nil];
        // 捕获 NSInternalInconsistencyException 异常，是由 NSAssert 抛出的异常
        XCTAssertThrowsSpecificNamed([ZallDataSDK completeConfigOption:options], NSException, NSInternalInconsistencyException, @"");

        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

/**
 多次调用初始化方法会生成多个实例，不是一个单例对象 修复
 */
- (void)testMultipleCallOldInitializeMethod {
    NSUInteger hash = self.zallAnalytics.hash;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    [ZallDataSDK sharedInstanceWithServerURL:@"" andDebugMode:ZallAnalyticsDebugOff];
    XCTAssertEqual(hash, [ZallDataSDK sharedInstance].hash);

//    [ZallDataSDK sharedInstanceWithServerURL:@"" andLaunchOptions:nil];
    XCTAssertEqual(hash, [ZallDataSDK sharedInstance].hash);

//    [ZallDataSDK sharedInstanceWithServerURL:@"" andLaunchOptions:nil andDebugMode:ZallAnalyticsDebugOff];
    XCTAssertEqual(hash, [ZallDataSDK sharedInstance].hash);
#pragma clang diagnostic pop
}

// 调用 Profile 相关的方法时，事件名称为 nil，不调用 callback
- (void)testProfileEventWithoutCallback {
    __block BOOL isTrackEventCallbackExecuted = NO;
    [[ZallDataSDK sharedInstance] trackEventCallback:^BOOL(NSString * _Nonnull eventName, NSMutableDictionary<NSString *,id> * _Nonnull properties) {
        isTrackEventCallbackExecuted = YES;
        return YES;
    }];
    [[ZallDataSDK sharedInstance] set:@"avatar_url" to:@"http://www.zalldata.cn"];
    sleep(0.5);
    XCTAssertFalse(isTrackEventCallbackExecuted);
}

#pragma mark - event
//测试 itemSet 接口，是否成功
- (void)testItemSet {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
//    
//    dispatch_queue_t queue = dispatch_queue_create("zallData-Test", DISPATCH_QUEUE_SERIAL);
//    dispatch_async(queue, ^{
//        
//        NSInteger lastCount = [ZallDataSDK sharedInstance].messageQueue.count;
//        [[ZallDataSDK sharedInstance] itemSetWithType:@"itemSet0517" itemId:@"itemId0517" properties:@{@"itemSet":@"acsdfgvzscd"}];
//        
//        sleep(1);
//        
//        NSInteger newCount = [ZallDataSDK sharedInstance].messageQueue.count;
//        BOOL insertSucceed = newCount == lastCount + 1;
//        XCTAssertTrue(insertSucceed);
//        
//        [expectation fulfill];
//    });
//    
//    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
//        XCTAssertNil(error);
//    }];
}

//测试 itemDelete 接口，是否成功
- (void)testItemDelete {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
//
//    dispatch_queue_t queue = dispatch_queue_create("zallData-Test", DISPATCH_QUEUE_SERIAL);
//    dispatch_async(queue, ^{
//        NSInteger lastCount = [ZallDataSDK sharedInstance].messageQueue.count;
//        [[ZallDataSDK sharedInstance] itemDeleteWithType:@"itemSet0517" itemId:@"itemId0517"];
//
//        sleep(1);
//
//        NSInteger newCount = [ZallDataSDK sharedInstance].messageQueue.count;
//        BOOL insertSucceed = newCount == lastCount + 1;
//        XCTAssertTrue(insertSucceed);
//
//        [expectation fulfill];
//    });
//
//    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
//        XCTAssertNil(error);
//    }];
}

#pragma mark - trackTimer
///测试是否开启事件计时
- (void)testShouldTrackTimerStart {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("zallData-Test", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        
        [[ZallDataSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
            if ([eventName isEqualToString:@"timerEvent"]) {
                
                NSDictionary *callBackProperties = properties;
                BOOL isContainsDuration = [callBackProperties.allKeys containsObject:@"event_duration"];
                XCTAssertTrue(isContainsDuration);
                
                [expectation fulfill];
            }
            return YES;
        }];
        
        [[ZallDataSDK sharedInstance] trackTimerStart:@"timerEvent"];
        sleep(1);
        [[ZallDataSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
         XCTAssertNil(error);
    }];
}

/// 测试事件计时暂停
- (void)testTrackTimerPause {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    
    dispatch_queue_t queue = dispatch_queue_create("zallData-Test", DISPATCH_QUEUE_SERIAL);

    [[ZallDataSDK sharedInstance] trackTimerStart:@"timerEvent"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerPause:@"timerEvent"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    });
    [[ZallDataSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            XCTAssertEqualWithAccuracy([properties[@"event_duration"] floatValue], 1.5, 0.1);

            [expectation fulfill];
        }
        return NO;
    }];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

/// 测试事件计时暂停后恢复
- (void)testTrackTimerResume {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];

    dispatch_queue_t queue = dispatch_queue_create("zallData-Test", DISPATCH_QUEUE_SERIAL);

    [[ZallDataSDK sharedInstance] trackTimerStart:@"timerEvent"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerPause:@"timerEvent"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerResume:@"timerEvent"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerEnd:@"timerEvent"];
    });
    [[ZallDataSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            XCTAssertEqualWithAccuracy([properties[@"event_duration"] floatValue], 2.5, 0.1);
        }
        [expectation fulfill];
        return NO;
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

//测试动态开启 ZallAnalyticsEventTypeAppEnd，event_duration 是否从启动开始计算
- (void)testCheckAppEndEventDuration {
    XCTestExpectation *expect = [self expectationWithDescription:@"异步超时timeout!"];
    
    double durationSecond = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(durationSecond * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [[ZallDataSDK sharedInstance] trackEventCallback:^BOOL(NSString * _Nonnull eventName, NSMutableDictionary<NSString *,id> * _Nonnull properties) {
            
            if ([eventName isEqualToString:@"$AppEnd"]) {
                double duration = [properties[@"event_duration"] doubleValue];
                
                XCTAssertGreaterThan(duration, durationSecond);
                [expect fulfill];
            }
            return YES;
        }];
        [[ZallDataSDK sharedInstance] track:@"$AppEnd"];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)testCrossTrackTimer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步操作timeout"];
    __block NSString *timer1;
    __block NSString *timer2;
    dispatch_queue_t queue = dispatch_queue_create("zallData-Test", DISPATCH_QUEUE_SERIAL);
    timer1 = [[ZallDataSDK sharedInstance] trackTimerStart:@"testTimer"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), queue, ^{
        timer2 = [[ZallDataSDK sharedInstance] trackTimerStart:@"testTimer"];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerPause:timer1];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerPause:timer2];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerResume:timer1];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerResume:timer2];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerEnd:timer1];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(14 * NSEC_PER_SEC)), queue, ^{
        [[ZallDataSDK sharedInstance] trackTimerEnd:timer2];
    });
 
    [[ZallDataSDK sharedInstance] trackEventCallback:^BOOL (NSString *_Nonnull eventName, NSMutableDictionary<NSString *, id> *_Nonnull properties) {
        if ([eventName isEqualToString:@"timerEvent"]) {
            XCTAssertEqualWithAccuracy([properties[@"event_duration"] floatValue], 8, 0.1);
        }
        [expectation fulfill];
        return NO;
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

@end
