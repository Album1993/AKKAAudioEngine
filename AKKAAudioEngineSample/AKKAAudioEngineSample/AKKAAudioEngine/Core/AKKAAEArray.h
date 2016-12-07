//
//  AKKAAEArray.h
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/6.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif
    
    
#import <Foundation/Foundation.h>

typedef const void * AKKAAEArrayToken; //!< Token for real-thread use
    
/*!
 * Block for mapping between objects and opaque pointer values
 *
 *  Pass a block matching this type to AEArray's initializer in order to map
 *  between objects in the array and an arbitrary data block; this can be a pointer
 *  to an allocated C structure, for example, or any other collection of bytes.
 *
 *  The block is invoked on the main thread whenever a new item is added to the array
 *  during an update. You should allocate the memory you need, set the contents, and
 *  return a pointer to this memory. It will be freed automatically once the item is
 *  removed from the array, unless you provide a custom @link AEArray::releaseBlock releaseBlock @endlink.
 *
 * @param item The original object
 * @return Pointer to an allocated memory region
 */

/**
 *
 * 将匹配此类型的块传递给AEArray的初始化器，以便在数组中的对象和任意数据块之间进行映射
 * 这可以是指向所分配的C结构的指针，例如，或任何其他字节集合。
 * 每当在更新期间将新项目添加到阵列时，在主线程上调用该块。
 * 你应该分配你需要的内存，设置内容，并返回一个指向这个内存的指针。
 * 一旦项目从数组中删除，它将被自动释放，除非你提供一个自定义@link AEArray :: releaseBlock releaseBlock @endlink
 *
 * */

typedef void * _Nullable (^AKKAAEArrayCustomMappingBlock)(id _Nonnull item);

/*!
 * Block for mapping between objects and opaque pointer values, for use with AEArray's
 * @link AEArray::updateWithContentsOfArray:customMapping: updateWithContentsOfArray:customMapping: @endlink
 * method.
 *
 *  See documentation for AEArrayCustomMappingBlock for details.
 *
 * @param item The original object
 * @return Pointer to an allocated memory region
 */

/**
 *
 * 用于对象和不透明指针值之间的映射的块，用于AEArray的@link AEArray :: updateWithContentsOfArray：customMapping：updateWithContentsOfArray：customMapping：@endlink方法。
 *
 * */
typedef void * _Nullable (^AKKAAEArrayIndexedCustomMappingBlock)(id _Nonnull item, int index);

/*!
 * Block for releasing allocated values
 *
 *  Assign a block matching this type to AEArray's releaseBlock property to provide
 *  a custom release implementation. Use this if you are using a custom mapping block
 *  and need to perform extra cleanup tasks beyond simply freeing the returned pointer.
 *
 * @param item The original object
 * @param bytes The bytes originally returned from the custom mapping block
 */

/**
 * 用于释放分配值的块
 * 将与此类型匹配的块分配给AEArray的releaseBlock属性以提供自定义发布实现。
 * 如果您使用自定义映射块并需要执行额外的清除任务，而不仅仅是释放返回的指针，则使用此选项。
 * */
typedef void (^AKKAAEArrayReleaseBlock)(id _Nonnull item, void * _Nonnull bytes);

// Some indirection macros required for AEArrayEnumerate
#define __AKKAAEArrayVar2(x, y) x ## y
#define __AKKAAEArrayVar(x, y) __AEArrayVar2(__ ## x ## _line_, y)


/*!
 * Real-time safe array
 *
 *  Use this class to manage access to an array of items from the audio thread. Accesses
 *  are both thread-safe and realtime-safe.
 *
 *  Using the default initializer results in an instance that manages an array of object
 *  references. You can cast the items returned directly to an __unsafe_unretained Objective-C type.
 *
 *  Alternatively, you can use the custom initializer to provide a block that maps between
 *  objects and any collection of bytes, such as a C structure.
 *
 *  When accessing the array on the realtime audio thread, you must first obtain a token to access
 *  the array using @link AEArrayGetToken @endlink. This token remains valid until the next time
 *  AEArrayGetToken is called. Pass the token to @link AEArrayGetCount @endlink and
 *  @link AEArrayGetItem @endlink to access array items.
 *
 *  Remember to use the __unsafe_unretained directive to avoid ARC-triggered retains on the
 *  audio thread if using this class to manage Objective-C objects, and only interact with such objects
 *  via C functions they provide, not via Objective-C methods.
 */

