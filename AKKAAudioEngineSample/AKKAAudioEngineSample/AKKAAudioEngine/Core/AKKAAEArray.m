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
@property (nonatomic, strong, readwrite) NSArray * allValues;
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

- (void)dealloc {
#ifdef DEBUG
    // 确定是不是被释放
    __weak AKKAAEManagedValue * weakvalue = nil;
    @autoreleasepool {
        weakvalue = _value;
        self.value = nil;
    }
    if (weakvalue) {
        NSLog(@"AKKAAEArray value leaked: %@",weakvalue);
        weakvalue.releaseBlock = nil;
    }
#else
    @autoreleasepool {
        self.value = nil;
    }
#endif
}

- (NSArray *)allValues {
    array_t * array = (array_t *)_value.pointerValue;
    return array->objects ? array->objects : @[];
}

- (int)count {
    array_t * array = (array_t *)_value.pointerValue;
    return array->count;
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    array_t * array = (array_t *)_value.pointerValue;
    return [array->objects countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    array_t * array = (array_t*)_value.pointerValue;
    return [array->objects objectAtIndexedSubscript:idx];
}

- (void *)pointerValueAtIndex:(int)index {
    array_t * array = (array_t *)_value.pointerValue;
    return index < array->count ? array->entries[index]->pointer : NULL;// entries 有索引的作用
}

- (void *)pointerValueForObject:(id)object {
    array_t * array = (array_t *)_value.pointerValue;
    if (!array->objects) return NULL;
    NSUInteger index = [array->objects indexOfObject:object];
    if (index == NSNotFound) return NULL;
    return [self pointerValueAtIndex:(int)index];
}

- (void)updatePointerValue:(void *)value forObject:(id)object {
    array_t * array = (array_t *)_value.pointerValue;
    if (!array->objects) return;
    NSUInteger index = [array->objects indexOfObject:object];
    if (index == NSNotFound || index >= array->count) return;
    size_t size = 
}

- (void)releaseOldArray:(array_t *)array {

}
@end
