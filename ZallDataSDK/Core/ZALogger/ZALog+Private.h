//
// ZALog+Private.h
// ZallDataSDK
//
// Created by guo on 2020/3/27.
// Copyright © 2020 Zall Data Co., Ltd. All rights reserved.
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

#import "ZAAbstractLogger.h"

@interface ZALog (Private)

@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

+ (void)addLogger:(ZAAbstractLogger<ZALogger> *)logger;
+ (void)addLoggers:(NSArray<ZAAbstractLogger<ZALogger> *> *)loggers;
+ (void)removeLogger:(ZAAbstractLogger<ZALogger> *)logger;
+ (void)removeLoggers:(NSArray<ZAAbstractLogger<ZALogger> *> *)loggers;
+ (void)removeAllLoggers;

- (void)addLogger:(ZAAbstractLogger<ZALogger> *)logger;
- (void)addLoggers:(NSArray<ZAAbstractLogger<ZALogger> *> *)loggers;
- (void)removeLogger:(ZAAbstractLogger<ZALogger> *)logger;
- (void)removeLoggers:(NSArray<ZAAbstractLogger<ZALogger> *> *)loggers;
- (void)removeAllLoggers;

@end
