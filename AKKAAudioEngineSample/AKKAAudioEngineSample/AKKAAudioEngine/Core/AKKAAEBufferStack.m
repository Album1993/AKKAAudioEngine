//
//  AKKAAEBufferStack.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/16.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAEBufferStack.h"
#import "AKKAAETypes.h"
#import "AKKAAEDSPUtilties.h"
#import "AKKAAEUtilities.h"

const UInt32 AKKAAEBufferStackMaxFramesPerSlice = 4096;
static const int kDefaultPoolSize = 16;

typedef struct _AKKAAEBufferStackBufferLinkedList {
    void * buffer;
    struct _AKKAAEBufferStackBufferLinkedList * next;
} AKKAAEBufferStackPoolEntry;

typedef struct {
    void * bytes;
    AKKAAEBufferStackPoolEntry * free;//在bufferlistpool中，这个是空的，在audiopool中，这个指的是没有用过的数据
    AKKAAEBufferStackPoolEntry * used;// 在bufferlistpool中，这个是有刚转化好的数据的意思，在audiopool中，这个指的是用过的数据
} AKKAAEBufferStackPool;

typedef struct {
    AudioTimeStamp timestamp;
    AudioBufferList audioBufferList;
} AKKAAEBufferStackBuffer;

struct AKKAAEBufferStack {
    int                         poolSize;
    int                         maxChannelsPerBuffer;
    UInt32                      frameCount; // 每一个声道一次切成的片数，默认为4096
    AudioTimeStamp              timeStamp;
    int                         stackCount;
    AKKAAEBufferStackPool       audioPool; /// 就是个结构存储要释放的和在用的两个链表
    AKKAAEBufferStackPool       bufferListPool;
};

static void AKKAAEBufferStackPoolInit(AKKAAEBufferStackPool * pool, int entries, size_t bytesPerEntry);
static void AKKAAEBufferStackPoolCleanup(AKKAAEBufferStackPool * pool);
static void AKKAAEBufferStackPoolReset(AKKAAEBufferStackPool * pool);
static void * AKKAAEBufferStackPoolGetNextFreeBuffer(AKKAAEBufferStackPool * pool);
static BOOL AKKAAEBufferStackPoolFreeBuffer(AKKAAEBufferStackPool * pool, void * buffer);
static void * AKKAAEBufferStackPoolGetUsedBufferAtIndex(const AKKAAEBufferStackPool * pool, int index);
static void AKKAAEBufferStackSwapTopTwoUsedBuffers(AKKAAEBufferStackPool * pool);

AKKAAEBufferStack * AKKAAEBufferStackNew(int poolSize) {
    return AKKAAEBufferStackNewWithOptions(poolSize, 2, 0);
}

// numberOfSingleChannelsBuffer 是将每一个声道的音频传入 所以就是声道数 * poolsize
AKKAAEBufferStack * AKKAAEBufferStackNewWithOptions(int poolSize, int maxChannelsPerBuffer, int numberOfSingleChannelBuffers) {
    if ( !poolSize) poolSize = kDefaultPoolSize;
    if ( !numberOfSingleChannelBuffers) numberOfSingleChannelBuffers = poolSize * maxChannelsPerBuffer;
    AKKAAEBufferStack * stack = (AKKAAEBufferStack *)calloc(1, sizeof(AKKAAEBufferStack));
    stack->poolSize = poolSize;
    stack->maxChannelsPerBuffer = maxChannelsPerBuffer;
    stack->frameCount = AKKAAEBufferStackMaxFramesPerSlice;
    //bytesPerBufferChannel = 4096 * sizeof(float) 一个声道所有切片的所有bytes
    //numberOfSingleChannelBuffers 有多少个片数据
    //bytesPerBufferChannel 一片数据多少byte
    size_t bytesPerBufferChannel = AKKAAEBufferStackMaxFramesPerSlice * AKKAAEAudioDescription.mBytesPerFrame;
    AKKAAEBufferStackPoolInit(&stack->audioPool, numberOfSingleChannelBuffers, bytesPerBufferChannel);
    
    // 以audiobufferlist 形式存储下来的链表
    size_t bytesPerBufferListEntry = sizeof(AKKAAEBufferStackBuffer) +((maxChannelsPerBuffer - 1) * sizeof(AudioBuffer));
    AKKAAEBufferStackPoolInit(&stack->bufferListPool, poolSize, bytesPerBufferListEntry);
    
    return stack;
}

