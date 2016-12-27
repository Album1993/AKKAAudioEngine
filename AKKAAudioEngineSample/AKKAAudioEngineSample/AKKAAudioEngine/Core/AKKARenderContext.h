//
//  AKKARenderContext.h
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
#import "AKKAAEBufferStack.h"
    
/*!
 * Render context
 *
 *  This structure is passed into the render loop block, and contains information about the
 *  current rendering environment, as well as providing access to the render's buffer stack.
 */
typedef struct {
    
    //! The output buffer list. You should write to this to produce audio.
    const AudioBufferList * _Nonnull output;
    
    //! The number of frames to render to the output
    UInt32 frames;
    
    //! The current sample rate, in Hertz
    double sampleRate;
    
    //! The current audio timestamp
    const AudioTimeStamp * _Nonnull timestamp;
    
    //! Whether rendering is offline (faster than realtime)
    BOOL offlineRendering;
    
    //! The buffer stack. Use this as a workspace for generating and processing audio.
    AKKAAEBufferStack * _Nonnull stack;
    
} AKKAAERenderContext;
    
/*!
 * Mix stack items onto the output
 *
 *  The given number of stack items will mixed into the context's output.
 *  This method is a convenience wrapper for AEBufferStackMixToBufferList.
 *
 * @param context The context
 * @param bufferCount Number of buffers on the stack to process, or 0 for all
 */
void AKKAAERenderContextOutput(const AKKAAERenderContext * _Nonnull context, int bufferCount);

/*!
 * Mix stack items onto the output, with specific channel configuration
 *
 *  The given number of stack items will mixed into the context's output.
 *  This method is a convenience wrapper for AEBufferStackMixToBufferListChannels.
 *
 * @param context The context
 * @param bufferCount Number of buffers on the stack to process, or 0 for all
 * @param channels The set of channels to output to. If stereo, any mono inputs will be doubled to stereo.
 *      If mono, any stereo inputs will be mixed down.
 */
void AKKAAERenderContextOutputToChannels(const AKKAAERenderContext * _Nonnull context, int bufferCount, AKKAAEChannelSet channels);



#ifdef __cplusplus
}
#endif
