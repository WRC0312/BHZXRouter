//
//  BHZXRouter.m
//  BHZXRouters
//
//  Created by wrc on 2022/11/27.
//  Copyright © 2021 BHZX. All rights reserved.
//

#import "BHZXRouter.h"
#import <objc/runtime.h>
#import "BHZXRouterEvent.h"

static NSString * const HS_ROUTER_WILDCARD_CHARACTER = @"~";
static NSString *specialCharacters = @"/?&.";

NSString *const BHZXRouterParameterURL = @"BHZXRouterParameterURL";
NSString *const BHZXRouterParameterCompletion = @"BHZXRouterParameterCompletion";
NSString *const BHZXRouterParameterUserInfo = @"BHZXRouterParameterUserInfo";

#ifdef DEBUG
    #define BHZXRouterLog NSLog
#else
    #define BHZXRouterLog(format, ...)
#endif

@interface BHZXRouter ()
/**
 *  保存了所有已注册的 URL
 *  结构类似 @{@"beauty": @{@":id": {@"_", [block copy]}}}
 */
@property (nonatomic) NSMutableDictionary *routes;

// 保存注册的拦截器，优先级越高，在数组中的位置越靠前
@property (nonatomic) NSMutableArray <id <BHZXRouterInterceptorProtocol >> *interceptors;

@end

@implementation BHZXRouter

+ (instancetype)sharedInstance
{
    static BHZXRouter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (void)registerURLPattern:(NSString *)URLPattern toHandler:(BHZXRouterHandler)handler
{
    [[self sharedInstance] addURLPattern:URLPattern andHandler:handler];
}

+ (void)registerURLPattern:(NSString *)URLPattern bindPageHandler:(BHZXRouterBindPageHandler)bindPageHandler toHandler:(BHZXRouterHandler)handler
{
    //GMU框架页面注册
    if (bindPageHandler) {
        bindPageHandler(URLPattern);
    }
    [[self sharedInstance] addURLPattern:URLPattern andHandler:handler];
}

+ (void)deregisterURLPattern:(NSString *)URLPattern
{
    [[self sharedInstance] removeURLPattern:URLPattern];
}

+ (void)openURL:(NSString *)URL
{
    [self openURL:URL completion:nil];
}

+ (void)openURL:(NSString *)URL completion:(BHZXRouterCompletion)completion
{
    [self openURL:URL withUserInfo:nil completion:completion];
}

+ (void)openURL:(NSString *)URL withUserInfo:(nullable NSDictionary *)userInfo completion:(BHZXRouterCompletion)completion
{
    if (!URL) return;
    
    BHZXRouterEvent *routerEvent = [[BHZXRouterEvent alloc] initWithUrl:URL userInfo:userInfo completion:completion];
    __weak typeof(self) weakSelf = self;
    [[self sharedInstance] excuteInterceptorAtIndex:0 routerEvent:routerEvent complete:^(BOOL isContinue) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (isContinue) {
            [[strongSelf sharedInstance] openURL:URL withUserInfo:userInfo completion:completion];
        }
    }];
}

+ (BOOL)canOpenURL:(NSString *)URL
{
    URL = [URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return [[self sharedInstance] extractParametersFromURL:URL] ? YES : NO;
}

+ (NSString *)generateURLWithPattern:(NSString *)pattern parameters:(NSArray *)parameters
{
    NSInteger startIndexOfColon = 0;
    
    NSMutableArray *placeholders = [NSMutableArray array];
    
    for (int i = 0; i < pattern.length; i++) {
        NSString *character = [NSString stringWithFormat:@"%c", [pattern characterAtIndex:i]];
        if ([character isEqualToString:@":"]) {
            startIndexOfColon = i;
        }
        if ([specialCharacters rangeOfString:character].location != NSNotFound && i > (startIndexOfColon + 1) && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon);
            NSString *placeholder = [pattern substringWithRange:range];
            if (![self checkIfContainsSpecialCharacter:placeholder]) {
                [placeholders addObject:placeholder];
                startIndexOfColon = 0;
            }
        }
        if (i == pattern.length - 1 && startIndexOfColon) {
            NSRange range = NSMakeRange(startIndexOfColon, i - startIndexOfColon + 1);
            NSString *placeholder = [pattern substringWithRange:range];
            if (![self checkIfContainsSpecialCharacter:placeholder]) {
                [placeholders addObject:placeholder];
            }
        }
    }
    
    __block NSString *parsedResult = pattern;
    
    [placeholders enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        idx = parameters.count > idx ? idx : parameters.count - 1;
        parsedResult = [parsedResult stringByReplacingOccurrencesOfString:obj withString:parameters[idx]];
    }];
    
    return parsedResult;
}

