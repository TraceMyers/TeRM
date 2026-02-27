// do not use this. it's mid-development
// why is it here? because it doesn't hurt anybody

// todo: temp/allocator stuff

// --- sections --- 
// interface procedures
// interface types
// errors
// parse mid layer
// parse number
// parse string
// parse boolean or null
// on enter and exit
// collection handling first pass
// collection handling second pass
// misc

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------- :interface procedures

// alt name
load_json :: load_json_from_file;

load_json_from_file :: (file_path: string, log_errors := false) -> JSON_Load_Result {
    on_enter_load(log_errors);

    // todo: go back to temp
    file_data, success := read_entire_file(file_path, log_errors=log_errors);
    // file_data, success := read_entire_file(file_path, log_errors=log_errors,, temp);

    if !success {
        add_load_error(.FAILED_TO_LOAD_FILE, 0, .FATAL);
        return context.json_load_result;
    }

    return load_json_from_string(file_data, log_errors);
}

load_json_from_string :: (text: string, log_errors := false) -> JSON_Load_Result {
    // two pass loader. iterates over text once to get collection data for allocations and a second time
    // to parse and create the elements array
    on_enter_load(log_errors);

    result := *context.json_load_result;
    result.file_size = xx text.count;

    collection_markers, element_count, success := gather_collection_markers(text, *collection_markers);

    if success {
        elements:, success = gather_elements(text, *collection_markers, element_count);
        if success then context.json_load_result.elements = elements;
    }

    if success {

    }

    report_module_error("collection marker count: %", collection_markers.count);
    report_module_error("text_size: %", text.count);
    report_module_error("collection_markers_per_byte: %", cast(float) collection_markers.count / text.count);
    report_module_error("bytes per collection marker: %",  cast(float) text.count  / collection_markers.count);
    report_module_error("collection markers: %", collection_markers);

    return context.json_load_result;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :interface types

JSON_Load_Result :: struct {
    // recursive-intrusive list of all elements. 
    // first object is file root, a special object representing the collection of top-level elements
    elements: []JSON_Element;
    // the size of the data that was read, whether a file or string was input. 
    file_size: s32;
    // if there are any errors, they will be in this list. errors are not necessarily
    // fatal. if fatal, they will be marked. fatal errors mark an unsucessful load.
    // this array points into a buffer owned by the module, and it's valid until 
    // the next load or save.
    // errors and terminal errors do not mean that the nodes weren't at least partially parsed
    errors: []JSON_Error;
    // for now, always utf8. may make this a parameter in the future.
    string_encoding: Text_Encoding = .UTF8;
    // if any errors caused loading to exit early, this will be true. if so,
    // the final error in the list is guaranteed to be a fatal one, but not necessarily the
    // inciting error. if the error list is truncated, the fatal error replaced a non-fatal one. 
    any_fatal_errors: bool;
    // if adding more errors would have overflowed the internal buffer, this is set
    errors_truncated: bool;
}

JSON_Element_Type :: enum u8 {
    // default element type. used for debugging.
    INTERNAL_UNINITIALIZED :: 0;
    // an object or array that is being or has been expored as a parent.
    // post-processed into an object or array.
    INTERNAL_COLLECTION_BUILDER;
    // types for you~
    OBJECT;
    ARRAY;
    STRING;
    INT;
    FLOAT;
    TRUE;
    FALSE;
    NULL;
}

JSON_Element :: union type: JSON_Element_Type {
    // internal fields. explained in enum.
    .INTERNAL_UNINITIALIZED      ,, _internal_null : void;
    .INTERNAL_COLLECTION_BUILDER ,, _internal_collection_builder : JSON_Collection_Builder;
    // fields for you~
    .OBJECT                   ,, object         : JSON_Object;
    .ARRAY                    ,, array          : JSON_Array;
    .STRING                   ,, bytes          : string;
    .INT                      ,, i64            : s64;            
    .FLOAT                    ,, f64            : float64;
    .TRUE                     ,, _true          : void; 
    .FALSE                    ,, _false         : void; 
    .NULL                     ,, _null          : void; 
}

JSON_Object :: struct {
    // an array the superimposes the KV_Pair type on top of JSON_Element. 
    // when adding elements from an object, into the elements array, 
    // the per-element layout looks like: [(key),(value),(key),(value), ..]
    // this array just puts a different view on it: [(key, value), (key, value), ..]
    elements : []JSON_KV_Pair;
}

JSON_Array :: struct {
    elements : []JSON_Element;
}

JSON_KV_Pair :: struct {
    key   : JSON_Element;
    value : JSON_Element;
}

JSON_Collection_Parse_State :: enum u8 {
    OBJECT_EXPECT_KEY_OR_END :: 1;
    OBJECT_EXPECT_KEY;
    OBJECT_EXPECT_COLON;
    OBJECT_EXPECT_VALUE;
    OBJECT_EXPECT_COMMA_OR_END;
    ARRAY_EXPECT_VALUE_OR_END;
    ARRAY_EXPECT_VALUE;
    ARRAY_EXPECT_COMMA_OR_END;
}

JSON_Collection_Builder :: struct {
    type: JSON_Element_Type;
    state: JSON_Collection_Parse_State;
    child_elements_offset  : s32;
    child_elements_count   : s32;
    child_elements_counter : s32;
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------------- :errors

JSON_Error_Code :: enum u16 {
    FAILED_TO_LOAD_FILE;
    FOUND_EXTRA_END_CURLY_BRACE;
    FOUND_EXTRA_END_SQUARE_BRACE;
    FOUND_COLLECTION_WITHOUT_END_DELIMITER;
    FOUND_TRAILING_COMMA;
    EXPECTED_OBJECT_END_DELIMITER;
    EXPECTED_ARRAY_END_DELIMITER;
    EXPECTED_TRUE;
    EXPECTED_FALSE;
    EXPECTED_NULL;
}

JSON_Error_Flags :: enum_flags u16 {
    FATAL;
    INTERNAL_UNPROCESSED;
}

JSON_Error :: struct {
    code: JSON_Error_Code; 
    flags: JSON_Error_Flags;
    line: s32;
    column: s32;
    // converted to line,column on exit
    #overlay(line) _internal_file_position: s32 = ---;
}

#scope_file // ----------------------------------------------------------------------

add_load_error :: (code: JSON_Error_Code, file_position: s64, flags: JSON_Error_Flags = 0) {
    using context;

    if flags & .FATAL {
        json_load_result.any_fatal_errors = true;
    }

    error := JSON_Error.{
        code=code, flags=flags|.INTERNAL_UNPROCESSED, _internal_file_position=xx file_position
    };

    if json_errors.count == json_error_buffer.count {
        if json_load_result.any_fatal_errors {
            // make sure at least the final fatal error is recorded, even if the errors are truncated.
            json_error_buffer[json_error_buffer.count-1] = error;
        }
        json_load_result.errors_truncated = true;
        return;
    }

    json_errors.count += 1;
    json_errors[json_errors.count-1] = error;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------ :parse mid layer

JSON_Element_Parser :: struct {
    text: string;
    pos: s64;
    elements: [..]JSON_Element;
    markers: []Collection_Marker; 
    builder_stack: [..]s32;
    building_collection: *JSON_Collection_Builder;
}

gather_collection_markers :: (text: string) -> markers: []Collection_Marker, total_element_count: int, success: bool {
    markers: [..]Collection_Marker;
    markers.allocator = temp;
    // from a single test file, estimated 131 bytes per collection. 
    // 96 < 131, conservative estimate giving more markers
    array_reserve(*markers, max(text.count / 96, 64));

    collection_marker_stack: [..]int;
    collection_marker_stack.allocator = temp;
    array_reserve(*markers, 128);

    top_marker := push_top_marker(.OBJECT, 0);
    inside_string := false;
    total_element_count := 0;

    // 73 us
    for text {
        if is_space(it) {
            continue;
        } else if inside_string {
            if it == "\"" && it_index > 0 && text[it_index-1] != "\\" {
                inside_string = false;
            }
        } else if it == #char "}" {
            on_collection_ending_delimiter_found(.OBJECT);
            top_marker = pop_top_marker();
            if top_marker == null {
                add_load_error(.FOUND_EXTRA_END_CURLY_BRACE, it_index, .FATAL);
                return .[], 0, false;
            }
        } else if it == #char "]" {
            on_collection_ending_delimiter_found(.ARRAY);
            top_marker = pop_top_marker();
            if top_marker == null {
                add_load_error(.FOUND_EXTRA_END_SQUARE_BRACE, it_index, .FATAL);
                return .[], 0, false;
            }
        } else if it == #char "," {
            if top_marker.text_encountered_since_last_delimiter {
                total_element_count += 1;
                top_marker.element_count += 1;
                top_marker.text_encountered_since_last_delimiter = false;
            } else {
                add_load_error(.FOUND_TRAILING_COMMA, it_index, .FATAL);
                return .[], 0, false;
            }
        } else {
            top_marker.text_encountered_since_last_delimiter = true;
            if it == {
            case #char "{";
                top_marker = push_top_marker(.OBJECT, it_index);
                total_element_count += 1;
            case #char "[";
                top_marker = push_top_marker(.ARRAY, it_index);
                total_element_count += 1;
            case #char ":";
                total_element_count += 1;
            case #char "\"";
                inside_string = true;
            }
        }
    }

    if collection_marker_stack.count != 1 {
        add_load_error(.FOUND_COLLECTION_WITHOUT_END_DELIMITER, top_marker.file_position, .FATAL);
        return .[], 0, false; 
    } 

    return markers, total_element_count, true;
}

