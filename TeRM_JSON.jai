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

    elements: []JSON_Element;

    collection_markers, element_count, success := gather_collection_markers(text);
    if success elements = gather_elements(text, collection_markers, element_count);
    success &= elements.count > 0;
    if success then success = post_process_collections(*elements);
    if success then context.json_load_result.elements = elements;

    on_exit_load(text, log_errors);
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
    // string_encoding: Text_Encoding = .UTF8;
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
    EXTRA_END_CURLY_BRACE;
    EXTRA_END_SQUARE_BRACE;
    COLLECTION_WITHOUT_END_DELIMITER;
    TRAILING_COMMA;
    UNEXPECTED_COLON;
    UNEXPECTED_END_OF_OBJECT;
    UNEXPECTED_END_OF_ARRAY;
    UNEXPECTED_BEGINNING_OF_OBJECT;
    INVALID_BYTE;
    OUT_OF_PLACE_PLUS_WHEN_PARSING_NUMBER;
    OUT_OF_PLACE_MINUS_WHEN_PARSING_NUMBER;
    OUT_OF_PLACE_DOT_WHEN_PARSING_NUMBER;
    OUT_OF_PLACE_E_WHEN_PARSING_NUMBER;
    EXTRA_DIGITS_IN_ZERO_WHEN_PARSING_NUMBER;
    IMPROPERLY_FORMED_NUMBER_VALUE;
    STRING_WITHOUT_END_QUOTE;
    FIRST_WORD_OF_UTF16_CODE_POINT_IS_HIGH_SURROGATE_BUT_FOUND_NO_LOW_SURROGATE;
    EXPECTED_VALUE_TRUE;
    EXPECTED_VALUE_FALSE;
    EXPECTED_VALUE_NULL;
    EXPECTED_COLON;
    EXPECTED_OBJECT_KEY;
    EXPECTED_COMMA_OR_END_OF_COLLECTION;
    UNEXPECTED_END_OF_INPUT;
    IMPROPERLY_FORMED_HEX;
    _INTERNAL_ERROR_MARKER_COUNT_DOES_NOT_MATCH_COLLECTION_COUNT;
    _INTERNAL_ERROR_BUILDER_STACK_DEPLETED;
    _INTERNAL_FAILED_TRANSLATING_UTF16_TO_UTF8;
    _INTERNAL_UNEXPECTED_UTF16_READ_BYTE_COUNT;
    _INTERNAL_ERROR_MARKER_TYPE_DOES_NOT_MATCH_COLLECTION_TYPE;
    _INTERNAL_ERROR_INVALID_COLLECTION_TYPE;
    _INTERNAL_ERROR_COLLECTION_MISSING_ELEMENTS;
    _INTERNAL_ERROR_OBJECT_HAS_ODD_NUMBER_OF_ELEMENTS;
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
            if !on_collection_ending_delimiter_found(.OBJECT) {
                return .[], 0, false;
            }
            top_marker = pop_top_marker();
            if top_marker == null {
                add_load_error(.EXTRA_END_CURLY_BRACE, it_index, .FATAL);
                return .[], 0, false;
            }
        } else if it == #char "]" {
            if !on_collection_ending_delimiter_found(.ARRAY) {
                return .[], 0, false;
            }
            top_marker = pop_top_marker();
            if top_marker == null {
                add_load_error(.EXTRA_END_SQUARE_BRACE, it_index, .FATAL);
                return .[], 0, false;
            }
        } else if it == #char "," {
            if top_marker.text_encountered_since_last_delimiter {
                total_element_count += 1;
                top_marker.element_count += 1;
                top_marker.text_encountered_since_last_delimiter = false;
            } else {
                add_load_error(.TRAILING_COMMA, it_index, .FATAL);
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
        add_load_error(.COLLECTION_WITHOUT_END_DELIMITER, top_marker.file_position, .FATAL);
        return .[], 0, false; 
    } 

    return markers, total_element_count, true;
}