void AKKAAEBufferStackFree(AKKAAEBufferStack * stack) {
    AKKAAEBufferStackPoolCleanup(&stack->audioPool);
    AKKAAEBufferStackPoolCleanup(&stack->bufferListPool);
    free(stack);
}

void AKKAAEBufferStackSetFrameCount(AKKAAEBufferStack * stack,UInt32 frameCount) {
    assert(frameCount <= AKKAAEBufferStackMaxFramesPerSlice);
    stack->frameCount = frameCount;
}

UInt32 AKKAAEBufferStackGetFrameCount(const AKKAAEBufferStack * stack) {
    return stack->frameCount;
}

void AKKAAEBufferStackSetTimeStamp(AKKAAEBufferStack * stack, const AudioTimeStamp * timestamp) {
    stack->timeStamp = *timestamp;
}

const AudioTimeStamp * AKKAAKKAAEBufferStackGetAEBufferStackGetTimeStamp(const AKKAAEBufferStack * stack) {
    return &stack->timeStamp;
}

int AKKAAEBufferStackGetPoolSize(const AKKAAEBufferStack * stack) {
    return stack->poolSize;
}

int AKKKAAEBufferStackGetMaximumChannelsPerBuffer(const AKKAAEBufferStack * stack) {
    return stack->maxChannelsPerBuffer;
}

int AKKAAEBufferStackCount(const AKKAAEBufferStack * stack) {
    return stack->stackCount;
}

// 因为用过了才知道，没用过不能有任何操作
const AudioBufferList * AKKAAEBufferStackGet(const AKKAAEBufferStack * stack, int index) {
    if ( index >= stack->stackCount ) return NULL;
    return &((const AKKAAEBufferStackBuffer*)AKKAAEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, index))->audioBufferList;
}

const AudioBufferList * AKKAAEBufferStackPush(AKKAAEBufferStack * stack, int count) {
    return AKKAAEBufferStackPushWithChannels(stack, count, 2);
}

#ifdef DEBUG
static void AKKAAEBufferStackPushFailed() {}
#endif

const AudioBufferList * AKKAAEBufferStackPushWithChannels(AKKAAEBufferStack * stack, int count, int channelCount) {
    assert(channelCount > 0);
    if (stack->stackCount + count > stack->poolSize) {
#ifdef DEBUG
        if ( AKKAAERateLimit() )
            printf("Couldn't push a buffer. Add a breakpoint on AEBufferStackPushFailed to debug.\n");
        AKKAAEBufferStackPushFailed();
#endif
        return NULL;
        
    }
    
    if ( channelCount > stack->maxChannelsPerBuffer ) {
#ifdef DEBUG
        if ( AKKAAERateLimit() )
            printf("Tried to push a buffer with too many channels. Add a breakpoint on AEBufferStackPushFailed to debug.\n");
        AKKAAEBufferStackPushFailed();
#endif
        return NULL;
    }
    
    //mBytesPerFrame 是sizeof（float）= 4 是因为是双声道的音频
    size_t sizePerBuffer = stack->frameCount * AKKAAEAudioDescription.mBytesPerFrame;
    AKKAAEBufferStackBuffer * first = NULL;
    
    for (int j = 0; j < count; j++) {
        // bufferlistpool 是用来存储转换好的bufferlistpool，貌似是空的
        AKKAAEBufferStackBuffer * buffer = (AKKAAEBufferStackBuffer *)AKKAAEBufferStackPoolGetNextFreeBuffer(&stack->bufferListPool);
        assert(buffer);
        if (!first) first = buffer;
        buffer->timestamp = stack->timeStamp;
        // 双声道就是两个buffer
        buffer->audioBufferList.mNumberBuffers = channelCount;
        for (int i = 0; i < channelCount; i++) {
            //每个buffer都是一个声道的数据
            buffer->audioBufferList.mBuffers[i].mNumberChannels = 1;
            //每个buffer就是4096个切片数据的集合
            buffer->audioBufferList.mBuffers[i].mDataByteSize = (UInt32)sizePerBuffer;
            //audiopool中的数据就是data
            buffer->audioBufferList.mBuffers[i].mData = AKKAAEBufferStackPoolGetNextFreeBuffer(&stack->audioPool);
            assert(buffer->audioBufferList.mBuffers[i].mData);
        }
        stack->stackCount ++;
    }
    // 将转换好的第一个的数据放出来，感觉是用来判断有没有可用的数据，在AKKAAEBufferStackDuplicate用到了
    return &first->audioBufferList;
}