gather_elements :: (text: string, collection_markers: []Collection_Marker, element_count: int) -> []JSON_Element {
    parser: JSON_Element_Parser;
    parser.text = text;
    array_reserve(*parser.elements, element_count*9/8);
    parser.builder_stack.allocator = temp;
    array_reserve(*parser.builder_sack, 128);
    parser.markers = collection_markers;

    // bottom of stack = whole file = root object
    success := push_collection(*parser, .OBJECT, false);
    if !success {
        return .[];
    }

    while parser.pos < parser.text.count {
        byte := parser.text[parser.pos];
        
        if is_space(byte) {
            parser.pos += 1;
            continue;
        }

        if byte == {
        case #char "{";
            if !begin_parse_collection(*parser, .OBJECT) {
                return .[];
            }
        case #char "[";
            if !begin_parse_collection(*parser, .ARRAY) {
                return .[];
            }
        case #char "\"";
            if !parse_string(*parser) {
                return .[];
            }
        case #char "t";
            if !parse_boolean_or_null(*parser, .TRUE) {
                return .[];
            }
        case #char "f";
            if !parse_boolean_or_null(*parser, .FALSE) {
                return .[];
            }
        case #char "n";
            if !parse_boolean_or_null(*parser, .NULL) {
                return .[];
            }
        case #char ",";
            if building_collection.state == {
            case .OBJECT_EXPECT_COMMA_OR_END;
                building_collection.state = .OBJECT_EXPECT_KEY;
            case .ARRAY_EXPECT_COMMA_OR_END;
                building_collection.state = .ARRAY_EXPECT_VALUE;
            case;
                // todo : error
                return .[];
            }
        case #char ":";
            if building_collection.state == {
            case .OBJECT_EXPECT_COLON;
                building_collection.state = .OBJECT_EXPECT_VALUE;
            case;
                // todo : error
                return .[];
            }
        case #char "}";
            if building_collection.state == {
            case .OBJECT_EXPECT_KEY_OR_END;
                #through;
            case .OBJECT_EXPECT_COMMA_OR_END;
                if parser.building_collection.type != .OBJECT {
                    // todo : error
                    return .[];
                }
                if !pop_collection() {
                    return .[];
                }
            case;
                // todo : error
                return .[];
            }
        case #char "]";
            if building_collection.state == {
            case .ARRAY_EXPECT_VALUE_OR_END;
                #through;
            case .ARRAY_EXPECT_COMMA_OR_END;
                if parser.building_collection.type != .ARRAY {
                    // todo : error
                    return .[];
                }
                if !pop_collection() {
                    return .[];
                }
            case;
                // todo : error
                return .[];
            }       
        case;
            if is_digit(it) || it == "-" {
                parse_number(*parser);
            } else {
                // todo : error
                return .[];
            }
        }
    }

    return parser.elements;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------------------ :parse int

Parse_Number_Stage :: enum {
    SIGN; 
    BASE_BEGIN;
    BASE_ZERO;
    BASE_NONZERO;
    FRACTION_DIGITS_BEGIN;
    FRACTION_DIGITS;
    EXPONENT_SIGN; 
    EXPONENT_DIGITS_BEGIN;
    EXPONENT_DIGITS;
}

JSON_Number_Parser :: struct {
    sign           : s64 = 1;
    exponent_sign  : s64 = 1;
    base           : s64;
    base           : s64;
    fraction: string;
    stage: Parse_Number_Stage;
}

parse_number :: (text_parser: *JSON_Parser) -> bool {
    using number_parser: JSON_Number_Parser;

    success                         := parse_number_components(*number_parser, text_parser);
    if !success then return false;
    represent_with_integer:, success = should_represent_number_with_integer(*number_parser, parser);
    if !success then return false;

    if represent_with_integer {
        if exponent > 0 {
            base = mul_by_pow10_exponent(base, exponent, exponent_sign);
        }
        element := push_collection_child(text_parser);
        element.type = .INT;
        element.i64 = base * number_parser.sign;
    } else {
        element := push_collection_child(text_parser);
        element.type = .FLOAT;
        element.f64 = compose_float(base * sign, fraction, exponent * exponent_sign);
    }

    return true;
}

parse_number_components :: (using number_parser: *JSON_Number_Parser, text_parser: *JSON_Parser) -> success: bool {
    while text_parser.pos < text_parser.text.count {
        byte := text_parser.text[text_parser.pos];

        if byte == {
        case #char "+";
            if stage == .EXPONENT_SIGN {
                stage = .EXPONENT_DIGITS; 
            } else {
                // todo: error
                return false;
            }
        case #char "-";
            if stage == {
            case .SIGN;
                sign = -1;
                stage = .BASE_BEGIN;
            case .EXPONENT_SIGN;
                exponent_sign = -1;
                stage = .EXPONENT_DIGITS; 
            case;
                // todo: error
                return false;
            }
        case #char ".";
            if stage == .BASE_ZERO || stage == .BASE_NONZERO {
                stage = .FRACTION_DIGITS_BEGIN;
            } else {
                // todo: error
                return false;
            }
        case #char "E";
            #through;
        case #char "e";
            if stage == .BASE_ZERO || stage == .BASE_NONZERO || stage == .FRACTION_DIGITS {
                stage = .EXPONENT_SIGN;
            } else {
                // todo: error
                return false;
            }
        case;
            digit := to_digit(byte); // returns 0xff if not digit
            if digit <= 9 {
                if stage == {
                case .SIGN;
                    #through;
                case .BASE_BEGIN;
                    if digit == 0 {
                        stage = .BASE_ZERO;
                    } else {
                        stage = .BASE_NONZERO;
                    }
                case .BASE_ZERO;
                    // todo: error
                    return false;
                case .BASE_NONZERO;
                    base = base * 10 + digit;
                case .FRACTION_DIGITS_BEGIN;
                    fraction.data = text_parser.text.data + text_parser.pos;
                    fraction.count = 1;
                    stage = .FRACTION_DIGITS;
                case .FRACTION_DIGITS;
                    fraction.count += 1;
                case .EXPONENT_DIGITS_BEGIN;
                    stage = .EXPONENT_DIGITS;
                    #through;
                case .EXPONENT_DIGITS;
                    exponent = exponent * 10 + digit;
                }
            } else {
                break;
            }
        }
        
        text_parser.pos += 1;
    }

    // trim trailing zeroes from the fraction
    while fraction.count > 0 && fraction[fraction.count-1] == "0" {
        fraction.count -= 1;
    }

    return true;
}

should_represent_number_with_integer :: (using number_parser: *JSON_Number_Parser, text_parser: *JSON_Parser) -> should_use_int: bool, success: bool {
    maybe_represent_with_float := fraction.count == 0;

    if stage == { 
    case .SIGN; 
        // todo : error
        return false, false;
    case .BASE_BEGIN;
        // todo : error
        return false, false;
    case .BASE_ZERO;
        #though;
    case .BASE_NONZERO;
        // this may not necessarily be the right call, but if so, critical information
        // is already gone due to representing the base as a 64 bit integer during parsing
        maybe_represent_with_float = false;
    case .FRACTION_DIGITS_BEGIN;
        // todo : error
        return false, false;
    case .FRACTION_DIGITS;
        // float ok
    case .EXPONENT_SIGN; 
        // todo : error
        return false, false;
    case .EXPONENT_DIGITS_BEGIN;
        // todo : error
        return false, false;
    case .EXPONENT_DIGITS;
        // todo: see if it can be represented as an integer
        // float ok
    }

    represent_with_integer := true;

    if maybe_represent_with_float {
        represent_with_integer = false;
        // checking if the value can be an int even though a fraction was put in the number
        // is messy, so I'm going to avoid it for now.
        // todo: see if numbers with fractions can be represented as integers.
        if fraction.count == 0 {
            // conservative estimation to see if an integer representation is possible.
            // if we round the exponent to the nearest power of two, that represents a
            // bit shift left or right. if we could shift left or right while only losing
            // zeroes, the number can definitely be an int.
            exponent_nearest_pow2 := ceil_to_power_of_two(exponent);
            exponent_shift_size := shift_for_power_of_two_mul_or_div(exponent_nearest_pow2);
            erasable_zeroes := ifx exponent_sign == 1 then bit_scan_reverse(base) else bit_scan_forward(base);

            if exponent_shift_size <= erasable_zeroes {
                represent_with_integer = true;
            }
        }
    }

    return represent_with_integer;
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------- :parse string

// helper struct for allocating the strings into the elements array
JSON_String_Parser :: struct {
    json_elements: *[..]JSON_Element;
    fake_elements_begin_index: s32;
    fake_elements_count: s32;
    string_bytes: string;
    string_builder: string;
    passthrough_byte_count: int;
    i: int;


parse_string :: (parser: *JSON_Parser) -> bool {
    // get past opening quote
    parser.pos += 1;
    
    using string_parser: JSON_String_Parser;
    json_elements = *parser.elements;

    remaining_bytes := parser.text.count - parser.pos;
    remaining_text  := string.{remaining_bytes, parser.text.data + parser.pos};
    // collect string including end quote
    string_bytes=, found_end_quote := consume_until_non_escaped_quote(remaining_text);
    parser.pos += string_bytes.count + 1;

    if !found_end_quote {
        parser.pos -= 1;
        // todo : error
        return false;
    }

    while i + passthrough_byte_count < string_bytes.count {
        if byte == #char "\\" {

            if passthrough_bytes > 0 {
                push_bytes(parser, {passthrough_bytes, string_bytes.data + i};
                i += passthrough_bytes;
            }
            i += 1;

            if string_bytes[i] == {
            case #char "\"";
                push_byte(*string_parser, #char "\"");
            case #char "\\";
                push_byte(*string_parser, #char "\\");
            case #char "/";
                push_byte(*string_parser, #char "/");
            case #char "b";
                push_byte(*string_parser, #char "\b");
            case #char "f";
                push_byte(*string_parser, #char "\f");
            case #char "n";
                push_byte(*string_parser, #char "\n");
            case #char "r";
                push_byte(*string_parser, #char "\r");
            case #char "t";
                push_byte(*string_parser, #char "\t");
            case #char "u";
                parse_hex_bytes(*string_parser);
            }
        } else if byte == #char "\"" {
            assert(i + passthrough_byte_count + 1 == string_bytes.count);
            break;
        } else {
            passthrough_byte_count += 1;
        }
    }
    
    if passthrough_bytes > 0 {
        push_bytes(parser, {passthrough_bytes, string_bytes.data + i};
    }
    
}

consume_until_non_escaped_quote :: inline (text: string) -> bytes: string, found_quote: bool {
    exchange := String_Exchange.{src=text};
    for exchange {
        if it == #char "\"" && (it_index == 0 || exchange.src[it_index-1] != #char "\\") {
            break;
        }
    }
    return exchange.dst, exchange.broke_out_of_loop;
}

// not a generally good resize function, but marginally correct
resize_if_needed :: inline (using string_parser: *JSON_String_Parser, new_strlen: int) {
    capacity := fake_elements_count * size_of(JSON_Element);
    if new_strlen < capacity {
        array_resize(json_elements, json_elements.count + new_element_count);
        fake_elements_count += new_element_count;
        if old_capacity == 0 {
            assert(string_builder.count == 0);
            fake_elements_begin_index = xx (json_elements.count - 1);
        }
        // always set this ptr after an array resize!
        string_builder.data = xx (json_elements.data + fake_elements_begin_index);
    }
}

push_byte :: inline (using string_parser: *JSON_String_Parser, byte: u8) {
    new_strlen := string_builder.count + 1;
    resize_if_needed(string_parser, new_strlen);
    string_builder.count += 1;
    string_builder[string_builder.count-1] = byte;
}

push_bytes :: inline (using string_parser: *JSON_String_Parser, bytes: string) {
    new_strlen := string_builder.count + bytes.count;
    resize_if_needed(string_parser, new_strlen);
    old_count := string_builder.count;
    string_builder.count += bytes.count;
    memcpy(string_builder.data + old_count, bytes.data, bytes.count);
}

push_byte :: inline (using parser: *JSON_String_Parser, code: u8) {
    push_byte(parser, code);
    i += 1;
}

parse_hex_bytes :: (using parser: *JSON_String_Parser) {

}
// utf16_to_utf8 :: (in: *u8, out: *u8, in_buf_size: int, out_buf_size: int) -> s8, s8, Text_Encode_Failure {


// -----------------------------------------------------------------------------------
// ------------------------------------------------------------ :parse boolean or null

parse_boolean_or_null :: (parser: *JSON_Parser, $type: JSON_Element_Type) -> bool {
    // it's a car with a spoiler.
    //               _____________
    type_string ::  //////////////\
             #ifx type == .TRUE  then "true" 
        else #ifx type == .FALSE then "false";
        else                          "null";

    remaining_bytes := parser.text.count - parser.pos;
    str_in_text := string.{min(type_string.count, remaining_bytes), parser.text.data + parser.pos};
    parser.pos += str_in_text.count;

    if str_in_text != type_string {
        // todo : error
        return false;
    }

    element := push_collection_child(parser);
    element.type = type;

    return true;
}

// -----------------------------------------------------------------------------------
// ---------------------------------------------------------------- :on enter and exit

on_enter_load :: (log_errors: bool) #expand {
    `_mark := get_temporary_storage_mark();
    `defer if context.allocator.proc != temp.proc then set_temporary_storage_mark(`_mark);

    `defer context.json_load_initialized = false;
    `defer context.json_load_result.errors = context.json_errors;

    // making sure errors don't get reset when non-fatal errors occur during 
    // initial wrapper procedures
    if !context.json_load_initialized {
        context.json_load_result = {};

        context.json_errors.data = context.json_error_buffer.data;
        context.json_errors.count = 0;

        context.json_load_initialized = true;
    }
}

on_exit_load :: (file_text: string, elements: *[..]JSON_Element, log_errors: bool) {
    using context;

    json_load_result.elements = elements.*;

    if file_text.count > 0 && json_errors.count > 0 {
        next_file_position := 0;

        // each error originally is only recorded at a file position
        // convert that to line, column
        for :per_line line, line_index : file_text {
            file_position := next_file_position;
            next_file_position += line.count;

            processed_error_count := 0;

            for *err : json_errors {
                if (err.flags & .INTERNAL_UNPROCESSED) == 0 {
                    processed_error_count += 1;
                    continue;
                }

                if err._internal_file_position >= file_position 
                && err._internal_file_position < next_file_position {
                    err.column = xx (err._internal_file_position - file_position);
                    err.line = xx line_index;
                    err.flags &= ~.INTERNAL_UNPROCESSED;

                    space_buffer: [128]u8 = ---;
                    space_count := min(space_buffer.count, err.column);
                    memset(space_buffer.data, " ", space_count);
                    spaces := string.{space_count, space_buffer.data};

                    if log_errors {
                        report_module_error(
#string HERE


    error code : %
    flags      : %
    line #     : %
    column #   : %
    line       : '%'
                  %^
HERE,
                            err.code, err.flags, err.line, err.column, line, spaces
                        );
                    }

                    processed_error_count += 1;
                }
            }

            if processed_error_count == json_errors.count {
                break;
            }
        }
    }
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------- :collection handling first pass

Collection_Marker :: struct {
    type: JSON_Element_Type;
    element_count: s32; 
    file_position: s32;
    text_encountered_since_last_delimiter: bool;
}

pop_top_marker :: () -> *Collection_Marker #expand {
    array_unordered_remove_by_index(*`collection_marker_stack, `collection_marker_stack.count-1);
    if `collection_marker_stack.count == 0 {
        return null;
    }
    return *`markers[`collection_marker_stack[`collection_marker_stack.count-1]];
}

push_top_marker :: (type: JSON_Element_Type, file_position: int) -> *Collection_Marker #expand {
    if `collection_marker_stack.count == 1 {
        // found a top-level element. need to make sure root element increments its count
        `markers[`collection_marker_stack[0]].element_count += 1;
    }
    array_add(*`markers, {type, 0, xx file_position, false});
    array_add(*`collection_marker_stack, `markers.count-1);
    return *`markers[`collection_marker_stack[`collection_marker_stack.count-1]];
}

on_collection_ending_delimiter_found :: (type: JSON_Element_Type) #expand {
    if `top_marker.type != type {
        // todo : error
    }
    any_commas_encountered := `top_marker.element_count > 0;
    if `top_marker.text_encountered_since_last_delimiter {
        `top_marker.element_count += 1;
        `total_element_count += 1;
    } else if any_commas_encountered {
        // no text since last comma = invalid
        // todo : error
    }
}

// get the in-place location of the new element within the parent collection's list,
// the parent collection's list is allocated when the collection is pushed.
push_collection_child :: inline (parser: *JSON_Parser) -> *JSON_Element {
    using parser.building_collection;
    assert(child_elements_offset < child_elements_count);
    element_index := child_elements_offset + child_elements_counter;
    new_element = *parser.elements[element_index];
    child_elments_counter += 1;
    return new_element;
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------- :collection handling second pass

push_collection :: (using parser: *JSON_Parser, type: JSON_Element_Type, $in_place := true) -> success: bool {
    if markers.count == 0 {
        // todo: error
        return false;
    }

    // in the first pass, information about how many elements were in each collection
    // was gathered and put into a marker. retrieving the marker for this collection,
    // treating the markers array as a fifo stack.
    marker := *(markers.*)[0];
    markers.data  += 1;
    markers.count -= 1;

    new_collection: *JSON_Element;

    #if in_place {
        // all elements (except for the root object) are children of a parent collection. 
        // this new collection is also a child. as it happens below, when a collection is 
        // pushed, that collection's element list is reserved at the end of the elements array 
        //                               -----------------
        //                              |                 |
        //                              |                 v
        // elements array = ... [ parent collection ] ... [ elem 0 ] [ elem 1] ...
        //                                                           ^
        //                                                           |
        // if the parent object's list already has 1 previously instantiated element,
        // we are getting this element back from this proc call. the element itself will 
        // become a parent object with its own list at the end of the array.
        new_element = push_collection_child(parser);
    } else {
        // the only non-in-place element allocation is the root object
        assert(elements.count == 0);
        new_element = array_add(*elements);
    }

    new_element.type = .INTERNAL_COLLECTION_BUILDER;
    {
        using new_element._internal_collection_builder;
        type = type;
        child_elements_count = marker.element_count;
        state = ifx type == .OBJECT then .OBJECT_EXPECT_KEY_OR_END else .ARRAY_EXPECT_VALUE_OR_END;

        if child_elements_count > 0 {
            child_elements_offset = xx elements.count;
            // push all of this collection's elements into the element array right now 
            // so they're contiguously allocated. elements will have type UNINITIALIZED
            // so they can be checked later to make sure they were set correctly after this step
            array_resize(*elements, elements.count + marker.element_count);
            // put this collection at the top of the stack
            array_add(builder_stack, xx (new_element - elements.data));
            building_collection = *new_element._internal_element_builder;
        } else {
            child_elements_offset = -1;
        }
    }

    return true;
}

pop_collection :: (using parser: *JSON_Parser) -> success: bool {
    if builder_stack.count == 0 {
        // todo: error
        return false;
    }
    builder_stack.count -= 1;
    building_collection = *elements[builder_stack[builder_stack.count-1]].internal_element_builder;
    return true;
}

begin_parse_collection :: inline (parser: *[..]JSON_Parser, $type: JSON_Element_Type) {
    success := push_collection(parser, type);
    parser.pos += 1;
    return success;
}

// -----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------- :misc

report_module_error :: (fmt: string, args: ..Any) #expand {
    trm_log(fmt=fmt, args=..args, header="TeRM/JSON");
}

mul_by_pow10_exponent :: (x: s64, exponent: s64, exponent_sign: s64) -> s64 {
    if exponent <= 0 {
        return x;
    }
    if exponent_sign == -1 {
        exp_factor := 1; 
        for 0..exponent-1 {
            exp_factor *= 10;
        }
        return x / exp_factor;
    } else {
        exp_factor := 1; 
        for 0..exponent-1 {
            exp_factor *= 10;
        }
        return x * exp_factor;
    }
}

to_digit :: inline (byte: u8) -> u8 {
    if byte >= #char "0" && byte <= #char "9" {
        return byte - #char "0";
    }
    return 0xff;
}


// -----------------------------------------------------------------------------------

// errors are cleared and added per-load and per-save, for each thread. 
// if the number of errors maxes out, errors are no longer stored unless a fatal error happens,
// then that ovewrites the last error.
// adding these to the context so they can be thread-local, allowing for multithreaded processing
#add_context json_error_buffer:       [32]JSON_Error;
#add_context json_errors:             []JSON_Error;
#add_context json_load_result:        JSON_Load_Result;
#add_context json_load_initialized:   bool;

#import "Basic";
#import "File";
#import "String";

#import "TeRM/TeRM_EncodeText";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_Math";
