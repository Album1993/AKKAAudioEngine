//
//  AKKAAEWeakRetainingProxy.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/13.
//  Copyright © 2016年 AKKA. All rights reserved.
//


#import "AKKAAEWeakRetainingProxy.h"

@interface AKKAAEWeakRetainingProxy()

@property (nonatomic, weak, readwrite) id target;

@end

@implementation AKKAAEWeakRetainingProxy

+ (instancetype)proxyWithTarget:(id)target {
    AKKAAEWeakRetainingProxy * proxy = [AKKAAEWeakRetainingProxy alloc];
    proxy.target = target;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [_target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    __strong id target = _target;
    [invocation setTarget:target];
    [invocation invoke];
}

@end


