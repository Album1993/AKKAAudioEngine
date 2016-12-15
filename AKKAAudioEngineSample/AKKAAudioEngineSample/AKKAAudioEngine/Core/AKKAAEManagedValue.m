//
//  AKKAAEManagedValue.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/8.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAEManagedValue.h"
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import "AKKAAEWeakRetainingProxy.h"
#import "AKKAAEUtilities.h"

typedef struct __linkedlistitem_t {
    void * data;
    struct __linkedlistitem_t * next;
}linkedlistitem_t;

static int __atomicUpdateCounter = 0;
static pthread_rwlock_t __atomicUpdateMutex = PTHREAD_RWLOCK_INITIALIZER;
static NSHashTable * __atomicUpdatedDeferredSyncValues = nil;
static BOOL __atomicUpdateWaitingForCommit = NO;

static linkedlistitem_t * __pendingInstances = NULL;
static linkedlistitem_t * __servicedInstances = NULL;
static pthread_mutex_t __pendingInstanceMutex = PTHREAD_MUTEX_INITIALIZER;

#ifdef DEBUG
pthread_t AKKAAEManagedValueRealtimeThreadIdentifier = NULL;
#endif


@interface AKKAAEManagedValue () {
    void    *   _value;
    BOOL        _valueSet;
    void    *   _atomicBatchUpdateLastValue;
    BOOL        _wasUpdatedInAtomicBatchUpdate;
    BOOL        _isObjectValue;
    OSQueueHead _pendingReleaseQueue;
    int _pendingReleaseCount;
    OSQueueHead _releaseQueue;
}
@property (nonatomic, strong)NSTimer * pollTimer;

@end

@implementation AKKAAEManagedValue
@dynamic objectValue,pointerValue;

+(void)initialize {
    __atomicUpdatedDeferredSyncValues = [[NSHashTable alloc]initWithOptions:NSPointerFunctionsWeakMemory
                                                                   capacity:0];
}

/*!
 * Some comments about the implementation for atomic batch updates, as it's a bit tricky:
 *
 *  - This works by making the realtime thread read the previously set value, instead of
 *    the new one.
 *
 *  - We need to protect against the scenario where the batch-update-in-progress check on the
 *    realtime thread passes followed immediately by the main thread entering the batch update and
 *    changing the value, as this violates atomicity. To do this, we use a mutex to guard the
 *    realtime thread check-and-return. We use a try lock on the realtime thread, the failure
 *    of which conveniently tells us that a batch update is happening, so it's the only check
 *    we need.
 *
 *  - We need the realtime thread to only return the previously set value between the time an
 *    update starts, and the time it's committed. Commit happens on the realtime thread at the
 *    start of the main render loop, initiated by the third-party developer, so that batch updates
 *    occur all together with respect to the main render loop - otherwise, completion of a batch
 *    update could occur while the render loop is midway through, violating atomicity.
 *
 *  - This mechanism requires the previously set value (_atomicBatchUpdateLastValue) to be
 *    synced correctly to the current value at the time the atomic batch update begins.
 *
 *  - setValue is responsible for maintaining this sync. It can't do this during a batch update
 *    though, or it would defeat the purpose.
 *
 *  - Consequently, this is deferred until the next time sync is required: at the beginning
 *    of the next batch update. We do this by keeping track of those deferrals in a static
 *    NSHashTable, and performing them at the start of the batch update method.
 *
 *  - In order to allow values to be deallocated cleanly, we store weak values in this set, and
 *    remove outgoing instances in dealloc.
 *
 *  - Side note: An alternative deferral implementation is to perform post-batch update sync from
 *    the commit function, on the realtime thread, but this introduces two complications: (1) that
 *    the _atomicBatchUpdateLastValue variable would then be written to from both main and realtime
 *    thread, and (2) that we then need a mechanism to release items in the list, which we can't
 *    do on the realtime thread.
 */

/*!
 *  关于原子批量更新的实现的一些注释，因为它有点棘手：
 *
 *  - 这通过使实时线程读取先前设置的值而不是新的值来工作。
 *
 *  - 我们需要防止在实时线程中的批量更新进行中检查立即由主线程进入批量更新并更改值的情况，因为这违反了原子性。(不能在更新的时候获取返回值)
 * 为此，我们使用互斥保护实时线程检查和返回。
 * 我们在实时线程中使用try锁，其失败方便地告诉我们批量更新正在发生，
 * 因此这是我们需要的唯一检查。
 *
 *  - 此机制要求在原子批量更新开始时，将先前设置的值（_atomicBatchUpdateLastValue）正确同步到当前值。
 *
 *  - setValue负责维护此同步。 但是它不能在批量更新期间这样做，否则就是违反目的。
 *
 *  - 因此，这被推迟到下一次时间同步需要时：在下一批次更新的开始。 我们通过在静态NSHashTable中跟踪这些延迟，并在批量更新方法的开始执行它们。
 *
 *  - 为了允许值被干净地解除分配，我们在这个集合中存储弱值，并且在dealloc中删除传出的实例。
 *
 *  - 旁注：一个替代的延迟实现是在实时线程上从提交函数执行批处理后更新同步，
 *  但是这引入了两个复杂性：（1）然后将从主线程和实时线程写入_atomicBatchUpdateLastValue变量，
 *  和（2）我们需要一个机制来释放列表中的项目，这是我们不能在实时线程上做的。
 *
 */
