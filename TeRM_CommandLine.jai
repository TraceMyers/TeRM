// --- module params & debug ---
// -----------------------------------------------------------------------------------

#module_parameters()(
    // 0, 1, 2 (0=none, 1=validate+log, 2=validate+assert). validation requires TeRM_Log module.
    // term logs can be customized program-wide to go to stdout, stdout + callback, or just callback.
    VALIDATION_LEVEL := 0
);

// optionally replace this proc pointer with a procedure that tells this module whether 
// asserts should be allowed to trigger or not. only used when on validation level 2.
term_command_line_allow_assert := () -> bool { return true; };

// optionally replace this proc pointer with a procedure that tells this module whether 
// logs should be printed or not. only used when on validation level >= 1.
term_command_line_allow_log := () -> bool { return true; };

// -----------------------------------------------------------------------------------

command_line_procedures: [..]Command_Line_Procedure;

Command_Line_Argument :: struct {
    _int: s64; 
    _float: float64;
    _string: string;
    parse_int_success: bool;
    parse_float_success: bool;
}

Command_Line_Procedure :: struct {
    name: string;
    proc: ([]Command_Line_Argument);
    hash: u64;
}

find_command_line_procedure :: (hash: u64) -> s32 {
    for command_line_procedures {
        if hash == it.hash {
            return xx it_index;
        }
    }
    return -1;
}

parse_command_line_arguments :: (str: string) -> []Command_Line_Argument {
    if str.count == 0 {
        return .[];
    }

    tokens := split(str, #char " ");
    out_args := make_dynamic_array(Command_Line_Argument, tokens.count,,temp);
    
    for tokens {
        token := trim(it);

    }
}

try_call_command_line_procedure :: (input_hash: u64, args: []Command_Line_Argument) -> bool {
    index := command_line_procedure_index(input_hash);
    if index >= 0 {
        command_line_procedures[index].proc(args);
        return true;
    } else return false;
}

try_parse_command_line_arg :: (in_arg: *Command_Line_Argument, $T: Type) -> T, bool #expand {
    parse_success := true;
    arg_type_info_type :: #run T.(*Type_Info).type;
    var: T = ---;
    #if arg_type_info_type == .INTEGER {
        var, parse_success = in_arg._int, in_arg.parse_int_success;
    } else #if arg_type_info_type == .FLOAT {
        var, parse_success = in_arg._float, in_arg.parse_float_success;
    } else #if arg_type_info_type == .ENUM {
        arg := in_arg._string;
        var, parse_success = parse_enum(*arg, T);
    } else #if arg_type_info_type == .STRING {
        var = in_arg._string;
    } else {
        assert(false);
    }
    if !parse_success {
        report_module_error("unable to create arg type % from %", T, in_arg.*);
    }
    return var, parse_success;
}

init_command_line_proc_or_return :: (args: []Command_Line_Argument, expected_min_count: s64, expected_max_count := S64_MAX) #expand {
    use_max := expected_max_count;
    if expected_max_count == S64_MAX {
        use_max = expected_min_count;
    }
    if args.count < expected_min_count || args.count > use_max {
        if expected_min_count == expected_max_count {
            report_module_error("expected % args. got %. arglist: %", expected_min_count, args.count, args);
        } else {
            report_module_error("expected %-% args. got %. arglist: %", expected_min_count, expected_max_count, args.count, args);
        }
        `return;
    }
}

#scope_file

S64_MAX :: 0x7fff_ffff_ffff_ffff;

VALIDATION_LEVEL_NONE   :: 0;
VALIDATION_LEVEL_MEDIUM :: 1;
VALIDATION_LEVEL_HIGH   :: 2;

report_module_error :: (fmt: string, args: ..Any) #expand {
    #if VALIDATION_LEVEL >= VALIDATION_LEVEL_MEDIUM {
        #import "TeRM/TeRM_Log";
        if term_command_line_allow_log() {
            trm_log(fmt=fmt, args=..args, log_location=true, header="TeRM/CommandLine");
        }
    } else #if VALIDATION_LEVEL == VALIDATION_LEVEL_HIGH {
        if term_command_line_allow_assert() {
            assert(false, fmt, ..args);
        }
    }
}

// Copyright (c) 2026 Trace Myers
// Licensed under the MIT License. See LICENSE file in the project root for license information.
