//
// ZAAppPushConstants.m
// ZallDataSDK
//
// Created by guo on 2021/1/18.
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

#import "ZAAppPushConstants.h"

//AppPush Notification related
NSString * const kZAEventNameNotificationClick = @"$AppPushClick";
NSString * const kZAEventPropertyNotificationTitle = @"$app_push_msg_title";
NSString * const kZAEventPropertyNotificationContent = @"$app_push_msg_content";
NSString * const kZAEventPropertyNotificationServiceName = @"$app_push_service_name";
NSString * const kZAEventPropertyNotificationChannel = @"$app_push_channel";
NSString * const kZAEventPropertyNotificationServiceNameLocal = @"Local";
NSString * const kZAEventPropertyNotificationServiceNameJPUSH = @"JPush";
NSString * const kZAEventPropertyNotificationServiceNameGeTui = @"GeTui";
NSString * const kZAEventPropertyNotificationChannelApple = @"Apple";

//identifier for third part push service
NSString * const kZAPushServiceKeyJPUSH = @"_j_business";
NSString * const kZAPushServiceKeyGeTui = @"_ge_";
NSString * const kZAPushServiceKeySF = @"sf_data";

//APNS related key
NSString * const kZAPushAppleUserInfoKeyAps = @"aps";
NSString * const kZAPushAppleUserInfoKeyAlert = @"alert";
NSString * const kZAPushAppleUserInfoKeyTitle = @"title";
NSString * const kZAPushAppleUserInfoKeyBody = @"body";

//sf_data related properties
NSString * const kSFMessageTitle = @"$sf_msg_title";
NSString * const kSFPlanStrategyID = @"$sf_plan_strategy_id";
NSString * const kSFChannelCategory = @"$sf_channel_category";
NSString * const kSFAudienceID = @"$sf_audience_id";
NSString * const kSFChannelID = @"$sf_channel_id";
NSString * const kSFLinkUrl = @"$sf_link_url";
NSString * const kSFPlanType = @"$sf_plan_type";
NSString * const kSFChannelServiceName = @"$sf_channel_service_name";
NSString * const kSFMessageID = @"$sf_msg_id";
NSString * const kSFPlanID = @"$sf_plan_id";
NSString * const kSFStrategyUnitID = @"$sf_strategy_unit_id";
NSString * const kSFEnterPlanTime = @"$sf_enter_plan_time";
NSString * const kSFMessageContent = @"$sf_msg_content";
