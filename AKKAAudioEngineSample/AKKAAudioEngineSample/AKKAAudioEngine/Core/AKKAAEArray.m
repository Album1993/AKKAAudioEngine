//
//  AKKAAEArray.m
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/6.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#import "AKKAAEArray.h"
#import "AKKAAEManagedValue.h"

typedef struct {
    void * pointer;
    int referenceCount;
} array_entry_t;

typedef struct {
    int count;
    __unsafe_unretained NSArray * objects;
    array_entry_t * entries[1];
}array_t;

@interface AKKAAEArray ()

@property (nonatomic, strong) AKKAAEManagedValue * value;
@property (nonatomic, strong, readwrite) NSArray * allValue;
@property (nonatomic, copy) void*(^mappingBlock)(id item);

@end

@implementation AKKAAEArray
@dynamic allValues,count;

- (instancetype)init {
    return [self initWithCustomMapping:nil];
}

- (instancetype)initWithCustomMapping:(AKKAAEArrayCustomMappingBlock)block {
    if (!(self = [super init])) return nil;
    self.mappingBlock = block;
    self.value = [AKKAAEManagedValue new];
    __unsafe_unretained AKKAAEArray *weakSelf = self;
    self.value.releaseBlock = ^(void * value) {[weakSelf releaseOldArray:(array_t *)value];};
    array_t * array = (array_t *)calloc(1, sizeof(array_t));
    array->count = 0;
    self.value.pointerValue = array;
    return self;
}

- (void)releaseOldArray:(array_t *)array {
    
}
@end
