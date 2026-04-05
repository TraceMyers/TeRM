Skeletal_Animation_Blend :: struct {
    animation_index: s32;
    animation_time: float;
    blend_alpha: float;
}

get_duration :: inline (animation: *Skeletal_Animation) -> float {
    if animation.timestamps.count > 0 {
        return animation.timestamps[animation.timestamps.count-1];
    } else return 0;
}

get_joint_transforms :: inline (skeleton: *Skeleton, animation: *Skeletal_Animation, frame: int) -> []Joint_Transform {
    transforms: []Joint_Transform;
    start_index     := frame * skeleton.joints.count;
    transforms.data  = animation.transforms.data + start_index;
    transforms.count = skeleton.joints.count;
    return transforms;
}

free_pose :: (pose: *Skeletal_Pose) {
    free(pose.allocation);
    pose.* = {};
}

make_transform_matrix :: inline (joint_transform: Joint_Transform) -> Matrix4 {
    return make_transform_matrix(joint_transform.translation, joint_transform.rotation, joint_transform.scale);
}

make_pose :: (pose: *Skeletal_Pose, skeleton: *Skeleton, blends: []Skeletal_Animation_Blend) {
    assert(blends.count > 0);

    blend_alpha_sum := 0.0;
    for blends {
        blend_alpha_sum += it.blend_alpha;
    }
    assert(abs(blend_alpha_sum - 1.0) < 0.001);


    assert(pose.allocation == null);

    allocation_size := (size_of(Joint_Transform) + (size_of(Matrix4) * 2)) * skeleton.joints.count;
    joint_count     := skeleton.joints.count;
    
    pose.skeleton   = skeleton;
    pose.allocation = alloc(allocation_size);
    memset(pose.allocation, 0, allocation_size);

    pose.local_joints.data     = xx pose.allocation;
    pose.local_joints.count    = joint_count;
    pose.model_joints.data     = xx ((cast(*u8) pose.local_joints.data) + size_of(Joint_Transform) * joint_count);
    pose.model_joints.count    = joint_count;
    pose.skinning_joints.data  = xx ((cast(*u8) pose.model_joints.data) + size_of(Matrix4) * joint_count);
    pose.skinning_joints.count = joint_count;

    next_frame_index: int;

    per_anim: [3]Per_Animation_Data;
    assert(blends.count <= per_anim.count);

    for blend : blends {
        animation := *skeleton.animations[blend.animation_index];
        assert(animation.timestamps.count >= 2);

        anim_data := *per_anim[it_index];

        for 1..animation.timestamps.count - 1 {
            if blend.animation_time < animation.timestamps[it] {
                anim_data.next_frame_index = xx it;
                break;
            }
        }

        anim_data.next_frame_index = max(anim_data.next_frame_index, 1);
        anim_data.prev_frame_index = anim_data.next_frame_index - 1;

        anim_data.prev_timestamp = animation.timestamps[anim_data.prev_frame_index];
        anim_data.next_timestamp = animation.timestamps[anim_data.next_frame_index];

        anim_data.anim_alpha = respace(blend.animation_time, {anim_data.prev_timestamp, anim_data.next_timestamp}, {0, 1});
        anim_data.blend_alpha = blend.blend_alpha;

        anim_data.prev_frame_transforms = get_joint_transforms(skeleton, animation, anim_data.prev_frame_index);
        anim_data.next_frame_transforms = get_joint_transforms(skeleton, animation, anim_data.next_frame_index);
    }

    for *joint, ji : skeleton.joints {
            
        local_joint := *pose.local_joints[ji];

        for blends {
            anim := *per_anim[it_index];

            prev_frame := *anim.prev_frame_transforms[ji];
            next_frame := *anim.next_frame_transforms[ji];

            translation := lerp(prev_frame.translation, next_frame.translation, anim.anim_alpha);
            rotation    := interp_rotate_with_alpha(prev_frame.rotation, next_frame.rotation, anim.anim_alpha);
            scale       := lerp(prev_frame.scale, next_frame.scale, anim.anim_alpha);

            local_joint.translation += translation * anim.blend_alpha;
            local_joint.scale       += scale * anim.blend_alpha;

            if it_index == 0 {
                local_joint.rotation = rotation * anim.blend_alpha;
            } else {
                rotation_sign := dot(local_joint.rotation, rotation);
                // making sure rotation blends don't take the long way around
                if rotation_sign < 0 {
                    local_joint.rotation -= rotation * anim.blend_alpha;
                } else {
                    local_joint.rotation += rotation * anim.blend_alpha;
                }
            }
        }

        if per_anim.count > 0 {
            normalize(local_joint.rotation);
        }

        if joint.parent != -1 {
            pose.model_joints[ji] = pose.model_joints[joint.parent] * make_transform_matrix(local_joint.*);
        } else {
            pose.model_joints[ji] = make_transform_matrix(local_joint.*);
        }

        pose.skinning_joints[ji] = pose.model_joints[ji] * joint.inverse_bind_pose;
    }
}

#scope_file

Per_Animation_Data :: struct {
    prev_frame_index: s32;
    next_frame_index: s32;
    prev_timestamp: float32;
    next_timestamp: float32;
    anim_alpha: float32;
    blend_alpha: float32;
    prev_frame_transforms: []Joint_Transform;
    next_frame_transforms: []Joint_Transform;
}
