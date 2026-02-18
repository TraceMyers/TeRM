
scope_lock_mutex :: (mutex: *Mutex) #expand {
    lock(mutex);
    `defer unlock(mutex);
}

scope_set_working_directory :: (dir: string) #expand {
    cwd := get_working_directory();
    set_working_directory(dir);
    `defer set_working_directory(cwd);   
}

#scope_file

#import "Thread";
