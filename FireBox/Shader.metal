#include <metal_stdlib>

using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float y_acceleration;
    float lifetime;
    float left_time;
    float elapsed_time;
    float start_size;
    float brightness_atten;
    float size_atten;
    int emitterId;
    int particleId;
    float3 pad0;
    float4 color;
    float4x4 transform;
};

struct Vertex {
    float4 position [[position]];
    float2 uv;
};

struct VertexOutput {
    float4 position [[position]];
    float4 color;
    float2 uv;
};

vertex VertexOutput particleVertex(const device Vertex *vertices [[buffer(0)]],
                             const device float2 &resolution [[buffer(1)]],
                             const device Particle *particles [[buffer(2)]],
                             unsigned int vid [[vertex_id]],
                             unsigned int particleId [[instance_id]]) {
    Vertex v = vertices[vid];
    
    Particle p = particles[particleId];
    float life_atten_ratio = saturate(p.left_time / max(p.lifetime, 0.001));
    float brightness_atten = mix(1.0, life_atten_ratio, p.brightness_atten);
    float size_atten = mix(1.0, life_atten_ratio, p.size_atten);
    constexpr float particle_size_scale = 4.0;
    float rendered_size = size_atten * particle_size_scale;
    float4x4 atten_transform = float4x4(float4(rendered_size, 0.0, 0.0, 0.0),
                                        float4(0.0, rendered_size, 0.0, 0.0),
                                        float4(0.0, 0.0, rendered_size, 0.0),
                                        float4(0.0, 0.0, 0.0, 1.0));
    v.position = atten_transform * p.transform * v.position;
    v.position.x = ((v.position.x + p.position.x) - resolution.x / 2) / (resolution.x / 2);
    v.position.y = -((v.position.y + p.position.y) - resolution.y / 2) / (resolution.y / 2);
    
    VertexOutput out;
    out.position = v.position;
    out.color = p.color * brightness_atten;
    out.uv = v.uv;
    return out;
}

fragment float4 particleFragment(VertexOutput in [[stage_in]],
                                 constant float &maximum_edr [[buffer(0)]]) {
    float2 point = in.uv * 2.0 - 1.0;
    float radius_squared = dot(point, point);
    float core = 1.0 - smoothstep(0.0, 0.12, radius_squared);
    float glow = 1.0 - smoothstep(0.04, 1.0, radius_squared);
    float alpha = saturate(core * 0.85 + glow * 0.55) * in.color.a;
    float sdr_intensity = saturate(core + glow * 0.22);
    float edr_boost = mix(1.0, maximum_edr, core);
    float intensity = min(sdr_intensity * edr_boost, maximum_edr);
    constexpr float exposure = 2.0;
    float3 color = min(in.color.rgb * intensity * exposure, float3(maximum_edr));
    return float4(color, alpha);
}

kernel void updateParticles(device Particle *particles [[buffer(0)]],
                            const device float &delta_time [[buffer(1)]],
                            unsigned int index [[thread_position_in_grid]]) {
    // handle gravity
    particles[index].velocity.y -= particles[index].y_acceleration * delta_time;
    
    simd_float2 displacement = particles[index].velocity * delta_time;
    particles[index].position += displacement;
    particles[index].left_time -= delta_time;
    particles[index].elapsed_time += delta_time;
}
