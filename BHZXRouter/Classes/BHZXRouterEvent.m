//
//  BHZXRouterEvent.m
//  BHZXRouters
//
//  Created by wrc on 2022/11/27.
//  Copyright © 2021 BHZX. All rights reserved.
//

#import "BHZXRouterEvent.h"

@interface BHZXRouterEvent ()

@property (nonatomic,   copy) NSString *url;
@property (nonatomic, strong) NSDictionary *queryParams;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic,   copy) BHZXRouterCompletion completion;

@end

@implementation BHZXRouterEvent

- (instancetype)initWithUrl:(NSString *)url userInfo:(NSDictionary *)userInfo completion:(BHZXRouterCompletion)completion
{
    self = [super init];
    if (self) {
        _url = url;
        NSString *encodingUrl = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        NSURL *tempUrl = [NSURL URLWithString:encodingUrl];
        if (tempUrl) {
            NSArray<NSURLQueryItem *> *queryItems = [[NSURLComponents alloc] initWithURL:tempUrl resolvingAgainstBaseURL:false].queryItems;
            for (NSURLQueryItem *item in queryItems) {
                params[item.name] = [item.value stringByRemovingPercentEncoding];
            }
        }
        _queryParams = [NSDictionary dictionaryWithDictionary:params];
        _userInfo = userInfo;
        _completion = [completion copy];
    }
    return self;
}

@end
