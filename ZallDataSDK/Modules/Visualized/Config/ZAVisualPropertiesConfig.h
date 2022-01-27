//
// ZAVisualPropertiesConfig.h
// ZallDataSDK
//
// Created by guo on 2021/1/6.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZAConstantsEnum.h"

/**
 * @abstract
 * 属性类型
 *
 * @discussion
 * 自定义属性类型
 *   ZAVisualPropertyTypeString - 字符型
 *   ZAVisualPropertyTypeNumber - 数值型
 */
typedef NS_ENUM(NSInteger, ZAVisualPropertyType) {
    ZAVisualPropertyTypeString,
    ZAVisualPropertyTypeNumber
};

NS_ASSUME_NONNULL_BEGIN

///  view 标识，包含页面名称、路径等
@interface ZAViewIdentifier : NSObject<NSCoding>

/// 元素路径
@property (nonatomic, copy) NSString *elementPath;

/// 元素所在页面
@property (nonatomic, copy) NSString *screenName;

/// 元素位置
@property (nonatomic, copy) NSString *elementPosition;

/// 元素内容
@property (nonatomic, copy) NSString *elementContent;

/*
 当前同类页面序号
 -1：同级只存在一个同类页面，不需要用比较 pageIndex
 >=0：同级同类页面序号序号
 */
@property (nonatomic, assign) NSInteger pageIndex;

- (instancetype)initWithDictionary:(NSDictionary *)dic;

- (instancetype)initWithView:(UIView *)view;

- (BOOL)isEqualToViewIdentify:(ZAViewIdentifier *)object;

@end


/// 属性绑定的事件配置
@interface ZAVisualPropertiesEventConfig : ZAViewIdentifier<NSCoding>

/// 是否限制元素位置
@property (nonatomic, assign, getter=isLimitPosition) BOOL limitPosition;

/// 是否限制元素内容
@property (nonatomic, assign, getter=isLimitContent) BOOL limitContent;

/// 是否为 H5 事件
@property (nonatomic, assign, getter=isH5) BOOL h5;

/// 当前事件配置，是否命中元素
- (BOOL)isMatchVisualEventWithViewIdentify:(ZAViewIdentifier *)viewIdentify;
@end

/// 属性绑定的属性配置
@interface ZAVisualPropertiesPropertyConfig : ZAViewIdentifier<NSCoding>

/// 属性名
@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign) ZAVisualPropertyType type;

// 属性正则表达式
@property (nonatomic, copy) NSString *regular;

/// 是否限制元素位置
@property (nonatomic, assign, getter=isLimitPosition) BOOL limitPosition;

/// 是否为 H5 属性
@property (nonatomic, assign, getter=isH5) BOOL h5;

/// webview 的元素路径，App 内嵌 H5 属性配置才包含
@property (nonatomic, copy) NSString *webViewElementPath;

/* 本地扩展，用于元素匹配 */
/// 点击事件所在元素位置，点击元素传值
@property (nonatomic, copy) NSString *clickElementPosition;

/// 当前属性配置，是否命中元素
/// @param viewIdentify 元素节点
/// @return 是否命中
- (BOOL)isMatchVisualPropertiesWithViewIdentify:(ZAViewIdentifier *)viewIdentify;
@end

/// 属性绑定配置信息
@interface ZAVisualPropertiesConfig : NSObject<NSCoding>

/// 事件类型，目前只支持 AppClick
@property (nonatomic, assign) ZAAutoTrackEventType eventType;

/// 定义的事件名称
@property (nonatomic, copy) NSString *eventName;

/// 事件配置
@property (nonatomic, strong) ZAVisualPropertiesEventConfig *event;

/// 属性配置
@property (nonatomic, strong) NSArray<ZAVisualPropertiesPropertyConfig *> *properties;

/// web 属性配置，原始配置 json
@property (nonatomic, strong) NSArray<NSDictionary *> *webProperties;
@end


@interface ZAVisualPropertiesResponse : NSObject<NSCoding>

@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *project;
@property (nonatomic, copy) NSString *appId;

// 系统
@property (nonatomic, copy) NSString *os;
@property (nonatomic, strong) NSArray<ZAVisualPropertiesConfig *> *events;

/// 原始配置 json 数据
@property (nonatomic, copy) NSDictionary *originalResponse;

- (instancetype)initWithDictionary:(NSDictionary *)responseDic;
@end

NS_ASSUME_NONNULL_END
