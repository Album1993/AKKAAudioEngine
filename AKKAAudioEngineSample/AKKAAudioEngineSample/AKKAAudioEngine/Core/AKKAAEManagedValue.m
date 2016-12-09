//
//  AKKAAEManagedValue.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/8.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAEManagedValue.h"
#import <pthread.h>

typedef struct __linkedlistitem_t {
    void * data;
    struct __linkedlistitem_t * next;
}linkedlistitem_t;

static int __atomicUpdateCounter = 0;
static pthread_rwlock_t __atomicUpdateMutex = PTHREAD_RWLOCK_INITIALIZER;
static NSHashTable * __atomicUpdatedDeferredSyncValues = nil;
static BOOL

@implementation AKKAAEManagedValue

@end
