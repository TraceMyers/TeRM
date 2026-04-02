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

make_pose :: (pose: *Skeletal_Pose, skeleton: *Skeleton, animation_index: int, animation_time: float32) {
    animation := *skeleton.animations[animation_index];
    assert(animation.timestamps.count >= 2);
    assert(pose.allocation == null);

    allocation_size := (size_of(Joint_Transform) + (size_of(Matrix4) * 2)) * skeleton.joints.count;
    joint_count     := skeleton.joints.count;
    
    pose.skeleton   = skeleton;
    pose.allocation = alloc(allocation_size);

    pose.local_joints.data     = xx pose.allocation;
    pose.local_joints.count    = joint_count;
    pose.model_joints.data     = xx ((cast(*u8) pose.local_joints.data) + size_of(Joint_Transform) * joint_count);
    pose.model_joints.count    = joint_count;
    pose.skinning_joints.data  = xx ((cast(*u8) pose.model_joints.data) + size_of(Matrix4) * joint_count);
    pose.skinning_joints.count = joint_count;

    next_frame_index: int;

    for 1..animation.timestamps.count - 1 {
        if animation_time < animation.timestamps[it] {
            next_frame_index = it;
            break;
        }
    }

    next_frame_index  = max(next_frame_index, 1);
    prev_frame_index := next_frame_index - 1;

    prev_timestamp := animation.timestamps[prev_frame_index];
    next_timestamp := animation.timestamps[next_frame_index];

    alpha := respace(animation_time, {prev_timestamp, next_timestamp}, {0, 1});

    prev_frame_transforms := get_joint_transforms(skeleton, animation, prev_frame_index);
    next_frame_transforms := get_joint_transforms(skeleton, animation, next_frame_index);

    for *joint : skeleton.joints {
        prev_frame := *prev_frame_transforms[it_index];
        next_frame := *next_frame_transforms[it_index];
        
        local_joint := *pose.local_joints[it_index];
        local_joint.translation = lerp(prev_frame.translation, next_frame.translation, alpha);
        local_joint.rotation    = interp_rotate_with_alpha(prev_frame.rotation, next_frame.rotation, alpha);
        local_joint.scale       = lerp(prev_frame.scale, next_frame.scale, alpha);

        if joint.parent != -1 {
            pose.model_joints[it_index] = pose.model_joints[joint.parent] * make_transform_matrix(local_joint.*);
        } else {
            pose.model_joints[it_index] = make_transform_matrix(local_joint.*);
        }

        pose.skinning_joints[it_index] = pose.model_joints[it_index] * joint.inverse_bind_pose;
    }
}