+ (id)objectForURL:(NSString *)URL withUserInfo:( NSDictionary * _Nullable )userInfo
{
    if (!URL) return nil;

    BHZXRouter *router = [BHZXRouter sharedInstance];
    
    URL = [URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableDictionary *parameters = [router extractParametersFromURL:URL];
    BHZXRouterObjectHandler handler = parameters[@"block"];
    
    if (handler) {
        if (userInfo) {
            parameters[BHZXRouterParameterUserInfo] = userInfo;
        }
        [parameters removeObjectForKey:@"block"];
        return handler(parameters);
    }
    return nil;
}

+ (id)objectForURL:(NSString *)URL
{
    
    return [self objectForURL:URL withUserInfo:nil];
}

+ (void)objectForURL:(NSString *)URL completion:(nullable BHZXRouterCompletion)completion
{
    [self objectForURL:URL withUserInfo:nil completion:completion];
}

+ (void)objectForURL:(NSString *)URL withUserInfo:(NSDictionary * _Nullable)userInfo completion:(nullable BHZXRouterCompletion)completion
{
    BHZXRouter *router = [BHZXRouter sharedInstance];
    
    URL = [URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableDictionary *parameters = [router extractParametersFromURL:URL];
    BHZXRouterObjectHandler handler = parameters[@"block"];
    
    if (handler) {
        if (userInfo) {
            parameters[BHZXRouterParameterUserInfo] = userInfo;
        }
        if (completion) {
            parameters[BHZXRouterParameterCompletion] = completion;
        }
        [parameters removeObjectForKey:@"block"];
        handler(parameters);
    }
}

+ (void)registerURLPattern:(NSString *)URLPattern toObjectHandler:(BHZXRouterObjectHandler)handler
{
    [[self sharedInstance] addURLPattern:URLPattern andObjectHandler:handler];
}

+ (void)registerInterceptor:(id <BHZXRouterInterceptorProtocol>)interceptor
{
    [[self sharedInstance] addInterceptor:interceptor];
}

+ (BOOL)matchRouterURL:(NSString *)routerURL withOtherRouterURL:(NSString *)otherRouterURL
{
    if (routerURL.length == 0 || otherRouterURL.length == 0)
        return NO;
    BOOL result = [[self keyForURL:routerURL] isEqualToString:[self keyForURL:otherRouterURL]];
    return result;
}

+ (NSString *)generateRouterURL:(NSString *)routerURL withParameters:(NSDictionary *)parameters
{
    if (routerURL.length == 0 || parameters.allKeys.count == 0)
        return routerURL;
    
    BOOL addQuestionMark = NO; //添加一次问号即可
    for (int i = 0; i < parameters.allKeys.count; i++) {
        NSString *key = parameters.allKeys[i];
        NSString *value = parameters.allValues[i];
        if (![key isKindOfClass:NSString.class] || ![value isKindOfClass:NSString.class]) {
            continue;
        }
        if (!addQuestionMark) {
            routerURL = [routerURL stringByAppendingString:@"?"];
        }
        routerURL = [routerURL stringByAppendingFormat:@"%@=%@",key,value];
    }
    return routerURL;
}


- (void)addURLPattern:(NSString *)URLPattern andHandler:(BHZXRouterHandler)handler
{
    NSMutableDictionary *subRoutes = [self addURLPattern:URLPattern];
    if (handler && subRoutes) {
        subRoutes[@"_"] = [handler copy];
    }
}

- (void)addURLPattern:(NSString *)URLPattern andObjectHandler:(BHZXRouterObjectHandler)handler
{
    NSMutableDictionary *subRoutes = [self addURLPattern:URLPattern];
    if (handler && subRoutes) {
        subRoutes[@"_"] = [handler copy];
    }
}

- (NSMutableDictionary *)addURLPattern:(NSString *)URLPattern
{
    NSArray *pathComponents = [self pathComponentsFromURL:URLPattern];

    NSMutableDictionary* subRoutes = self.routes;
    
    for (NSString* pathComponent in pathComponents) {
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
    }
    return subRoutes;
}

- (void)addInterceptor:(id <BHZXRouterInterceptorProtocol>)interceptor
{
    for (id <BHZXRouterInterceptorProtocol> interceptor_t in self.interceptors) {
        //存在相同拦截器则不添加
        if ([interceptor isMemberOfClass:interceptor_t.class]) {
            return;
        }
    }
    
    for (int i = 0; i < self.interceptors.count; i++) {
        id <BHZXRouterInterceptorProtocol> temp = self.interceptors[i];
        NSUInteger priority1 = BHZXRouterInterceptorPriorityDefault;
        NSUInteger priority2 = BHZXRouterInterceptorPriorityDefault;
        if ([temp respondsToSelector:@selector(priority)]) {
            priority1 = [temp priority];
        }
        if ([temp respondsToSelector:@selector(priority)]) {
            priority2 = [interceptor priority];
        }
        if (priority1 < priority2) {
            [self.interceptors insertObject:interceptor atIndex:i];
            return;
        }
    }
    
    [self.interceptors addObject:interceptor];
}

// 递归调用拦截器
- (void)excuteInterceptorAtIndex:(int)index routerEvent:(BHZXRouterEvent *)routerEvent complete:(void(^)(BOOL isContinue))complete
{
    if (self.interceptors.count == 0 || index >= self.interceptors.count) {
        complete(YES);
        return;
    }
    
    id<BHZXRouterInterceptorProtocol> interceptor_t = self.interceptors[index];
    __weak typeof(self) weakSelf = self;
    [interceptor_t checkRouterEvent:routerEvent complete:^(BOOL isContinue) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (isContinue) {
            [strongSelf excuteInterceptorAtIndex:index + 1 routerEvent:routerEvent complete:complete];
        }
        else {
            complete(NO);
        }
    }];
}

- (void)openURL:(NSString *)URL withUserInfo:(NSDictionary *)userInfo completion:(BHZXRouterCompletion)completion
{
    BHZXRouterLog(@"【路由】打开页面路径：%@", URL);
    URL = [URL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSMutableDictionary *parameters = [self extractParametersFromURL:URL];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, NSString *obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            parameters[key] = [obj stringByRemovingPercentEncoding];
        }
    }];
    
    if (parameters) {
        BHZXRouterHandler handler = parameters[@"block"];
        if (completion) {
            parameters[BHZXRouterParameterCompletion] = completion;
        }
        if (userInfo) {
            parameters[BHZXRouterParameterUserInfo] = userInfo;
        }
        if (handler) {
            [parameters removeObjectForKey:@"block"];
            handler(parameters);
        }
    }
}

