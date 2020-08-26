//
//  HTShaders.metal
//  MetalBasicBuffers
//
//  Created by zhangchi on 8/25/20.
//  Copyright © 2020 Wangqiao. All rights reserved.
//

#include <metal_stdlib>
    //使用命名空间 Metal
using namespace metal;

    // 导入Metal shader 代码和执行Metal API命令的C代码之间共享的头
#import "HTShaderTypes.h"

    // 顶点着色器输出和片段着色器输入
    //结构体
typedef struct
{
        //处理空间的顶点信息
    float4 clipSpacePosition [[position]];

        //颜色
    float4 color;

} RasterizerData;

    //顶点着色函数
vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]],
             constant HTVertex *vertices [[buffer(HTVertexInputIndexVertices)]],
             constant vector_uint2 *viewportSizePointer [[buffer(HTVertexInputIndexViewportSize)]])
{
    /*
     处理顶点数据:
     1) 执行坐标系转换,将生成的顶点剪辑空间写入到返回值中.
     2) 将顶点颜色值传递给返回值
     */

        //定义out
    RasterizerData out;

    out.clipSpacePosition = vertices[vertexID].position;

        //把我们输入的颜色直接赋值给输出颜色. 这个值将于构成三角形的顶点的其他颜色值插值,从而为我们片段着色器中的每个片段生成颜色值.
    out.color = vertices[vertexID].color;

        //完成! 将结构体传递到管道中下一个阶段:
    return out;
}

    //当顶点函数执行3次,三角形的每个顶点执行一次后,则执行管道中的下一个阶段.栅格化/光栅化.


    // 片元函数
    //[[stage_in]],片元着色函数使用的单个片元输入数据是由顶点着色函数输出.然后经过光栅化生成的.单个片元输入函数数据可以使用"[[stage_in]]"属性修饰符.
    //一个顶点着色函数可以读取单个顶点的输入数据,这些输入数据存储于参数传递的缓存中,使用顶点和实例ID在这些缓存中寻址.读取到单个顶点的数据.另外,单个顶点输入数据也可以通过使用"[[stage_in]]"属性修饰符的产生传递给顶点着色函数.
    //被stage_in 修饰的结构体的成员不能是如下这些.Packed vectors 紧密填充类型向量,matrices 矩阵,structs 结构体,references or pointers to type 某类型的引用或指针. arrays,vectors,matrices 标量,向量,矩阵数组.
fragment float4 fragmentShader(RasterizerData in [[stage_in]])
{
        //返回输入的片元颜色
    return in.color;
}


