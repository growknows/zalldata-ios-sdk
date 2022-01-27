//
//  ZADelegateProxy.m
//  ZallDataSDK
//
//  Created by guo on 2019/6/19.
//  Copyright © 2019 ZallData. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "NSObject+HookProxy.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZAHookProtocol <NSObject>
@optional
+ (NSSet<NSString *> *)optionalSelectors;

@end

@interface ZAProxy : NSObject <ZAHookProtocol>

/// proxy delegate with selectors
/// @param delegate delegate object, such as UITableViewDelegate、UICollectionViewDelegate, etc.
/// @param selectors delegate proxy methods, such as "tableView:didSelectRowAtIndexPath:"、"collectionView:didSelectItemAtIndexPath:", etc.
+ (void)proxyDelegate:(id)delegate selectors:(NSSet<NSString *>*)selectors;


/// forward selector with arguments
/// @param target target
/// @param selector selector
+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector, ...;


/// actions for optional selectors
/// @param delegate delegate object
+ (void)resolveOptionalSelectorsForDelegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
