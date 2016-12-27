//
//  AKKAAEBufferStack.h
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

extern const UInt32 AKKAAEBufferStackMaxFramesPerSlice;

typedef struct AKKAAEBufferStack AKKAAEBufferStack;

/*!
 * Initialize a new buffer stack
 *
 * @param poolSize The number of audio buffer lists to make room for in the buffer pool, or 0 for default value
 * @return The new buffer stack
 */
AKKAAEBufferStack * AKKAAEBufferStackNew(int poolSize);

/*!
 * Initialize a new buffer stack, supplying additional options
 *
 * @param poolSize The number of audio buffer lists to make room for in the buffer pool, or 0 for default value
 * @param maxChannelsPerBuffer The maximum number of audio channels for each buffer (default 2)
 * @param numberOfSingleChannelBuffers Number of mono float buffers to allocate (or 0 for default: poolSize*maxChannelsPerBuffer)
 * @return The new buffer stack
 */
AKKAAEBufferStack * AKKAAEBufferStackNewWithOptions(int poolSize, int maxChannelsPerBuffer, int numberOfSingleChannelBuffers);

/*!
 * Clean up a buffer stack
 *
 * @param stack The stack
 */
void AKKAAEBufferStackFree(AKKAAEBufferStack * stack);

/*!
 * Set current frame count per buffer
 *
 * @param stack The stack
 * @param frameCount The number of frames for newly-pushed buffers
 */
void AKKAAEBufferStackSetFrameCount(AKKAAEBufferStack * stack, UInt32 frameCount);

/*!
 * Get the current frame count per buffer
 *
 * @param stack The stack
 * @return The current frame count for newly-pushed buffers
 */
UInt32 AKKAAEBufferStackGetFrameCount(const AKKAAEBufferStack * stack);

/*!
 * Set timestamp for the current interval
 *
 * @param stack The stack
 * @param timestamp The current timestamp
 */
void AKKAAEBufferStackSetTimeStamp(AKKAAEBufferStack * stack, const AudioTimeStamp * timestamp);

/*!
 * Get the timestamp for the current interval
 *
 * @param stack The stack
 * @return The current timestamp
 */
const AudioTimeStamp * AKKAAEBufferStackGetTimeStamp(const AKKAAEBufferStack * stack);

/*!
 * Get the pool size
 *
 * @param stack The stack
 * @return The current pool size
 */
int AKKAAEBufferStackGetPoolSize(const AKKAAEBufferStack * stack);

/*!
 * Get the maximum number of channels per buffer
 *
 * @param stack The stack
 * @return The maximum number of channels per buffer
 */
int AKKAAEBufferStackGetMaximumChannelsPerBuffer(const AKKAAEBufferStack * stack);

/*!
 * Get the current stack count
 *
 * @param stack The stack
 * @return Number of buffers currently on stack
 */
int AKKAAEBufferStackCount(const AKKAAEBufferStack * stack);

/*!
 * Get a buffer
 *
 * @param stack The stack
 * @param index The buffer index
 * @return The buffer at the given index (0 is the top of the stack: the most recently pushed buffer)
 */
const AudioBufferList * AKKAAEBufferStackGet(const AKKAAEBufferStack * stack, int index);

/*!
 * Push one or more new buffers onto the stack
 *
 *  Note that a buffer that has been pushed immediately after a pop points to the same data -
 *  essentially, this is a no-op. If a buffer is pushed immediately after a pop with more
 *  channels, then the first channels up to the prior channel count point to the same data,
 *  and later channels point to new buffers.
 *
 * @param stack The stack
 * @param count Number of buffers to push
 * @return The first new buffer
 */
const AudioBufferList * AKKAAEBufferStackPush(AKKAAEBufferStack * stack, int count);


/*!
 * Push one or more new buffers onto the stack
 *
 *  Note that a buffer that has been pushed immediately after a pop points to the same data -
 *  essentially, this is a no-op. If a buffer is pushed immediately after a pop with more
 *  channels, then the first channels up to the prior channel count point to the same data,
 *  and later channels point to new buffers.
 *
 * @param stack The stack
 * @param count Number of buffers to push
 * @param channelCount Number of channels of audio for each buffer
 * @return The first new buffer
 */
const AudioBufferList * AKKAAEBufferStackPushWithChannels(AKKAAEBufferStack * stack, int count, int channelCount);

/*!
 * Push an external audio buffer
 *
 *  This function allows you to push a buffer that was allocated elsewhere. Note while the
 *  mData pointers within the pushed buffer will remain the same, and thus will point to the
 *  same audio data memory, the AudioBufferList structure itself will be copied; later changes
 *  to the original structure will not be reflected in the copy on the stack.
 *
 *  It is the responsibility of the caller to ensure that it does not modify the audio data until
 *  the end of the current render cycle. Note that successive audio modules may modify the contents.
 *
 * @param stack The stack
 * @param buffer The buffer list to copy onto the stack
 * @return The new buffer
 */
const AudioBufferList * AKKAAEBufferStackPushExternal(AKKAAEBufferStack * stack, const AudioBufferList * buffer);

/*!
 * Duplicate the top buffer on the stack
 *
 *  Pushes a new buffer onto the stack which is a copy of the prior buffer.
 *
 * @param stack The stack
 * @return The duplicated buffer
 */