// 在更新的时候不能使用新值
+ (void)performAtomicBatchUpdate:(AKKAAEManagedValueUpdateBlock _Nonnull)block {
    if (!__atomicUpdateWaitingForCommit) {
        //对以前批次更新的值执行延迟同步到_atomicBatchUpdateLastValue
        for (AKKAAEManagedValue *value in __atomicUpdatedDeferredSyncValues) {
            value->_atomicBatchUpdateLastValue = value->_value;
        } // 将正在缓存的值都放到value位置上
        [__atomicUpdatedDeferredSyncValues removeAllObjects];// 因为是弱引用 ，所以就是把当前缓存的值都替换
    }

    if (__atomicUpdateCounter == 0) {
        // Wait for realtime thread to exit any GetValue calls
        pthread_rwlock_wrlock(&__atomicUpdateMutex); // 写锁开始
        // Mark that we're awaiting a commit
        __atomicUpdateWaitingForCommit = YES;
    }

    __atomicUpdateCounter ++;

    // Perform the updates
    block();
    
    __atomicUpdateCounter --;
    
    if (__atomicUpdateCounter == 0) {
        // Unlock, allowing GetValue to access _value again
        pthread_rwlock_unlock(&__atomicUpdateMutex);
    }
}

- (instancetype)init {
    if (!(self = [super init]))return nil;
    return self;
}

- (void)dealloc  {
    // Remove self from deferred sync list
    [__atomicUpdatedDeferredSyncValues removeObject:self];

    pthread_mutex_lock(&__pendingInstanceMutex);
    for (linkedlistitem_t * entry = __pendingInstances,* prior = NULL ; entry ; prior = entry ,entry = entry->next) {
        if (entry->data == (__bridge void *)self) {
            if (prior) {
                prior->next = entry->next;
            } else {
                __pendingInstances = entry->next;
            }
            free(entry);
            break;
        }
    }
    pthread_mutex_unlock(&__pendingInstanceMutex);

    // Perform any pending release
    if (_value)
        [self releaseOldValue:_value];

    linkedlistitem_t * release;
    while ( (release = OSAtomicDequeue(&_pendingReleaseQueue,offsetof(linkedlistitem_t,next))) ) {
        OSAtomicEnqueue(&_releaseQueue, release, offsetof(linkedlistitem_t, next));
    }
    [self pollReleaseList];
}

- (id)objectValue {
    NSAssert(!_valueSet || _isObjectValue, @"You can use objectValue or pointerValue, but not both");
    return (__bridge id)_value;
}

- (void)setObjectValue:(id)objectValue {
    NSAssert(!_valueSet || _isObjectValue, @"You can use objectValue or pointerValue, but not both");
    _isObjectValue = YES;
    [self setValue:(__bridge_retained void*)objectValue];
}

- (void *)pointerValue {
    NSAssert(!_valueSet || !_isObjectValue, @"You can use objectValue or pointerValue, but not both");
    return _value;
}

- (void)setPointerValue:(void *)pointerValue {
    NSAssert(!_valueSet || !_isObjectValue, @"You can use objectValue or pointerValue, but not both");
    [self setValue:pointerValue];
}

- (void)setValue:(void *)value {
    if (value == _value)  return;
    
    //assign new value
    void * oldvalue = _value;
    _value = value;
    _valueSet = YES;
    
    if (__atomicUpdateCounter == 0 && !__atomicUpdateWaitingForCommit) {
        // Sync value for recall on realtime thread during atomic batch update
        //同步在原子批量更新期间在实时线程上调用的值
        _atomicBatchUpdateLastValue = _value;
    } else {
        //延迟值同步
        // Defer value sync
        [__atomicUpdatedDeferredSyncValues addObject:self];
    }
    
    if (oldvalue) {
        // Mark old value as pending release - it'll be transferred to the release queue by
        // AEManagedValueGetValue on the audio thread
        // 将旧值标记为待释放 - 它将通过音频线程上的AEManagedValueGetValue传输到释放队列
        
        linkedlistitem_t * release = (linkedlistitem_t *)calloc(1, sizeof(linkedlistitem_t));
        release->data = oldvalue;
        
        OSAtomicEnqueue(&_pendingReleaseQueue, release, offsetof(linkedlistitem_t, next));
        _pendingReleaseCount++;
        
        if (!self.pollTimer) {
            // Start polling for pending releases
            // 开始轮询待处理的版本
            self.pollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                              target:[AKKAAEWeakRetainingProxy proxyWithTarget:self]
                                                            selector:@selector(pollReleaseList)
                                                            userInfo:nil
                                                             repeats:YES];
            self.pollTimer.tolerance = 0.5;
        }
        //将self添加到在 AEManagedValueCommitPendingUpdates里的实时线程内服务的实例列表
        // Add self to the list of instances to service on the realtime thread within AEManagedValueCommitPendingUpdates
        
        pthread_mutex_lock(&__pendingInstanceMutex);
        BOOL alreadyPresent = NO;
        for (linkedlistitem_t * entry = __pendingInstances; entry; entry = entry->next) {
            if (entry->data == (__bridge void *)self) {
                alreadyPresent = YES;
            }
        }
        if (!alreadyPresent) {
            linkedlistitem_t * entry = malloc(sizeof(linkedlistitem_t));
            entry->next = __pendingInstances;
            entry->data = (__bridge void * )self;
            __pendingInstances = entry;
        }
        pthread_mutex_unlock(&__pendingInstanceMutex);
    }
}

