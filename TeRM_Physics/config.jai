pause_physics :: () {
    world.step_state = .PAUSED;
}

unpause_physics :: () {
    world.step_state = .RUN_PHYSICS;
}