const AudioBufferList * AKKAAEBufferStackDuplicate(AKKAAEBufferStack * stack);

/*!
 * Swap the top two stack items
 * 交换顶部两个堆栈项
 *
 * @param stack The stack
 */
void AKKAAEBufferStackSwap(AKKAAEBufferStack * stack);

/*!
 * Pop one or more buffers from the stack
 *
 *  The popped buffer remains valid until another buffer is pushed. A newly pushed buffer
 *  will use the same memory regions as the old one, and thus a pop followed by a push is
 *  essentially a no-op, given the same number of channels in each.
 *
 * @param stack The stack
 * @param count Number of buffers to pop, or 0 for all
 */
void AKKAAEBufferStackPop(AKKAAEBufferStack * stack, int count);

/*!
 * Remove a buffer from the stack
 *
 *  Remove an indexed buffer from within the stack. This has the same behaviour as AEBufferStackPop,
 *  in that a removal followed by a push results in a buffer pointing to the same memory.
 *
 * @param stack The stack
 * @param index The buffer index
 */
void AKKAAEBufferStackRemove(AKKAAEBufferStack * stack, int index);

/*!
 * Mix two or more buffers together
 *
 *  Pops the given number of buffers from the stack, and pushes a buffer with these mixed together.
 *
 *  When mixing a mono buffer and a stereo buffer, the mono buffer's channels will be duplicated.
 *
 * @param stack The stack
 * @param count Number of buffers to mix
 * @return The resulting buffer
 */
const AudioBufferList * AKKAAEBufferStackMix(AKKAAEBufferStack * stack, int count);

/*!
 * Mix two or more buffers together, with individual mix factors by which to scale each buffer
 *  将两个或多个buffers混合在一起，使用单独的混合因子来缩放每个缓冲液
 * @param stack The stack
 * @param count Number of buffers to mix
 * @param gains The gain factors (power ratio) for each buffer. You must provide 'count' values
 * 每个缓冲器的增益因子（功率比）。 您必须提供“count”值
 * @return The resulting buffer
 */
const AudioBufferList * AKKAAEBufferStackMixWithGain(AKKAAEBufferStack * stack, int count, const float * gains);

/*!
 * Apply volume and balance controls to the top buffer
 *
 *  This function applies gains to the given buffer to affect volume and balance, with a smoothing ramp
 *  applied to avoid discontinuities. If the buffer is mono, and the balance is non-zero, the buffer will
 *  be made stereo instead.
 *
 *  此函数将增益应用于给定缓冲区以影响音量和平衡，应用平滑斜坡以避免不连续。 如果缓冲区是单声道，并且天平非零，则缓冲区将变为立体声。
 *
 * @param stack The stack
 * @param targetVolume The target volume (power ratio)
 * @param currentVolume On input, the current volume; on output, the new volume. Store this and pass it
 *  back to this function on successive calls for a smooth ramp. If NULL, no smoothing will be applied.
 * @param targetBalance The target balance
 * @param currentBalance On input, the current balance; on output, the new balance. Store this and pass it
 *  back to this function on successive calls for a smooth ramp. If NULL, no smoothing will be applied.
 */
void AKKAAEBufferStackApplyFaders(AKKAAEBufferStack * stack,
                              float targetVolume, float * currentVolume,
                              float targetBalance, float * currentBalance);

/*!
 * Silence the top buffer
 *
 *  This function zereos out all samples in the topmost buffer.
 *
 * @param stack The stack
 */
void AKKAAEBufferStackSilence(AKKAAEBufferStack * stack);

/*!
 * Mix stack items onto an AudioBufferList
 *
 *  The given number of stack items will mixed into the buffer list.
 *
 * @param stack The stack
 * @param bufferCount Number of buffers to process, or 0 for all
 * @param output The output buffer list
 */
void AKKAAEBufferStackMixToBufferList(AKKAAEBufferStack * stack, int bufferCount, const AudioBufferList * output);

/*!
 * Mix stack items onto an AudioBufferList, with specific channel configuration
 *
 *  The given number of stack items will mixed into the buffer list.
 *
 * @param stack The stack
 * @param bufferCount Number of buffers to process, or 0 for all
 * @param channels The set of channels to output to. If stereo, any mono inputs will be doubled to stereo.
 *      If mono, any stereo inputs will be mixed down.
 * @param output The output buffer list
 */
void AKKAAEBufferStackMixToBufferListChannels(AKKAAEBufferStack * stack,
                                          int bufferCount,
                                          AKKAAEChannelSet channels,
                                          const AudioBufferList * output);

/*!
 * Get the timestamp for the given buffer index
 *
 *  Modules can use this method to access and manipulate the timestamp that corresponds
 *  to a piece of audio. For example, AEAudioUnitInputModule replaces the timestamp with
 *  one that corresponds to the input audio.
 *
 * @param stack The stack
 * @param index The buffer index
 * @return The timestamp that corresponds to the buffer at the given index
 */
AudioTimeStamp * AKKAAEBufferStackGetTimeStampForBuffer(AKKAAEBufferStack * stack, int index);

/*!
 * Reset the stack
 *
 *  This pops all items until the stack is empty
 *
 * @param stack The stack
 */
void AKKAAEBufferStackReset(AKKAAEBufferStack * stack);

#ifdef __cplusplus
}
#endif
