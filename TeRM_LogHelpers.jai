_fmt_commas :: (x: $T) -> FormatInt #expand #modify { return T.(*Type_Info).type == .INTEGER; } {
    return FormatInt.{value=x, digits_per_comma=3, comma_string=","};
}

_fmt_commas :: (x: $T) -> FormatFloat #expand #modify { return T.(*Type_Info).type == .FLOAT; } {
    return FormatFloat.{value=x, thousand_separators=true};
}

_fmt_hex :: (x: $T, minimum_digits := 0) -> FormatInt #expand {
    return FormatInt.{value=x, base=16, minimum_digits=minimum_digits};
}

_fmt_oct :: (x: $T, minimum_digits := 0) -> FormatInt #expand {
    return FormatInt.{value=x, base=8, minimum_digits=minimum_digits};
}

_fmt_bin :: (x: $T, minimum_digits := 0) -> FormatInt #expand {
    return FormatInt.{value=x, base=2, minimum_digits=minimum_digits};
}

_fmt_verbose :: (x: $T, draw_type_name := true) -> FormatStruct #expand #modify { return T.(*Type_Info).type == .STRUCT; } {
    return FormatStruct.{value=x, draw_type_name=draw_type_name, use_long_form_if_more_than_this_many_members=0, use_newlines_if_long_form=true};
}

#scope_file

#import "Basic";
