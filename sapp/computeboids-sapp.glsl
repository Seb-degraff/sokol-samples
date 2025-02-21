@cs cs

// keep this in sync with NUM_PARTICLES on the C side
const uint NUM_PARTICLES = 1500;

struct particle {
    vec2 pos;
    vec2 vel;
};

layout(binding=0) readonly buffer ssbo_in {
    particle prt_in[];
};

layout(binding=1) buffer ssbo_out {
    particle prt_out[];
};

layout(binding=0) uniform sim_params {
    float dt;
    float rule1_distance;
    float rule2_distance;
    float rule3_distance;
    float rule1_scale;
    float rule2_scale;
    float rule3_scale;
};

layout(local_size_x=64, local_size_y=1, local_size_z=1) in;
void main() {
    uint idx = gl_GlobalInvocationID.x;

    vec2 v_pos = prt_in[idx].pos;
    vec2 v_vel = prt_in[idx].vel;
    vec2 c_mass = vec2(0);
    vec2 c_vel = vec2(0);
    vec2 col_vel = vec2(0);
    uint c_mass_count = 0;
    uint c_vel_count = 0;
    for (uint i = 0; i < NUM_PARTICLES; i++) {
        if (i == idx) {
            continue;
        }
        vec2 pos = prt_in[i].pos;
        vec2 vel = prt_in[i].vel;
        float dist = distance(pos, v_pos);
        if (dist < rule1_distance) {
            c_mass += pos;
            c_mass_count += 1;
        }
        if (dist < rule2_distance) {
            col_vel -= pos - v_pos;
        }
        if (dist < rule3_distance) {
            c_vel += vel;
            c_vel_count += 1;
        }
    }
    if (c_mass_count > 0) {
        c_mass = (c_mass / vec2(c_mass_count)) - v_pos;
    }
    if (c_vel_count > 0) {
        c_vel /= float(c_vel_count);
    }
    v_vel += (c_mass * rule1_scale) + (col_vel * rule2_scale) + (c_vel * rule3_scale);

    // clamp velocity for a more pleasing simulation
    v_vel = normalize(v_vel) * clamp(length(v_vel), 0, 1);
    // kinematic update
    v_pos = v_pos + (v_vel * dt);
    // wrap around boundary
    if (v_pos.x < -1.0) {
        v_pos.x = 1.0;
    } else if (v_pos.x > 1.0) {
        v_pos.x = -1.0;
    }
    if (v_pos.y < -1.0) {
        v_pos.y = 1.0;
    } else if (v_pos.y > 1.0) {
        v_pos.y = -1.0;
    }

    prt_out[idx].pos = v_pos;
    prt_out[idx].vel = v_vel;
}
@end

@program compute cs
