//
//  BHZXRouterInterceptorProtocol.h
//  BHZXRouters
//
//  Created by wrc on 2022/11/27.
//  Copyright © 2021 BHZX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 拦截器优先级
#define BHZXRouterInterceptorPriorityDefault  1000 // 默认
#define BHZXRouterInterceptorPriorityLow      100  // 低
#define BHZXRouterInterceptorPriorityHigh     2000 // 高

@class BHZXRouterEvent;

@protocol BHZXRouterInterceptorProtocol <NSObject>

@required

/// 拦截器处理
/// @param routerEvent 路由事件参数
/// @param isContinue isContinue(YES) 继续执行当前操作， isContinue(NO) 中断当前操作
- (void)checkRouterEvent:(nonnull BHZXRouterEvent *)routerEvent complete:(void(^)(BOOL isContinue))isContinue;

@optional

/**
 拦截器优先级，数值越小优先级越低；
 默认为BHZXRouterInterceptorPriorityDefault
 */
- (NSUInteger)priority;

@end

NS_ASSUME_NONNULL_END
