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
    float life_time;
};

vertex VertexOutput particleVertex(const device Vertex *vertices [[buffer(0)]],
                             const device float2 &resolution [[buffer(1)]],
                             const device Particle *particles [[buffer(2)]],
                             const device float2 &targetFrameSize [[buffer(3)]],
                             unsigned int vid [[vertex_id]],
                             unsigned int particleId [[instance_id]]) {
    Vertex v = vertices[vid];
    
    Particle p = particles[particleId];
    float life_atten_ratio = p.left_time / p.lifetime;
    float brightness_atten = mix(1.0, life_atten_ratio, p.brightness_atten);
    float size_atten = mix(1.0, life_atten_ratio, p.size_atten);
    float4x4 atten_transform = float4x4(float4(size_atten, 0.0, 0.0, 0.0),
                                        float4(0.0, size_atten, 0.0, 0.0),
                                        float4(0.0, 0.0, size_atten, 0.0),
                                        float4(0.0, 0.0, 0.0, 1.0));
    v.position = atten_transform * p.transform * v.position;
    v.position.x = ((v.position.x + p.position.x) - resolution.x / 2) / (resolution.x / 2);
    v.position.y = -((v.position.y + p.position.y) - resolution.y / 2) / (resolution.y / 2);
    
    VertexOutput out;
    out.position = v.position;
    out.life_time = p.lifetime;
    out.color = p.color * brightness_atten * 2.0;
    out.uv = v.uv;
    return out;
}

fragment float4 particleFragment(VertexOutput in [[stage_in]],
                                 const texture2d<float> texture [[texture(0)]]) {
    constexpr sampler sampler;
    float4 color = texture.sample(sampler, in.uv) * in.color;
    return color;
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
