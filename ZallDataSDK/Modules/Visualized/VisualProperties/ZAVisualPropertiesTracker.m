//
// ZAVisualPropertiesTracker.m
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

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "ZAVisualPropertiesTracker.h"
#import <UIKit/UIKit.h>
#import "ZAVisualPropertiesConfigSources.h"
#import "ZAVisualizedUtils.h"
#import "UIView+AutoTrackProperty.h"
#import "UIView+ZAElementPath.h"
#import "ZAVisualizedDebugLogTracker.h"
#import "ZAVisualizedLogger.h"
#import "ZAJavaScriptBridgeManager.h"
#import "ZAAlertViewController.h"
#import "UIView+ZAVisualProperties.h"
#import "ZAJSONUtil.h"
#import "ZALog.h"


@interface ZAVisualPropertiesTracker()

@property (atomic, strong, readwrite) ZAViewNodeTree *viewNodeTree;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) ZAVisualPropertiesConfigSources *configSources;
@property (nonatomic, strong) ZAVisualizedDebugLogTracker *debugLogTracker;
@property (nonatomic, strong) ZAAlertViewController *enableLogAlertController;
@end

@implementation ZAVisualPropertiesTracker

- (instancetype)initWithConfigSources:(ZAVisualPropertiesConfigSources *)configSources {
    self = [super init];
    if (self) {
        _configSources = configSources;
        NSString *serialQueueLabel = [NSString stringWithFormat:@"com.zalldata.ZAVisualPropertiesTracker.%p", self];
        _serialQueue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        _viewNodeTree = [[ZAViewNodeTree alloc] initWithQueue:_serialQueue];
    }
    return self;
}

#pragma mark build ViewNodeTree
- (void)didMoveToSuperviewWithView:(UIView *)view {
    /*节点更新和属性遍历，共用同一个队列
     防止触发点击事件，同时进行页面跳转，尚未遍历结束节点元素就被移除了
     */
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree didMoveToSuperviewWithView:view];
    });
}

- (void)didMoveToWindowWithView:(UIView *)view {
    /*节点更新和属性遍历，共用同一个队列
     防止触发点击事件，同时进行页面跳转，尚未遍历结束节点元素就被移除了
     */
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree didMoveToWindowWithView:view];
    });
}

- (void)didAddSubview:(UIView *)subview {
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree didAddSubview:subview];
    });
}

- (void)becomeKeyWindow:(UIWindow *)window {
    if (!window.isKeyWindow) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self.viewNodeTree becomeKeyWindow:window];
    });
}

- (void)enterRNViewController:(UIViewController *)viewController {
    [self.viewNodeTree refreshRNViewScreenNameWithViewController:viewController];
}

#pragma mark - visualProperties

#pragma mark App visualProperties
// 采集元素自定义属性
- (void)visualPropertiesWithView:(UIView *)view completionHandler:(void (^)(NSDictionary *_Nullable visualProperties))completionHandler {

    // 如果列表定义事件不限定元素位置，则只能在当前列表内元素（点击元素所在位置）添加属性。所以此时的属性元素位置，和点击元素位置必须相同
    NSString *clickPosition = [view za_property_elementPosition];
    
    
    NSInteger pageIndex = [ZAVisualizedUtils pageIndexWithView:view];
    // 单独队列执行耗时查询
    dispatch_async(self.serialQueue, ^{
        /* 添加日志信息
         在队列执行，防止快速点击导致的顺序错乱
         */
        if (self.debugLogTracker) {
            [self.debugLogTracker addTrackEventWithView:view withConfig:self.configSources.originalResponse];
        }
        
        /* 查询事件配置
         因为涉及是否限定位置，一个 view 可能被定义多个事件
         */
        ZAViewNode *viewNode = view.zalldata_viewNode;
        NSArray <ZAVisualPropertiesConfig *>*allEventConfigs = [self.configSources propertiesConfigsWithViewNode:viewNode];

        NSMutableDictionary *allEventProperties = [NSMutableDictionary dictionary];
        NSMutableArray *webPropertiesConfigs = [NSMutableArray array];
        for (ZAVisualPropertiesConfig *config in allEventConfigs) {
            if (config.webProperties.count > 0) {
                [webPropertiesConfigs addObjectsFromArray:config.webProperties];
            }

            // 查询 native 属性
            NSDictionary *properties = [self queryAllPropertiesWithPropertiesConfig:config clickPosition:clickPosition pageIndex:pageIndex];
            if (properties.count > 0) {
                [allEventProperties addEntriesFromDictionary:properties];
            }
        }

        // 不包含 H5 属性配置
        if (webPropertiesConfigs.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(allEventProperties.count > 0 ? allEventProperties : nil);
            });
            return;
        }

        // 查询多个 WebView 内所有自定义属性
        [self queryMultiWebViewPropertiesWithConfigs:webPropertiesConfigs viewNode:viewNode completionHandler:^(NSDictionary * _Nullable properties) {
            if (properties.count > 0) {
                [allEventProperties addEntriesFromDictionary:properties];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(allEventProperties.count > 0 ? allEventProperties : nil);
            });
        }];
    });
}