#pragma mark - Utils

- (NSMutableDictionary *)extractParametersFromURL:(NSString *)url
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    parameters[BHZXRouterParameterURL] = url;

    NSMutableDictionary* subRoutes = self.routes;
    NSArray* pathComponents = [self pathComponentsFromURL:url];
    
    // borrowed from HHRouter(https://github.com/Huohua/HHRouter)
    for (NSString* pathComponent in pathComponents) {
        BOOL found = NO;
        // 对 key 进行排序，这样可以把 ~ 放到最后
        NSArray *subRoutesKeys =[subRoutes.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }];
        
        for (NSString* key in subRoutesKeys) {
            if ([key isEqualToString:pathComponent] || [key isEqualToString:HS_ROUTER_WILDCARD_CHARACTER]) {
                found = YES;
                subRoutes = subRoutes[key];
                break;
            } else if ([key hasPrefix:@":"]) {
                found = YES;
                subRoutes = subRoutes[key];
                NSString *newKey = [key substringFromIndex:1];
                NSString *newPathComponent = pathComponent;
                // 再做一下特殊处理，比如 :id.html -> :id
                if ([self.class checkIfContainsSpecialCharacter:key]) {
                    NSCharacterSet *specialCharacterSet = [NSCharacterSet characterSetWithCharactersInString:specialCharacters];
                    NSRange range = [key rangeOfCharacterFromSet:specialCharacterSet];
                    if (range.location != NSNotFound) {
                        // 把 pathComponent 后面的部分也去掉
                        newKey = [newKey substringToIndex:range.location - 1];
                        NSString *suffixToStrip = [key substringFromIndex:range.location];
                        newPathComponent = [newPathComponent stringByReplacingOccurrencesOfString:suffixToStrip withString:@""];
                    }
                }
                parameters[newKey] = newPathComponent;
                break;
            }
        }
        
        // 如果没有找到该 pathComponent 对应的 handler，则以上一层的 handler 作为 fallback
        if (!found && !subRoutes[@"_"]) {
            return nil;
        }
    }
    
    // Extract Params From Query.
    NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:[[NSURL alloc] initWithString:url] resolvingAgainstBaseURL:false].queryItems;
    
    for (NSURLQueryItem *item in queryItems) {
        parameters[item.name] = item.value;
    }

    if (subRoutes[@"_"]) {
        parameters[@"block"] = [subRoutes[@"_"] copy];
    }
    
    return parameters;
}

