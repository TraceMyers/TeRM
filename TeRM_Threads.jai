// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :read write lock
// spin lock, no mutex.
// any number of concurrent readers allowed. or, only one writer (and no readers) allowed.
// also has a mechanism for allowing writers through when writers have

RW_Lock_Mode :: enum {
    READ;
    WRITE;
}

// assumes you never have > 255 threads contesting the same lock.
// if that's a bad assumption, this is not the right lock for you.
// just a note: for most computers, 100+ threads all working at once
// on spin-locked data is not going to be good for perf. it is better
// to make your jobs bigger, have as many active threads as you have 
// cores (-1), and in general just reduce contestation on data.
RW_Lock :: struct {
    counter: s32 = 0;
    writers_waiting: u8 = 0;
    // if consecutive reads goes above this threshold and there are writers waiting,
    // readers will wait until a single writer gets through
    suppress_reads_threshold: u8 = 30;
    consecutive_reads_while_writers_waiting: s16 = 0;
}

init :: (lock: *RW_Lock) {
    lock.* = {};
}

// lock now and unlock at the end of the scope
scope_read_write_lock :: (lock: *RW_Lock, $mode: RW_Lock_Mode) #expand {
    read_write_lock(lock, mode);
    `defer read_write_unlock(lock, mode);
}

read_write_lock :: (lock: *RW_Lock, $mode: RW_Lock_Mode) {
    // think of positive numbers as 'read' territory, and -100,000 as 'write'
    // -100,001  -100,000   -99,999  ...  -2    -1     0     1      2      3      4   ...
    //               w                                 |     r      r      r      r
    // if a thread that wants to read adds 1 to the lock and gets back a value > 0, read ok
    // if a thread that wants to write subtracts 100,000 and gets back a value = -100,000, write ok
    // using +1 and -100,000 to make it impossible for +1's to push the lock above 0 if writing.
    #if mode == .READ {
        lock_value_before_add: s32;
        // make sure readers aren't hogging the resource
        while lock.consecutive_reads_while_writers_waiting > lock.suppress_reads_threshold 
        && lock.writers_waiting > 0 {
            ;
        }
        while true {
            lock_value_before_add = atomic_add(*lock.counter, 1);
            if lock_value_before_add >= 0 {
                // won read access
                if lock.writers_waiting > 0
                && lock.consecutive_reads_while_writers_waiting < CONSECUTIVE_READS_THRESHOLD {
                    atomic_increment(*lock.consecutive_reads_while_writers_waiting);
                }
                break;
            }
            atomic_decrement(*lock.counter);
        }
    } else { // WRITE
        lock_value_before_subtract: s32;
        atomic_increment(*lock.writers_waiting);
        while true {
            lock_value_before_subtract = atomic_add(*lock.counter, -LARGE_NUMBER);
            if lock_value_before_subtract == 0 {
                // won write access
                atomic_swap(*lock.consecutive_reads_while_writers_waiting, 0);
                atomic_decrement(*lock.writers_waiting);
                break;
            }
            atomic_add(*lock.counter, LARGE_NUMBER);
        }
    }
}

read_write_unlock :: (lock: *RW_Lock, $mode: RW_Lock_Mode) {
    #if mode == .READ {
        atomic_decrement(*lock.counter);
    } else {
        atomic_add(*lock.counter, LARGE_NUMBER);
    }
}

#scope_file

CONSECUTIVE_READS_THRESHOLD : s16 : 0x7fff / 2;
LARGE_NUMBER : s32 : 100_000;

// -----------------------------------------------------------------------------------

#scope_file

#import "Basic";
#import "Atomics";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