/// 根据配置查询元素属性信息
/// @param config 配置信息
/// @param clickPosition 点击元素位置
/// @param pageIndex 页面序号
- (nullable NSDictionary *)queryAllPropertiesWithPropertiesConfig:(ZAVisualPropertiesConfig *)config clickPosition:(NSString *)clickPosition pageIndex:(NSInteger)pageIndex {

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    
    for (ZAVisualPropertiesPropertyConfig *propertyConfig in config.properties) {
        // 合法性校验
        if (propertyConfig.regular.length == 0 || propertyConfig.name.length == 0 || propertyConfig.elementPath.length == 0) {
            NSString *logMessage = [ZAVisualizedLogger buildLoggerMessageWithTitle:@"属性配置" message:@"属性 %@ 无效", propertyConfig];
            ZALogError(@"ZAVisualPropertiesPropertyConfig error, %@", logMessage);
            continue;
        }
        
        // 事件是否限定元素位置，影响属性元素的匹配逻辑
        propertyConfig.limitPosition = config.event.limitPosition;
        
        /* 属性配置，保存点击位置
         属性配置中保存当前点击元素位置，用于属性元素筛选
         如果属性元素为当前点击 Cell 嵌套 Cell 的内嵌元素，则不需使用当前位置匹配
         路径示例如下：
         Cell 本身路径：UIView/UITableView[0]/ZACommonTableViewCell[0][-]
         Cell 嵌套普通元素路径：UIView/UITableView[0]/ZACommonTableViewCell[0][-]/UITableViewCellContentView[0]/UIButton[0]
         Cell 嵌套 Cell 路径：UIView/UITableView[1]/TableViewCollectionViewCell[0][0]/UITableViewCellContentView[0]/UICollectionView[0]/HomeOptionsCollecionCell[0][-]
         Cell 嵌套 Cell 再嵌套元素路径：UIView/UITableView[1]/TableViewCollectionViewCell[0][0]/UITableViewCellContentView[0]/UICollectionView[0]/HomeOptionsCollecionCell[0][-]/UIView[0]/UIView[0]/UIButton[0]
         
         备注: cell 内嵌 button 的点击事件，那么 cell 内嵌 其他 view，也支持这种不限定位置的约束和筛选逻辑，path 示例如下:
         UIView/UITableView[0]/ZATestTableViewCell[0][-]/UITableViewCellContentView[0]/UIStackView[0]/UIButton[1]
         UIView/UITableView[0]/ZATestTableViewCell[0][-]/UITableViewCellContentView[0]/UIStackView[0]/UILabel[0]
         */
        
        NSRange propertyRange = [propertyConfig.elementPath rangeOfString:@"[-]"];
        NSRange eventRange = [config.event.elementPath rangeOfString:@"[-]"];
        
        if (propertyRange.location != NSNotFound && eventRange.location != NSNotFound) {
            NSString *propertyElementPathPrefix = [propertyConfig.elementPath substringToIndex:propertyRange.location];
            NSString *eventElementPathPrefix = [config.event.elementPath substringToIndex:eventRange.location];
            if ([propertyElementPathPrefix isEqualToString:eventElementPathPrefix]) {
                propertyConfig.clickElementPosition = clickPosition;
            }
        }

        // 页面序号，仅匹配当前页面元素
        propertyConfig.pageIndex = pageIndex;

        // 根据修改后的配置，查询属性值
        NSDictionary *property = [self queryPropertiesWithPropertyConfig:propertyConfig];
        if (!property) {
            continue;
        }
        [properties addEntriesFromDictionary:property];
    }
    return properties;
}

