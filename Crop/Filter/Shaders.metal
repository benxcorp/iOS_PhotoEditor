//
//  Shaders.metal
//  ImageCropSample
//
//  Created by iron on 2021/08/26.
//

#include <metal_stdlib>
using namespace metal;


struct VertexIO
{
    float4 position [[position]];
    float2 textureCoord [[user(texturecoord)]];
};

vertex VertexIO vertexPassThrough(const device packed_float4 *pPosition  [[ buffer(0) ]],
                                  const device packed_float2 *pTexCoords [[ buffer(1) ]],
                                  uint vid [[ vertex_id ]]) {
    VertexIO outVertex;
    outVertex.position = pPosition[vid];
    outVertex.textureCoord = pTexCoords[vid];
    return outVertex;
}


struct RasterizerData {
    float4 position [[ position ]];
    float2 textureCoord [[ user(texturecoord) ]];
};

vertex RasterizerData vertexPassThroughShader(const device packed_float2* vertices [[ buffer(0) ]],
                                              unsigned int vertexId [[ vertex_id ]]) {
    RasterizerData outData;
    outData.position = float4(vertices[vertexId], 0.0, 1.0);
    outData.textureCoord = vertices[vertexId];
    return outData;
}

struct VertexOut {
    float4 position [[ position ]];
    float2 textureCoordinate;
};

struct VertexIn {
    vector_float4 position;
    vector_float2 textureCoordinate;
};

vertex VertexOut passthroughVertex(const device VertexIn * vertices [[ buffer(0) ]],
                                   uint vid [[ vertex_id ]]) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position;
    outVertex.textureCoordinate = inVertex.textureCoordinate;
    return outVertex;
}


METAL_FUNC float4 metalColorLookUp(texture2d<float, access::sample> lutTexture,
                                   sampler lutSamper,
                                   float3 texCoord,
                                   float size) {
    float sliceSize = 1.0 / size;
    float slicePixelSize = sliceSize / size;
    float sliceInnerSize = slicePixelSize * (size - 1.0);
    float xOffset = 0.5 * sliceSize + texCoord.x * (1.0 - sliceSize);
    
    float yOffset = 0.5 * slicePixelSize + texCoord.y * sliceInnerSize;
    float zOffset = texCoord.z * (size - 1.0);
    float zSlice0 = floor(zOffset);
    float zSlice1 = zSlice0 + 1.0;
    float s0 = yOffset + (zSlice0 * sliceSize);
    float s1 = yOffset + (zSlice1 * sliceSize);
    float4 slice0Color = lutTexture.sample(lutSamper, float2(xOffset, s0));
    float4 slice1Color = lutTexture.sample(lutSamper, float2(xOffset, s1));
    return mix(slice0Color, slice1Color, zOffset - zSlice0);
}

fragment float4 fragmentLookupShader(VertexIO data [[stage_in]],
                                     texture2d<float, access::sample> inputTexture [[ texture(0) ]],
                                     texture2d<float, access::sample> lutTexture [[ texture(1) ]],
                                     sampler sampler [[sampler(0)]]) {
    
    float4 inputSampledColor = inputTexture.sample(sampler, data.textureCoord);
    
    float3 lutColor = metalColorLookUp(lutTexture,
                                       sampler,
                                       inputSampledColor.rgb,
                                       33).rgb;
    
    float strength = 0.5;
    
    float3 finalRGB = mix(inputSampledColor.rgb, lutColor.rgb, strength);
    float4 finalColor = float4(finalRGB, 1);
    
    return finalColor;
}


METAL_FUNC float4 colorLookup2DSquareLUT(float4 color,
                                         int dimension,
                                         float intensity,
                                         texture2d<float, access::sample> lutTexture,
                                         sampler lutSamper) {
    float row = round(sqrt((float)dimension));
    float blueColor = color.b * (dimension - 1);
    
    float2 quad1;
    quad1.y = floor(floor(blueColor) / row);
    quad1.x = floor(blueColor) - (quad1.y * row);
    
    float2 quad2;
    quad2.y = floor(ceil(blueColor) / row);
    quad2.x = ceil(blueColor) - (quad2.y * row);;
    
    float2 texPos1;
    texPos1.x = (quad1.x * (1.0/row)) + 0.5/lutTexture.get_width() + ((1.0/row - 1.0/lutTexture.get_width()) * color.r);
    texPos1.y = (quad1.y * (1.0/row)) + 0.5/lutTexture.get_height() + ((1.0/row - 1.0/lutTexture.get_height()) * color.g);

    float2 texPos2;
    texPos2.x = (quad2.x * (1.0/row)) + 0.5/lutTexture.get_width() + ((1.0/row - 1.0/lutTexture.get_width()) * color.r);
    texPos2.y = (quad2.y * (1.0/row)) + 0.5/lutTexture.get_height() + ((1.0/row - 1.0/lutTexture.get_height()) * color.g);
    
    float4 newColor1 = lutTexture.sample(lutSamper, texPos1);
    float4 newColor2 = lutTexture.sample(lutSamper, texPos2);
    
    float4 newColor = mix(newColor1, newColor2, float(fract(blueColor)));
    
    float4 finalColor = mix(color, float4(newColor.rgb, color.a), intensity);
    
    return finalColor;
}



fragment float4 colorLookup2DSquare (VertexIO data  [[stage_in]],
                                     texture2d<float, access::sample> sourceTexture [[texture(0)]],
                                     texture2d<float, access::sample> lutTexture [[texture(1)]],
                                     sampler colorSampler [[sampler(0)]],
                                     sampler lutSamper [[sampler(1)]],
                                     constant int & dimension [[buffer(0)]],
                                     constant float & intensity [[ buffer(1) ]]) {
    float2 sourceCoord = data.textureCoord;
    float4 color = sourceTexture.sample(colorSampler,sourceCoord);
    return colorLookup2DSquareLUT(color, dimension, intensity, lutTexture, lutSamper);
}
