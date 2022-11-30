//
//  BHZXRouterEvent.h
//  BHZXRouters
//
//  Created by wrc on 2022/11/27.
//  Copyright © 2021 BHZX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BHZXRouter.h"

NS_ASSUME_NONNULL_BEGIN

@interface BHZXRouterEvent : NSObject

/**
 路由URL
 对应 BHZXRouter中openURL:withUserInfo:completion:方法的URL
 */
@property (nonatomic,   copy, readonly) NSString *url;

/**
 路由URL ？后接参数
 */
@property (nonatomic, strong, readonly) NSDictionary *queryParams;

/**
 额外参数
 对应 BHZXRouter中openURL:withUserInfo:completion:方法的userInfo
 */
@property (nonatomic, strong, readonly) NSDictionary *userInfo;

/**
 完成回调
 对应 BHZXRouter中openURL:withUserInfo:completion:方法的completion
 */
@property (nonatomic,   copy, readonly) BHZXRouterCompletion completion;


- (instancetype)initWithUrl:(NSString *)url userInfo:(NSDictionary *)userInfo completion:(BHZXRouterCompletion)completion;

@end

NS_ASSUME_NONNULL_END
