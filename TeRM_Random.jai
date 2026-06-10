// credit to Marc "MAHK" LeBlanc
// predicate can take either pointer to T or just T. returns the same.
random_select :: (array: []$T1, predicate: (x: $T2) -> bool, _state: *Random_State = null) -> T2 #modify { 
    return T2 == T1 || type_2_is_pointer_to_type_1(T1, T2);
} {
    best_score := -1.0;
    best_item: T2;

    state := ifx _state == null then *context.random_state else _state;

    for *=(T2==*T1) array {
        if predicate(it) {
            score := random_get_zero_to_one(state);
            if score > best_score {
                best_score = score;
                best_item  = it;
            }
        }
    }
    
    return best_item;
}

#import "Random";
#import "TeRM/TeRM_Metaprogram";
