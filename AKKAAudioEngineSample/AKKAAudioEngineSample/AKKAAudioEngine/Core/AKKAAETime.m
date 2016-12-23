//
//  AKKAAETime.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/15.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAETime.h"
#import <mach/mach_time.h>

static double __hostTickToSeconds = 0.0;
static double __secondToHostTicks = 0.0;

const AudioTimeStamp AKKAAETimeStampNone = {};

void AKKAAETimeInit() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mach_timebase_info_data_t tinfo;
        mach_timebase_info(&tinfo);
        __hostTickToSeconds = ((double)tinfo.numer / tinfo.denom) * 1.0e-9;
        __secondToHostTicks = 1.0 / __hostTickToSeconds;
    });
}

AKKAAEHostTicks AKKAAECurrentTimeInHostTicks(void) {
    return mach_absolute_time();
}

AKKAAESeconds AKKAAECurrentTimeInSeconds(void) {
    if (!__hostTickToSeconds) AKKAAETimeInit();
    return mach_absolute_time() * __hostTickToSeconds;
}

AKKAAEHostTicks AKKAAEHostTicksFromSeconds(AKKAAESeconds seconds) {
    if (!__secondToHostTicks) AKKAAETimeInit();
    assert(seconds >= 0);
    return seconds * __secondToHostTicks;
}

AKKAAESeconds AKKAAESecondsFromHostTicks(AKKAAEHostTicks ticks) {
    if (!__hostTickToSeconds) AKKAAETimeInit();
    return ticks * __hostTickToSeconds;
}

AudioTimeStamp AKKAAETimeStampWithHostTicks(AKKAAEHostTicks ticks) {
    if (! ticks) return AKKAAETimeStampNone;
    return (AudioTimeStamp){ .mFlags = kAudioTimeStampHostTimeValid, .mHostTime = ticks };
}

AudioTimeStamp AKKAAETimeStampWithSamples(Float64 samples) {
    return (AudioTimeStamp) { .mFlags = kAudioTimeStampSampleTimeValid, .mSampleTime = samples };
}
