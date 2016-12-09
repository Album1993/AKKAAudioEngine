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
    void * pointer; // 存储allvalues 中每个单个数据
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
    size_t size = sizeof(array_t) + (sizeof(void *) * array->count - 1);
    array_t * newArray = (array_t *)malloc(size);
    memcpy(newArray, array, size);
    
    newArray->entries[index] = (array_entry_t *)malloc(sizeof(array_entry_t));
    newArray->entries[index]->pointer = value;
    newArray->entries[index]->referenceCount = 1;
    
    for (int i = 0; i < newArray->count; i++) {
        if (i != index)  newArray->entries[i]->referenceCount++;
    }
    CFBridgingRetain(newArray->objects);
    _value.pointerValue = newArray;
}

- (void)updateWithContentsOfArray:(NSArray *)array {
    [self updateWithContentsOfArray:array
                      customMapping:nil];
}

- (void)updateWithContentsOfArray:(NSArray *)array customMapping:(AKKAAEArrayIndexedCustomMappingBlock)block {
    array_t * currentArray = (array_t *)_value.pointerValue;
    if (currentArray && currentArray->objects && [currentArray->objects isEqualToArray:array]) {
        return;
    }
    
    array = [array copy];
    array_t * newArray = (array_t *)malloc(sizeof(array_t) + (sizeof(void *) * array.count -1));
    newArray->count = (int)array.count;
    newArray->objects = array;
    CFBridgingRetain(array);
    
    array_t * priorArray = (array_t *)_value.pointerValue;
    
    int i = 0;
    for (id item in array) {
        NSUInteger priorIndex = priorArray && priorArray->objects ? [priorArray->objects indexOfObject:item] : NSNotFound;
        if (priorIndex != NSNotFound) {
            newArray->entries[i] = priorArray->entries[priorIndex];
            newArray->entries[i]->referenceCount++;
        } else {
            newArray->entries[i] = (array_entry_t *)malloc(sizeof(array_entry_t));
            newArray->entries[i]->pointer = block ? block(item,i) : _mappingBlock ? _mappingBlock(item) : (__bridge void *)item;
            newArray->entries[i]->referenceCount = 1;
        }
        i++;
    }
    _value.pointerValue = newArray;
}

AKKAAEArrayToken AKKAAEArrayGetToken(__unsafe_unretained AKKAAEArray * THIS) {
    return AKKAAEManagedValueGetValue(THIS->_value);
}

int AKKAAEArrayGetCount(AKKAAEArrayToken _Nonnull token) {
    return ((array_t *) token)->count;
}

void * _Nullable AKKAAEArrayGetItem(AKKAAEArrayToken _Nonnull token, int index) {
    return ((array_t *)token)->entries[index]->pointer;
}

- (void)releaseOldArray:(array_t *)array {
    for (int i = 0; i < array->count; i++) {
        array->entries[i]->referenceCount--;
        if (array->entries[i]->referenceCount == 0) {
            if (_releaseBlock) {
                _releaseBlock(array->objects[i],array->entries[i]->pointer);
            } else if(array->entries[i]->pointer && array->entries[i]->pointer != (__bridge void *)array->objects[i]) {
                free(array->entries[i]->pointer);// 如果不相同就单独释放，相同就在下面一起释放
            }
            free(array->entries[i]);
        }
    }
    if (array->objects) CFBridgingRelease((__bridge CFTypeRef)array->objects);
    free(array);
}
@end