/// 解析属性值
- (NSString *)analysisPropertyWithView:(UIView *)view propertyConfig:(ZAVisualPropertiesPropertyConfig *)config {
    
    // 获取元素内容，主线程执行
    __block NSString *content = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        content = view.zalldata_propertyContent;
    });
    
    if (content.length == 0) {
        // 打印 view 需要在主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *logMessage = [ZAVisualizedLogger buildLoggerMessageWithTitle:@"解析属性" message:@"属性 %@ 获取元素内容失败, %@", config.name, view];
            ZALogWarn(@"%@", logMessage);
        });
        return nil;
    }
    
    // 根据正则解析属性
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:config.regular options:NSRegularExpressionDotMatchesLineSeparators error:&error];
    
    // 仅取出第一条匹配记录
    NSTextCheckingResult *firstResult = [regex firstMatchInString:content options:0 range:NSMakeRange(0, [content length])];
    if (!firstResult) {
        NSString *logMessage = [ZAVisualizedLogger buildLoggerMessageWithTitle:@"解析属性" message:@"元素内容 %@ 正则解析属性失败，属性名：%@，正则为：%@", content,  config.name, config.regular];
        ZALogWarn(@"%@", logMessage);
        return nil;
    }
    
    NSString *value = [content substringWithRange:firstResult.range];
    return value;
}

/// 根据属性配置查询属性值
- (nullable NSDictionary *)queryPropertiesWithPropertyConfig:(ZAVisualPropertiesPropertyConfig *)propertyConfig {
    // 1. 获取属性元素
    UIView *view = [self.viewNodeTree viewWithPropertyConfig:propertyConfig];
    if (!view) {
        NSString *logMessage = [ZAVisualizedLogger buildLoggerMessageWithTitle:@"获取属性元素" message:@"属性 %@ 未找到对应属性元素", propertyConfig.name];
        ZALogDebug(@"%@", logMessage);
        return nil;
    }

    // 2. 根据属性元素，解析属性值
    NSString *propertyValue = [self analysisPropertyWithView:view propertyConfig:propertyConfig];
    if (!propertyValue) {
        return nil;
    }

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 3. 属性类型转换
    // 字符型属性
    if (propertyConfig.type == ZAVisualPropertyTypeString) {
        properties[propertyConfig.name] = propertyValue;
        return [properties copy];
    }

    // 数值型属性
    NSDecimalNumber *propertyNumber = [NSDecimalNumber decimalNumberWithString:propertyValue];
    // 判断转换后是否为 NAN
    if ([propertyNumber isEqualToNumber:NSDecimalNumber.notANumber]) {
        NSString *logMessage = [ZAVisualizedLogger buildLoggerMessageWithTitle:@"解析属性" message:@"属性 %@ 正则解析后为：%@，数值型转换失败", propertyConfig.name, propertyValue];
        ZALogWarn(@"%@", logMessage);
        return nil;
    }
    properties[propertyConfig.name] = propertyNumber;
    return [properties copy];
}

/// 根据配置，查询 Native 属性
- (void)queryVisualPropertiesWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler {

    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *allEventProperties = [NSMutableDictionary dictionary];
        for (NSDictionary *propertyConfigDic in propertyConfigs) {
            ZAVisualPropertiesPropertyConfig *propertyConfig = [[ZAVisualPropertiesPropertyConfig alloc] initWithDictionary:propertyConfigDic];

            /* 查询 native 属性
             如果存在多个 page 页面，这里可能查询错误
             */
            NSDictionary *property = [self queryPropertiesWithPropertyConfig:propertyConfig];
            if (property.count > 0) {
                [allEventProperties addEntriesFromDictionary:property];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(allEventProperties);
        });
    });
}


#pragma mark webView visualProperties
/// 查询多个 webView 内自定义属性
- (void)queryMultiWebViewPropertiesWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs viewNode:(ZAViewNode *)viewNode completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler {
    if (propertyConfigs.count == 0) {
        completionHandler(nil);
        return;
    }

    // 事件元素为 App，属性元素可能存在于多个 WebView
    NSDictionary <NSString *, NSArray *>* groupPropertyConfigs = [self groupMultiWebViewWithConfigs:propertyConfigs];

    NSMutableDictionary *webProperties = [NSMutableDictionary dictionary];
    dispatch_group_t group = dispatch_group_create();
    for (NSArray *configArray in groupPropertyConfigs.allValues) {

        dispatch_group_enter(group);
        [self queryCurrentWebViewPropertiesWithConfigs:configArray viewNode:viewNode completionHandler:^(NSDictionary * _Nullable properties) {
            if (properties.count > 0) {
                [webProperties addEntriesFromDictionary:properties];
            }
            dispatch_group_leave(group);
        }];
    }

    // 多个 webview 属性查询完成，返回结果
    dispatch_group_notify(group, self.serialQueue, ^{
        completionHandler([webProperties copy]);
    });
}

