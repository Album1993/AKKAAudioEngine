//
//  AKKAAEIOAudioUnit.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/27.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAEIOAudioUnit.h"
#import "AKKAAETypes.h"
#import "AKKAAEUtilities.h"
#import "AKKAAEBufferStack.h"
#import "AKKAAETime.h"
#import "AKKAAEManagedValue.h"
#import "AKKAAEAudioBufferListUtilities.h"
#import "AKKAAEDSPUtilties.h"
#import <AVFoundation/AVFoundation.h>

NSString * const AKKAAEIOAudioUnitDidUpdateStreamFormatNotification = @"AKKAAEIOAudioUnitDidUpdateStreamFormatNotification";
NSString * const AKKAAEIOAudioUnitDidSetupNotification = @"AKKAAEIOAudioUnitDidSetupNotification";

@interface AKKAAEIOAudioUnit()

@property (nonatomic, strong) AKKAAEManagedValue * renderBlockValue;
@property (nonatomic, readwrite) double currentSampleRate;
@property (nonatomic, readwrite) int numberOfOutputChannels;
@property (nonatomic, readwrite) int numberOfInputChannels;
@property (nonatomic, assign) AudioTimeStamp inputTimestamp;
@property (nonatomic, assign) BOOL needsInputGainScaling;
@property (nonatomic, assign) float currentInputGain;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) id sessionInterruptionObserverToken;
@property (nonatomic, strong) id mediaResetObserverToken;
@property (nonatomic, strong) id routeChangeObserverToken;
@property (nonatomic, assign) NSTimeInterval outputLatency;
@property (nonatomic, assign) NSTimeInterval inputLatency;

#endif

@end

@implementation AKKAAEIOAudioUnit



@end
