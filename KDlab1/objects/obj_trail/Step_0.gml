/// obj_trail - Step
t += 1;
y -= 0.03;                                               // drifts up slowly
if (t >= 4 * KD_TRAIL_FRAME_STEPS) instance_destroy();   // 4 frames, then gone