/*!
 *实时安全数组
 * 使用此类来管理从音频线程对项目数组的访问。 访问是线程安全的和实时安全的。
 *
 * 使用默认初始化器导致管理对象引用数组的实例。 您可以将直接返回的项目转换为__unsafe_unretained Objective-C类型。
 *
 * 或者，您可以使用自定义初始化程序来提供在对象和任何字节集合之间映射的块，例如C结构。
 *
 * 当在实时音频线程上访问阵列时，您必须首先获得一个Token，以使用@link AEArrayGetToken @endlink访问数组。
 * 此Token 将保持有效，直到下一次调用AEArrayGetToken。
 * 将Token传递到@link AEArrayGetCount @endlink和@link AEArrayGetItem @endlink以访问数组项。
 *
 * 记得用__unsafe_unretained来防止ARC在你用这个类来管理objective-c对象，并且只用C函数而不是用OC方法产生交互时产生的对音频线程的保留。（oc对象没有被自动释放，这个类也没被释放）
 * */

@interface AKKAAEArray : NSObject <NSFastEnumeration>

/*!
 * Default initializer
 *
 *  This configures the instance to manage an array of object references. You can cast the items
 *  returned directly to an __unsafe_unretained Objective-C type.
 */

/*!
 *默认初始化
 *这将配置实例以管理对象引用数组。 您可以将直接返回的项目转换为__unsafe_unretained Objective-C类型。
 */
- (instancetype _Nonnull)init;

/*!
 * Custom initializer
 *
 *  This allows you to provide a block that maps between the given object and a C structure, or any
 *  other collection of bytes. The block will be invoked on the main thread whenever a new item is
 *  added to the array during an update. You should allocate the memory you need, set the contents, and
 *  return a pointer to this memory. It will be freed automatically once the item is removed from the array,
 *  unless you provide a custom releaseBlock.
 *
 * @param block The block mapping between objects and stored information, or nil to get the same behaviour
 *  as the default initializer.
 */
        /*!
         *
         *这允许您提供在给定对象和C结构或任何其他字节集合之间映射的块。
         * 每当在更新期间将新项目添加到阵列时，将在主线程上调用该块。
         * 你应该分配你需要的内存，设置内容，并返回一个指向这个内存的指针。
         * 一旦项目从数组中删除，它将被自动释放，除非你提供一个自定义releaseBlock。
         *
         * @param block
         * @return
         */
- (instancetype _Nullable)initWithCustomMapping:(AKKAAEArrayCustomMappingBlock _Nullable)block;

/*!
 * Update the array by copying the contents of the given NSArray
 *
 *  New values will be retained, and old values will be released in a thread-safe manner.
 *  If you have provided a custom mapping when initializing the instance, the custom mapping
 *  block will be called for all new values. Values in the new array that are also present in
 *  the prior array value will be maintained, and old values not present in the new array are released.
 *
 *  Using this method within an AEManagedValue
 *  @link AEManagedValue::performAtomicBatchUpdate: performAtomicBatchUpdate @endlink block
 *  will cause the update to occur atomically along with any other value updates.
 *
 * @param array Array of values
 */
        /*!
         * 通过复制给定的NSArray的内容更新数组
         * 将保留新值，并以线程安全的方式释放旧值。
         * 如果在初始化实例时提供了自定义映射，则将为所有新值调用自定义映射块。
         * 新数组中也存在于先前数组值中的值将被保留，并且新数组中不存在的旧值被释放。
         * @param array
         */
- (void)updateWithContentsOfArray:(NSArray * _Nonnull)array;

/*!
 * Update the array, with custom mapping
 *
 *  If you provide a custom mapping using this method, it will be used instead of the one
 *  provided when initializing this instance (if any), for all new values not present in the
 *  previous array value. This allows you to capture state particular to an individual
 *  update at the time of calling this method.
 *
 *  New values will be retained, and old values will be released in a thread-safe manner.
 *
 *  Using this method within an AEManagedValue
 *  @link AEManagedValue::performAtomicBatchUpdate: performAtomicBatchUpdate @endlink block
 *  will cause the update to occur atomically along with any other value updates.
 *
 * @param array Array of values
 * @param block The block mapping between objects and stored information
 */

        /*!
         *
         * 使用自定义映射更新数组
         *
         * 如果使用此方法提供自定义映射，则将使用它替代初始化此实例（如果有）时提供的自定义映射，以用于上一个数组值中不存在的所有新值。 这允许您在调用此方法时捕获特定于单个更新的状态。
         *
         */

- (void)updateWithContentsOfArray:(NSArray * _Nonnull)array customMapping:(AKKAAEArrayIndexedCustomMappingBlock _Nullable)block;

/*!
 * Get the pointer value at the given index of the C array, as seen by the audio thread
 *
 *  This method allows you to access the same values as the audio thread; if you are using
 *  a mapping block to create structures that correspond to objects in the original array,
 *  for instance, then you may access these structures using this method.
 *
 *  Note: Take care if modifying these values, as they may also be accessed from the audio
 *  thread. If you wish to make changes atomically with respect to the audio thread, use
 *  @link updatePointerValue:forObject: @endlink.
 *
 * @param index Index of the item to retrieve
 * @return Pointer to the item at the given index
 */

