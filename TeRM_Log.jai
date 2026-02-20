// have the logging system call this proc with the finalized text, if set
term_log_passthrough_callback: (log_text: string);

// if true, don't log to stdout - only send contextualized log text to the passthrough callback
call_term_log_passthrough_only := false;

trm_error :: (fmt: string, args: ..Any, log_location := true, caller_loc := #caller_location) #expand {
    log_context := #procedure_name();
    report_impl(fmt, ..args, log_context=log_context, log_location, caller_loc, "ERROR");
}

trm_warning :: (fmt: string, args: ..Any, log_location := true, caller_loc := #caller_location) #expand {
    log_context := #procedure_name();
    report_impl(fmt, ..args, log_context=log_context, log_location, caller_loc, "WARNING");
}

trm_log :: (fmt: string, args: ..Any, log_location := false, caller_loc := #caller_location, header := "LOG", add_newline := true) #expand {
    log_context := #procedure_name();
    report_impl(fmt, ..args, log_context=log_context, log_location, caller_loc, header, add_newline);
}

#scope_file

report_impl :: (
    fmt: string, 
    args: ..Any, 
    log_context: string, 
    log_location: bool, 
    caller_loc: Source_Code_Location, 
    header: string,
    add_newline := true
) {
    auto_release_temp();

    MAX_HEADER_COUNT :: 16;
    MAX_CONTEXT_COUNT :: 26;
    BRACKETS_COUNT :: 4;
    END_LEAD_SPACE :: 1;
    LEAD_BUFFER_SIZE :: MAX_HEADER_COUNT + MAX_CONTEXT_COUNT + BRACKETS_COUNT;

    lead_buffer := talloc(LEAD_BUFFER_SIZE);
    lead_buffer_string := string.{0, xx lead_buffer};
    print_lead_item_to_buffer_string(*lead_buffer_string, header, MAX_HEADER_COUNT);
    print_lead_item_to_buffer_string(*lead_buffer_string, log_context, MAX_CONTEXT_COUNT);

    use_location: string;
    if log_location {
        use_location = tprint("\n>%", caller_loc);
    }

    msg := tprint(fmt, ..args);
    fully_processed_text := tprint("% % %", lead_buffer_string, msg, use_location);

    if term_log_passthrough_callback {
        term_log_passthrough_callback(fully_processed_text);
    }
    if !call_term_log_passthrough_only {
        if add_newline {
            log(fully_processed_text);
        } else {
            print(fully_processed_text);
        }
    }
}

print_char_to_buffer_string :: inline (bufstr: *string, char: u8) {
    bufstr.count += 1;
    bufstr.*[bufstr.count-1] = char;
}

print_lead_item_to_buffer_string :: inline (bufstr: *string, lead_item: string, $MAX_COUNT: s64) {
    print_char_to_buffer_string(bufstr, #char "[");
    remain_space := MAX_COUNT - lead_item.count;
    for c : 0..lead_item.count-1 {
        if c >= MAX_COUNT then break;
        else if remain_space < 0 && (c == MAX_COUNT-2 || c == MAX_COUNT-1) {
            print_char_to_buffer_string(bufstr, #char ".");
        } else {
            print_char_to_buffer_string(bufstr, lead_item[c]);
        }
    }
    print_char_to_buffer_string(bufstr, #char "]");

    for i : 0..remain_space-1 {
        print_char_to_buffer_string(bufstr, #char " ");
    }
}

#import "Basic";

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
