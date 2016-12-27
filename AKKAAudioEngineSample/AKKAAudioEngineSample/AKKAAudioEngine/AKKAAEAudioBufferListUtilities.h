//
//  AKKAAEAudioBufferListUtilities.h
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/16.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AKKAAETypes.h"

/*!
* Allocate an audio buffer list and the associated mData pointers, using the default audio format.
*
*  Note: Do not use this utility from within the Core Audio thread (such as inside a render
*  callback). It may cause the thread to block, inducing audio stutters.
*
*注意：不要在Core Audio线程中使用此实用程序（例如，在render回调中）。 它可能导致线程阻塞，引发音频停顿。
*
* @param frameCount The number of frames to allocate space for (or 0 to just allocate the list structure itself)
* @return The allocated and initialised audio buffer list
*/

AudioBufferList * AKKAAudioBufferListCreate(int frameCount);

/*!
* Allocate an audio buffer list and the associated mData pointers, with a custom audio format.
*
*  Note: Do not use this utility from within the Core Audio thread (such as inside a render
*  callback). It may cause the thread to block, inducing audio stutters.
*
* 注意：不要在Core Audio线程中使用此实用程序（例如，在render回调中）。 它可能导致线程阻塞，引发音频停顿。
*
* @param audioFormat Audio format describing audio to be stored in buffer list
* @param frameCount The number of frames to allocate space for (or 0 to just allocate the list structure itself)
* @return The allocated and initialised audio buffer list
*/
AudioBufferList *AKKAAEAudioBufferListCreateWithFormat(AudioStreamBasicDescription audioFormat, int frameCount);

/*!
* Create an audio buffer list on the stack, using the default audio format.
*
*  This is useful for creating buffers for temporary use, without needing to perform any
*  memory allocations. It will create a local AudioBufferList* variable on the stack, with
*  a name given by the first argument, and initialise the buffer according to the given
*  audio format.
*
*  这对于创建临时使用的缓冲区很有用，无需执行任何内存分配。
*  它将在堆栈上创建一个本地AudioBufferList *变量，其名称由第一个参数给定，并根据给定的音频格式初始化缓冲区。
*
*  The created buffer will have NULL mData pointers and 0 mDataByteSize: you will need to
*  assign these to point to a memory buffer.
*
* @param name Name of the variable to create on the stack
*/
#define AKKAAEAudioBufferListCreateOnStack(name) \
AKKAAEAudioBufferListCreateOnStackWithFormat(name, AKKAAEAudioDescription)

/*!
* Create an audio buffer list on the stack, with a custom audio format.
*
*  This is useful for creating buffers for temporary use, without needing to perform any
*  memory allocations. It will create a local AudioBufferList* variable on the stack, with
*  a name given by the first argument, and initialise the buffer according to the given
*  audio format.
*
*  这对于创建临时使用的缓冲区很有用，无需执行任何内存分配。
*  它将在堆栈上创建一个本地AudioBufferList *变量，其名称由第一个参数给定，并根据给定的音频格式初始化缓冲区。
*
*  The created buffer will have NULL mData pointers and 0 mDataByteSize: you will need to
*  assign these to point to a memory buffer.
*
* @param name Name of the variable to create on the stack
* @param audioFormat The audio format to use
*/

