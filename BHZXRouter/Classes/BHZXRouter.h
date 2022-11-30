//
//  BHZXRouter.h
//  BHZXRouters
//
//  Created by wrc on 2022/11/27.
//  Copyright © 2021 BHZX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHZXRouterInterceptorProtocol.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const BHZXRouterParameterURL;
extern NSString *const BHZXRouterParameterCompletion;
extern NSString *const BHZXRouterParameterUserInfo;

/**
 *  routerParameters 里内置的几个参数会用到上面定义的 string
 */
typedef void (^BHZXRouterHandler)(NSDictionary *routerParameters);

/**
 *  配合页面管理框架绑定页面，URL与BHZXRouterParameterURL对应的URL相同
 */
typedef void (^BHZXRouterBindPageHandler)(NSString *URL);


/**
 *  需要返回一个 object，配合 objectForURL: 使用
 */
typedef id _Nullable (^BHZXRouterObjectHandler)(NSDictionary *routerParameters);

/**
 *  URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
typedef void(^BHZXRouterCompletion)(id _Nullable result);

@interface BHZXRouter : NSObject

/**
 *  注册 URLPattern 对应的 Handler，在 handler 中可以初始化 VC，然后对 VC 做各种操作
 *
 *  @param URLPattern 带上 scheme，如 hs://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 hs://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (void)registerURLPattern:(NSString *)URLPattern toHandler:(BHZXRouterHandler)handler;

/**
 *  注册 URLPattern 对应的 Handler，在 handler 中可以初始化 VC，然后对 VC 做各种操作
 *
 *  @param URLPattern 带上 scheme，如 hs://beauty/:id
 *  @param bindPageHandler 配合页面管理框架绑定页面，该block入参为URLPattern去掉参数后的URL
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 hs://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 */
+ (void)registerURLPattern:(NSString *)URLPattern bindPageHandler:(BHZXRouterBindPageHandler)bindPageHandler toHandler:(BHZXRouterHandler)handler;

/**
 *  注册 URLPattern 对应的 ObjectHandler，需要返回一个 object 给调用方
 *
 *  @param URLPattern 带上 scheme，如 hs://beauty/:id
 *  @param handler    该 block 会传一个字典，包含了注册的 URL 中对应的变量。
 *                    假如注册的 URL 为 hs://beauty/:id 那么，就会传一个 @{@"id": 4} 这样的字典过来
 *                    自带的 key 为 @"url" 和 @"completion" (如果有的话)
 */
+ (void)registerURLPattern:(NSString *)URLPattern toObjectHandler:(BHZXRouterObjectHandler)handler;

/**
 *  取消注册某个 URL Pattern
 *
 *  @param URLPattern URLPattern
 */
+ (void)deregisterURLPattern:(NSString *)URLPattern;

/**
 *  打开此 URL
 *  会在已注册的 URL -> Handler 中寻找，如果找到，则执行 Handler
 *
 *  @param URL 带 Scheme，如 hs://beauty/3
 */
+ (void)openURL:(NSString *)URL;

/**
 *  打开此 URL，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 hs://beauty/4
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(NSString *)URL completion:(nullable BHZXRouterCompletion)completion;

/**
 *  打开此 URL，带上附加信息，同时当操作完成时，执行额外的代码
 *
 *  @param URL        带 Scheme 的 URL，如 hs://beauty/4
 *  @param userInfo 附加参数
 *  @param completion URL 处理完成后的 callback，完成的判定跟具体的业务相关
 */
+ (void)openURL:(NSString *)URL
   withUserInfo:(nullable NSDictionary *)userInfo
     completion:(nullable BHZXRouterCompletion)completion;

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object
 *
 *  @param URL 带 Scheme，如 hs://beauty/3
 */
+ (id)objectForURL:(NSString *)URL;

/**
 * 查找谁对某个 URL 感兴趣，如果有的话，返回一个 object
 *
 *  @param URL 带 Scheme，如 hs://beauty/3
 *  @param userInfo 附加参数
 */
+ (id)objectForURL:(NSString *)URL withUserInfo:(NSDictionary * _Nullable)userInfo;

/**
 * 通过URL异步获取对象，通过completion返回具体对象
 *
 *  @param URL 带 Scheme，如 hs://beauty/3
 *  @param completion URL对应的ObjectHandler处理完成后的 callback，用于返回异步获取的对象
 */
+ (void)objectForURL:(NSString *)URL completion:(nullable BHZXRouterCompletion)completion;

/**
 * 通过URL异步获取对象，通过completion返回具体对象
 *
 *  @param URL 带 Scheme，如 hs://beauty/3
 *  @param userInfo 附加参数
 *  @param completion URL对应的ObjectHandler处理完成后的 callback，用于返回异步获取的对象
 */
+ (void)objectForURL:(NSString *)URL withUserInfo:(NSDictionary * _Nullable)userInfo completion:(nullable BHZXRouterCompletion)completion;

/**
 *  是否可以打开URL
 *
 *  @param URL 带 Scheme，如 hs://beauty/3
 *
 *  @return 返回BOOL值
 */
+ (BOOL)canOpenURL:(NSString *)URL;

/**
 *  调用此方法来拼接 urlpattern 和 parameters
 *
 *  #define HS_ROUTE_BEAUTY @"beauty/:id"
 *  [BHZXRouter generateURLWithPattern:HS_ROUTE_BEAUTY, @[@13]];
 *
 *
 *  @param pattern    url pattern 比如 @"beauty/:id"
 *  @param parameters 一个数组，数量要跟 pattern 里的变量一致
 *
 *  @return 返回生成的URL String
 */
+ (NSString *)generateURLWithPattern:(NSString *)pattern parameters:(NSArray *)parameters;

/**
 *  注册拦截器
 *  @param interceptor 拦截器
 */
+ (void)registerInterceptor:(id <BHZXRouterInterceptorProtocol>)interceptor;

/**
 *  判断两个路由URL是否相同，只判断到？号前，URL的参数不做匹配条件
 *  @param routerURL 路由URL
 *  @param otherRouterURL 路由URL
 *
 *  @return 返回生成的URL String
 */
+ (BOOL)matchRouterURL:(NSString *)routerURL withOtherRouterURL:(NSString *)otherRouterURL;


/**
 *  URL拼接参数
 *  @param routerURL 路由URL
 *  @param parameters 拼接参数
 *
 *  @return 返回生成的URL String
 */
+ (NSString *)generateRouterURL:(NSString *)routerURL withParameters:(NSDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