const AudioBufferList * AKKAAEBufferStackDuplicate(AKKAAEBufferStack * stack) {
    if (stack->stackCount == 0) return NULL;
    const AKKAAEBufferStackBuffer * top = (const AKKAAEBufferStackBuffer *)AKKAAEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, 0);
    if (!top) return NULL;
    if ( !AKKAAEBufferStackPushWithChannels(stack, 1, top->audioBufferList.mNumberBuffers)) return NULL;
    AKKAAEBufferStackBuffer * duplicate = (AKKAAEBufferStackBuffer *)AKKAAEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, 0);
    for (int i = 0; i < duplicate->audioBufferList.mNumberBuffers; i++) {
        memcpy(duplicate->audioBufferList.mBuffers[i].mData,
               top->audioBufferList.mBuffers[i].mData,
               duplicate->audioBufferList.mBuffers[i].mDataByteSize);
    }
    duplicate->timestamp = top->timestamp;
    return &duplicate->audioBufferList;
}

void AKKAAEBufferStackSwap(AKKAAEBufferStack * stack) {
    AKKAAEBufferStackSwapTopTwoUsedBuffers(&stack->bufferListPool);
}

void AKKAAEBufferStackPop(AKKAAEBufferStack * stack, int count) {
    count = MIN(count, stack->stackCount);
    if (count == 0) {
        return;
    }
    for (int i = 0; i < count; i++) {
        AKKAAEBufferStackRemove(stack, 0);
    }
}

void AKKAAEBufferStackRemove(AKKAAEBufferStack * stack, int index) {
    AKKAAEBufferStackBuffer * buffer = (AKKAAEBufferStackBuffer *)AKKAAEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, index);
    if (!buffer) {
        return;
    }
    for (int j = buffer->audioBufferList.mNumberBuffers - 1; j >= 0; j--) {
        // Free buffers in reverse order, so that they're in correct order if we push again
        AKKAAEBufferStackPoolFreeBuffer(&stack->audioPool, buffer->audioBufferList.mBuffers[j].mData);
    }
    AKKAAEBufferStackPoolFreeBuffer(&stack->bufferListPool, buffer);
    stack->stackCount--;
}

const AudioBufferList * AKKAAEBufferStackMix(AKKAAEBufferStack * stack,int count) {
    return AKKAAEBufferStackMixWithGain(stack, count, NULL);
}

const AudioBufferList * AKKAAEBufferStackMixWithGain(AKKAAEBufferStack * stack, int count,const float * gains) {
    if (count != 0 && count < 2) return NULL;
    
    for (int i = 1; count ? i < count : i; i++) {
        const AudioBufferList * abl1 = AKKAAEBufferStackGet(stack, 0);
        const AudioBufferList * abl2 = AKKAAEBufferStackGet(stack, 1);
        // 如果其中有一个没有 那么就返回第一个的，要么有，要么没有
        if (!abl1 || !abl2) return AKKAAEBufferStackGet(stack, 0);
        // 因为是从1开始计数，但gains[0]是从0开始
        float abl1Gain = i == 1 && gains ? gains[0] : 1.0;
        float abl2Gain = gains ? gains[i] : 1.0;
        //用少的那个开始校准
        if (abl2->mNumberBuffers < abl1->mNumberBuffers) {
            // Swap abl1 and abl2, so that we're writing into the buffer with more channels
            AKKAAEBufferStackSwap(stack);
            abl1 = AKKAAEBufferStackGet(stack, 0);
            abl2 = AKKAAEBufferStackGet(stack, 1);
            float tmp = abl1Gain;
            abl2Gain = abl1Gain;
            abl1Gain = tmp;
        }
        
        AKKAAEBufferStackPop(stack, 1);
        
        // 先将abl1开始变换
        if (i == 1 && abl1Gain != 1.0f) {
            AKKAAEDSPApplyGain(abl1, abl1Gain, stack->frameCount);
        }
        // 再将两个合成
        AKKAAEDSPMix(abl1, abl2, 1, abl2Gain, YES, stack->frameCount, abl2);
    }
    return AKKAAEBufferStackGet(stack, 0);
}

