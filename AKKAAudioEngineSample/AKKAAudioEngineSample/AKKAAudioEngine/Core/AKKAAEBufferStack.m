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
    void * buffer;
    AKKAAEBufferStackPoolEntry * free;
    AKKAAEBufferStackPoolEntry * used;
} AKKAAEBufferStackPool;

typedef struct {
    AudioTimeStamp timestamp;
    AudioBufferList audioBufferList;
} AKKAAEBufferStackBuffer;

struct AKKAAEBufferStack {
    int                         poolSize;
    int                         maxChannelsPerBuffer;
    UInt32                      frameCount;
    AudioTimeStamp              timeStamp;
    int                         stackCount;
    AKKAAEBufferStackPool       audioPool;
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

AKKAAEBufferStack * AKKAAEBufferStackNewWithOptions(int poolSize, int maxChannelsPerBuffer, int numberOfSingleChannelBuffers) {
    if ( !poolSize) poolSize = kDefaultPoolSize;
    if ( !numberOfSingleChannelBuffers) numberOfSingleChannelBuffers = poolSize * maxChannelsPerBuffer;
    AKKAAEBufferStack * stack = (AKKAAEBufferStack *)calloc(1, sizeof(AKKAAEBufferStack));
    stack->poolSize = poolSize;
    stack->maxChannelsPerBuffer = maxChannelsPerBuffer;
    stack->frameCount = AKKAAEBufferStackMaxFramesPerSlice;
    
    size_t bytesPerBufferChannel = AKKAAEBufferStackMaxFramesPerSlice * AKKAAEAudioDescription.mBytesPerFrame;
    AKKAAEBufferStackPoolInit(&stack->audioPool, numberOfSingleChannelBuffers, bytesPerBufferChannel);
    
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

const AudioTimeStamp * AEBufferStackGetTimeStamp(const AKKAAEBufferStack * stack) {
    return &stack->timeStamp;
}

int AKKAAEBufferStackGetPoolSize(const AKKAAEBufferStack * stack) {
    return stack->poolSize;
}

int AEBufferStackGetMaximumChannelsPerBuffer(const AKKAAEBufferStack * stack) {
    return stack->maxChannelsPerBuffer;
}

int AKKAAEBufferStackCount(const AKKAAEBufferStack * stack) {
    return stack->stackCount;
}

const AudioBufferList * AEBufferStackGet(const AKKAAEBufferStack * stack, int index) {
    if ( index >= stack->stackCount ) return NULL;
    return &((const AKKAAEBufferStackBuffer*)AKKAAEBufferStackPoolGetUsedBufferAtIndex(&stack->bufferListPool, index))->audioBufferList;
}

const AudioBufferList * AEBufferStackPush(AKKAAEBufferStack * stack, int count) {
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
    
    size_t sizePerBuffer = stack->frameCount * AKKAAEAudioDescription.mBytesPerFrame;
    AKKAAEBufferStackBuffer * first = NULL;
    for (int j = 0; j < count; j++) {
        AKKAAEBufferStackBuffer * buffer = (AKKAAEBufferStackBuffer *)AKKAAEBufferStackPoolGetNextFreeBuffer(&stack->bufferListPool);
        assert(buffer);
        if (!first) first = buffer;
        buffer->timestamp = stack->timeStamp;
        buffer->audioBufferList.mNumberBuffers = channelCount;
        for (int i = 0; i < channelCount; i++) {
            buffer->audioBufferList.mBuffers[i].mNumberChannels = 1;
            buffer->audioBufferList.mBuffers[i].mDataByteSize = (UInt32)sizePerBuffer;
            buffer->audioBufferList.mBuffers[i].mData = AKKAAEBufferStackPoolGetNextFreeBuffer(&stack->audioPool);
            assert(buffer->audioBufferList.mBuffers[i].mData);
        }
        stack->stackCount ++;
    }
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
        if (!abl1 || abl2) return AKKAAEBufferStackGet(stack, 0);
        float abl1Gain = i == 1 && gains ? gains[0] : 1.0;
        float abl2Gain = gains ? gains[i] : 1.0;
        
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
        
        if (i == 1 && abl1Gain != 1.0f) {
            AKKAAEDSPApplyGain(abl1, abl1Gain, stack->frameCount);
        }
        
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
        if (!abl) {
            // Restore prior buffer and bail
            AKKAAEBufferStackPushWithChannels(stack, 1, 1);
            return;
        }
        if (abl->mBuffers[0].mData != priorBuffer) {
            memcpy(abl->mBuffers[1].mData, priorBuffer, abl->mBuffers[1].mDataByteSize);
        }
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
    AKKAAEAudioBufferListCopyOnStackWithChannelSubset();
}
















