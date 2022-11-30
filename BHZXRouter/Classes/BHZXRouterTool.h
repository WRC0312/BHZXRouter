//
//  BHZXRouterTool.h
//  BHZXRouters
//
//  Created by wrc on 2020/8/31.
//  Copyright © 2020 BHZX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, BHZXRouteType) {
    BHZXRouteTypeNone = 0,
    BHZXRouteTypeObject = 1,
    BHZXRouteTypeBlock = 2
};

typedef id _Nullable (^BHZXRouterBlock)(NSDictionary * _Nullable params);

@interface BHZXRouterTool : NSObject

+ (instancetype)sharedInstance;

/**
 * @brief 注入对象
 * @param route 存储key/路径，格式：/组件名/类名，如/BHZXMain/BHZXHomeViewModel
 * @param objectClass 对象对应的类
 */
- (void)map:(NSString *)route toObjectClass:(Class)objectClass;

/**
 * @brief 获取对象
 * @param route 存储key/路径，格式：/组件名/类名，如/BHZXMain/BHZXHomeViewModel
 */
- (id)matchObject:(NSString *)route;

/**
 * @brief 注入Block
 * @param route 存储key/路径，格式：/组件名(类名)/Block名
 * @param block 所注入的Block
 */
- (void)map:(NSString *)route toBlock:(BHZXRouterBlock)block;

/**
 * @brief 获取Block
 * @param route 存储key/路径，格式：/组件名(类名)/Block名
 */
- (BHZXRouterBlock)matchBlock:(NSString *)route;

/**
 * @brief 执行Block
 * @param route 存储key/路径，格式：/组件名(类名)/Block名
 * @return Block返回参数
 */
- (id)callBlock:(NSString *)route;

/**
 * @brief 校验route是否存在
 * @param route 存储key/路径
 * @return route类型
 */
- (BHZXRouteType)canRoute:(NSString *)route;

@end
NS_ASSUME_NONNULL_END
