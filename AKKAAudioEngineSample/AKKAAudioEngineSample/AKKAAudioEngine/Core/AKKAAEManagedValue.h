//
//  AKKAAEManagedValue.h
//  AKKAAudioEngineSample
//
//  Created by 张一鸣 on 2016/12/8.
//  Copyright © 2016年 AKKA. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>

//! Batch update block
//! 批量更新block
typedef void (^AKKAAEManagedValueUpdateBlock)();

/*!
 * Release block
 *
 * @param value Original value provided
 */
typedef void (^AKKAAEManagedValueReleaseBlock)(void * _Nonnull value);

//! Release notification block
typedef void (^AKKAAEManagedValueReleaseNotificationBlock)();

/*!
 * Managed value
 *
 *  This class manages a mutable reference to a memory buffer or Objective-C object which is both thread-safe
 *  and realtime safe. It manages the life-cycle of the buffer/object so that it can not be deallocated
 *  while being accessed on the main thread, and does so without locking the realtime thread.
 *
 *  You can use this utility to manage a single module instance, which can be swapped out for
 *  another at any time, for instance.
 *
 *  Remember to use the __unsafe_unretained directive to avoid ARC-triggered retains on the
 *  audio thread if using this class to manage an Objective-C object, and only interact with such objects
 *  via C functions they provide, not via Objective-C methods.
 */

/*!
 *这个类管理对内存缓冲区的可变引用或Objective-C对象，它既是线程安全的，也是实时安全的。
 * 它管理缓冲区/对象的生命周期，使得它在主线程上被访问时不能被释放，并且不锁定实时线程。
 *
 * 您可以使用此实用程序来管理单个模块实例，例如，可以随时将其替换为另一个模块实例。
 *
 * 记住使用__unsafe_unretained指令，以避免ARC触发的音频线程上的保留，如果使用这个类来管理一个Objective-C对象，
 * 并且只通过它们提供的C函数而不是通过Objective-C方法与这些对象交互。
 *
 */
@interface AKKAAEManagedValue : NSObject

/*!
 * Update multiple AEManagedValue instances atomically
 *
 *  Any changes made within the block will be applied atomically with respect to the audio thread.
 *  Any value accesses made from the realtime thread while the block is executing will return the
 *  prior value, until the block has completed.
 *
 *  These may be nested safely.
 *
 *  If you are not using AEAudioUnitOutput, then you must call the AEManagedValueCommitPendingUpdates
 *  function at the beginning of your main render loop, particularly if you use this method. This
 *  ensures batched updates are all committed in sync with your render loop. Until this function is
 *  called, AEManagedValueGetValue returns old values, prior to those set in the given block.
 *
 * @param block Atomic update block
 */
        /*!
         * 以原子方式更新多个AEManagedValue实例
         *
         * 在block中相对于音频线程的任何更改都是原子性的
         * 在执行块时，从实时线程进行的任何值访问将返回先前值，直到块完成
         *
         *这些可以安全嵌套。
         *
         *如果不使用AEAudioUnitOutput，那么必须在主渲染循环开始时调用AEManagedValueCommitPendingUpdates函数，特别是如果使用此方法。
         * 这确保批量更新都与提交循环同步提交。
         * 直到调用此函数，AKKAAEManagedValueGetValue都返回旧值，在给定块中设置的值之前。
         *
         * @param block
         */
+ (void)performAtomicBatchUpdate:(AKKAAEManagedValueUpdateBlock _Nonnull)block;

/*!
 * Get access to the value on the realtime audio thread
 *
 *  The object or buffer returned is guaranteed to remain valid until the next call to this function.
 *
 *  Can also be called safely on the main thread (although the @link objectValue @endlink and
 *  @link pointerValue @endlink properties are easier).
 *
 * @param managedValue The instance
 * @return The value
 */

/*!
 * 获取对实时音频线程的值
 *
 * 返回的对象或缓冲区保证保持有效，直到下一次调用此函数
 *
 * 也可以安全的在主线程中被调用（虽然@link objectValue @endlink和@link pointerValue @endlink属性更容易）。
 * @param managedValue
 * @return
 */
void * _Nullable AKKAAEManagedValueGetValue(__unsafe_unretained AKKAAEManagedValue * _Nonnull managedValue);

/*!
 * Commit pending updates on the realtime thread
 *
 *  If you are not using AEAudioUnitOutput, then you should call this function at the start of
 *  your top-level render loop in order to apply updates in sync. If you are using AEAudioUnitOutput,
 *  then this function is already called for you within that class, so you don't need to do so yourself.
 *
 *  After this function is called, any updates made within the block passed to performAtomicBatchUpdate:
 *  become available on the render thread, and any old values are scheduled for release on the main thread.
 *
 *  Important: Only call this function on the audio thread. If you call this on the main thread, you
 *  will see sporadic crashes on the audio thread.
 */

/*!
 * 在实时线程上提交待定更新
 *
 * 如果您没有使用AEAudioUnitOutput，那么您应该在顶级渲染循环开始时调用此函数，以便同步应用更新。 如果你使用AEAudioUnitOutput，那么这个函数已经在你的类中调用，所以你就不用自己调用这个。
 *
 * 调用此函数后，在block中传递给performAtomicBatchUpdate的任何更新在渲染线程上可用，并且任何旧值都被调度为在主线程上释放。
 */

void AKKAAEManagedValueCommitPendingUpdates();

/*!
 * An object. You can set this property from the main thread. Note that you can use this property,
 * or pointerValue, but not both.
 */

/*!
 * 您可以从主线程设置此属性。 请注意，您可以使用此属性或pointerValue，但不能同时使用两者。
 */

@property (nonatomic, strong) id _Nullable objectValue;

/*!
 * A pointer to an allocated memory buffer. Old values will be automatically freed when the value
 * changes. You can set this property from the main thread. Note that you can use this property,
 * or objectValue, but not both.
 */

/*!
 * 指向分配的内存缓冲区的指针。 值更改时，旧值将自动释放。 您可以从主线程设置此属性。 请注意，您可以使用此属性或objectValue，但不能同时使用两者。
 */

@property (nonatomic) void * _Nullable pointerValue;

/*!
 * Block to perform when deleting old items, on main thread. If not specified, will simply use
 * free() to dispose values set via pointerValue, or CFBridgingRelease() to dispose values set via objectValue.
 */
@property (nonatomic, copy) AKKAAEManagedValueReleaseBlock _Nullable releaseBlock;

/*!
 * Block for release notifications. Use this to be informed when an old value has been released.
 */
@property (nonatomic, copy) AKKAAEManagedValueReleaseNotificationBlock _Nullable releaseNotificationBlock;

@end

#ifdef __cplusplus
}
#endif