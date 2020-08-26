//
//  HTRender.m
//  MetalBasicBuffers
//
//  Created by zhangchi on 8/25/20.
//  Copyright © 2020 Wangqiao. All rights reserved.
//
@import MetalKit;
#import "HTRender.h"
#import "HTShaderTypes.h"

@implementation HTRender
{
    //渲染的设备(GPU)
    id<MTLDevice> _device;

    //渲染管道:顶点着色器/片元着色器,存储于.metal shader文件中
    id<MTLRenderPipelineState> _pipelineState;

    //命令队列
    id<MTLCommandQueue> _commandQueue;

    //点点缓存区
    id<MTLBuffer> _vertexBuffer;

    //当前视图大小
    vector_uint2 _viewportSize;

    //顶点个数
    NSInteger _numVertices;
}

//初始化
-(instancetype)initWithMetalKitView:(MTKView *)mView
{
    self = [super init];
    if(self){
       //1.初始GPU设备
        _device = mView.device;
       //2.加载Metal文件
        [self loadMetal:mView];
    }


    return self;

}

- (void)loadMetal:(nonnull MTKView *)mView
{
    //1.设置绘制纹理的像素格式
    mView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    //2.加载.metal着色器文件
    id<MTLLibrary> defaultLirary = [_device newDefaultLibrary];
    //加载顶点函数
    id<MTLFunction> vertexFuction = [defaultLirary newFunctionWithName:@"vertexShader"];
    //加载片元函数
    id<MTLFunction> fragmentFunction = [defaultLirary newFunctionWithName:@"fragmentShader"];

    //3.配置用于创建管道状态的管道
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    //管道名称
    pipelineStateDescriptor.label = @"Pipeline";
    //可编程函数,用于处理渲染过程中的各个顶点
    pipelineStateDescriptor.vertexFunction = vertexFuction;
    //可编程函数,用于处理渲染过程总的各个片段/片元
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    //设置管道中存储颜色数据的组件格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mView.colorPixelFormat;

    //4.同步创建并返回渲染管线对象
     NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if(!_pipelineState){
        NSLog(@"Failed to created pipeline state, error: %@", error);
    }

    //5.获取顶点数据
    NSData *vertexData = [HTRender generateVertexData];
    //创建一个vertex buffer,可以由GPU来读取
    _vertexBuffer = [_device newBufferWithLength:vertexData.length options:MTLResourceStorageModeShared];

    //复制vertex data 到vertex buffer 通过缓存区的"content"内容属性访问指针
    memcpy(_vertexBuffer.contents, vertexData.bytes, vertexData.length);

        //计算顶点个数 = 顶点数据长度 / 单个顶点大小
    _numVertices = vertexData.length / sizeof(HTVertex);

        //6.创建命令队列
    _commandQueue = [_device newCommandQueue];


}


    //顶点数据
+ (nonnull NSData *)generateVertexData
{
        //1.正方形 = 三角形+三角形
    const HTVertex quadVertices[] =
    {
        // Pixel 位置, RGBA 颜色
    { { -20,   20 },    { 1, 0, 0, 1 } },
    { {  20,   20 },    { 1, 0, 0, 1 } },
    { { -20,  -20 },    { 1, 0, 0, 1 } },

    { {  20,  -20 },    { 0, 0, 1, 1 } },
    { { -20,  -20 },    { 0, 0, 1, 1 } },
    { {  20,   20 },    { 0, 0, 1, 1 } },
    };
        //行/列 数量
    const NSUInteger NUM_COLUMNS = 25;
    const NSUInteger NUM_ROWS = 15;
        //顶点个数
    const NSUInteger NUM_VERTICES_PER_QUAD = sizeof(quadVertices) / sizeof(HTVertex);
        //四边形间距
    const float QUAD_SPACING = 50.0;
        //数据大小 = 单个四边形大小 * 行 * 列
    NSUInteger dataSize = sizeof(quadVertices) * NUM_COLUMNS * NUM_ROWS;

        //2. 开辟空间
    NSMutableData *vertexData = [[NSMutableData alloc] initWithLength:dataSize];
        //当前四边形
    HTVertex * currentQuad = vertexData.mutableBytes;


        //3.获取顶点坐标(循环计算)
        //行
    for(NSUInteger row = 0; row < NUM_ROWS; row++)
        {
            //列
        for(NSUInteger column = 0; column < NUM_COLUMNS; column++)
            {
                //A.左上角的位置
            vector_float2 upperLeftPosition;

                //B.计算X,Y 位置.注意坐标系基于2D笛卡尔坐标系,中心点(0,0),所以会出现负数位置
            upperLeftPosition.x = ((-((float)NUM_COLUMNS) / 2.0) + column) * QUAD_SPACING + QUAD_SPACING/2.0;

            upperLeftPosition.y = ((-((float)NUM_ROWS) / 2.0) + row) * QUAD_SPACING + QUAD_SPACING/2.0;

                //C.将quadVertices数据复制到currentQuad
            memcpy(currentQuad, &quadVertices, sizeof(quadVertices));

                //D.遍历currentQuad中的数据
            for (NSUInteger vertexInQuad = 0; vertexInQuad < NUM_VERTICES_PER_QUAD; vertexInQuad++)
                {
                    //修改vertexInQuad中的position
                currentQuad[vertexInQuad].position += upperLeftPosition;
                }

                //E.更新索引
            currentQuad += 6;
            }
        }

    return vertexData;

}
#pragma mark -- MTKView Delegate

    //每当视图改变方向或调整大小时调用
-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{

    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

    //每当视图需要渲染帧时调用
- (void)drawInMTKView:(MTKView *)view
{

    //1.为当前渲染的每个渲染传递创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"command buffer";

    //2. MTLRenderPassDescriptor:一组渲染目标，用作渲染通道生成的像素的输出目标。
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor!=nil) {
        //创建渲染命令编码器
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"myRenderEncoder";

        //3.设置我们绘制的可绘制区域
        /*
         typedef struct {
         double originX, originY, width, height, znear, zfar;
         } MTLViewport;
         */
        [renderEncoder setViewport:(MTLViewport){0.0,0.0,_viewportSize.x,_viewportSize.y,-1.0,1.0}];

         //4. 设置渲染管道
        [renderEncoder setRenderPipelineState:_pipelineState];

            //将_vertexBuffer 设置到顶点缓存区中
        [renderEncoder setVertexBuffer:_vertexBuffer
                                offset:0
                               atIndex:HTVertexInputIndexVertices];

            //将 _viewportSize 设置到顶点缓存区绑定点设置数据
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:HTVertexInputIndexViewportSize];

        //6.开始绘图
        // @method drawPrimitives:vertexStart:vertexCount:
        //@brief 在不使用索引列表的情况下,绘制图元
        //@param 绘制图形组装的基元类型
        //@param 从哪个位置数据开始绘制,一般为0
        //@param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];

        //7.表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
        [renderEncoder endEncoding];

        //8.一旦框架缓冲区完成，使用当前可绘制的进度表
        [commandBuffer presentDrawable:view.currentDrawable];

    }
        //9.最后,在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];



}

@end