/*!
 * 获取C数组的给定索引处的指针值，如音频线程所示
 *
 * 此方法允许您访问与音频线程相同的值; 如果您使用映射块来创建与原始数组中的对象对应的结构，那么您可以使用此方法访问这些结构。
 *
 * 注意：小心如果修改这些值，因为它们也可以从音频线程访问。 如果你想对音频线程进行原子性的更改，请使用@link updatePointerValue：forObject：@endlink。
 */
- (void * _Nullable)pointerValueAtIndex:(int)index;

/*!
 * Get the pointer value associated with the given object, if any
 *
 *  This method allows you to access the same values as the audio thread; if you are using
 *  a mapping block to create structures that correspond to objects in the original array,
 *  for instance, then you may access these structures using this method.
 *
 *  Note: Take care if modifying these values, as they may also be accessed from the audio
 *  thread. If you wish to make changes atomically with respect to the audio thread, use
 *  @link updatePointerValue:forObject: @endlink.
 *
 * @param object The object
 * @return Pointer to the item corresponding to the object
 */

/*
 * 获取与给定对象相关联的指针值（如果有）
 * 此方法允许您访问与音频线程相同的值; 如果您使用映射块来创建与原始数组中的对象对应的结构，那么您可以使用此方法访问这些结构。
 * 注意：小心如果修改这些值，因为它们也可以从音频线程访问。 如果你想对音频线程进行原子性的更改，请使用@link updatePointerValue：forObject：@endlink
 */
- (void * _Nullable)pointerValueForObject:(id _Nonnull)object;

/*!
 * Update the pointer value associated with the given object
 *
 *  If you are using a mapping block to create structures that correspond to objects in the
 *  original array, you may use this method to update those structures atomically, with
 *  respect to the audio thread.
 *
 *  The prior value associated with this object will be released, possibly calling your
 *  @link releaseBlock @endlink, if one is provided.
 *
 * @param value The new pointer value
 * @param object The associated object
 */

/*
 *更新与给定对象相关联的指针值
 * 如果使用映射块来创建与原始数组中的对象相对应的结构，则可以使用此方法相对于音频线程以原子方式更新这些结构。
 * 与此对象关联的先前值将被释放，可能调用您的@link releaseBlock @endlink（如果提供）。
 **/
- (void)updatePointerValue:(void * _Nullable)value forObject:(id _Nonnull)object;

/*!
 * Access objects using subscript syntax
 */
/**
 * 通过下标获得对象
 */
- (id _Nullable)objectAtIndexedSubscript:(NSUInteger)idx;

/*!
 * Get the array token, for use on realtime audio thread
 *
 *  In order to access this class on the audio thread, you should first use AEArrayGetToken
 *  to obtain a token for accessing the object. Then, pass that token to AEArrayGetCount or
 *  AEArrayGetItem. The token remains valid until the next time AEArrayGetToken is called,
 *  after which the array values may differ. Consequently, it is advised that AEArrayGetToken
 *  is called only once per render loop.
 *
 *  Note: Do not use this function on the main thread
 *
 * @param array The array
 * @return The token, for use with other accessors
 */

/**
 *获取数组token，用于实时音频线程
 * 为了在音频线程上访问这个类，你应该首先使用AEArrayGetToken获取一个令牌来访问对象。
 * 然后，将该令牌传递给AEArrayGetCount或AEArrayGetItem。
 * 令牌保持有效，直到下一次调用AEArrayGetToken时为止，在此之后，数组值可能不同。 
 * 因此，建议每个渲染循环只调用一次AEArrayGetToken。
 *
 * 注意：不要在主螺纹上使用此功能
 */
AKKAAEArrayToken _Nonnull AKKAAEArrayGetToken(__unsafe_unretained AKKAAEArray * _Nonnull array);

/*!
 * Get the number of items in the array
 *
 * @param token The array token, as returned from AEArrayGetToken
 * @return Item count
 */

/*
 获取数组中的项数
 */
int AKKAAEArrayGetCount(AKKAAEArrayToken _Nonnull token);

/*!
 * Get the item at a given index
 *
 * @param token The array token, as returned from AEArrayGetToken
 * @param index The item index
 * @return Item at the given index
 */

/*
 获取给定index的item
 */
void * _Nullable AKKAAEArrayGetItem(AKKAAEArrayToken _Nonnull token, int index);