/*
* AKKAAEAudioBufferListCreateOnStackWithFormat( name, audioFormat) {
* int name_numberBuffers = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? audioFormat.mChannelsPerFrame : 1;
* char name_bytes[sizeof(AudioBufferList) + (sizeof(AudioBuffer) * (name_numberBuffers - 1))];
* memset(&name_bytes, 0, sizeof(name_bytes));
* AudioBufferList * name = (AudioBufferList*)name_bytes;
* name->mNumberBuffers = name_numberBuffers;
* for ( int i=0; i<name->mNumberBuffers; i++ ) {
* name->mBuffers[i].mNumberChannels
* = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : audioFormat.mChannelsPerFrame;
* }
* }
*/
#define AKKAAEAudioBufferListCreateOnStackWithFormat(name, audioFormat) \
int name ## _numberBuffers = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved \
? audioFormat.mChannelsPerFrame : 1; \
char name ## _bytes[sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(name ## _numberBuffers-1))]; \
memset(&name ## _bytes, 0, sizeof(name ## _bytes)); \
AudioBufferList * name = (AudioBufferList*)name ## _bytes; \
name->mNumberBuffers = name ## _numberBuffers; \
for ( int i=0; i<name->mNumberBuffers; i++ ) { \
name->mBuffers[i].mNumberChannels \
= audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : audioFormat.mChannelsPerFrame; \
}


/*!
* Create a stack copy of the given audio buffer list and offset mData pointers
*
*  This is useful for creating buffers that point to an offset into the original buffer,
*  to fill later regions of the buffer. It will create a local AudioBufferList* variable
*  on the stack, with a name given by the first argument, copy the original AudioBufferList
*  structure values, and offset the mData and mDataByteSize variables.
*
*  这对于创建指向原始缓冲区中的偏移量的缓冲区以填充缓冲区的后续区域很有用。
*  它将在堆栈上创建一个本地AudioBufferList *变量，其名称由第一个参数给出，复制原始AudioBufferList结构值，并偏移mData和mDataByteSize变量。
*
*  Note that only the AudioBufferList structure itself will be copied, not the data to
*  which it points.
*  注意，只有AudioBufferList结构本身将被复制，而不是它指向的数据。
*
* @param name Name of the variable to create on the stack
* @param sourceBufferList The original buffer list to copy
* @param offsetFrames Number of frames of noninterleaved float to offset mData/mDataByteSize members
*/
#define AKKAAEAudioBufferListCopyOnStack(name, sourceBufferList, offsetFrames) \
AKKAAEAudioBufferListCopyOnStackWithByteOffset(name, sourceBufferList, offsetFrames * AKKAAEAudioDescription.mBytesPerFrame)

/*!
* Create a stack copy of the given audio buffer list and offset mData pointers, with offset in bytes
*
*  This is useful for creating buffers that point to an offset into the original buffer,
*  to fill later regions of the buffer. It will create a local AudioBufferList* variable
*  on the stack, with a name given by the first argument, copy the original AudioBufferList
*  structure values, and offset the mData and mDataByteSize variables.
*
*  Note that only the AudioBufferList structure itself will be copied, not the data to
*  which it points.
*
* @param name Name of the variable to create on the stack
* @param sourceBufferList The original buffer list to copy
* @param offsetBytes Number of bytes to offset mData/mDataByteSize members
*/

/*
* AKKAAEAudioBufferListCopyOnStackWithByteOffset(name, sourceBufferList, offsetBytes) {
* char name_bytes[sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(sourceBufferList->mNumberBuffers-1))];
* memcpy(name_bytes, sourceBufferList, sizeof(name_bytes));
* AudioBufferList * name = (AudioBufferList*)name_bytes;
* for ( int i=0; i<name->mNumberBuffers; i++ ) {
*  name->mBuffers[i].mData = (char*)name->mBuffers[i].mData + offsetBytes;
*  name->mBuffers[i].mDataByteSize -= offsetBytes;
*  }
* }
*/
#define AKKAAEAudioBufferListCopyOnStackWithByteOffset(name, sourceBufferList, offsetBytes) \
char name ## _bytes[sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(sourceBufferList->mNumberBuffers-1))]; \
memcpy(name ## _bytes, sourceBufferList, sizeof(name ## _bytes)); \
AudioBufferList * name = (AudioBufferList*)name ## _bytes; \
for ( int i=0; i<name->mNumberBuffers; i++ ) { \
name->mBuffers[i].mData = (char*)name->mBuffers[i].mData + offsetBytes; \
name->mBuffers[i].mDataByteSize -= offsetBytes; \
}

/*!
* Create a stack copy of an audio buffer list that points to a subset of its channels
* 创建指向其通道子集的音频缓冲区列表的堆栈副本
* @param name Name of the variable to create on the stack
* @param sourceBufferList The original buffer list to copy
* @param channelSet The subset of channels
*/

/*
* AKKAAEAudioBufferListCopyOnStackWithChannelSubset(name, sourceBufferList, channelSet) {
* // 预防出现负数
* int name_bufferCount = MIN(sourceBufferList->mNumberBuffers-1, channelSet.lastChannel) - MIN(sourceBufferList->mNumberBuffers-1, channelSet.firstChannel) + 1;
 * // 初始化audiobufferlist
* char name_bytes[sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(name_bufferCount-1))];
* AudioBufferList * name = (AudioBufferList*)name_bytes;
* name->mNumberBuffers = name_bufferCount;
* memcpy(name->mBuffers, &sourceBufferList->mBuffers[MIN(sourceBufferList->mNumberBuffers-1, channelSet.firstChannel)],sizeof(AudioBuffer) * name_bufferCount);
* }
*/
#define AKKAAEAudioBufferListCopyOnStackWithChannelSubset(name, sourceBufferList, channelSet) \
int name ## _bufferCount = MIN(sourceBufferList->mNumberBuffers-1, channelSet.lastChannel) - \
MIN(sourceBufferList->mNumberBuffers-1, channelSet.firstChannel) + 1; \
char name ## _bytes[sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(name ## _bufferCount-1))]; \
AudioBufferList * name = (AudioBufferList*)name ## _bytes; \
name->mNumberBuffers = name ## _bufferCount; \
memcpy(name->mBuffers, &sourceBufferList->mBuffers[MIN(sourceBufferList->mNumberBuffers-1, channelSet.firstChannel)], \
sizeof(AudioBuffer) * name ## _bufferCount);

/*!
* Create a copy of an audio buffer list
*
*  Note: Do not use this utility from within the Core Audio thread (such as inside a render
*  callback). It may cause the thread to block, inducing audio stutters.
*
* @param original The original AudioBufferList to copy
* @return The new, copied audio buffer list
*/
AudioBufferList *AKKAAEAudioBufferListCopy(const AudioBufferList *original);

/*!
* Free a buffer list and associated mData buffers
*
*  Note: Do not use this utility from within the Core Audio thread (such as inside a render
*  callback). It may cause the thread to block, inducing audio stutters.
*/
void AKKAAEAudioBufferListFree(AudioBufferList *bufferList);

/*!
* Get the number of frames in a buffer list, with the default audio format
*
*  Calculates the frame count in the buffer list based on the given
*  audio format. Optionally also provides the channel count.
*
* @param bufferList  Pointer to an AudioBufferList containing audio
* @param oNumberOfChannels If not NULL, will be set to the number of channels of audio in 'list'
* @return Number of frames in the buffer list
*/
UInt32 AKKAAEAudioBufferListGetLength(const AudioBufferList *bufferList, int *oNumberOfChannels);

/*!
* Get the number of frames in a buffer list, with a custom audio format
*
*  Calculates the frame count in the buffer list based on the given
*  audio format. Optionally also provides the channel count.
*
* @param bufferList Pointer to an AudioBufferList containing audio
* @param audioFormat Audio format describing the audio in the buffer list
* @param oNumberOfChannels If not NULL, will be set to the number of channels of audio in 'list'
* @return Number of frames in the buffer list
*/
UInt32 AKKAAEAudioBufferListGetLengthWithFormat(const AudioBufferList *bufferList,
                        AudioStreamBasicDescription audioFormat,
                        int *oNumberOfChannels);
/*!
* Set the number of frames in a buffer list, with the default audio format
*
*  Calculates the frame count in the buffer list based on the given
*  audio format, and assigns it to the buffer list members.
*
* @param bufferList Pointer to an AudioBufferList containing audio
* @param frames The number of frames to set
*/
void AKKAAEAudioBufferListSetLength(AudioBufferList *bufferList, UInt32 frames);

/*!
* Set the number of frames in a buffer list, with a custom audio format
*
*  Calculates the frame count in the buffer list based on the given
*  audio format, and assigns it to the buffer list members.
*
* @param bufferList Pointer to an AudioBufferList containing audio
* @param audioFormat Audio format describing the audio in the buffer list
* @param frames The number of frames to set
*/
void AKKAAEAudioBufferListSetLengthWithFormat(AudioBufferList *bufferList,
                      AudioStreamBasicDescription audioFormat,
                      UInt32 frames);

/*!
*  Offset the pointers in a buffer list, with the default audio format
*  使用默认的音频格式偏移缓冲区列表中的指针
*  Increments the mData pointers in the buffer list by the given number
*  of frames. This is useful for filling a buffer in incremental stages.
*  将缓冲区列表中的mData指针增加给定的帧数。 这对于以增量阶段填充缓冲区很有用。
* @param bufferList Pointer to an AudioBufferList containing audio
* @param frames The number of frames to offset the mData pointers by
*/
void AKKAAEAudioBufferListOffset(AudioBufferList *bufferList, UInt32 frames);

/*!
* Offset the pointers in a buffer list, with a custom audio format
*
* 使用自定义音频格式在缓冲区列表中偏移指针
*
*  Increments the mData pointers in the buffer list by the given number
*  of frames. This is useful for filling a buffer in incremental stages.
*
* @param bufferList Pointer to an AudioBufferList containing audio
* @param audioFormat Audio format describing the audio in the buffer list
* @param frames The number of frames to offset the mData pointers by
*/
void AKKAAEAudioBufferListOffsetWithFormat(AudioBufferList *bufferList,
                   AudioStreamBasicDescription audioFormat,
                   UInt32 frames);

/*!
* Assign values of one buffer list to another, with the default audio format
*
* 使用默认音频格式将一个缓冲区列表的值分配给另一个缓冲区列表
*  Note that this simply assigns the buffer list values; if you wish to copy
*  the contents, use AEAudioBufferListCopy or AEAudioBufferListCopyContents
*
* @param target Target buffer list, to assign values to
* @param source Source buffer list, to assign values from
* @param offset Offset into target buffer
* @param length Length to assign, in frames
*/
void AKKAAEAudioBufferListAssign(AudioBufferList * target, const AudioBufferList * source, UInt32 offset, UInt32 length);

/*!
* Assign values of one buffer list to another, with the default audio format
*
*  Note that this simply assigns the buffer list values; if you wish to copy
*  the contents, use AEAudioBufferListCopy or AEAudioBufferListCopyContents
*
* @param target Target buffer list, to assign values to
* @param source Source buffer list, to assign values from
* @param audioFormat Audio format describing the audio in the buffer list
* @param offset Offset into target buffer
* @param length Length to assign, in frames
*/
void AKKAAEAudioBufferListAssignWithFormat(AudioBufferList * target, const AudioBufferList * source,
                   AudioStreamBasicDescription audioFormat, UInt32 offset, UInt32 length);

/*!
* Silence an audio buffer list (zero out frames), with the default audio format
* 使用默认音频格式使音频缓冲区列表（零输出帧）静音
* @param bufferList Pointer to an AudioBufferList containing audio
* @param offset Offset into buffer
* @param length Number of frames to silence
*/
void AKKAAEAudioBufferListSilence(const AudioBufferList *bufferList, UInt32 offset, UInt32 length);

/*!
* Silence an audio buffer list (zero out frames), with a custom audio format
*
* @param bufferList Pointer to an AudioBufferList containing audio
* @param audioFormat Audio format describing the audio in the buffer list
* @param offset Offset into buffer
* @param length Number of frames to silence
*/
void AKKAAEAudioBufferListSilenceWithFormat(const AudioBufferList *bufferList,
                    AudioStreamBasicDescription audioFormat,
                    UInt32 offset,
                    UInt32 length);

/*!
* Copy the contents of one AudioBufferList to another, with the default audio format
*
* @param target Target buffer list, to copy to
* @param source Source buffer list, to copy from
* @param targetOffset Offset into target buffer
* @param sourceOffset Offset into source buffer
* @param length Number of frames to copy
*/
void AKKAAEAudioBufferListCopyContents(const AudioBufferList * target,
               const AudioBufferList * source,
               UInt32 targetOffset,
               UInt32 sourceOffset,
               UInt32 length);

/*!
* Copy the contents of one AudioBufferList to another, with a custom audio format
*
* @param target Target buffer list, to copy to
* @param source Source buffer list, to copy from
* @param audioFormat Audio format describing the audio in the buffer list
* @param targetOffset Offset into target buffer
* @param sourceOffset Offset into source buffer
* @param length Number of frames to copy
*/
void AKKAAEAudioBufferListCopyContentsWithFormat(const AudioBufferList * target,
                         const AudioBufferList * source,
                         AudioStreamBasicDescription audioFormat,
                         UInt32 targetOffset,
                         UInt32 sourceOffset,
                         UInt32 length);
/*!
* Get the size of an AudioBufferList structure
*
*  Use this method when doing a memcpy of AudioBufferLists, for example.
*
*  Note: This method returns the size of the AudioBufferList structure itself, not the
*  audio bytes it points to.
*
* @param bufferList Pointer to an AudioBufferList
* @return Size of the AudioBufferList structure
*/
static inline size_t AEAudioBufferListGetStructSize(const AudioBufferList *bufferList) {
    return sizeof(AudioBufferList) + (bufferList->mNumberBuffers-1) * sizeof(AudioBuffer);
}

#ifdef __cplusplus
}
#endif
