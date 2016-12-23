//
//  AKKAAEAudioBufferListUtilities.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/16.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAEAudioBufferListUtilities.h"

AudioBufferList *AKKAAEAudioBufferListCreate(int frameCount) {
    return AKKAAEAudioBufferListCreateWithFormat(AKKAAEAudioDescription, frameCount);
}

AudioBufferList *AKKAAEAudioBufferListCreateWithFormat(AudioStreamBasicDescription audioFormat, int frameCount) {
    // kAudioFormatFlagIsNonInterleaved 和 mChannelsPerFrame 有关
    int numberOfBuffers = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? audioFormat.mChannelsPerFrame : 1;
    int channelsPerBuffer = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : audioFormat.mChannelsPerFrame;
    int bytesPerBuffer = audioFormat.mBytesPerFrame * frameCount;
    
    AudioBufferList *audio = malloc(sizeof(AudioBufferList) + (numberOfBuffers - 1) * sizeof(AudioBuffer));
    if (!audio) {
        return NULL;
    }
    
    audio->mNumberBuffers = numberOfBuffers;
    for (int i = 0; i < numberOfBuffers; i++) {
        if (bytesPerBuffer > 0) {
            audio->mBuffers[i].mData = calloc(bytesPerBuffer, 1);
            if (!audio->mBuffers[i].mData) {// 一个没初始化好就会全部清空
                for (int j = 0; j < i; j++) free(audio->mBuffers[j].mData);
                free(audio);
                return NULL;
            }
        } else {
            audio->mBuffers[i].mData = NULL;
        }
        audio->mBuffers[i].mDataByteSize = bytesPerBuffer;
        audio->mBuffers[i].mNumberChannels = channelsPerBuffer;
    }
    return audio;
}

AudioBufferList *AKKAAEAudioBufferListCopy(const AudioBufferList *original) {
    AudioBufferList * audio = malloc(sizeof(AudioBufferList) + (original->mNumberBuffers - 1) * sizeof(AudioBuffer));
    if (!audio) {
        return NULL;
    }
    
    audio->mNumberBuffers = original->mNumberBuffers;
    for (int i = 0; i < original->mNumberBuffers; i++) {
        audio->mBuffers[i].mData = malloc(original->mBuffers[i].mDataByteSize);
        if (!audio->mBuffers[i].mData) {
            for (int j = 0; j < i; j++) free(audio->mBuffers[j].mData);
            free(audio);
            return NULL;
        }
        audio->mBuffers[i].mDataByteSize = original->mBuffers[i].mDataByteSize;
        audio->mBuffers[i].mNumberChannels = original->mBuffers[i].mNumberChannels;
        memcpy(audio->mBuffers[i].mData, original->mBuffers[i].mData, original->mBuffers[i].mDataByteSize);
    }
    return audio;
}

void AKKAAEAudioBufferListFree(AudioBufferList *bufferList ) {
    for ( int i=0; i<bufferList->mNumberBuffers; i++ ) {
        if ( bufferList->mBuffers[i].mData ) free(bufferList->mBuffers[i].mData);
    }
    free(bufferList);
}

UInt32 AKKAAEAudioBufferListGetLength(const AudioBufferList *bufferList, int *oNumberOfChannels) {
    return AKKAAEAudioBufferListGetLengthWithFormat(bufferList, AKKAAEAudioDescription, oNumberOfChannels);
}

UInt32 AKKAAEAudioBufferListGetLengthWithFormat(const AudioBufferList * bufferList,
                                                AudioStreamBasicDescription audioFormat,
                                                int *oNumberOfChannels) {
    if (oNumberOfChannels) {
        *oNumberOfChannels = audioFormat.mFormatFlags * kAudioFormatFlagIsNonInterleaved ? bufferList->mNumberBuffers : bufferList->mBuffers[0].mNumberChannels;
    }
    return bufferList->mBuffers[0].mDataByteSize / audioFormat.mBytesPerFrame;
}

