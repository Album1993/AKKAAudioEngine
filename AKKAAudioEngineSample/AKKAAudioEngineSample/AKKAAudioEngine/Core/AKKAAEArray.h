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

typedef const void * AEArrayToken; //!< Token for real-thread use
    
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
typedef void * _Nullable (^AEArrayCustomMappingBlock)(id _Nonnull item);

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
typedef void * _Nullable (^AEArrayIndexedCustomMappingBlock)(id _Nonnull item, int index);

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
typedef void (^AEArrayReleaseBlock)(id _Nonnull item, void * _Nonnull bytes);

// Some indirection macros required for AEArrayEnumerate
#define __AEArrayVar2(x, y) x ## y
#define __AEArrayVar(x, y) __AEArrayVar2(__ ## x ## _line_, y)

    


@interface AKKAAEArray : NSObject

@end
