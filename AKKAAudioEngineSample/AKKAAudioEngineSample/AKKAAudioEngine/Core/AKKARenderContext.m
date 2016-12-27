//
//  AKKARenderContext.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/27.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKARenderContext.h"
#import "AKKAAEBufferStack.h"

void AKKAAERenderContextOutput(const AKKAAERenderContext * _Nonnull context, int bufferCount) {
    AKKAAEBufferStackMixToBufferList(context->stack, bufferCount, context->output);
}

void AKKAAERenderContextOutputToChannels(const AKKAAERenderContext * _Nonnull context, int bufferCount, AKKAAEChannelSet channels) {
    AKKAAEBufferStackMixToBufferListChannels(context->stack, bufferCount, channels, context->output);
}