void AEManagedValueCommitPendingUpdates() {
#ifdef DEBUG
    if (AKKAAEManagedValueRealtimeThreadIdentifier && AKKAAEManagedValueRealtimeThreadIdentifier != pthread_self()) {
        if (AKKAAERateLimit()) printf("%s called from outside realtime thread\n", __FUNCTION__);
    }
#endif
    // Finish atomic update
    if (pthread_rwlock_tryrdlock(&__atomicUpdateMutex) == 0) {
        __atomicUpdateWaitingForCommit = NO;
        pthread_rwlock_unlock(&__atomicUpdateMutex);
    } else {
        // Still in the middle of an atomic update
        return;
    }
    
    //服务任何等待更新的实例，因此我们可以将旧值标记为可以释放
    if (pthread_mutex_trylock(&__pendingInstanceMutex) == 0) {
        linkedlistitem_t * lastEntry = NULL;
        for ( linkedlistitem_t * entry = __pendingInstances ; entry ; lastEntry = entry,entry = entry->next) {
            AKKAAEManagedValueServiceReleaseQueue((__bridge AKKAAEManagedValue *)entry->data);
        }
        if (lastEntry) {
            // Move Pending instances to serviced instance list, ready for cleanup on main thread;
            lastEntry->next = __servicedInstances;
            __servicedInstances = __pendingInstances;
            __pendingInstances = NULL;
        }
        pthread_mutex_unlock(&__pendingInstanceMutex);
    }
}

void * _Nullable AKKAAEManagedValueGetValue(__unsafe_unretained AKKAAEManagedValue * THIS) {
    if (!THIS) return NULL;
    if (__atomicUpdateWaitingForCommit || pthread_rwlock_tryrdlock(&__atomicUpdateMutex) != 0) {
        return THIS->_atomicBatchUpdateLastValue;
    }
    
    if (!pthread_main_np()) {
        AKKAAEManagedValueServiceReleaseQueue(THIS);
    }
    
    void * value = THIS->_value;
    pthread_rwlock_unlock(&__atomicUpdateMutex);
    return value;
}

void AKKAAEManagedValueServiceReleaseQueue(__unsafe_unretained AKKAAEManagedValue * THIS) {
#ifdef DEBUG
    if ( AKKAAEManagedValueRealtimeThreadIdentifier && AKKAAEManagedValueRealtimeThreadIdentifier != pthread_self() ) {
        if ( AKKAAERateLimit() ) printf("%p: %s called from outside realtime thread\n", THIS, __FUNCTION__);
    }
#endif
    linkedlistitem_t * release;
    while ((release = OSAtomicDequeue(&THIS->_pendingReleaseQueue, offsetof(linkedlistitem_t, next)))) {
        OSAtomicEnqueue(&THIS->_releaseQueue, release, offsetof(linkedlistitem_t, next));
    }
}

- (void)pollReleaseList {
    linkedlistitem_t * release ;
    while ( (release = OSAtomicDequeue(&_releaseQueue, offsetof(linkedlistitem_t, next)))) {
        NSAssert(release->data != _value, @"About to release value still in use");
        [self releaseOldValue:release->data];
        free(release);
        _pendingReleaseCount--;
    }
    
    if (_pendingReleaseCount == 0) {
        [self.pollTimer invalidate];
        self.pollTimer = nil;
    }
    
    pthread_mutex_lock(&__pendingInstanceMutex);
    for (linkedlistitem_t * entry = __servicedInstances , * prior = NULL; entry; prior = entry , entry = entry->next) {
        if (entry->data == (__bridge void *)self) {
            if (prior) {
                prior->next = entry->next;
            } else {
                __servicedInstances = entry->next;
            }
            free(entry);
            break;
        }
    }
    pthread_mutex_unlock(&__pendingInstanceMutex);
}

- (void)releaseOldValue:(void *)value {
    if (_releaseBlock) {
        _releaseBlock(value);
    } else if (_isObjectValue) {
        CFBridgingRelease(value);
    } else {
        free(value);
    }
    if (_releaseNotificationBlock) {
        _releaseNotificationBlock();
    }
}

@end