/// 查询当前 webView 内自定义属性
- (void)queryCurrentWebViewPropertiesWithConfigs:(NSArray <NSDictionary *> *)propertyConfigs viewNode:(ZAViewNode *)viewNode completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler {

    NSDictionary *config = [propertyConfigs firstObject];
    ZAVisualPropertiesPropertyConfig *propertyConfig = [[ZAVisualPropertiesPropertyConfig alloc] initWithDictionary:config];
    // 设置页面信息，准确查找 webView
    propertyConfig.screenName = viewNode.screenName;
    propertyConfig.pageIndex = viewNode.pageIndex;

    UIView *view = [self.viewNodeTree viewWithPropertyConfig:propertyConfig];
    if (![view isKindOfClass:WKWebView.class]) {
        NSString *logMessage = [ZAVisualizedLogger buildLoggerMessageWithTitle:@"获取属性元素" message:@"App 内嵌 H5 属性 %@ 未找到对应 WKWebView 元素", propertyConfig.name];
        ZALogDebug(@"%@", logMessage);
        completionHandler(nil);
        return;
    }

    WKWebView *webView = (WKWebView *)view;
    NSMutableDictionary *webMessageInfo = [NSMutableDictionary dictionary];
    webMessageInfo[@"platform"] = @"ios";
    webMessageInfo[@"zalldata_js_visual_properties"] = propertyConfigs;

    // 注入待查询的属性配置信息
    NSString *javaScriptSource = [ZAJavaScriptBridgeBuilder buildCallJSMethodStringWithType:ZAJavaScriptCallJSTypeWebVisualProperties jsonObject:webMessageInfo];
    if (!javaScriptSource) {
        completionHandler(nil);
        return;
    }
    // 使用 webview 调用 JS 方法，获取属性，主线程执行
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:javaScriptSource completionHandler:^(id _Nullable results, NSError *_Nullable error) {
            // 类型判断
            if ([results isKindOfClass:NSDictionary.class]) {
                completionHandler(results);
            } else {
                NSString *logMessage = [ZAVisualizedLogger buildLoggerMessageWithTitle:@"解析属性" message:@" 调用 JS 方法 %@，解析 App 内嵌 H5 属性失败", javaScriptSource];
                ZALogDebug(@"%@", logMessage);
                completionHandler(nil);
            }
        }];
    });
}

/// 对属性配置按照 webview 进行分组处理
- (NSDictionary <NSString *, NSArray *> *)groupMultiWebViewWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs {
    NSMutableDictionary *groupPropertyConfigs = [NSMutableDictionary dictionary];
    for (NSDictionary * propertyConfigDic in propertyConfigs) {
        NSString *webViewElementPath = propertyConfigDic[@"webview_element_path"];
        if (!webViewElementPath) {
            continue;
        }

        // 当前 webview 的属性配置
        NSMutableArray <NSDictionary *>* configs = groupPropertyConfigs[webViewElementPath];
        if (!configs) {
            configs = [NSMutableArray array];
            groupPropertyConfigs[webViewElementPath] = configs;
        }
        [configs addObject:propertyConfigDic];
    }
    return [groupPropertyConfigs copy];
}

#pragma mark - logInfos
/// 开始采集调试日志
- (void)enableCollectDebugLog:(BOOL)enable {
    if (!enable) { // 关闭日志采集
        self.debugLogTracker = nil;
        self.enableLogAlertController = nil;
        return;
    }
    // 已经开启日志采集
    if (self.debugLogTracker) {
        return;
    }
    
    // 开启日志采集
    if (ZAConfigOptions.sharedInstance.enableLog) {
        self.debugLogTracker = [[ZAVisualizedDebugLogTracker alloc] init];
        return;
    }
    
    // 避免重复弹框
    if (self.enableLogAlertController) {
        return;
    }
    // 未开启 enableLog，弹框提示
    __weak ZAVisualPropertiesTracker *weakSelf = self;
    self.enableLogAlertController = [[ZAAlertViewController alloc] initWithTitle:@"提示" message:@"可视化全埋点进入 Debug 模式，需要开启日志打印用于收集调试信息，退出 Debug 模式关闭日志打印，是否需要开启呢？" preferredStyle:ZAAlertControllerStyleAlert];
    [self.enableLogAlertController addActionWithTitle:@"开启日志打印" style:ZAAlertActionStyleDefault handler:^(ZAAlertAction * _Nonnull action) {
        [ZAConfigOptions.sharedInstance setEnableLog:YES];
        
        weakSelf.debugLogTracker = [[ZAVisualizedDebugLogTracker alloc] init];
    }];
    [self.enableLogAlertController addActionWithTitle:@"暂不开启" style:ZAAlertActionStyleCancel handler:nil];
    [self.enableLogAlertController show];
}

- (NSArray<NSDictionary *> *)logInfos {
    return [self.debugLogTracker.debugLogInfos copy];
}

@end