/*!
 * Enumerate object types in the array, for use on audio thread
 *
 *  This convenience macro provides the ability to enumerate the objects
 *  in the array, in a realtime-thread safe fashion.
 *
 *  Use it like:
 *
 *      AEArrayEnumerateObjects(array, MyObjectType *, myVar) {
 *          // Do stuff with myVar, which is a MyObjectType *
 *      }
 *
 *  Note: This macro calls AEArrayGetToken to access the array. Consequently, it is not
 *  recommended for use when you need to access the array in addition to this enumeration.
 *
 *  Note: Do not use this macro on the main thread
 *
 * @param array The array
 * @param type The object type
 * @param varname Name of object variable for inner loop
 */

/**
 * 枚举数组中的对象类型，用于音频线程
 * 这个方便的宏提供以实时线程安全的方式枚举数组中的对象的能力。
 * Use it like:
 *
 *      AEArrayEnumerateObjects(array, MyObjectType *, myVar) {
 *          // Do stuff with myVar, which is a MyObjectType *
 *      }
 * 注意：此宏调用AEArrayGetToken以访问数组。 因此，除了枚举之外，当您需要访问数组时，不建议使用它。
 * 注意：不要在主线程上使用此宏
 */
#define AKKAAEArrayEnumerateObjects(array, type, varname) \
    AKKAAEArrayToken __AKKAAEArrayVar(token, __LINE__) = AKKAAEArrayGetToken(array); \
    int __AKKAAEArrayVar(count, __LINE__) = AKKAAEArrayGetCount(__AKKAAEArrayVar(token, __LINE__)); \
    int __AKKAAEArrayVar(i, __LINE__) = 0; \
    for ( __unsafe_unretained type varname = __AKKAAEArrayVar(count, __LINE__) > 0 ? (__bridge type)AKKAAEArrayGetItem(__AKKAAEArrayVar(token, __LINE__), 0) : NULL; \
          __AKKAAEArrayVar(i, __LINE__) < __AKKAAEArrayVar(count, __LINE__); \
          __AKKAAEArrayVar(i, __LINE__)++, varname = __AKKAAEArrayVar(i, __LINE__) < __AKKAAEArrayVar(count, __LINE__) ? \
            (__bridge type)AKKAAEArrayGetItem(__AKKAAEArrayVar(token, __LINE__), __AKKAAEArrayVar(i, __LINE__)) : NULL )

/*!
 * Enumerate pointer types in the array, for use on audio thread
 *
 *  This convenience macro provides the ability to enumerate the pointers
 *  in the array, in a realtime-thread safe fashion. It differs from AEArrayEnumerateObjects
 *  in that it is designed for use with pointer types, rather than objects.
 *
 *  Use it like:
 *
 *      AEArrayEnumeratePointers(array, MyCType *, myVar) {
 *          // Do stuff with myVar, which is a MyCType *
 *      }
 *
 *  Note: This macro calls AEArrayGetToken to access the array. Consequently, it is not
 *  recommended for use when you need to access the array in addition to this enumeration.
 *
 *  Note: Do not use this macro on the main thread
 *
 * @param array The array
 * @param type The pointer type (e.g. struct myStruct *)
 * @param varname Name of pointer variable for inner loop
 */
#define AKKAAEArrayEnumeratePointers(array, type, varname) \
    AKKAAEArrayToken __AKKAAEArrayVar(token, __LINE__) = AKKAAEArrayGetToken(array); \
    int __AKKAAEArrayVar(count, __LINE__) = AKKAAEArrayGetCount(__AKKAAEArrayVar(token, __LINE__)); \
    int __AKKAAEArrayVar(i, __LINE__) = 0; \
    for ( type varname = __AKKAAEArrayVar(count, __LINE__) > 0 ? (type)AKKAAEArrayGetItem(__AKKAAEArrayVar(token, __LINE__), 0) : NULL; \
          __AKKAAEArrayVar(i, __LINE__) < __AKKAAEArrayVar(count, __LINE__); \
          __AKKAAEArrayVar(i, __LINE__)++, varname = __AKKAAEArrayVar(i, __LINE__) < __AKKAAEArrayVar(count, __LINE__) ? \
            (type)AKKAAEArrayGetItem(__AKKAAEArrayVar(token, __LINE__), __AKKAAEArrayVar(i, __LINE__)) : NULL )


//! Number of values in array
@property (nonatomic, readonly) int count;

//! Current object values
@property (nonatomic, strong, readonly) NSArray * _Nonnull allValues;

//! Block to perform when deleting old items, on main thread. If not specified, will simply use
//! free() to dispose bytes, if pointer differs from original Objective-C pointer.
@property (nonatomic, copy) AKKAAEArrayReleaseBlock _Nullable releaseBlock;

@end

#ifdef __cplusplus
}
#endif
