#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "BHZXRouter.h"
#import "BHZXRouterEvent.h"
#import "BHZXRouterInterceptorProtocol.h"
#import "BHZXRouterTool.h"

FOUNDATION_EXPORT double BHZXRouterVersionNumber;
FOUNDATION_EXPORT const unsigned char BHZXRouterVersionString[];

