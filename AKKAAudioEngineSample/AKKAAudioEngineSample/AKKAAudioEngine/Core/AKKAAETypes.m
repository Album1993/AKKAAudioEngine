//
//  AKKAAETypes.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/15.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAETypes.h"

AudioStreamBasicDescription const AKKAAEAudioDescription = {
    .mFormatID          = kAudioFormatLinearPCM,
    .mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved,
    .mChannelsPerFrame  = 2,
    .mBytesPerPacket    = sizeof(float),
    .mFramesPerPacket   = 1,
    .mBytesPerFrame     = sizeof(float),
    .mBitsPerChannel    = 8 * sizeof(float),
    .mSampleRate        = 0,
};

AudioStreamBasicDescription AKKAAEAudioDescriptionWithChannelsAndRate(int channels, double rate) {
    AudioStreamBasicDescription description = AKKAAEAudioDescription;
    description.mChannelsPerFrame = channels;
    description.mSampleRate = rate;
    return description;
}

AKKAAEChannelSet AEChannelSetDefault = {0, 1};
