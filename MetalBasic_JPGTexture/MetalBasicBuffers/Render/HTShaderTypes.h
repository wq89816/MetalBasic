//
//  HTShaderTypes.h
//  MetalBasicBuffers
//
//  Created by zhangchi on 8/25/20.
//  Copyright © 2020 Wangqiao. All rights reserved.
//

/*
 介绍:
 头文件包含了 Metal shaders 与C/OBJC 源之间共享的类型和枚举常数
 */

#ifndef HTShaderTypes_h
#define HTShaderTypes_h
#include <simd/simd.h>
    //纹理索引
typedef enum HTTextureIndex
{
    HTTextureIndexBaseColor = 0
}HTTextureIndex;

typedef enum HTVertexInputIndex
{
        //顶点
    HTVertexInputIndexVertices     = 0,
        //视图大小
    HTVertexInputIndexViewportSize = 1,
} HTVertexInputIndex;

    //结构体: 顶点/颜色值
typedef struct
{
        // 像素空间的位置
        // 像素中心点(100,100)
        //float float
    vector_float2 position;
        // RGBA颜色
        // 2D 纹理坐标
    vector_float2 textureCoordinate;

} HTVertex;


#endif /* HTShaderTypes_h */