gather_elements :: no_inline (text: string, collection_markers: []Collection_Marker, element_count: int) -> []JSON_Element {
    parser: JSON_Element_Parser;
    parser.text = text;
    array_reserve(*parser.elements, element_count*9/8);
    parser.builder_stack.allocator = temp;
    array_reserve(*parser.builder_stack, 128);
    parser.markers = collection_markers;

    // bottom of stack = whole file = root object
    success := push_collection(*parser, .OBJECT, false);
    if !success {
        return .[];
    }

    last_thing: string;

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
            last_thing = "object";
        case #char "[";
            if !begin_parse_collection(*parser, .ARRAY) {
                return .[];
            }
            last_thing = "array";
        case #char "\"";
            if !parse_string(*parser) {
                return .[];
            }
            last_thing = "string";
        case #char "t";
            if !parse_boolean_or_null(*parser, .TRUE) {
                return .[];
            }
            last_thing = "bool or null";
        case #char "f";
            if !parse_boolean_or_null(*parser, .FALSE) {
                return .[];
            }
            last_thing = "bool or null";
        case #char "n";
            if !parse_boolean_or_null(*parser, .NULL) {
                return .[];
            }
            last_thing = "bool or null";
        case #char ",";
            if parser.building_collection.state == {
            case .OBJECT_EXPECT_COMMA_OR_END;
                parser.building_collection.state = .OBJECT_EXPECT_KEY;
            case .ARRAY_EXPECT_COMMA_OR_END;
                parser.building_collection.state = .ARRAY_EXPECT_VALUE;
            case;
                add_load_error(.TRAILING_COMMA, parser.pos, .FATAL);
                return .[];
            }
            parser.pos += 1;
            last_thing = "comma";
        case #char ":";
            if parser.building_collection.state == {
            case .OBJECT_EXPECT_COLON;
                parser.building_collection.state = .OBJECT_EXPECT_VALUE;
            case;
                add_load_error(.UNEXPECTED_COLON, parser.pos, .FATAL);
                return .[];
            }
            parser.pos += 1;
            last_thing = "colon";
        case #char "}";
            if parser.building_collection.state == {
            case .OBJECT_EXPECT_KEY_OR_END;
                #through;
            case .OBJECT_EXPECT_COMMA_OR_END;
                if parser.building_collection.type != .OBJECT {
                    add_load_error(.UNEXPECTED_END_OF_OBJECT, parser.pos, .FATAL);
                    return .[];
                }
                if !pop_collection(*parser) {
                    return .[];
                }
            case;
                add_load_error(.UNEXPECTED_END_OF_OBJECT, parser.pos, .FATAL);
                return .[];
            }
            parser.pos += 1;
            last_thing = "end object";
        case #char "]";
            if parser.building_collection.state == {
            case .ARRAY_EXPECT_VALUE_OR_END;
                #through;
            case .ARRAY_EXPECT_COMMA_OR_END;
                if parser.building_collection.type != .ARRAY {
                    add_load_error(.UNEXPECTED_END_OF_ARRAY, parser.pos, .FATAL);
                    return .[];
                }
                if !pop_collection(*parser) {
                    return .[];
                }
            case;
                add_load_error(.UNEXPECTED_END_OF_ARRAY, parser.pos, .FATAL);
                return .[];
            }       
            parser.pos += 1;
            last_thing = "end array";
        case;
            if is_digit(byte) || byte == "-" {
                parse_number(*parser);
                last_thing = "number";
            } else {
                add_load_error(.INVALID_BYTE, parser.pos, .FATAL);
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
    exponent       : s64;
    fraction: string;
    stage: Parse_Number_Stage;
}

parse_number :: (main_parser: *JSON_Element_Parser) -> bool {
    advance_collection_state_for_value_or_return_if_invalid();

    using number_parser: JSON_Number_Parser;

    success                         := parse_number_components(*number_parser, main_parser);
    if !success then return false;
    represent_with_integer:, success = should_represent_number_with_integer(*number_parser, main_parser);
    if !success then return false;

    if represent_with_integer {
        if exponent > 0 {
            base = mul_by_pow10_exponent(base, exponent, exponent_sign);
        }
        element := push_collection_child(main_parser);
        element.type = .INT;
        element.i64 = base * number_parser.sign;
    } else {
        element := push_collection_child(main_parser);
        element.type = .FLOAT;
        element.f64 = compose_float(base * sign, fraction, exponent * exponent_sign);
    }

    return true;
}

parse_number_components :: (using number_parser: *JSON_Number_Parser, main_parser: *JSON_Element_Parser) -> success: bool {
    while main_parser.pos < main_parser.text.count {
        byte := main_parser.text[main_parser.pos];

        if byte == {
        case #char "+";
            if stage == .EXPONENT_SIGN {
                stage = .EXPONENT_DIGITS; 
            } else {
                add_load_error(.OUT_OF_PLACE_PLUS_WHEN_PARSING_NUMBER, main_parser.pos, .FATAL);
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
                add_load_error(.OUT_OF_PLACE_MINUS_WHEN_PARSING_NUMBER, main_parser.pos, .FATAL);
                return false;
            }
        case #char ".";
            if stage == .BASE_ZERO || stage == .BASE_NONZERO {
                stage = .FRACTION_DIGITS_BEGIN;
            } else {
                add_load_error(.OUT_OF_PLACE_DOT_WHEN_PARSING_NUMBER, main_parser.pos, .FATAL);
                return false;
            }
        case #char "E";
            #through;
        case #char "e";
            if stage == .BASE_ZERO || stage == .BASE_NONZERO || stage == .FRACTION_DIGITS {
                stage = .EXPONENT_SIGN;
            } else {
                add_load_error(.OUT_OF_PLACE_E_WHEN_PARSING_NUMBER, main_parser.pos, .FATAL);
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
                    add_load_error(.EXTRA_DIGITS_IN_ZERO_WHEN_PARSING_NUMBER, main_parser.pos, .FATAL);
                    return false;
                case .BASE_NONZERO;
                    base = base * 10 + digit;
                case .FRACTION_DIGITS_BEGIN;
                    fraction.data = main_parser.text.data + main_parser.pos;
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
        
        main_parser.pos += 1;
    }

    // trim trailing zeroes from the fraction
    while fraction.count > 0 && fraction[fraction.count-1] == "0" {
        fraction.count -= 1;
    }

    return true;
}

should_represent_number_with_integer :: (using number_parser: *JSON_Number_Parser, main_parser: *JSON_Element_Parser) -> should_use_int: bool, success: bool {
    maybe_represent_with_float := fraction.count == 0;

    if #complete stage == { 
    case .SIGN; 
        add_load_error(.IMPROPERLY_FORMED_NUMBER_VALUE, main_parser.pos, .FATAL);
        return false, false;
    case .BASE_BEGIN;
        add_load_error(.IMPROPERLY_FORMED_NUMBER_VALUE, main_parser.pos, .FATAL);
        return false, false;
    case .BASE_ZERO;
        #through;
    case .BASE_NONZERO;
        // this may not necessarily be the right call, but if so, critical information
        // is already gone due to representing the base as a 64 bit integer during parsing
        maybe_represent_with_float = false;
    case .FRACTION_DIGITS_BEGIN;
        add_load_error(.IMPROPERLY_FORMED_NUMBER_VALUE, main_parser.pos, .FATAL);
        return false, false;
    case .FRACTION_DIGITS;
        // float ok
    case .EXPONENT_SIGN; 
        add_load_error(.IMPROPERLY_FORMED_NUMBER_VALUE, main_parser.pos, .FATAL);
        return false, false;
    case .EXPONENT_DIGITS_BEGIN;
        add_load_error(.IMPROPERLY_FORMED_NUMBER_VALUE, main_parser.pos, .FATAL);
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

    return represent_with_integer, true;
}

// -----------------------------------------------------------------------------------
// --------------------------------------------------------------------- :parse string

// helper struct for allocating the strings into the elements array
JSON_String_Parser :: struct {
    main_parser: *JSON_Element_Parser;
    json_elements: *[..]JSON_Element;
    fake_elements_begin_index: s32;
    fake_elements_count: s32;
    string_bytes: string;
    string_builder: string;
    passthrough_byte_count: int;
    pos: int;
}

parse_string :: (parser: *JSON_Element_Parser) -> bool {
    using string_parser: JSON_String_Parser;
    main_parser = parser;
    json_elements = *parser.elements;

    advance_collection_state_for_string_or_return_if_invalid();

    // jai compiler doesn't recognize \b and \f
    BACKSPACE : u8 : 0x8;
    FORM_FEED : u8 : 0xc;

    // get past opening quote
    parser.pos += 1;

    remaining_bytes := parser.text.count - parser.pos;
    remaining_text  := string.{remaining_bytes, parser.text.data + parser.pos};
    // collect string including end quote
    string_bytes=, found_end_quote := consume_until_non_escaped_quote(remaining_text);
    parser.pos += string_bytes.count + 1;

    if !found_end_quote {
        parser.pos -= 1;
        add_load_error(.STRING_WITHOUT_END_QUOTE, parser.pos, .FATAL);
        return false;
    }
    
    while pos + passthrough_byte_count < string_bytes.count {
        if string_bytes[pos] == #char "\\" {

            if passthrough_byte_count > 0 {
                push_bytes(*string_parser, {passthrough_byte_count, string_bytes.data + pos});
            }
            pos += 1;

            if string_bytes[pos] == {
            case #char "\"";
                push_byte(*string_parser, #char "\"");
            case #char "\\";
                push_byte(*string_parser, #char "\\");
            case #char "/";
                push_byte(*string_parser, #char "/");
            case #char "b";
                push_byte(*string_parser, BACKSPACE);
            case #char "f";
                push_byte(*string_parser, FORM_FEED);
            case #char "n";
                push_byte(*string_parser, #char "\n");
            case #char "r";
                push_byte(*string_parser, #char "\r");
            case #char "t";
                push_byte(*string_parser, #char "\t");
            case #char "u";
                if !parse_hex_bytes(*string_parser) {
                    return false;
                }
            }
        } else if string_bytes[pos] == #char "\"" {
            assert(pos + passthrough_byte_count + 1 == string_bytes.count);
            break;
        } else {
            passthrough_byte_count += 1;
        }
    }
    
    if passthrough_byte_count > 0 {
        push_bytes(*string_parser, {passthrough_byte_count, string_bytes.data + pos});
    }
    
    return true;
}

consume_until_non_escaped_quote :: inline (text: string) -> bytes: string, found_quote: bool {
    exchange := String_Exchange.{src=text};
    for exchange {
        if it == #char "\"" && (it_index == 0 || exchange.src[it_index-1] != #char "\\") {
            exchange.trim_bytes = 1;
            break;
        }
    }
    return exchange.dst, exchange.broke_out_of_loop;
}

// not a generally good resize function, but marginally correct
resize_if_needed :: no_inline (using string_parser: *JSON_String_Parser, new_strlen: int) {
    capacity := fake_elements_count * size_of(JSON_Element);

    if new_strlen > capacity {
        new_element_count : s32 = xx div_ceil((new_strlen - capacity), size_of(JSON_Element));
        array_resize(json_elements, json_elements.count + new_element_count);

        // if resizing from 0 capacity
        if fake_elements_count == 0 {
            assert(string_builder.count == 0);
            fake_elements_begin_index = xx (json_elements.count - 1);
        }
        fake_elements_count += new_element_count;

        // pointers into the array always set after an array resize!
        string_builder.data = xx (json_elements.data + fake_elements_begin_index);
        top_collection := main_parser.builder_stack[main_parser.builder_stack.count-1];
        main_parser.building_collection = *(json_elements.*)[top_collection]._internal_collection_builder;
    }
}

push_byte :: inline (using string_parser: *JSON_String_Parser, byte: u8) {
    new_strlen := string_builder.count + 1;
    resize_if_needed(string_parser, new_strlen);
    string_builder.count += 1;
    string_builder[string_builder.count-1] = byte;
    pos += 1;
}

push_bytes :: inline (using string_parser: *JSON_String_Parser, bytes: string) {
    new_strlen := string_builder.count + bytes.count;
    resize_if_needed(string_parser, new_strlen);
    old_count := string_builder.count;
    string_builder.count += bytes.count;
    memcpy(string_builder.data + old_count, bytes.data, bytes.count);
    pos += bytes.count;
}

parse_hex_bytes :: (using parser: *JSON_String_Parser) -> bool {
    // get past 'u' char
    pos += 1;

    word_count := 1;

    utf16: [2]u16;
    success: bool;
    utf16[0], success = parse_utf16_word_from_hex_text(parser);

    if !success {
        return false;
    }
    pos += 4;

    if utf16[0] >= UTF16_HIGH_SURROGATE_MIN && utf16[0] <= UTF16_HIGH_SURROGATE_MAX {
        word_count = 2;

        if string_bytes[pos] != #char "\\" {
            add_load_error(.FIRST_WORD_OF_UTF16_CODE_POINT_IS_HIGH_SURROGATE_BUT_FOUND_NO_LOW_SURROGATE, parser.pos, .FATAL);
            return false;
        }
        if string_bytes[pos+1] != #char "u" {
            add_load_error(.FIRST_WORD_OF_UTF16_CODE_POINT_IS_HIGH_SURROGATE_BUT_FOUND_NO_LOW_SURROGATE, parser.pos, .FATAL);
            return false;
        }
        pos += 2;
        
        utf16[1], success = parse_utf16_word_from_hex_text(parser);
        if !success {
            return false;
        }
        pos += 4;
    }

    utf8: [6]u8;
    read_byte_count, write_byte_count, failure := utf16_to_utf8(xx utf16.data, utf8.data, utf16.count*2, utf8.count);

    if failure != 0 {
        add_load_error(._INTERNAL_FAILED_TRANSLATING_UTF16_TO_UTF8, parser.pos, .FATAL);
        return false;
    }
    if read_byte_count * 2 != word_count {
        add_load_error(._INTERNAL_UNEXPECTED_UTF16_READ_BYTE_COUNT, parser.pos, .FATAL);
        return false;
    }

    utf8_str := string.{write_byte_count, utf8.data};
    push_bytes(parser, utf8_str);
    return true;
}

// -----------------------------------------------------------------------------------
// ------------------------------------------------------------ :parse boolean or null

parse_boolean_or_null :: (main_parser: *JSON_Element_Parser, $type: JSON_Element_Type) -> bool {
    advance_collection_state_for_value_or_return_if_invalid();

    // it's a car with a spoiler.
    //               _____________
    type_string ::  //////////////\
             #ifx type == .TRUE  then "true" 
        else #ifx type == .FALSE then "false"
        else                          "null";

    remaining_bytes := main_parser.text.count - main_parser.pos;
    str_in_text := string.{min(type_string.count, remaining_bytes), main_parser.text.data + main_parser.pos};
    main_parser.pos += str_in_text.count;

    if str_in_text != type_string {
        error_code : JSON_Error_Code :
            #ifx type == .TRUE  then JSON_Error_Code.EXPECTED_VALUE_TRUE
            else #ifx type == .FALSE then JSON_Error_Code.EXPECTED_VALUE_FALSE
            else JSON_Error_Code.EXPECTED_VALUE_NULL;
        add_load_error(error_code, main_parser.pos, .FATAL);
        return false;
    }

    element := push_collection_child(main_parser);
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

on_exit_load :: (file_text: string, log_errors: bool) {
    using context;

    _increment_wrap :: inline (x: $T, min: T, max: T) -> T {
        if x >= max {
            return min;
        } else return x + 1;
    }

    json_load_result.errors = json_errors;

    file_context_lines: [8]string;
    fcl_indices: [file_context_lines.count]int;
    fcl_i := 0;

    if file_text.count > 0 && json_errors.count > 0 {
        next_text_covered_size := 0;

        // each error originally is only recorded at a file position
        // convert that to line, column
        for :per_line line, line_index : file_text {
            text_covered_size := next_text_covered_size;
            next_text_covered_size += line.count;

            line_file_position_begin := line.data - file_text.data;
            line_file_position_end   := line_file_position_begin + line.count;

            processed_error_count := 0;

            file_context_lines[fcl_i] = line;
            defer fcl_i = _increment_wrap(fcl_i, 0, file_context_lines.count-1);

            for *err : json_errors {
                if (err.flags & .INTERNAL_UNPROCESSED) == 0 {
                    processed_error_count += 1;
                    continue;
                }

                if err._internal_file_position >= line_file_position_begin 
                && err._internal_file_position <= line_file_position_end {
                    err.column = xx (err._internal_file_position - line_file_position_begin);
                    err.line = xx line_index;
                    err.flags &= ~.INTERNAL_UNPROCESSED;

                    space_buffer: [128]u8 = ---;
                    space_count := min(space_buffer.count, err.column);
                    memset(space_buffer.data, " ", space_count);
                    spaces := string.{space_count, space_buffer.data};

                    // getting cached line indices, oldest to newest
                    fcl_indices[0] = _increment_wrap(fcl_i, 0, file_context_lines.count-1);
                    if fcl_indices.count > 1 then for 1..fcl_indices.count-1 {
                        fcl_indices[it] = _increment_wrap(fcl_indices[it-1], 0, file_context_lines.count-1);
                    }

                    if log_errors {
                        error_string_builder: String_Builder;
                        print(*error_string_builder,
#string HERE


    error code : %
    flags      : %
    line #     : %
    column #   : %
HERE,
                            err.code, 
                            err.flags, 
                            err.line, 
                            err.column
                        );

                        // print the file lines so the user can see the error location in the text
                        for fcl_indices {
                            if it_index == 0 {
                                print(*error_string_builder, "    text       : %\n", file_context_lines[it]);
                            } else {
                                print(*error_string_builder, "                 %\n", file_context_lines[it]);
                            }
                        }
                        // caret points at the problem location
                        print(*error_string_builder,         "                 %^\n", spaces);

                        report_module_error(builder_to_string(*error_string_builder));
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

on_collection_ending_delimiter_found :: (type: JSON_Element_Type) -> bool #expand {
    if `top_marker.type != type {
        add_load_error(._INTERNAL_ERROR_MARKER_TYPE_DOES_NOT_MATCH_COLLECTION_TYPE, `it_index, .FATAL);
        return false;
    }
    any_commas_encountered := `top_marker.element_count > 0;
    if `top_marker.text_encountered_since_last_delimiter {
        `top_marker.element_count += 1;
        `total_element_count += 1;
    } else if any_commas_encountered {
        // no text since last comma = invalid
        add_load_error(.TRAILING_COMMA, `it_index, .FATAL);
        return false;
    }

    return true;
}

// get the in-place location of the new element within the parent collection's list,
// the parent collection's list is allocated when the collection is pushed.
push_collection_child :: inline (parser: *JSON_Element_Parser) -> *JSON_Element {
    using parser.building_collection;
    assert(child_elements_counter < child_elements_count);
    element_index := child_elements_offset + child_elements_counter;
    new_element := *parser.elements[element_index];
    child_elements_counter += 1;
    return new_element;
}

// -----------------------------------------------------------------------------------
// -------------------------------------------------- :collection handling second pass

push_collection :: (using parser: *JSON_Element_Parser, collection_type: JSON_Element_Type, $in_place := true) -> success: bool {
    if markers.count == 0 {
        add_load_error(._INTERNAL_ERROR_MARKER_COUNT_DOES_NOT_MATCH_COLLECTION_COUNT, parser.pos, .FATAL);
        return false;
    }

    // in the first pass, information about how many elements were in each collection
    // was gathered and put into a marker. retrieving the marker for this collection,
    // treating the markers array as a fifo stack.
    marker := markers[0];
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
        new_collection = push_collection_child(parser);
    } else {
        // the only non-in-place element allocation is the root object
        assert(elements.count == 0);
        new_collection = array_add(*elements);
    }

    new_collection.type = .INTERNAL_COLLECTION_BUILDER;
    {
        using new_collection._internal_collection_builder;
        type = collection_type;
        child_elements_count = marker.element_count;
        state = ifx type == .OBJECT then .OBJECT_EXPECT_KEY_OR_END else .ARRAY_EXPECT_VALUE_OR_END;

        if child_elements_count > 0 {
            child_elements_offset = xx elements.count;
            // push all of this collection's elements into the element array right now 
            // so they're contiguously allocated. elements will have type UNINITIALIZED
            // so they can be checked later to make sure they were set correctly after this step
            array_resize(*elements, elements.count + marker.element_count);

        } else {
            child_elements_offset = -1;
        }

        // put this collection at the top of the stack, even if empty
        array_add(*builder_stack, xx (new_collection - elements.data));
        building_collection = *new_collection._internal_collection_builder;
    }

    return true;
}

pop_collection :: (using parser: *JSON_Element_Parser) -> success: bool {
    if builder_stack.count == 0 {
        add_load_error(._INTERNAL_ERROR_BUILDER_STACK_DEPLETED, parser.pos, .FATAL);
        return false;
    }
    
    builder_stack.count -= 1;
    building_collection = *elements[builder_stack[builder_stack.count-1]]._internal_collection_builder;
    return true;
}

begin_parse_collection :: inline (parser: *JSON_Element_Parser, $type: JSON_Element_Type) -> bool {
    // if the builder stack has only one member, it's the fake top-level scope object.
    if parser.builder_stack.count != 1 {
        // advance the state machine determining what symbols are valid to encounter next
        if parser.building_collection.state == {
        case .OBJECT_EXPECT_VALUE;
            parser.building_collection.state = .OBJECT_EXPECT_COMMA_OR_END;
        case .ARRAY_EXPECT_VALUE_OR_END; 
            #through;
        case .ARRAY_EXPECT_VALUE;
            parser.building_collection.state = .ARRAY_EXPECT_COMMA_OR_END;
        case;
            add_load_error(.UNEXPECTED_BEGINNING_OF_OBJECT, parser.pos, .FATAL);
            return false;
        }
    }

    success := push_collection(parser, type);
    parser.pos += 1;
    return success;
}

post_process_collections :: (elements: *[]JSON_Element) -> bool {
    // todo: actually can't do this here duh
    for *element : elements.* {
        if element.type != .INTERNAL_COLLECTION_BUILDER {
            continue;
        }

        builder := *element._internal_collection_builder;

        if builder.child_elements_counter != builder.child_elements_count {
            add_load_error(._INTERNAL_ERROR_COLLECTION_MISSING_ELEMENTS, 0, .FATAL);
            return false;
        }
        if builder.type == .OBJECT {
            // must be even number of elements, so they can be key-value pairs
            if (builder.child_elements_count & 0x1) != 0 { 
                add_load_error(._INTERNAL_ERROR_OBJECT_HAS_ODD_NUMBER_OF_ELEMENTS, 0, .FATAL);
                return false;
            }
            collection_elements: []JSON_KV_Pair;
            collection_elements.data = xx *(elements.*)[builder.child_elements_offset];
            collection_elements.count = xx (builder.child_elements_count / 2);
            element.type = .OBJECT;
            element.object.elements = collection_elements;
        } else if builder.type == .ARRAY {
            collection_elements: []JSON_Element;
            collection_elements.data = *(elements.*)[builder.child_elements_offset];
            collection_elements.count = xx builder.child_elements_count;
            element.type = .ARRAY;
            element.array.elements = collection_elements;
        } else {
            add_load_error(._INTERNAL_ERROR_INVALID_COLLECTION_TYPE, 0, .FATAL);
            return false;
        }
    }
    return true;
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

parse_utf16_word_from_hex_text :: (using parser: *JSON_String_Parser) -> u16, bool {
    hex_string := string.{min(4, string_bytes.count - pos), string_bytes.data + pos};
    if hex_string.count < 4 {
        add_load_error(.UNEXPECTED_END_OF_INPUT, main_parser.pos, .FATAL);
        return 0, false;
    }
    hex_bytes, success := hex_text_to_bytes(hex_string);
    if !success {
        add_load_error(.IMPROPERLY_FORMED_HEX, main_parser.pos, .FATAL);
        return 0, false;
    }
    pos += 4;
    return (cast(*u16) hex_bytes.data).*, true;
}

advance_collection_state_for_string_or_return_if_invalid :: () #expand {
    // if the builder stack has only one member, it's the fake top-level scope object.
    if `main_parser.builder_stack.count != 1 {
        if `main_parser.building_collection.state == {
        case .OBJECT_EXPECT_KEY_OR_END;
            #through;
        case .OBJECT_EXPECT_KEY;
            `main_parser.building_collection.state = .OBJECT_EXPECT_COLON;
        case .OBJECT_EXPECT_COLON;
            add_load_error(.EXPECTED_COLON, `main_parser.pos, .FATAL);
            `return false;
        case .OBJECT_EXPECT_VALUE;
            `main_parser.building_collection.state = .OBJECT_EXPECT_COMMA_OR_END;
        case .OBJECT_EXPECT_COMMA_OR_END;
            add_load_error(.EXPECTED_COMMA_OR_END_OF_COLLECTION, `main_parser.pos, .FATAL);
            `return false;
        case .ARRAY_EXPECT_VALUE_OR_END;
            #through;
        case .ARRAY_EXPECT_VALUE;
            `main_parser.building_collection.state = .ARRAY_EXPECT_COMMA_OR_END;
        case .ARRAY_EXPECT_COMMA_OR_END;
            add_load_error(.EXPECTED_COMMA_OR_END_OF_COLLECTION, `main_parser.pos, .FATAL);
            `return false;
        }
    }
}

advance_collection_state_for_value_or_return_if_invalid :: () #expand {
    // if the builder stack has only one member, it's the fake top-level scope object.
    if `main_parser.builder_stack.count != 1 {
        if `main_parser.building_collection.state == {
        case .OBJECT_EXPECT_KEY_OR_END;
            #through;
        case .OBJECT_EXPECT_KEY;
            add_load_error(.EXPECTED_OBJECT_KEY, `main_parser.pos, .FATAL);
            `return false;
        case .OBJECT_EXPECT_COLON;
            add_load_error(.EXPECTED_COLON, `main_parser.pos, .FATAL);
            `return false;
        case .OBJECT_EXPECT_VALUE;
            `main_parser.building_collection.state = .OBJECT_EXPECT_COMMA_OR_END;
        case .OBJECT_EXPECT_COMMA_OR_END;
            add_load_error(.EXPECTED_COMMA_OR_END_OF_COLLECTION, `main_parser.pos, .FATAL);
            `return false;
        case .ARRAY_EXPECT_VALUE_OR_END;
            #through;
        case .ARRAY_EXPECT_VALUE;
            `main_parser.building_collection.state = .ARRAY_EXPECT_COMMA_OR_END;
        case .ARRAY_EXPECT_COMMA_OR_END;
            add_load_error(.EXPECTED_COMMA_OR_END_OF_COLLECTION, `main_parser.pos, .FATAL);
            `return false;
        }
    }
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
#import "Bit_Operations";

#import "TeRM/TeRM_EncodeText";
#import "TeRM/TeRM_String";
#import "TeRM/TeRM_Log";
#import "TeRM/TeRM_Math";