void AKKAAEAudioBufferListSetLength(AudioBufferList * bufferList,UInt32 frames) {
    return AKKAAEAudioBufferListSetLengthWithFormat(bufferList, AKKAAEAudioDescription, frames);
}

void AKKAAEAudioBufferListSetLengthWithFormat(AudioBufferList * bufferList,
                                              AudioStreamBasicDescription audioFormat,
                                              UInt32 frames) {
    for (int i = 0; i < bufferList->mNumberBuffers; i++) {
        bufferList->mBuffers[i].mDataByteSize = frames * audioFormat.mBytesPerFrame;
    }
}

void AKKAAEAudioBufferListOffset(AudioBufferList *bufferList, UInt32 frames) {
    return AKKAAEAudioBufferListOffsetWithFormat(bufferList, AKKAAEAudioDescription, frames);
}

void AKKAAEAudioBufferListOffsetWithFormat(AudioBufferList * bufferList,
                                           AudioStreamBasicDescription audioFormat,
                                           UInt32 frames) {
    for (int i = 0; i < bufferList->mNumberBuffers; i++) {
        bufferList->mBuffers[i].mData = (char *)bufferList->mBuffers[i].mData + frames * audioFormat.mBytesPerFrame;
        bufferList->mBuffers[i].mDataByteSize -= frames * audioFormat.mBytesPerFrame;
    }
}

void AKKAAEAudioBufferListAssign(AudioBufferList * target, const AudioBufferList * source,UInt32 offset,UInt32 length) {
    AKKAAEAudioBufferListAssignWithFormat(target, source, AKKAAEAudioDescription, offset, length);
}

void AKKAAEAudioBufferListAssignWithFormat(AudioBufferList * target,const AudioBufferList * source,AudioStreamBasicDescription audioFormat,UInt32 offset,UInt32 length){
    target->mNumberBuffers = source->mNumberBuffers;
    for (int i = 0; i < source->mNumberBuffers; i++) {
        target->mBuffers[i].mNumberChannels = source->mBuffers[i].mNumberChannels;
        target->mBuffers[i].mData = source->mBuffers[i].mData + (offset * audioFormat.mBytesPerFrame);
        target->mBuffers[i].mDataByteSize = length * audioFormat.mBytesPerFrame;
    }
}

void AKKAAEBufferListSilence(const AudioBufferList * bufferList, UInt32 offset, UInt32 length) {
    return AKKAAEAudioBufferListSilenceWithFormat(bufferList, AKKAAEAudioDescription, offset, length);
}

void AKKAAEBufferListSilenceWithFormat(const AudioBufferList * bufferList, AudioStreamBasicDescription audioFormat, UInt32 offset, UInt32 length) {
    for (int i = 0; i < bufferList->mNumberBuffers; i++) {
        memset((char *)bufferList->mBuffers[i].mData + offset * audioFormat.mBytesPerFrame, 0, length * audioFormat.mBytesPerFrame);
    }
}
// offset 是将声音变短
void AKKAAEAudioBufferListCopyContents(const AudioBufferList * target, const AudioBufferList * source,UInt32 targetOffset,UInt32 sourceOffset,UInt32 length) {
    AKKAAEAudioBufferListCopyContentsWithFormat(target,
                                                source,
                                                AKKAAEAudioDescription,
                                                targetOffset,
                                                sourceOffset,
                                                length);
}

void AKKAAEAudioBufferListCopyContentsWithFormat(const AudioBufferList * target,
                                                 const AudioBufferList * source,
                                                 AudioStreamBasicDescription audioFormat,
                                                 UInt32 targetOffset,
                                                 UInt32 sourceOffset,
                                                 UInt32 length) {
    for (int i = 0; i < MIN(target->mNumberBuffers, source->mNumberBuffers); i++) {
        memcpy(target->mBuffers[i].mData + (targetOffset * audioFormat.mBytesPerFrame),
               source->mBuffers[i].mData + (sourceOffset * audioFormat.mBytesPerFrame),
               length * audioFormat.mBytesPerFrame);
    }
}
