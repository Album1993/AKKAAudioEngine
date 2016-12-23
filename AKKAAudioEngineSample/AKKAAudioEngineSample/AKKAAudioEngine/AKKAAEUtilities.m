//
//  AKKAAEUtilities.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/13.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAEUtilities.h"
#import "AKKAAETime.h"
AudioComponentDescription AKKAAEAudioComponentDescriptionMake(OSType manufacturer, OSType type, OSType subtype) {
    AudioComponentDescription description;
    memset(&description, 0, sizeof(description));
    description.componentManufacturer = manufacturer;
    description.componentType = type;
    description.componentSubType = subtype;
    return description;
}

BOOL AKKAAERateLimit(void) {
    static double lastMessage = 0;
    static int messageCount = 0;
    double now = AKKAAECurrentTimeInSeconds();
    if (now-lastMessage > 1) {
        messageCount = 0;
        lastMessage = now;
    }
    if (++messageCount >= 10) {
        if (messageCount == 10) {
            NSLog(@"TAAE: Suppressing some messages");
        }
        return NO;
    }
    return YES;
}

void AKKAAEError(OSStatus result, const char * _Nonnull operation, const char * _Nonnull file, int line) {
    if ( AKKAAERateLimit() ) {
        int fourCC = CFSwapInt32HostToBig(result);
        if ( isascii(((char*)&fourCC)[0]) && isascii(((char*)&fourCC)[1]) && isascii(((char*)&fourCC)[2]) ) {
            NSLog(@"%s:%d: %s: '%4.4s' (%d)", file, line, operation, (char*)&fourCC, (int)result);
        } else {
            NSLog(@"%s:%d: %s: %d", file, line, operation, (int)result);
        }
    }
}

ExtAudioFileRef AKKAAEExtAudioFileCreate(NSURL * _Nonnull url,
                                         AKKAAEAudioFileType fileType,
                                         double sampleRate,
                                         int channelCount,
                                         NSError * _Nullable *error) {
    AudioStreamBasicDescription asbd = {
        .mChannelsPerFrame = channelCount,
        .mSampleRate = sampleRate,
    };
    AudioFileTypeID fileTypeID;
    
    if (fileType == AKKAAEAudioFileTypeM4A) {
        // AAC encoding in M4A container
        // Get the output audio description for encoding AAC
        asbd.mFormatID = kAudioFormatMPEG4AAC;
        UInt32 size = sizeof(asbd);
        OSStatus status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                                                 0,
                                                 NULL,
                                                 &size,
                                                 &asbd);
        if ( ! AKKAAECheckOSStatus(status, "AudioFormatGetProperty(kAudioFormatProperty_FormatInfo")) {
            int fourCC = CFSwapInt32HostToBig(status);
            if ( error ) *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                                      code:status
                                                  userInfo:@{ NSLocalizedDescriptionKey:
                                                                  [NSString stringWithFormat:NSLocalizedString(@"Couldn't prepare the output format (error %d/%4.4s)", @""), status, (char*)&fourCC]}];
            return NULL;
        }
        fileTypeID = kAudioFileM4AType;
    } else if (fileType == AKKAAEAudioFileTypeAIFFFloat32) {
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kLinearPCMFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsBigEndian;
        asbd.mBitsPerChannel = sizeof(float) * 8;
        asbd.mBytesPerPacket = asbd.mChannelsPerFrame * sizeof(float);
        asbd.mBytesPerFrame = asbd.mBytesPerPacket;
        asbd.mFramesPerPacket = 1;
        fileTypeID = kAudioFileAIFCType;
    } else {
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | (fileType == AKKAAEAudioFileTypeAIFFInt16 ? kAudioFormatFlagIsBigEndian : 0);
        asbd.mBitsPerChannel = 16;
        asbd.mBytesPerPacket = asbd.mChannelsPerFrame * 2;
        asbd.mFramesPerPacket = 1;
        
        if (fileType == AKKAAEAudioFileTypeAIFFInt16) {
            fileTypeID = kAudioFileAIFFType;
        } else {
            fileTypeID = kAudioFileWAVEType;
        }
    }
    
    ExtAudioFileRef audioFile;
    OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef)url, fileTypeID, &asbd, NULL, kAudioFileFlags_EraseFile, &audioFile);
    if ( !AKKAAECheckOSStatus(status, "ExtAudioFileCreateWithURL") ) {
        if ( error )
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:@{ NSLocalizedDescriptionKey:
                                                     NSLocalizedString(@"Couldn't open the output file", @"") }];
        return NULL;
    }
    
    // Set the client format
    asbd = AKKAAEAudioDescriptionWithChannelsAndRate(channelCount, sampleRate);
    // Enable an audio converter on the input audio data by setting
    // the kExtAudioFileProperty_ClientDataFormat property. Each
    // read from the input file returns data in linear pcm format.
    status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(asbd), &asbd);
    
    if ( !AKKAAECheckOSStatus(status, "ExtAudioFileSetProperty") ) {
        ExtAudioFileDispose(audioFile);
        if ( error )
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:status
                                     userInfo:@{ NSLocalizedDescriptionKey:
                                                     NSLocalizedString(@"Couldn't configure the file writer", @"") }];
        return NULL;
    }
    
    return audioFile;
}