void AKKAAEBufferStackApplyFaders (AKKAAEBufferStack * stack,
                                   float targetVolume,
                                   float * currentVolume,
                                   float targetBalance,
                                   float * currentBalance) {
    const AudioBufferList * abl = AKKAAEBufferStackGet(stack, 0);
    if (!abl) return;
    if (fabs(targetBalance) > FLT_EPSILON) {
        // Make mono buffer stereo
        float * priorBuffer = abl->mBuffers[0].mData;
        AKKAAEBufferStackPop(stack, 1);
        abl = AKKAAEBufferStackPushWithChannels(stack, 1, 2);
        if (!abl) {// 转双声道失败
            // Restore prior buffer and bail
            AKKAAEBufferStackPushWithChannels(stack, 1, 1);
            return;
        }
        if (abl->mBuffers[0].mData != priorBuffer) {
            memcpy(abl->mBuffers[1].mData, priorBuffer, abl->mBuffers[1].mDataByteSize);
        }
        // 转双声道就是复制下
        memcpy(abl->mBuffers[1].mData, priorBuffer, abl->mBuffers[1].mDataByteSize);
    }
    AKKAAEDSPApplyVolumeAndBalance(abl, targetVolume, currentVolume, targetBalance, currentBalance, stack->frameCount);
}

void AKKAAEBufferStackSilence(AKKAAEBufferStack * stack) {
    const AudioBufferList * abl = AKKAAEBufferStackGet(stack, 0);
    if (!abl) return;
    AKKAAEAudioBufferListSilence(abl, 0, stack->frameCount);
}

void AKKAAEBufferStackMixToBufferList(AKKAAEBufferStack * stack, int bufferCount, const AudioBufferList * output) {
    // mix stackItems
    for (int i = 0; bufferCount ? 1 < bufferCount : 1; i++) {
        const AudioBufferList * abl = AKKAAEBufferStackGet(stack, i);
        if (!abl) return;
        AKKAAEDSPMix(abl,output,1,1,YES,stack->frameCount,output);
    }
}

void AKKAAEBufferStackMixToBufferListChannels(AKKAAEBufferStack * stack, int bufferCount, AKKAAEChannelSet channels, const AudioBufferList * output) {
    // Setup output buffer
    AKKAAEAudioBufferListCopyOnStackWithChannelSubset(outputBuffer,output,channels);
    
    for (int i = 0; bufferCount ? i < bufferCount : 1 ; i++) {
        const AudioBufferList * abl = AKKAAEBufferStackGet(stack, i);
        if (! abl) return;
        AKKAAEDSPMix(abl, outputBuffer, 1, 1, YES, stack->frameCount, outputBuffer);
    }
}

AudioTimeStamp * AKKAAEBufferStackGetTimeStampForBuffer(AKKAAEBufferStack * stack, int index) {
    if (index >= stack->stackCount) return NULL;
    return &((AKKAAEBufferStackBuffer * ) AKKAAEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, index))->timestamp;
}

void AKKAAEBufferStackReset(AKKAAEBufferStack * stack) {
    AKKAAEBufferStackPoolReset(&stack->audioPool);
    AKKAAEBufferStackPoolReset(&stack->bufferListPool);
    stack->stackCount = 0;
}

#pragma mark - Helpers

