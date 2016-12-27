//
//  AKKAAEIOAudioUnit.h
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/27.
//  Copyright © 2016年 AKKA. All rights reserved.
//
#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AKKAAETime.h"

/*!
 * Render block
 *
 *  For output-enabled AEIOAudioUnit instances, you must provide a block of this type
 *  to the @link AEIOAudioUnit::renderBlock renderBlock @endlink property.
 *
 *  对于已启用输出的AEIOAudioUnit实例，必须向@link AEIOAudioUnit :: renderBlock renderBlock @endlink属性提供此类型的块。
 *
 * @param ioData The audio buffer list to fill
 * @param frames The number of frames
 * @param timestamp The corresponding timestamp
 */
typedef void (^AKKAAEIOAudioUnitRenderBlock)(AudioBufferList * _Nonnull ioData,
                                            UInt32 frames,
                                            const AudioTimeStamp * _Nonnull timestamp);

/*!
 * Setup notification
 *  当设备设置或在更改参数后或在媒体服务重置后重新设置时，广播。 发送此通知后，audioUnit属性将为非NULL。
 *  This is broadcast when the unit is setup, or re-setup after changing parameters
 *  or after a media services reset. After this notification is sent, the audioUnit
 *  property will be non-NULL.
 */
extern NSString * const _Nonnull AKKAAEIOAudioUnitDidSetupNotification;

/*!
 * Stream update notification
 *
 *  This is broadcast when the stream format updates (sample rate/channel count).
 *  If sample rate has changed for an output-enabled unit, this block will be performed between
 *  stopping the unit and starting it again.
 */
extern NSString * const _Nonnull AKKAAEIOAudioUnitDidUpdateStreamFormatNotification;

/*!
 * Audio unit interface
 *
 *  This class manages an input/output/input-output audio unit. To use it, create an instance,
 *  set the properties, then call setup: to initialize, and start: to begin processing.
 *
 *  Typically, you do not use this class directly; instead, use AEAudioUnitOutput and/or
 *  AEAudioUnitInputModule to provide an interface with the audio hardware.
 *
 *  Important note: an audio unit with both input and output enabled is only possible on iOS. On
 *  the Mac, you must create two separate audio units.
 */
@interface AKKAAEIOAudioUnit : NSObject

/*!
* Setup the audio unit
*
*  Call this after configuring the instance to initialize it, prior to calling start:.
*
* @param error If an error occured and this is not nil, it will be set to the error on output
* @return YES on success, NO on failure
*/
- (BOOL)setup:(NSError * __autoreleasing _Nullable * _Nullable)error;

/*!
* Start the audio unit
*
* @param error If an error occured and this is not nil, it will be set to the error on output
* @return YES on success, NO on failure
*/
- (BOOL)start:(NSError * __autoreleasing _Nullable * _Nullable)error;

/*!
* Stop the audio unit
*/
- (void)stop;

/*!
* Get access to audio unit
*
*  Available for realtime thread usage
*
* @param unit The unit instance
* @return The audio unit
*/
AudioUnit _Nullable AKKAAEIOAudioUnitGetAudioUnit(__unsafe_unretained AKKAAEIOAudioUnit * _Nonnull unit);

/*!
* Render the input
*
*  For use with input-enabled instance, this fills the provided AudioBufferList with audio
*  from the input.
*
* @param unit The unit instance
* @param buffer The audio buffer list
* @param frames Number of frames
*/
OSStatus AKKAAEIOAudioUnitRenderInput(__unsafe_unretained AKKAAEIOAudioUnit * _Nonnull unit,
                              const AudioBufferList * _Nonnull buffer, UInt32 frames);

/*!
* Get the last received input timestamp
*
*  For use with input-enabled instances, this gives access to the most recent AudioTimeStamp
*  associated with input audio. Use this to perform synchronization.
*
* @param unit The unit instance
* @return The most recent audio timestamp
*/
AudioTimeStamp AKKAAEIOAudioUnitGetInputTimestamp(__unsafe_unretained AKKAAEIOAudioUnit * _Nonnull unit);

/*!
* Get the current sample rate
*
*  The sample rate is normally obtained from the current render context, but this function allows
*  access when the render context is not available
*
* @param unit The unit instance
* @return The current sample rate
*/
double AKKAAEIOAudioUnitGetSampleRate(__unsafe_unretained AKKAAEIOAudioUnit * _Nonnull unit);

#if TARGET_OS_IPHONE

/*!
* Get the input latency
*
*  This function returns the hardware input latency, in seconds. If you have disabled latency compensation,
*  and timing is important in your app, then you should factor this value into your timing calculations.
*
* @param unit The unit instance
* @return The current input latency
*/
AKKAAESeconds AKKAAEIOAudioUnitGetInputLatency(__unsafe_unretained AKKAAEIOAudioUnit * _Nonnull unit);

/*!
* Get the output latency
*
*  This function returns the hardware output latency, in seconds. If you have disabled latency compensation,
*  and timing is important in your app, then you should factor this value into your timing calculations.
*
* @param unit The unit instance
* @return The current output latency
*/
AKKAAESeconds AKKAAEIOAudioUnitGetOutputLatency(__unsafe_unretained AKKAAEIOAudioUnit * _Nonnull unit);

#endif

//! The audio unit. Will be NULL until setup: is called.
@property (nonatomic, readonly) AudioUnit _Nullable audioUnit;

//! The sample rate at which to run, or zero to track the hardware sample rate
@property (nonatomic) double sampleRate;

//! The current sample rate in use
@property (nonatomic, readonly) double currentSampleRate;

//! Whether unit is currently active
@property (nonatomic, readonly) BOOL running;

//! Whether output is enabled. Note that changing this value will cause the audio unit to be uninitialized,
//! reconfigured, and initialized again, temporarily interrupting audio rendering.
@property (nonatomic) BOOL outputEnabled;

//! The block to call when rendering output. May be changed at any time.
@property (nonatomic, copy) AKKAAEIOAudioUnitRenderBlock _Nullable renderBlock;

//! The current number of output channels
@property (nonatomic, readonly) int numberOfOutputChannels;

//! Whether input is enabled. Note that changing this value will cause the audio unit to be uninitialized,
//! reconfigured, and initialized again, temporarily interrupting audio rendering.
@property (nonatomic) BOOL inputEnabled;

//! The microphone gain, as power ratio. If the current audio session permits, this will be applied
//! using AVAudioSession's gain controls. Otherwise, it will be applied by affecting the input signal directly.
@property (nonatomic) double inputGain;

//! The maximum number of input channels to support, or zero for unlimited
@property (nonatomic) int maximumInputChannels;

//! The current number of input channels in use
@property (nonatomic, readonly) int numberOfInputChannels;

//! The IO buffer duration.
//! On iOS, this is fetched from AVAudioSession; on the Mac, this is taken from HAL
@property (nonatomic) AKKAAESeconds IOBufferDuration;

#if TARGET_OS_IPHONE

//! Whether to automatically perform latency compensation (default YES)
@property (nonatomic) BOOL latencyCompensation;

#endif
@end


#ifdef __cplusplus
}
#endif
