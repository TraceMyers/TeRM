// the documentation in this file is mostly written as an exploration of
// what I want the interface to be. it's very much in flux and everything
// is being edited pretty extensively.

// the newest component allocation management picture looks like this:

// after entities spawning...
// {
//     handshake: Component_Management_Handshake;
//     begin(*handshake);

//     any_allocations := allocate_components(*handshake,
//         {new_cameras.count,    Camera.components   },
//         {new_characters.count, Character.components}
//     );

//     if any_allocations {
//         hand_out_components(*handshake, new_cameras,    cameras);
//         hand_out_components(*handshake, new_characters, characters);

//         update_pointers_to_components(*handshake, cameras);
//         update_pointers_to_components(*handshake, characters);
//     }
// }

// before destroying entities...
// {
//     handshake: Component_Management_Handshake;
//     begin(*handshake);

//     free_components(*handshake, destroyed_cameras,    cameras);
//     free_components(*handshake, destroyed_characters, characters);

//     shrink_component_arrays();

//     update_pointers_to_components(*handshake, cameras);
//     update_pointers_to_components(*handshake, characters);
// }

// the idea is that it's probably convenient to just call the same
// code every frame, and have arrays like new_whatever lying around
// empty most of the time, filled whever somebody is spawned.
// same goes for destroyed_whatever. 

// update_pointers_to_components() is only called for arrays of entities
// who are (optionally) using component pointers instead of indexes.

// the boilerplate would be pretty easy to codegen away if you want,
// but I think there's little enough that it shouldn't be necessary.

// older docs:

// this module expects you to store entities of a type contiguously, rather 
// than indirectly. 
//
// e.g.
//
// Entity_Person [   |   |   |   |   |   |   | P ]
//                                             ^-- a new Entity_Person was added to the end of this array
//
//                                     .--------- pass an array with a pointer to that entity P
//                                     |          as well as the base array of entities containing P
//                                     |           |
//                                     v           v
//                allocate_components([*P], entity_persons);

// the decisions on constraints and interface were intended to strike a balance
// between safety, ease of use, speed, code size, and complexity. i guess 
// modules/libs are always doing this dance, but the point is that i put a lot 
// of thought into what would make this kind of module *actually* good. 

// and by good, i mean that it realizes the goal of setting your program up
// for success in doing cache efficient bulk processing, provides convenience 
// features that are often missing from things in the ECS vein, and only requires 
// you to write memory & reference management code where doing so dramatically 
// reduces the possibility for bugs to arise, while keeping complexity down.

// if you want to have something more automatically managed, you could certainly
// build such a thing on top of this module. actually, if you build it inside your 
// program rather than inside a module, you aren't constrained by the API boundary, 
// and making something more automatic would be pretty straightforward, given the 
// work already done here.

// ------------------------------------------------------------------------------------------

// here is an example usage / explanation of the component management interface:

// [init/tracking]

// // for all arrays of entities which use pointers to components (rather than indices),
// // make them tracked so that the program will crash if they aren't updated after changes
// // to component data.
//
// // if you don't use this feature because you want to do things another way, that's up to you.
// // everything will still work as long as you make sure pointers get rebased.
//
// track_array_of_entities_with_component_pointers(*characters);
// track_array_of_entities_with_component_pointers(*weapons);
// ...
// 
// // later, if you want to remove an array from tracking:
//
// untrack_array_of_entities_with_component_pointers(*characters);

// [runtime]
//
// {
//      auto_release_temp(); // if you want. handshake makes temp allocations
//      handshake: Component_Management_Handshake;
//      begin(*handshake);
//
//      // for each set of newly created entities, allocate and initialize their components.
//      allocate_components(*handshake, just_spawned_characters, characters); 
//      allocate_components(*handshake, just_spawned_weapons,    weapons);
//      allocate_components(*handshake, just_spawned_buildings,  buildings);
//      ...
//
//      // for each set of destroyed entities, deallocate thir components and clear their component infos
//      free_components(*handshake, just_destroyed_characters, characters);
//      ...
//
//      // for ALL arrays of entities that use pointers (rather than indices) for components,
//      // make sure their pointers are updated, since component allocations may have moved.
//      // if you have no entities with component pointers, you don't need to do this step.
//      update_entity_component_pointers(*handshake, *characters);
//      update_entity_component_pointers(*handshake, *weapons);
//      ...
//
//      <--- at this point, the program will crash if you tracked any arrays,
//           but did not update them with update_entity_component_pointers().
// }
//
// if you want to sidestep the safety mechanism of begin(), you don't have to call it.
//
// you don't need to do allocate and free at the same time. you can split the work
// up however you like, but the basic structure is:
// 1. begin handshake
// 2. update component allocations
// 3. update pointers to components, only for entities that use this feature
// 4. (implicit) end handshake, crashing if step 3 was not completed correctly

