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
    double now = AECurrentTimeInSeconds();
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

void AEError(OSStatus result, const char * _Nonnull operation, const char * _Nonnull file, int line) {
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
                                         NSError * _Nullable error) {
    AudioStreamBasicDescription asbd = {
        .mChannelsPerFrame = channelCount,
        .mSampleRate = sampleRate,
    };
    AudioFileID fileTypeID;
    
    if (fileType == AKKAAEAudioFileTypeM4A) {
        // AAC encoding in M4A container
        // Get the output audio description for encoding AAC
        asbd.mFormatID = kAudioFormatMPEG4AAC;
        UInt32 size = sizeof(asbd);
        OSStatus status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, <#UInt32 inSpecifierSize#>, <#const void * _Nullable inSpecifier#>, <#UInt32 * _Nullable ioPropertyDataSize#>, <#void * _Nullable outPropertyData#>)
    }
}















