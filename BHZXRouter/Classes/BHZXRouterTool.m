//
//  BHZXRouterTool.m
//  BHZXRouters
//
//  Created by wrc on 2020/8/31.
//  Copyright © 2020 BHZX. All rights reserved.
//

#import "BHZXRouterTool.h"
#import <objc/runtime.h>

@interface BHZXRouterTool ()
@property (strong, nonatomic) NSMutableDictionary *routes;
@end

@implementation BHZXRouterTool

+ (instancetype)sharedInstance
{
    static BHZXRouterTool *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [BHZXRouterTool new];
    });
    
    return instance;
}

- (void)map:(NSString *)route toBlock:(BHZXRouterBlock)block
{
    NSMutableDictionary *subRoutes = [self subRoutesToRoute:route];

    subRoutes[@"_"] = [block copy];
}

- (id)matchObject:(NSString *)route
{
    NSDictionary *params = [self paramsInRoute:route];
    Class objectClass = params[@"object_class"];

    id object = [[objectClass alloc] init];

    return object;
}

- (BHZXRouterBlock)matchBlock:(NSString *)route
{
    NSDictionary *params = [self paramsInRoute:route];
    
    if (!params){
    return nil;
    }
    
    BHZXRouterBlock routerBlock = [params[@"block"] copy];
    BHZXRouterBlock returnBlock = ^id(NSDictionary *aParams) {
        if (routerBlock) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:params];
            [dic addEntriesFromDictionary:aParams];
            return routerBlock([NSDictionary dictionaryWithDictionary:dic].copy);
        }
        return nil;
    };
    
    return [returnBlock copy];
}

- (id)callBlock:(NSString *)route
{
    NSDictionary *params = [self paramsInRoute:route];
    BHZXRouterBlock routerBlock = [params[@"block"] copy];

    if (routerBlock) {
        return routerBlock([params copy]);
    }
    return nil;
}

// extract params in a route
- (NSDictionary *)paramsInRoute:(NSString *)route
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    params[@"route"] = [self stringFromFilterAppUrlScheme:route];

    NSMutableDictionary *subRoutes = self.routes;
    NSArray *pathComponents = [self pathComponentsFromRoute:params[@"route"]];
    for (NSString *pathComponent in pathComponents) {
        BOOL found = NO;
        NSArray *subRoutesKeys = subRoutes.allKeys;
        for (NSString *key in subRoutesKeys) {
            if ([subRoutesKeys containsObject:pathComponent]) {
                found = YES;
                subRoutes = subRoutes[pathComponent];
                break;
            } else if ([key hasPrefix:@":"]) {
                found = YES;
                subRoutes = subRoutes[key];
                params[[key substringFromIndex:1]] = pathComponent;
                break;
            }
        }
        if (!found) {
            return nil;
        }
    }

    // Extract Params From Query.
    NSRange firstRange = [route rangeOfString:@"?"];
    if (firstRange.location != NSNotFound && route.length > firstRange.location + firstRange.length) {
        NSString *paramsString = [route substringFromIndex:firstRange.location + firstRange.length];
        NSArray *paramStringArr = [paramsString componentsSeparatedByString:@"&"];
        for (NSString *paramString in paramStringArr) {
            NSArray *paramArr = [paramString componentsSeparatedByString:@"="];
            if (paramArr.count > 1) {
                NSString *key = [paramArr objectAtIndex:0];
                NSString *value = [paramArr objectAtIndex:1];
                params[key] = value;
            }
        }
    }
    
    Class class = subRoutes[@"_"];
    if (class_isMetaClass(object_getClass(class))) {
        if ([class isSubclassOfClass:[NSObject class]]) {
            params[@"object_class"] = subRoutes[@"_"];
        } else {
            return nil;
        }
    } else {
        if (subRoutes[@"_"]) {
            params[@"block"] = [subRoutes[@"_"] copy];
        }
    }

    return [NSDictionary dictionaryWithDictionary:params];
}

#pragma mark - Private

- (NSMutableDictionary *)routes
{
    if (!_routes) {
        _routes = [[NSMutableDictionary alloc] init];
    }
    
    return _routes;
}

- (NSArray *)pathComponentsFromRoute:(NSString *)route
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    NSURL *url = [NSURL URLWithString:[route stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    for (NSString *pathComponent in url.path.pathComponents) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:[pathComponent stringByRemovingPercentEncoding]];
    }
    
    return [pathComponents copy];
}

- (NSString *)stringFromFilterAppUrlScheme:(NSString *)string
{
    // filter out the app URL compontents.
    for (NSString *appUrlScheme in [self appUrlSchemes]) {
        if ([string hasPrefix:[NSString stringWithFormat:@"%@:", appUrlScheme]]) {
            return [string substringFromIndex:appUrlScheme.length + 2];
        }
    }

    return string;
}

- (NSArray *)appUrlSchemes
{
    NSMutableArray *appUrlSchemes = [NSMutableArray array];

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];

    for (NSDictionary *dic in infoDictionary[@"CFBundleURLTypes"]) {
        NSString *appUrlScheme = dic[@"CFBundleURLSchemes"][0];
        [appUrlSchemes addObject:appUrlScheme];
    }

    return [appUrlSchemes copy];
}

- (NSMutableDictionary *)subRoutesToRoute:(NSString *)route
{
    NSArray *pathComponents = [self pathComponentsFromRoute:route];

    NSInteger index = 0;
    NSMutableDictionary *subRoutes = self.routes;

    while (index < pathComponents.count) {
        NSString *pathComponent = pathComponents[index];
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];

        index++;
    }
    
    return subRoutes;
}

- (void)map:(NSString *)route toObjectClass:(Class)objectClass
{
    NSMutableDictionary *subRoutes = [self subRoutesToRoute:route];

    subRoutes[@"_"] = objectClass;
}

- (BHZXRouteType)canRoute:(NSString *)route
{
    NSDictionary *params = [self paramsInRoute:route];
    
    if (params[@"object_class"]) {
        return BHZXRouteTypeObject;
    }
    
    if (params[@"block"]) {
        return BHZXRouteTypeBlock;
    }
    
    return BHZXRouteTypeNone;
}

@end

