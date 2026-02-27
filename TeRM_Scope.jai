
scope_lock_mutex :: (mutex: *Mutex) #expand {
    lock(mutex);
    `defer unlock(mutex);
}

scope_set_working_directory :: (dir: string) #expand {
    cwd := get_working_directory();
    set_working_directory(dir);
    `defer set_working_directory(cwd);   
}

scope_set_allocator :: (allocator: Allocator) #expand {
    original_allocator := context.allocator;
    context.allocator = allocator;
    `defer context.allocator = original_allocator;
}

#scope_file

#import "Thread";
#import "Basic";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
