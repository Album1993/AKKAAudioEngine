//
//  AKKAAETypes.h
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/15.
//  Copyright © 2016年 AKKA. All rights reserved.
//


#ifdef __cplusplus
extern "C" {
#endif
    
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
    
/*!
 * The audio description used throughout TAAE
 *
 *  This is 32-bit floating-point, non-interleaved stereo PCM.
 */

// TAAE中使用的音频描述
// 这是32位浮点，非交织立体声PCM。

extern const AudioStreamBasicDescription AKKAAEAudioDescription;

//Get the TAAE audio description at a given sample rate
//以给定的采样率获取TAAE音频描述
AudioStreamBasicDescription AKKAAEAudioDescriptionWithChannelsAndRate(int channels, double rate);
/*!
 * File types
 */
/*!
 * 文件类型
 */

typedef NS_ENUM(NSInteger, AKKAAEAudioFileType) {
    AKKAAEAudioFileTypeAIFFFloat32, //!< 32-bit floating point AIFF (AIFC)
    AKKAAEAudioFileTypeAIFFInt16,   //!< 16-bit signed little-endian integer AIFF
    AKKAAEAudioFileTypeWAVInt16,    //!< 16-bit signed little-endian integer WAV
    AKKAAEAudioFileTypeM4A,         //!< AAC in an M4A container
};

/*!
 * Channel set
 */
typedef struct {
    int firstChannel; //!< The index of the first channel of the set
    int lastChannel;  //!< The index of the last channel of the set
} AKKAAEChannelSet;

extern AKKAAEChannelSet AKKAAEChannelSetDefault; //!< A default, stereo channel set

/*!
 * Create an AKKAAEChannelSet
 *
 * @param firstChannel The first channel
 * @param lastChannel The last channel
 * @returns An initialized AEChannelSet structure
 */

/*!
 * 创建一个 AKKAAEChannelSet
 *
 * @param firstChannel The first channel
 * @param lastChannel The last channel
 * @returns An initialized AEChannelSet structure
 */
static inline AKKAAEChannelSet AKKAAEChannelSetMake(int firstChannel, int lastChannel) {
    return (AKKAAEChannelSet) {firstChannel, lastChannel};
}

/*!
 * Determine number of channels in an AEChannelSet
 *
 * @param set The channel set
 * @return The number of channels
 */

/*!
 * 获取AKKAEChannelSet 的数量
 *
 * @param set The channel set
 * @return The number of channels
 */
static inline int AKKAAEChannelSetGetNumberOfChannels(AKKAAEChannelSet set) {
    return set.lastChannel - set.firstChannel + 1;
}
    
#ifdef __cplusplus
}
#endif
