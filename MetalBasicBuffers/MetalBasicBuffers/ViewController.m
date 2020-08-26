//
//  ViewController.m
//  MetalBasicBuffers
//
//  Created by WangQiao on 8/25/20.
//  Copyright © 2020 Wangqiao. All rights reserved.
//

#import "ViewController.h"
#import "HTRender.h"

@interface ViewController (){
    MTKView *_view;
    HTRender *_renderer;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //1.获取MTKView
    _view = (MTKView *)self.view;
        //一个MTLDevice 对象就代表这着一个GPU,通常我们可以调用方法MTLCreateSystemDefaultDevice()来获取代表默认的GPU单个对象.
    _view.device = MTLCreateSystemDefaultDevice();
    if(!_view.device)
        {
        NSLog(@"Metal is not supported on this device");
        return;
        }

        //2.创建CCRender
    _renderer = [[HTRender alloc] initWithMetalKitView:_view];
    if(!_renderer)
        {
        NSLog(@"Renderer failed initialization");
        return;
        }
        //用视图大小初始化渲染器
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
        //设置MTKView代理
    _view.delegate = _renderer;
}


@end
