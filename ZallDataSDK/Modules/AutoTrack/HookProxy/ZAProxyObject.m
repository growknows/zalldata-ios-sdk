//
// ZADelegateProxyObject.m
// ZallDataSDK
//
// Created by guo on 2021/11/12.
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

#import "ZAProxyObject.h"
#import <objc/message.h>

NSString * const kZADelegateClassZallSuffix = @"_CN.ZALLDATA";
NSString * const kZADelegateClassKVOPrefix = @"KVONotifying_";

@implementation ZAProxyObject

- (instancetype)initWithDelegate:(id)delegate proxy:(id)proxy {
    self = [super init];
    if (self) {
        _delegateProxy = proxy;

        _selectors = [NSMutableSet set];
        _delegateClass = [delegate class];

        Class cla = object_getClass(delegate);
        NSString *name = NSStringFromClass(cla);

        if ([name containsString:kZADelegateClassKVOPrefix]) {
            _delegateISA = class_getSuperclass(cla);
            _kvoClass = cla;
        } else if ([name containsString:kZADelegateClassZallSuffix]) {
            _delegateISA = class_getSuperclass(cla);
            _zallClassName = name;
        } else {
            _delegateISA = cla;
            _zallClassName = [NSString stringWithFormat:@"%@%@", name, kZADelegateClassZallSuffix];
        }
    }
    return self;
}

- (Class)zallClass {
    return NSClassFromString(self.zallClassName);
}

- (void)removeKVO {
    self.kvoClass = nil;
    self.zallClassName = [NSString stringWithFormat:@"%@%@", self.delegateISA, kZADelegateClassZallSuffix];
    [self.selectors removeAllObjects];
}

@end

#pragma mark - Utils

@implementation ZAProxyObject (Utils)

/// 是不是 KVO 创建的类
/// @param cls 类
+ (BOOL)isKVOClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) containsString:kZADelegateClassKVOPrefix];
}

@end

