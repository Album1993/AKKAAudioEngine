//
//  AKKAAETime.h
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

typedef uint64_t AKKAAEHostTicks;
typedef double AKKAAESeconds;

extern const AudioTimeStamp AKKAAETimeStampNone; //!< An empty timestamp

/*!
 * Initialize
 */
void AKKAAETimeInit();

/*!
 * Get current global timestamp, in host ticks
 * 获取当前全局时间戳
 */
AKKAAEHostTicks AKKAAECurrentTimeInHostTicks(void);

/*!
 * Get current global timestamp, in seconds
 */
AKKAAESeconds AKKAAECurrentTimeInSeconds(void);

/*!
 * Convert time in seconds to host ticks
 *
 * @param seconds The time in seconds
 * @return The time in host ticks
 */
AKKAAEHostTicks AKKAAEHostTicksFromSeconds(AKKAAESeconds seconds);

/*!
 * Convert time in host ticks to seconds
 *
 * @param ticks The time in host ticks
 * @return The time in seconds
 */
AKKAAESeconds AKKAAESecondsFromHostTicks(AKKAAEHostTicks ticks);

/*!
 * Create an AudioTimeStamps with a host ticks value
 *
 *  If a zero value is provided, then AETimeStampNone will be returned.
 *
 * @param ticks The time in host ticks
 * @return The timestamp
 */
AudioTimeStamp AKKAAETimeStampWithHostTicks(AKKAAEHostTicks ticks);

/*!
 * Create an AudioTimeStamps with a sample time value
 *
 * @param samples The time in samples
 * @return The timestamp
 */
AudioTimeStamp AKKAAETimeStampWithSamples(Float64 samples);

#ifdef __cplusplus
}
#endif
