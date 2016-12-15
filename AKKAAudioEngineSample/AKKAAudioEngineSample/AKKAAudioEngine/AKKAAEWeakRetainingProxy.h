//
//  AKKAAEWeakRetainingProxy.h
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/13.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>

@interface AKKAAEWeakRetainingProxy : NSProxy

+ (instancetype _Nonnull)proxyWithTarget:(id _Nonnull)target;

@property (nonatomic, weak, readonly) id _Nullable target;

@end

#ifdef __cplusplus
}
#endif