ExtAudioFileRef _Nullable AKKAAExtAudioFileOpen(NSURL * url, AudioStreamBasicDescription * outAudioDescription,uint64_t * outLengthInFrames, NSError ** error) {
    
    // open the file
    ExtAudioFileRef reader ;
    OSStatus result = ExtAudioFileOpenURL((__bridge CFURLRef)url, &reader);
    if ( !AKKAAECheckOSStatus(result, "ExtAudioFileOpenURL") ) {
        if ( error )
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                     userInfo:@{NSLocalizedDescriptionKey: @"Couldn't open source file"}];
        return NULL;
    }
    
    // Get the file data format
    AudioStreamBasicDescription fileDescription;
    UInt32 size = sizeof(fileDescription);
    result = ExtAudioFileGetProperty(reader, kExtAudioFileProperty_FileDataFormat, &size, &fileDescription);
    if ( !AKKAAECheckOSStatus(result, "ExtAudioFileGetProperty(kExtAudioFileProperty_FileDataFormat)") ) {
        ExtAudioFileDispose(reader);
        if ( error )
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                     userInfo:@{NSLocalizedDescriptionKey: @"Couldn't read source file"}];
        return NULL;
    }
    
    if (outLengthInFrames) {
        // Determine length in frames
        UInt64 fileLengthInFrames;
        AudioFilePacketTableInfo packetInfo;
        UInt32 size = sizeof(packetInfo);
        result = ExtAudioFileGetProperty(reader, kExtAudioFileProperty_PacketTable, &size, &packetInfo);
        if ( result != noErr ) {
            size = 0;
        }
        
        if (size > 0) {
            fileLengthInFrames = packetInfo.mNumberValidFrames;
        } else {
            UInt64 frameCount ;
            size = sizeof(frameCount);
            result = ExtAudioFileGetProperty(reader, kExtAudioFileProperty_FileLengthFrames, &size, &frameCount);
            if ( !AKKAAECheckOSStatus(result, "ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames)") ) {
                ExtAudioFileDispose(reader);
                if ( error )
                    *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                             userInfo:@{NSLocalizedDescriptionKey: @"Couldn't read source file"}];
                return NULL;
            }
            fileLengthInFrames = frameCount;
        }
        * outLengthInFrames = fileLengthInFrames;
    }
    
    // Set the client format
    AudioStreamBasicDescription clientFormat = AKKAAEAudioDescriptionWithChannelsAndRate(fileDescription.mChannelsPerFrame, fileDescription.mSampleRate);
    result = ExtAudioFileSetProperty(reader, kExtAudioFileProperty_ClientDataFormat, sizeof(clientFormat), &clientFormat);
    if ( !AKKAAECheckOSStatus(result, "ExtAudioFileGetProperty(kExtAudioFileProperty_ClientDataFormat)") ) {
        ExtAudioFileDispose(reader);
        if ( error )
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:result
                                     userInfo:@{NSLocalizedDescriptionKey: @"Couldn't configure file for reading"}];
        return NULL;
    }
    
    if (outAudioDescription) *outAudioDescription = clientFormat;
    
    return reader;
}
