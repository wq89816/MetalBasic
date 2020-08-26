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
#import "HTImage.h"

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

        // Metal 纹理对象
    id<MTLTexture> _texture;

    //当前视图大小
    vector_uint2 _viewportSize;

    //顶点个数
    NSInteger _numVertices;

    MTKView *htMTKView;
}

//初始化
-(instancetype)initWithMetalKitView:(MTKView *)mView
{
    self = [super init];
    if(self){
       //1.初始GPU设备
        _device = mView.device;

        htMTKView = mView;

            //2.设置顶点相关操作
        [self setupVertex];
            //3.设置渲染管道相关操作
        [self setupPipeLine];
//            //4.加载纹理TGA 文件
//        [self setupTexture];

            //4.加载纹理jpg 文件
        [self setupTexturePNG];
    }


    return self;

}

#pragma mark -- init setUp


    //从UIImage 中读取Byte 数据返回
- (Byte *)loadImage:(UIImage *)image {
        // 1.获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;

        // 2.读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);

        //3.计算图片大小.rgba共4个byte
    Byte * spriteData = (Byte *) calloc(width * height * 4, sizeof(Byte));

        //4.创建画布
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);

        //5.在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);

        //6.图片翻转过来
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(spriteContext, 0, rect.size.height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
    CGContextDrawImage(spriteContext, rect, spriteImage);

        //7._
    CGContextRelease(spriteContext);

    return spriteData;
}

-(void)setupTexturePNG
{
        //1.获取图片
    UIImage *image = [UIImage imageNamed:@"meimei.jpg"];
        //2.纹理描述符
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
        //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
        //设置纹理的像素尺寸
    textureDescriptor.width = image.size.width;
    textureDescriptor.height = image.size.height;

        //3.使用描述符从设备中创建纹理
    _texture = [_device newTextureWithDescriptor:textureDescriptor];

        //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
        //4. 创建MTLRegion 结构体  [纹理上传的范围]
    MTLRegion region = {{ 0, 0, 0 }, {image.size.width, image.size.height, 1}};

        //5.获取图片数据
    Byte *imageBytes = [self loadImage:image];

        //6.UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
    if (imageBytes) {
        [_texture replaceRegion:region
                    mipmapLevel:0
                      withBytes:imageBytes
                    bytesPerRow:4 * image.size.width];
        free(imageBytes);
        imageBytes = NULL;
    }

}
-(void)setupTexture
{
    //1.获取tag的路径
    NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:@"Image" withExtension:@"tga"];

    //将tga转换为HTImage对象
    HTImage *image = [[HTImage alloc]initWithTGAFileAtLocation:imageFileLocation];
    //判断图片是否转换成功
    if(!image)
    {
        NSLog(@"Failed to create the image from:%@",imageFileLocation.absoluteString);

    }

    //2.创建纹理描述对象
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
        //设置纹理的像素尺寸
    textureDescriptor.width = image.width;
    textureDescriptor.height = image.height;
    //使用描述符从设备中创建纹理
    _texture = [_device newTextureWithDescriptor:textureDescriptor];
    //计算图像每行的字节数
    NSInteger bytesPerRow = 4*image.width;

    /*
     typedef struct
     {
     MTLOrigin origin; //开始位置x,y,z
     MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
        //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    //3. 创建MTLRegion 结构体
    MTLRegion region = {
        {0,0,0},
        {image.width,image.height,1}
    };
    //4.复制图片数据到texture
    [_texture replaceRegion:region mipmapLevel:0 withBytes:image.data.bytes bytesPerRow:bytesPerRow];


}

-(void)setupPipeLine
{
        //1.设置绘制纹理的像素格式
    htMTKView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

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
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = htMTKView.colorPixelFormat;

        //4.同步创建并返回渲染管线对象
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if(!_pipelineState){
        NSLog(@"Failed to created pipeline state, error: %@", error);
    }
        //5.使用_device创建commandQueue
    _commandQueue = [_device newCommandQueue];
}

-(void)setupVertex
{
        //1.根据顶点/纹理坐标建立一个MTLBuffer
    static const HTVertex quadVertices[] = {
            //像素坐标,纹理坐标
        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,  -250 },  { 0.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },

        { {  250,  -250 },  { 1.f, 0.f } },
        { { -250,   250 },  { 0.f, 1.f } },
        { {  250,   250 },  { 1.f, 1.f } },

    };
    //2.创建顶点缓冲区，并用我们的Qualsits数组初始化它
    _vertexBuffer = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];

    //3.通过将字节长度除以每个顶点的大小来计算顶点的数目
    _numVertices = sizeof(quadVertices) / sizeof(HTVertex);
}


#pragma mark -- MTKView Delegate

    //每当视图改变方向或调整大小时调用
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{

    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

    //每当视图需要渲染帧时调用
- (void)drawInMTKView:(nonnull MTKView *)view
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

        //设置纹理对象
        [renderEncoder setFragmentTexture:_texture atIndex:HTTextureIndexBaseColor];

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