- (void)removeURLPattern:(NSString *)URLPattern
{
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[self pathComponentsFromURL:URLPattern]];
    
    // 只删除该 pattern 的最后一级
    if (pathComponents.count >= 1) {
        // 假如 URLPattern 为 a/b/c, components 就是 @"a.b.c" 正好可以作为 KVC 的 key
        NSString *components = [pathComponents componentsJoinedByString:@"."];
        NSMutableDictionary *route = [self.routes valueForKeyPath:components];
        
        if (route.count >= 1) {
            NSString *lastComponent = [pathComponents lastObject];
            [pathComponents removeLastObject];
            
            // 有可能是根 key，这样就是 self.routes 了
            route = self.routes;
            if (pathComponents.count) {
                NSString *componentsWithoutLast = [pathComponents componentsJoinedByString:@"."];
                route = [self.routes valueForKeyPath:componentsWithoutLast];
            }
            [route removeObjectForKey:lastComponent];
        }
    }
}

- (NSArray*)pathComponentsFromURL:(NSString *)URL
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    if ([URL rangeOfString:@"://"].location != NSNotFound) {
        NSArray *pathSegments = [URL componentsSeparatedByString:@"://"];
        // 如果 URL 包含协议，那么把协议作为第一个元素放进去
        [pathComponents addObject:pathSegments[0]];
        
        // 如果只有协议，那么放一个占位符
        URL = pathSegments.lastObject;
        if (!URL.length) {
            [pathComponents addObject:HS_ROUTER_WILDCARD_CHARACTER];
        }
    }

    /*
     如果 URL 包含端口且开头不是/，则会导致下面pathComponents返回nil；
     如app.lczq.com:7091/upload/agreement/UserServiceProtocol.pdf会返回nil，
     则需在开头拼接/,变为/app.lczq.com:7091/upload/agreement/UserServiceProtocol.pdf
     */
    if (![URL hasPrefix:@"/"]) {
        URL = [NSString stringWithFormat:@"/%@",URL];
    }
    
    for (NSString *pathComponent in [[NSURL URLWithString:URL] pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    return [pathComponents copy];
}

- (NSMutableDictionary *)routes
{
    if (!_routes) {
        _routes = [[NSMutableDictionary alloc] init];
    }
    return _routes;
}

- (NSMutableArray <id<BHZXRouterInterceptorProtocol>> *)interceptors
{
    if (!_interceptors) {
        _interceptors = [[NSMutableArray alloc] init];
    }
    return _interceptors;
}

#pragma mark - Utils

+ (BOOL)checkIfContainsSpecialCharacter:(NSString *)checkedString {
    NSCharacterSet *specialCharactersSet = [NSCharacterSet characterSetWithCharactersInString:specialCharacters];
    return [checkedString rangeOfCharacterFromSet:specialCharactersSet].location != NSNotFound;
}

// 剔除URL后拼接的参数
+ (nonnull NSString*)keyForURL:(nonnull NSString*)urlStr {
    NSURL *URL = [NSURL URLWithString:urlStr];
    NSString *key = @"";
    if ([URL scheme]) {
        key = [key stringByAppendingFormat:@"%@://",[URL scheme]];
    }
    key = [key stringByAppendingFormat:@"%@%@", URL.host ? : @"", URL.path ? : @""];
    return key;
}

@end
