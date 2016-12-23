//
//  AKKAAEUtilities.h
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/13.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif
    
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AKKAAETypes.h"

/*!
 * Create an AudioComponentDescription structure
 *
 * @param manufacturer  The audio component manufacturer (e.g. kAudioUnitManufacturer_Apple)
 * @param type          The type (e.g. kAudioUnitType_Generator)
 * @param subtype       The subtype (e.g. kAudioUnitSubType_AudioFilePlayer)
 * @returns An AudioComponentDescription structure with the given attributes
 */

AudioComponentDescription AKKAAEAudioComponentDescriptionMake(OSType manufacturer, OSType type, OSType subtype);

/*!
 * Rate limit an operation
 *
 *  This can be used to prevent spamming error messages to the console
 *  when something goes wrong.
 */
//速率限制操作
//这可以用于防止在出现错误时向控制台发送垃圾邮件错误消息。
BOOL AKKAAERateLimit(void);

/*!
 * An error occurred within AECheckOSStatus
 *
 *  Create a symbolic breakpoint with this function name to break on errors.
 */
/*!
 * AECheckOSStatus中发生错误
 *
 * 使用此函数名称创建符号断点以在错误时中断
 */
void AKKAAEError(OSStatus result, const char * _Nonnull operation, const char * _Nonnull file, int line);

/*!
 * Check an OSStatus condition
 *
 * @param result The result
 * @param operation A description of the operation, for logging purposes
 */
#define AKKAAECheckOSStatus(result,operation) (_AKKAAECheckOSStatus((result),(operation),strrchr(__FILE__, '/')+1,__LINE__))
static inline BOOL _AKKAAECheckOSStatus(OSStatus result, const char * _Nonnull operation, const char * _Nonnull file, int line) {
    if ( result != noErr ) {
        AKKAAEError(result, operation, file, line);
        return NO;
    }
    return YES;
}

/*!
 * Initialize an ExtAudioFileRef for writing to a file
 *
 *  This provides a simple way to create an audio file writer, initialised appropriately for the
 *  given file type. To begin recording asynchronously, you should use `ExtAudioFileWriteAsync(audioFile, 0, NULL);`
 *  to prime asynchronous recording. For writing on the main thread, use `ExtAudioFileWrite`.
 *
 *  Finish writing and close the file by using `ExtAudioFileDispose` once you are done.
 *
 *  Use this function only on the main thread.
 *
 * @param url URL to the file to write to
 * @param fileType The type of the file to write
 * @param sampleRate Sample rate to use for input & output
 * @param channelCount Number of channels for input & output
 * @param error If not NULL, the error on output
 * @return The initialized ExtAudioFileRef, or NULL on error
 */

/*!
 * Initialize an ExtAudioFileRef for writing to a file
 *
 *  这提供了一种创建音频文件写入器的简单方法，对于给定的文件类型适当地初始化。
 *  要开始异步录制，您应该使用`ExtAudioFileWriteAsync（audioFile，0，NULL）;`来启动异步录制。
 *  对于在主线程上的写，使用`ExtAudioFileWrite`。 *
 *  Finish writing and close the file by using `ExtAudioFileDispose` once you are done.
 *
 *  Use this function only on the main thread.
 *
 * @param url URL to the file to write to
 * @param fileType The type of the file to write
 * @param sampleRate Sample rate to use for input & output
 * @param channelCount Number of channels for input & output
 * @param error If not NULL, the error on output
 * @return The initialized ExtAudioFileRef, or NULL on error
 */

ExtAudioFileRef _Nullable AKKAAEExtAudioFileCreate(NSURL * _Nonnull url,
                                                   AKKAAEAudioFileType fileType,
                                                   double sampleRate,
                                                   int channelCount,
                                                   NSError * _Nullable * _Nullable error);

/*!
 * Open an audio file for reading
 *
 *  This utility creates a new reader instance, and returns the reader, the client format AudioStreamBasicDescription
 *  used for reading, and the total length in frames, both usually useful for operating on files.
 *
 *  It will be configured to use the standard AEAudioDescription format, with the channel count and sample rate
 *  determined by the file format - this configured format is returned via the outAudioDescription parameter.
 *  Use kExtAudioFileProperty_ClientDataFormat to change this if required.
 *
 * @param url URL to the file to read from
 * @param outAudioDescription On output, the AEAudioDescription-derived stream format for reading (the client format)
 * @param outLengthInFrames On output, the total length in frames
 * @param error If not NULL, the error on output
 * @return The initialized ExtAudioFileRef, or NULL on error
 */

ExtAudioFileRef _Nullable AEExtAudioFileOpen(NSURL * _Nonnull url,
                                             AudioStreamBasicDescription * _Nullable outAudioDescription,
                                             UInt64 * _Nullable outLengthInFrames,
                                             NSError * _Nullable * _Nullable error);


#ifdef __cplusplus
}
#endif
