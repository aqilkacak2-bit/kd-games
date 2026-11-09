/// obj_kd_fx - Step
t += 1;
if (kind == "smoke" || kind == "ember")
{
    x += vx;
    y += vy;
}
if (t >= life) instance_destroy();
