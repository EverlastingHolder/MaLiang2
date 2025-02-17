//
//  Shaders.metal
//  MaLiang
//
//  Created by Harley-xk on 2019/3/28.
//  Copyright © 2019 Harley-xk. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//======================================
// Render Target Shaders
//======================================

struct Vertex {
    float4 position [[position]];
    float2 text_coord;
};

struct Uniforms {
    float4x4 scaleMatrix;
};

struct Point {
    float4 position [[position]];
    float4 color;
    float angle;
    float size [[point_size]];
    float intensity;
};

struct Transform {
    float2 offset;
    float scale;
};

vertex Vertex vertex_render_target(constant Vertex *vertexes [[ buffer(0) ]],
                                   constant Uniforms &uniforms [[ buffer(1) ]],
                                   uint vid [[vertex_id]])
{
    Vertex out = vertexes[vid];
    out.position = uniforms.scaleMatrix * out.position;
    return out;
};

float2 transformPointCoord(float2 pointCoord, float a, float2 anchor) {
    float2 point20 = pointCoord - anchor;
    float x = point20.x * cos(a) - point20.y * sin(a);
    float y = point20.x * sin(a) + point20.y * cos(a);
    return float2(x, y) + anchor;
}

//======================================
// Printer Shaders
//======================================
vertex Vertex vertex_printer_func(constant Vertex *vertexes [[ buffer(0) ]],
                                  constant Uniforms &uniforms [[ buffer(1) ]],
                                  constant Transform &transform [[ buffer(2) ]],
                                  uint vid [[ vertex_id ]])
{
    Vertex out = vertexes[vid];
    float scale = transform.scale;
    float2 offset = transform.offset;
    float2 pos = float2(out.position.x * scale - offset.x, out.position.y * scale - offset.y);
    out.position = uniforms.scaleMatrix * float4(pos, 0, 1);
    return out;
};

//======================================
// Point Shaders
//======================================
vertex Point vertex_point_func(constant Point *points [[ buffer(0) ]],
                               constant Uniforms &uniforms [[ buffer(1) ]],
                               constant Transform &transform [[ buffer(2) ]],
                               uint vid [[ vertex_id ]])
{
    Point out = points[vid];
    float scale = transform.scale;
    float2 offset = transform.offset;
    float2 pos = float2(out.position.x * scale - offset.x, out.position.y * scale - offset.y);
    out.position = uniforms.scaleMatrix * float4(pos, 0, 1);
    out.size = out.size * scale;
    return out;
};

fragment float4 fragment_point_func(Point point_data [[ stage_in ]],
                                    texture2d<float> tex2d [[ texture(0) ]],
                                    float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 text_coord = transformPointCoord(pointCoord, point_data.angle, float2(0.5));
    float4 color = float4(tex2d.sample(textureSampler, text_coord));
    return float4(point_data.color.rgb, color.a * point_data.color.a);
};

//======================================
// Draw points with single color
//======================================
fragment float4 fragment_render_target(Vertex vertex_data [[ stage_in ]],
                                       texture2d<float> tex2d [[ texture(0) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, vertex_data.text_coord));
    return color;
};

//======================================
// Draw points with image textures, not with single color
//======================================
fragment float4 fragment_render_printer(Point point_data [[ stage_in ]],
                                       texture2d<float> tex2d [[ texture(0) ]],
                                       float2 pointCoord [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 text_coord = transformPointCoord(pointCoord, point_data.angle, float2(0.5));
    float4 textureColor = float4(tex2d.sample(textureSampler, text_coord));
    return textureColor;
}

//======================================
// Draw blur
//======================================
fragment float4 fragment_render_smudge(Point point_data [[ stage_in ]],
                                       texture2d<float> tex2d [[ texture(0) ]],
                                       float2 pointCoord [[ point_coord ]],
                                       texture2d<float> texCanvas [[ texture(1) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    // Get texture sizes
    float2 texCanvasSize = float2(texCanvas.get_width(), texCanvas.get_height());
    
    // Initialize the accumulator for the blur
    float4 blurColor = float4(0.0, 0.0, 0.0, 0.0);
    int blurRadius = int(point_data.intensity); // You can adjust this radius to define the blur strength
    int count = 0;
    
    // Iterate over the region specified by tex2dSize
    for (int x = -blurRadius; x <= blurRadius; ++x)
    {
        for (int y = -blurRadius; y <= blurRadius; ++y)
        {
            // Calculate the sample position
            float2 sampleCoord = float2(point_data.position.x + x, point_data.position.y + y);
            
            // Ensure the sample coordinates are within bounds of texCanvas
            if (sampleCoord.x >= 0.0 && sampleCoord.x < texCanvasSize.x &&
                sampleCoord.y >= 0.0 && sampleCoord.y < texCanvasSize.y)
            {
                // Sample the color at the current coordinate
                float4 sampleColor = texCanvas.sample(textureSampler, sampleCoord / texCanvasSize);
                
                // Accumulate the color
                blurColor += sampleColor;
                count++;
            }
        }
    }
    
    // Average the accumulated colors to produce the blur
    if (count > 0)
    {
        blurColor /= float(count);
    }
    
    return blurColor;
}

// franment shader for glowing lines
fragment float4 fragment_point_func_glowing(Point point_data [[ stage_in ]],
                                            texture2d<float> tex2d [[ texture(0) ]],
                                            float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(tex2d.sample(textureSampler, pointCoord));
    if (color.a >= 1) {
        return float4(1, 1, 1, color.a);
    } else if (color.a <= 0) {
        return float4(0);
    }
    return float4(point_data.color.rgb, color.a * point_data.color.a);
};

// franment shader that applys original color of the texture
fragment half4 fragment_point_func_original(Point point_data [[ stage_in ]],
                                            texture2d<float> tex2d [[ texture(0) ]],
                                            float2 pointCoord  [[ point_coord ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    half4 color = half4(tex2d.sample(textureSampler, pointCoord));
    return half4(color.rgb, color.a * point_data.color.a);
};

fragment float4 fragment_point_func_without_texture(Point point_data [[ stage_in ]],
                                                    float2 pointCoord  [[ point_coord ]])
{
    float dist = length(pointCoord - float2(0.5));
    if (dist >= 0.5) {
        return float4(0);
    }
    return point_data.color;
}

fragment float4 fragment_mask_func(Point point_data [[ stage_in ]],
                                   texture2d<float> tex2d [[ texture(0) ]],
                                   float2 pointCoord [[ point_coord ]],
                                   texture2d<float> texCanvas [[ texture(1) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 texCanvasSize = float2(texCanvas.get_width(), texCanvas.get_height());
    
    float2 sampleCoord = float2(point_data.position.x, point_data.position.y);
    
    float4 mainColor = float4(tex2d.sample(textureSampler, pointCoord));
    float4 maskColor = texCanvas.sample(textureSampler, sampleCoord / texCanvasSize);
    
    return float4(maskColor.rgb, mainColor.a);
}
