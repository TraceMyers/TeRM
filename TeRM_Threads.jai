// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :read write lock
// spin lock, no mutex.
// any number of concurrent readers allowed. or, only one writer (and no readers) allowed.
// In the past, I have found this kind of solution useful for this kind of situation:
//
// - handful of threads that might access the locks (3-7)
// - many items of data with one lock per item
// - reads are many, writes are not so many.
//
// it might be useful for situations very different than the one described here as well

RW_Lock_Type :: enum {
    READ;
    WRITE;
}

init_read_write_lock :: (lock: *s32) {
    lock.* = 0;
}

// lock now and unlock at the end of the scope
scope_read_write_lock :: (lock: *s32, type: RW_Lock_Type) #expand {
    read_write_lock(lock, type);
    `defer read_write_unlock(lock, type);
}

read_write_lock :: (lock: *s32, type: RW_Lock_Type) {
    // think of positive numbers as 'read' territory, and -100,000 as 'write'
    // -100,001  -100,000   -99,999  ...  -2    -1     0     1      2      3      4   ...
    //               w                                 |     r      r      r      r
    // if a thread that wants to read adds 1 to the lock and gets back a value > 0, read ok
    // if a thread that wants to write subtracts 100,000 and gets back a value = -100,000, write ok
    // using +1 and -100,000 to make it impossible for +1's to push the lock above 0 if writing.
    if type == .READ {
        lock_value_before_add : s32;
        while true {
            lock_value_before_add = atomic_add(lock, 1);            
            if lock_value_before_add >= 0 {
                break;
            }
            atomic_decrement(lock);
        }
    } else { // WRITE
        lock_value_before_subtract : s32;
        while true {
            lock_value_before_subtract = atomic_add(lock, -LARGE_NUMBER);
            if lock_value_before_subtract == 0 {
                break;
            }
            atomic_add(lock, LARGE_NUMBER);
        }
    }
}

read_write_unlock :: (lock: *s32, type: RW_Lock_Type) {
    if type == .READ {
        atomic_decrement(lock);
    } else {
        atomic_add(lock, LARGE_NUMBER);
    }
}

#scope_file

LARGE_NUMBER : s32 : 100_000;

// -----------------------------------------------------------------------------------

#scope_file

#import "Basic";
#import "Atomics";
