//
//  HTRender.h
//  MetalBasicBuffers
//
//  Created by zhangchi on 8/25/20.
//  Copyright © 2020 Wangqiao. All rights reserved.
//

#import <Foundation/Foundation.h>
//导入MetalKit工具包
@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

//MTKViewDelegate协议:允许对象呈现在视图中渲染并响应调整大小事件
@interface HTRender : NSObject<MTKViewDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mView;
@end

NS_ASSUME_NONNULL_END
