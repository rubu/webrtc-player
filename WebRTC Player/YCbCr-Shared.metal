//
//  YCbCr-Shader.metal
//  MetalVideoCapture
//
//  Created by Simon Gladman on 09/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
// Based on code from http://mczonk.de/video-texture-streaming-with-metal/

#include <metal_stdlib>
using namespace metal;


kernel void YCbCrColorConversion(texture2d<float, access::read> yTexture [[texture(0)]],
                                   texture2d<float, access::read> uTexture [[texture(1)]],
                                   texture2d<float, access::read> vTexture [[texture(2)]],
                                   texture2d<float, access::write> outTexture [[texture(3)]],
                                   uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float3 colorOffset = float3(-(16.0/255.0), -0.5, -0.5);
    float3x3 colorMatrix = float3x3(
                                    float3(1.164,  1.164, 1.164),
                                    float3(0.000, -0.392, 2.017),
                                    float3(1.596, -0.813, 0.000)
                                    );
    
    uint2 cbcrCoordinates = uint2(gid.x / 2, gid.y / 2); // half the size because we are using a 4:2:0 chroma subsampling
    
    float y = yTexture.read(gid).r;
    float u = uTexture.read(cbcrCoordinates).r;
    float v = vTexture.read(cbcrCoordinates).r;
    
    float3 yuv = float3(y, u, v);
    
    float3 rgb = colorMatrix * (yuv + colorOffset);

    outTexture.write(float4(float3(rgb), 1.0), gid);
}
