//
//  AKKAAEDSPUtilties.h
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
#import "AKKAAEAudioBufferListUtilities.h"

// gain 是声音强度，和爆音有关
/*!
 * Scale values in a buffer list by some gain value
 *
 * 通过一些增益值对缓冲区列表中的值进行缩放
 * @param bufferList Audio buffer list, in non-interleaved float format
 * @param gain Gain amount (power ratio)
 * @param frames Length of buffer in frames
 */
void AKKAAEDSPApplyGain(const AudioBufferList * bufferList, float gain, UInt32 frames);

/*!
 * Apply a ramp to values in a buffer list
 * 对缓冲区列表中的值应用衰减
 *
 * @param bufferList Audio buffer list, in non-interleaved float format
 * @param start Starting gain (power ratio) on input; final gain value on output
 * @param step Amount per frame to advance gain
 * @param frames Length of buffer in frames
 */
void AKKAAEDSPApplyRamp(const AudioBufferList * bufferList, float * start, float step, UInt32 frames);

/*!
 * Apply an equal-power ramp to values in a buffer list
 * 对缓冲区列表中的值应用等功率衰减
 *
 *  This uses a quarter-cycle cosine ramp envelope to preserve the power level, useful when
 *  crossfading two signals without causing a bump in gain in the middle of the fade.
 *  使用1/4余弦波来保持gonglv， 对两个淡入淡出的信号间的切换有帮助
 *
 * @param bufferList Audio buffer list, in non-interleaved float format
 * @param start Starting gain (power ratio) on input; final gain value on output
 * @param step Amount per frame to advance gain
 * @param frames Length of buffer in frames
 * @param scratch A scratch buffer to use, or NULL to use an internal buffer. Not thread-safe if the latter is used.
 */
void AKKAAEDSPApplyEqualPowerRamp(const AudioBufferList * bufferList, float * start, float step, UInt32 frames, float * scratch);

/*!
 * Scale values in a buffer list by some gain value, with smoothing to avoid discontinuities
 * 通过一些增益值在缓冲器列表中缩放值，以及平滑以避免不连续性
 * @param bufferList Audio buffer list, in non-interleaved float format
 * @param targetGain Target gain amount (power ratio)
 * @param currentGain On input, current gain; on output, the new gain. Store this and pass it back to this
 *  function on successive calls for a smooth ramp
 * @param frames Length of buffer in frames
 */
void AKKAAEDSPApplyGainSmoothed(const AudioBufferList * bufferList, float targetGain, float * currentGain, UInt32 frames);

/*!
 * Scale values in a buffer list by some gain value, with smoothing to avoid discontinuities
 *
 * @param bufferList Audio buffer list, in non-interleaved float format
 * @param targetGain Target gain amount (power ratio)
 * @param currentGain On input, current gain; on output, the new gain. Store this and pass it back to this
 *  function on successive calls for a smooth ramp
 * @param frames Length of buffer in frames
 * @param rampDuration Duration of full 0.0-1.0/1.0-0.0 transition, in frames
 */
void AKKAAEDSPApplyGainWithRamp(const AudioBufferList * bufferList, float targetGain, float * currentGain, UInt32 frames,
                            UInt32 rampDuration);

/*!
 * Scale values in a single buffer by some gain value, with smoothing to avoid discontinuities
 *
 * @param buffer Float array
 * @param targetGain Target gain amount (power ratio)
 * @param currentGain On input, current gain; on output, the new gain
 * @param frames Length of buffer in frames
 */
void AKKAAEDSPApplyGainSmoothedMono(float * buffer, float targetGain, float * currentGain, UInt32 frames);

/*!
 * Apply volume and balance controls to the buffer
 *
 *  This function applies gains to the given buffer to affect volume and balance, with a smoothing ramp
 *  applied to avoid discontinuities.
 *
 * @param bufferList Audio buffer list, in non-interleaved float format
 * @param targetVolume The target volume (power ratio)
 * @param currentVolume On input, the current volume; on output, the new volume. Store this and pass it
 *  back to this function on successive calls for a smooth ramp. If NULL, no smoothing will be applied.
 * @param targetBalance The target balance
 * @param currentBalance On input, the current balance; on output, the new balance. Store this and pass it
 *  back to this function on successive calls for a smooth ramp. If NULL, no smoothing will be applied.
 * @param frames Length of buffer in frames
 */
void AKKAAEDSPApplyVolumeAndBalance(const AudioBufferList * bufferList, float targetVolume, float * currentVolume,
                                float targetBalance, float * currentBalance, UInt32 frames);


/*!
 * Mix two buffer lists
 *
 *  Combines values in each buffer list, after scaling by given factors. If monoToStereo is YES,
 *  then if a buffer is mono, and the output is stereo, the buffer will have its channels doubled
 *  If the output is mono, any buffers with more channels will have these mixed down into the
 *  mono output.
 * 在按给定因子缩放后，合并每个缓冲区列表中的值。
 * 如果monoToStereo为YES，那么如果缓冲区是单声道，输出是立体声的，则缓冲区的通道将是双声道的。
 * 如果输出是单声道，任何具有更多通道的缓冲区将被混合到单声道输出中。
 *
 *  This method assumes the number of frames in each buffer is the same.
 *
 *  Note that input buffer contents may be modified during this operation.
 *
 * @param bufferList1 First buffer list, in non-interleaved float format
 * @param bufferList2 Second buffer list, in non-interleaved float format
 * @param gain1 Gain factor for first buffer list (power ratio)
 * @param gain2 Gain factor for second buffer list
 * @param monoToStereo Whether to double mono tracks to stereo, if output is stereo
 * @param frames Length of buffer in frames, or 0 for entire buffer (based on mDataByteSize fields)
 * @param output Output buffer list (may be same as bufferList1 or bufferList2)
 */
void AKKAAEDSPMix(const AudioBufferList * bufferList1, const AudioBufferList * bufferList2, float gain1, float gain2,
              BOOL monoToStereo, UInt32 frames, const AudioBufferList * output);

/*!
 * Silence an audio buffer list (zero out frames)
 *
 * @param bufferList Pointer to an AudioBufferList containing audio
 * @param offset Offset into buffer
 * @param length Number of frames to silence (0 for whole buffer)
 */
#define AKKAAEDSPSilence AKKAAEAudioBufferListSilence

/*!
 * Generate oscillator/LFO 振荡器就是正弦的波
 *
 *  This function produces, sample by sample, an oscillator signal that approximates a sine wave. Its
 *  output lies in the range 0 - 1.
 *
 * @param rate Oscillation rate, per sample (frequency / sample rate)
 * @param position On input, current oscillator position; on output, new position.
 * @return One sample of oscillator signal
 */
static inline float AKKAAEDSPGenerateOscillator(float rate, float * position) {
    float x = *position;
    x *= x;
    x -= 1.0;
    x *= x;
    *position += rate;
    if ( *position > 1.0 ) *position -= 2.0;
    return x;
}

/*!
 * Convert power ratio to decibels
 *  将功率比转换为分贝
 * @param ratio Power ratio
 * @return Value in decibels
 */
static inline double AKKAAEDSPRatioToDecibels(double ratio) {
    return 20.0 * log10(ratio);
}

#ifdef __cplusplus
}
#endif