Component_Management_Handshake :: struct {
    component_allocation_counts:        [#run enum_highest_value(Component_Name)+1]s32;
    entity_pointers_updated:            []bool;
    component_moved_allocation:         []bool;
    components_with_new_allocations:    []Component_Name;
    component_allocation_min_addresses: []int;
    component_allocation_max_addresses: []int;
    stage := enum {
        UNINITIALIZED;
        MODIFYING_COMPONENT_ALLOCATIONS;
        UPDATING_POINTERS_TO_COMPONENTS;
        FINISHED;
    }.UNINITIALIZED;
}

begin :: (using handshake: *Component_Management_Handshake) #expand {
    // you can do multiple (begin -> update -> end) cycles in a row with the same 
    // handshake if you want. i can't think of a reason why, but it's easy to support.
    if handshake.stage == .FINISHED {
        handshake.* = {};
    } else {
        assert(handshake.stage == .UNINITIALIZED);
    }

    `defer {
        fail_update_pointers_message := "cannot end a component management handshake without updating pointers of entities whose arrays are tracked by the component system";
        if stage == {
        case .UNINITIALIZED;
            assert(entity_pointers_updated.count == 0 && component_moved_allocation.count == 0);
            stage = .FINISHED;
        case .MODIFYING_COMPONENT_ALLOCATIONS;
            if entity_pointers_updated.count != 0 {
                assert(false, fail_update_pointers_message);
            }
            stage = .FINISHED;
        case .UPDATING_POINTERS_TO_COMPONENTS;
            for pointer_set_updated : entity_pointers_updated {
                assert(pointer_set_updated, fail_update_pointers_message);
            }
            stage = .FINISHED;
        }
        // to keep bugs from developing due to changes in the switch statement.
        assert(stage == .FINISHED);
    }
}

// if you have an array of entities whose component info has pointers to components,
// rather than indices to components, call this like so:
// track_array_of_entities_with_component_pointers(*characters);
// ... assuming the 'characters' array itself doesn't move (its allocation can move)
// this adds validation to the handshake process, making sure entities in
// this array have their component pointers updated when component allocations move.
track_array_of_entities_with_component_pointers :: (pointer_to_array: *void) {
    // if this crashes, you didn't set the pointer.
    // e.g. context.tracked_entity_arrays = *tracked_entity_storage;
    array_add_if_unique(context.tracked_entity_arrays, pointer_to_array);
}

// remove an array from the handshake vaidation process described above.
untrack_array_of_entities_with_component_pointers :: (pointer_to_array: *void) {
    // if this crashes, you didn't set the pointer.
    // e.g. context.tracked_entity_arrays = *tracked_entity_storage;
    array_remove(context.tracked_entity_arrays, pointer_to_array);
}

begin_modifications :: (using handshake: *Component_Management_Handshake) {
    if #complete stage == {
    case .UNINITIALIZED;
        if context.tracked_entity_arrays != null {
            entity_pointers_updated = make_static_array(bool, context.tracked_entity_arrays.count,, temp);
        }
        component_moved_allocation = make_static_array(bool, enum_highest_value(Component_Name) + 1,, temp);
        component_allocation_min_addresses, component_allocation_max_addresses = prepare_rebase_entity_pointers();
        stage = .MODIFYING_COMPONENT_ALLOCATIONS;
    case .MODIFYING_COMPONENT_ALLOCATIONS;
        // do nothing, already initialized
    case .UPDATING_POINTERS_TO_COMPONENTS; 
        #through;
    case .FINISHED;
        assert(false, "after you begin updating pointers to components, going back to modifying component allocations is unsafe");
    }
}

begin_updating_pointers :: (using handshake: *Component_Management_Handshake) -> bool {
    if #complete stage == {
    case .UNINITIALIZED;
        // if you made no modifications, you can skip updating pointers
        stage = .FINISHED;
        return false;
    case .MODIFYING_COMPONENT_ALLOCATIONS;
        which_components_moved := make_dynamic_array(Component_Name, enum_highest_value(Component_Name) + 1,, temp);
        for component_moved : component_moved_allocations {
            if component_moved {
                array_add(*which_components_moved, cast(Component_Name) it_index);
            }
        }
        if which_components_moved.count == 0 {
            stage = .FINISHED;
            return false;
        } else {
            components_with_new_allocations = which_components_moved;
            stage = .UPDATING_POINTERS_TO_COMPONENTS;
        }
    case .UPDATING_POINTERS_TO_COMPONENTS;
        // do nothing
    case .FINISHED;
        return false;
    }
    return true;
}

Component_Management_Description :: struct {
    count: int;
    components: []Component_Name;
}

allocate_components :: (handshake: *Component_Management_Handshake, descriptions: ..Component_Management_Description) -> bool {
    allocating_any_components: bool;

    // todo: this should be a different stage than begin or the next should be different
    begin_modifications(handshake);

    for description : descriptions {
        if description.count == 0 {
            continue;
        }
        for component : description.components {
            handshake.component_allocation_counts[component] += xx description.count;
            allocating_any_components = true;
        }
    }

    if !allocating_any_components {
        return false;
    }

    #insert #run for_every_component_type(#code {
        alloc_count := handshake.component_allocation_counts[component_id];
        if alloc_count != 0 {
            new_size := component_array.count + alloc_count;
            array_resize(component_array, new_size);
            array_resize(*context.entity_id_arrays[component_id], new_size);
            if component_array.data != xx handshake.component_allocation_min_addresses[component_id] {
                handshake.component_moved_allocation[component_id] = true;
            }
        }
    });

    return true;
}


hand_out_components :: (handshake: *Component_Management_Handshake, new_entities: []*$I/interface Component_Info, array_entities_belong_to: []I) {
    if new_entities.count == 0 {
        return;
    }

    begin_modifications(handshake);

    entity_ids := make_static_array(int, new_entities.count,, temp);
    for *entity_ids {
        it.* = importer.cmp_get_id(new_entities[it_index]);
    }

    // unrolled loop over all components of this entity type.
    // not unrolled for speed or anything, just for convenience of codewriting.
    #insert #run for_each_component_type(I.components, #code {
        for 0..new_entities.count-1 {
            ent := new_entities[it];

            components_remaining := *handshake.component_allocation_counts[component_id];
            assigned_component_index := component_array.count - components_remaining.*;
            components_remaining.* -= 1;
            assert(components_remaining.* >= 0);

            assert(component_id_is_valid(xx,trunc assigned_component_index));

            entity_index := ent - array_entities_belong_to.data;
            assert(entity_index >= 0 && entity_index < array_entities_belong_to.count); 

            // for each component, store a back-reference to the entity that owns it.
            // should have only a small cache perf hit except when the array
            // itself reallocates, because then the whole thing needs to be copied.
            // otherwise, you get only one cache line pull from it, per component free.
            context.entity_id_arrays[component_id][assigned_component_index] = entity_ids[it];

            if ent.description_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer := get_component_pointer_at_index(ent, component_index);
                pointer.* = *component_array[assigned_component_index];
            } else {
                id := get_component_id_at_index(ent, component_index);
                id.* = xx assigned_component_index;
            }
        }
    });
}


// these entities will have their components deallocated and their Component_Info struct will be cleared.
free_components :: (handshake: *Component_Management_Handshake, destroyed_entities: []*$I/interface Component_Info, array_entities_belong_to: []I) {
    if destroyed_entities.count == 0 {
        return;
    }

    begin_modifications(handshake);

    #insert #run for_each_component_type(I.components, #code {
        for ent : destroyed_entities {
            entity_index := ent - array_entities_belong_to.data;
            assert(entity_index >= 0 && entity_index < array_entities_belong_to.count); 

            assigned_component_index: u16;

            if ent.description_flags & .HAS_POINTERS_TO_COMPONENTS {
                pointer := get_component_pointer_at_index(ent, component_index);
                assigned_component_index = xx (cast(*component_type) pointer - component_array.data);
                pointer.* = null;
            } else {
                id := get_component_id_at_index(ent, component_index);
                // log("EARLIER, in proc address of %: %", component_id, cast(int) id);
                assigned_component_index = id.*;
                id.* = 0xffff;
            }

            assert(component_array.count > 0);
            if assigned_component_index == component_array.count - 1 {
                component_array.count -= 1;
                context.entity_id_arrays.count -= 1;
            } else {
                id_of_entity_that_owns_component_at_the_end := context.entity_id_arrays[component_id][component_array.count-1];

                // remove-swap with last element in components array
                component_array.*[assigned_component_index] = component_array.*[component_array.count-1];
                component_array.count -= 1;

                // move the entity last component's entity pointer back to the location of the new component
                context.entity_id_arrays[component_id][assigned_component_index] = id_of_entity_that_owns_component_at_the_end;
                context.entity_id_arrays[component_id].count -= 1;

                //                            .------------------ 1. this component was just removed because 
                //                            |                      the entity that owned it was destroyed
                //                            v
                // some component array [   | x |   |   | o ] 
                //                            ^           |^        
                //                            |           || 
                //      2. the end component  .-----------.|
                //      is copied into the old             | 3. this entity owns this component, 
                //      component's place                  |    which just moved. so, we need to
                //                                         |    re-point it to the new location
                //                                         |
                // some entity array [   |   |   |   |   | e |   ]
                
                owning_sentinel := importer.cmp_get_sentinel(id_of_entity_that_owns_component_at_the_end);

                for :per_component owning_sentinel {
                    if it != component_id {
                        continue;
                    }

                    if owning_sentinel.description_flags & .HAS_POINTERS_TO_COMPONENTS {
                        pointer := get_component_pointer_at_index(owning_sentinel, component_index);
                        pointer.* = *(component_array.*)[assigned_component_index];
                    } else {
                        id := get_component_id_at_index(owning_sentinel, component_index);
                        id.* = xx assigned_component_index;
                    }

                    break;
                }
            }
        }
    });

    for ent : destroyed_entities {
        ent.component_sentinel = {};
    }
}

Shrink_Component_Array_Rule :: struct {
    component_id: Component_Name;
    shrink_if_using_less_than_proportion := 0.7;
    unless_less_than_min_count: s32 = 64;
    free_if_count_reaches_zero := false;
}

shrink_component_arrays :: (specified_rules: []Shrink_Component_Array_Rule = .[]) {
    rules: [#run enum_highest_value(Component_Name)+1]Shrink_Component_Array_Rule;

    for rule : specified_rules {
        rules[rule.component_id] = it;
    }

    #insert #run for_all_component_types(#code {
        rule := *rules[component_id];
        if component_array.count <= rule.unless_less_than_min_count {
            if component_array.allocated != 0 
            && component_array.count == 0 
            && rule.free_if_count_reaches_zero {
                array_reset(component_array);
            }
        } else {
            array_shrink_if_small_enough(*component_array, rule.shrink_if_using_less_than_proportion, 0);
        }
    });
}

prepare_rebase_entity_pointers :: () -> []int, []int {
    // making two arrays from one allocation because they're parallel. base address and max address, so we
    // can later validate that entities were inside one of those ranges when the array allocation moved.
    array_len := context.entity_component_arrays.count;
    allocation_min_addresses := make_static_array(int, array_len * 2,, temp);
    allocation_max_addresses := allocation_min_addresses;
    allocation_min_addresses.count -= array_len;
    allocation_max_addresses.data  += array_len;
    allocation_max_addresses.count -= array_len;

    for array : context.entity_component_arrays {
        allocation_min_addresses[it_index] = cast(int) array.data;
        allocation_max_addresses[it_index] = cast(int) (array.data + (array.count - 1));
    }
    return allocation_min_addresses, allocation_max_addresses;
}

update_pointers_to_components :: (handshake: *Component_Management_Handshake, entity_array: []$I/interface Component_Info) {
    if !begin_updating_pointers(handshake) {
        return;
    }
    if !I.declare_component_pointers {
        return;
    }

    #insert #run for_each_component_type(I.components, #code {
        prev_min_address := prev_min_addresses[component_id];
        prev_max_address := prev_max_addresses[component_id];
        new_min_address  := cast(int) component_array.data;
        new_max_address  := cast(int) (component_array.data + (component_array.count - 1));

        for *ent : entity_array {
            pointer := cast(*component_type) get_component_pointer_at_index(ent, component_index);
            address_of_pointer := cast(int) pointer.*;

            assert((prev_min_address <= address_of_pointer && address_of_pointer <= prev_max_address) || (new_min_address <= address_of_pointer && address_of_pointer <= new_max_address), "the % component array must have reallocated without an entity updating its pointer, or an entity must have moved without the component system being informed. options are: 1. let the TeRM component system manage the component arrays (and inform the system when entities are moved around in the entity arrays), 2. don't make use of the component pointers option, or 3. you need to rebase the entity component pointers when you make changes to the component arrays.", component_id);

            offset_to_component := address_of_pointer - prev_min_address;
            pointer.* = xx (cast(*u8) component_array.data + offset_to_component);
        }
    });
}