static void AKKAAEBufferStackPoolInit(AKKAAEBufferStackPool * pool, int entries,size_t bytesPerEntry) {
    pool->bytes = malloc(entries * bytesPerEntry);
    pool->used = NULL;
    
    AKKAAEBufferStackPoolEntry ** nextPtr = &pool->free;
    for (int i = 0; i < entries; i++) {
        AKKAAEBufferStackPoolEntry * entry = (AKKAAEBufferStackPoolEntry *)calloc(1, sizeof(AKKAAEBufferStackPoolEntry));
        entry->buffer = pool->bytes + (i * bytesPerEntry);
        * nextPtr = entry;
        nextPtr = &entry->next;
    }
}

static void AKKAAEBufferStackPoolCleanup(AKKAAEBufferStackPool * pool) {
    while (pool->free) {
        AKKAAEBufferStackPoolEntry * next = pool->free->next;
        free(pool->free);
        pool->free = next;
    }
    
    while (pool->used) {
        AKKAAEBufferStackPoolEntry * next = pool->free->next;
        free(pool->used);
        pool->used = next;
    }
    // 清空这个pool free 和used 都清空
    free(pool->bytes);
}

static void AKKAAEBufferStackPoolReset(AKKAAEBufferStackPool * pool) {
    // Return all used buffers back to the free list
    // 将used倒序填充到free中 将每一个used的第一个都压到free中
    AKKAAEBufferStackPoolEntry * entry = pool->used;
    while (entry) {
        // Point top entry at beginning of free list, and point free list to top entry (i.e. insert into free list)
        AKKAAEBufferStackPoolEntry * next = entry->next;
        entry->next = pool->free;
        pool->free = entry;
        
        entry = next;
    }
    pool->used = NULL;
}

// 每次获取到一个free buffer 都将 buffer 添加进used
static void * AKKAAEBufferStackPoolGetNextFreeBuffer(AKKAAEBufferStackPool * pool) {
    // Get entry at top of free list
    AKKAAEBufferStackPoolEntry * entry = pool->free;
    if (!entry) return NULL;
    
    // Point free list at next entry (i.e. remove the top entry from the list)
    pool->free = entry->next;
    
    // Point top entry at beginning of used list, and point used list to top entry (i.e. insert into used list)
    entry->next = pool->used;
    pool->used = entry;
    
    return entry->buffer;
}

static BOOL AKKAAEBufferStackPoolFreeBuffer(AKKAAEBufferStackPool * pool,void * buffer) {
    
    AKKAAEBufferStackPoolEntry * entry = NULL;
    
    if (pool->used && pool->used->buffer == buffer) {
        // Found the corresponding entry at the top. Remove it from the used list.
        // 如果是第一个就是要删除的buffer，直接将这个entry移除链表
        entry = pool->used;
        pool->used = entry->next;
    } else {
        // Find it in the list, and note the preceding item
        // 在链表中的话就在链表中删除
        AKKAAEBufferStackPoolEntry * preceding = pool->used;
        while (preceding && preceding->next && preceding->next->buffer != buffer) {
            preceding = preceding->next;
        }
        if (preceding && preceding->next) {
            // Found it. Remove it from the list
            entry = preceding->next;
            preceding->next = entry->next;
        }
    }
    
    if (!entry) {
        return NO;
    }
    
    // Point top entry at beginning of free list, and point free list to top entry (i.e. insert into free list)
    
    entry->next = pool->free;
    pool->free = entry;
    return YES;
}

static void * AKKAAEBufferStackPoolGetUsedBufferAtIndex(const AKKAAEBufferStackPool * pool ,int index) {
    AKKAAEBufferStackPoolEntry * entry = pool->used;
    for (int i = 0; i < index && entry; i++) {
        entry = entry->next;
    }
    return entry ? entry->buffer : NULL;
}

static void AKKAAEBufferStackSwapTopTwoUsedBuffers(AKKAAEBufferStackPool * pool) {
    AKKAAEBufferStackPoolEntry * entry = pool->used;
    if (!entry) return;
    AKKAAEBufferStackPoolEntry * next = entry->next;
    if (!next) return;
    
    entry->next = next->next;
    next->next = entry;
    pool->used = next;
}







