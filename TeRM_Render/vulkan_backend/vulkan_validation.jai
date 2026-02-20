validate :: (result: $T, error_msg: string, msg_args: ..Any, caller_loc := #caller_location) -> bool #expand 
#modify { return T == bool || T == VkResult; } {
    #if VALIDATION_ON {
        error_code_str: string;
        #if T == VkResult {
            failure := result != .SUCCESS;
            error_code_str = tprint("[VK ERROR: %] ", result);
        } else {
            failure := !result;
        }
        if failure {
            render_log(fmt=tprint("% :: %", error_code_str, error_msg), args=..msg_args, caller_loc=caller_loc);
            return false;
        }
    }
    return true;
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
