
scope_lock :: (mutex: *$T) #expand #modify { return T != RW_Mutex; } {
    lock(mutex);
    `defer unlock(mutex);
}

// -----------------------------------------------------------------------------------

Spin_Mutex :: struct {
    state: bool;
}

lock :: inline (mutex: *Spin_Mutex) {
    try_count: u64;
    while true {
        // read() == should use fewer cycles on failure.
        if atomic_read(*mutex.state) == false && compare_and_swap(*mutex.state, false, true) {
            return;
        }
        pause_cycles := min(try_count * 32, 4096);
        cpu_pause(pause_cycles);
        try_count += 1;
    }
}

unlock :: inline (mutex: *Spin_Mutex) {
    atomic_write(mutex.state, false);
}


// -----------------------------------------------------------------------------------

Spin_Queue_Mutex :: struct {
    counter: u64;
    serving: u64;
}

lock :: inline (mutex: *Spin_Queue_Mutex) {
    try_count: u64;
    ticket := atomic_add(*mutex.counter, 1);
    while atomic_read(*mutex.serving) != ticket {
        pause_cycles := min(try_count * 32, 4096);
        cpu_pause(pause_cycles);
        try_count += 1;
    }
}

unlock :: inline (mutex: *Spin_Queue_Mutex) {
    atomic_add(*mutex.serving, 1);
}


// -----------------------------------------------------------------------------------

RW_Lock_Type :: enum u8 {
    READ;
    WRITE;
}

RW_Mutex :: struct {
    state: s64;
    wait_events: [..]Event_Handle;
    wait_events_mutex: Spin_Mutex;

    READ_KEY  : s64 : 1;
    WRITE_KEY : s64 : -48_000;
}

RW_Mutex_Acquired :: struct {
    unlock_key: s64;
}

init :: (mutex: *RW_Mutex) {
    mutex.wait_events.allocator = context.allocator;
}

lock :: inline (mutex: *RW_Mutex, $type := RW_Lock_Type.WRITE) -> RW_Mutex_Acquired {
    acquired: RW_Mutex_Acquired = ---;

    #if type == .READ {
        lock_loop(mutex, RW_Mutex.READ_KEY,  state => state >= 0);
        acquired.key = -RW_Mutex.READ_KEY;
    } else {
        lock_loop(mutex, RW_Mutex.WRITE_KEY, state => state == 0);
        acquired.key = -RW_Mutex.WRITE_KEY;
    }
    
    return acquired;
}

unlock :: inline (mutex: *RW_Mutex, acquired: RW_Mutex_Acquired) {
    atomic_add(*mutex.state, acquired.unlock_key);
    // note: I think some threads might get stranded
    wake_front(mutex);
}

scope_lock :: (mutex: *RW_Mutex, $type := RW_Lock_Type.WRITE) {
    acquired := lock(mutex, type);
    `defer unlock(mutex, acquired);
}

#scope_file

lock_loop :: (mutex: *RW_Mutex, key: s64, $lock_acquired: (s64) -> bool) {
    try_count: s64;
    queued_at_least_once: bool;

    while true {
        if inline lock_acquired(mutex.state) {
            pre_lock_value := atomic_add(*mutex.state, key);           
            if inline lock_acquired(pre_lock_value) {
                if queued_at_least_once {
                    wake_front(mutex);
                }
                return;
            }
            atomic_add(*mutex.state, -key);
        }

        if try_count < 32 {
            pause_cycles := try_count * 128;
            cpu_pause(pause_cycles);
            try_count += 1;
        } else {
            try_count >>= 1;

            event := borrow_thread_wait_event();
            add_event_handle(mutex, event.handle);
            wait_for_event(event.handle);
            return_thread_wait_event(*event);

            queued_at_least_once = true;
        }
    }
}

wake_front :: inline (mutex: *RW_Mutex) {
    lock(*mutex.wait_events_mutex);
    front_event: Event_Handle;
    if mutex.wait_events.count > 0 {
        front_event := mutex.wait_events[0];
        array_ordered_remove_by_index(*mutex.wait_events, 0);
        unlock(*mutex.wait_events_mutex);
        signal_event(front_event);
        return;
    }
    unlock(*mutex.wait_events_mutex);
}

add_event_handle :: inline (mutex: *RW_Mutex, handle: Event_Handle) {
    scope_lock(*mutex.wait_events_mutex);
    array_add(*mutex.wait_events, handle);
}

#scope_export

// -----------------------------------------------------------------------------------

init_thread_wait_events :: () {
    context.thread_wait_Events.items.allocator = context.allocator;
    context.thread_wait_Events.queue.allocator = context.allocator;
}

borrow_thread_wait_event :: () -> Thread_Wait_Event {
    using context.thread_wait_events;

    assert(items.count < U16_MAX);

    if queue.count == 0 {
        old_count := items.count;
        new_count := max(16, old_count * 2);
        array_resize(*items, new_count);
        array_reserve(*queue, new_count);
        for < old_count..new_count-1 {
            array_add(*queue, it);
        }
    }

    event  := Thread_Wake_Event.{pool_id=queue[queue.count-1]};
    queue.count -= 1;

    handle := *items[event.pool_id];

    if handle.* == null {
        handle.* = CreateEventA(null, Win32.BOOL.TRUE, Win32.BOOL.FALSE, tprint("thread wait event %", event.pool_id));
        assert(handle.* != null);
    }
    event.handle = handle.*;

    return event;
}

return_thread_wait_event :: (event: *Thread_Wait_Event) {
    handle := context.thread_wait_events.items[event.pool_id];
    reset_event(event.handle);
    array_add(*context.thread_wait_events.queue, event.pool_id);
    event.* = {};
}

// -----------------------------------------------------------------------------------

#scope_file

#if OS == .WINDOWS {
    Win32 :: #import "Windows";
    Event_Handle :: Win32.HANDLE;
    #add_context thread_wait_events: Event_Pool;

    reset_event :: (handle: Event_Handle) {
        Win32.ResetEvent(handle);
    }

    signal_event :: (handle: Event_Handle) {
        Win32.SetEvent(handle);
    }

    wait_for_event :: (event: Event_Handle) {
        result := Win32.WaitForSingleObject(event, Win32.INFINITE);
        // ideally this would be a continuable break
        assert(result == Win32.WAIT_OBJECT_0);
    }
}

Thread_Wait_Event :: struct {
    handle: Event_Handle;
    pool_id: s64;
}

Event_Pool :: struct {
    items: [..]Event_Handle;
    queue: [..]u16;
}


#import "TeRM/TeRM_System";
#import "TeRM/TeRM_Storage";

#import "Basic";
#import "Atomics";
#import "Machine_X64";
