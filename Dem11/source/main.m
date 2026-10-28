#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <AudioToolbox/AudioToolbox.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include "shader.h"

static id<MTLDevice> gpu;
static id<MTLCommandQueue> queue;
static id<MTLRenderPipelineState> basePipeline, shardPipeline;
static id<MTLComputePipelineState> physicsPipeline;
static id<MTLBuffer> bodyBuffers[2];
static unsigned bodyRead,bodyFrame;
static BOOL bodiesActive;
static double lastBodyTime;
static CAMetalLayer *layer;
static double startTime;
static AudioQueueRef audio;
static unsigned long sampleIndex;
static double noiseLP;
static const double totalDuration=51.95;

static float rnd(unsigned x) { x^=x>>16;x*=0x7feb352dU;x^=x>>15;x*=0x846ca68bU;x^=x>>16;return (float)x/2147483648.f-1.f; }
static void ambient(void *ctx,AudioQueueRef aq,AudioQueueBufferRef b) {
    float *o=b->mAudioData;
    for(int i=0;i<4096;i++,sampleIndex++) {
        double t=sampleIndex/44100.,n=rnd((unsigned)sampleIndex);
        noiseLP+=(n-noiseLP)*.012;
        double breath=.65+.22*sin(t*.13)+.13*sin(t*.071+.7);
        double tone=sin(6.2831853*55*t+.18*sin(t*.07))*.045
            +sin(6.2831853*82.4069*t+.2*sin(t*.055+1.))*.031
            +sin(6.2831853*110*t+.13*sin(t*.09))*.024
            +sin(6.2831853*164.8138*t+.12*sin(t*.07+1.))*.016
            +sin(6.2831853*220*t+.17*sin(t*.041+2.))*.009;
        double s=(noiseLP*.025*breath+tone)*fmin(1.,t/4.)*fmax(0.,fmin(1.,(totalDuration-t)/5.));
        o[2*i]=s;o[2*i+1]=s*.94;
    }
    b->mAudioDataByteSize=32768;
    AudioQueueEnqueueBuffer(aq,b,0,0);
}

typedef struct { float width,height,time,pad; } Uniforms;
typedef struct { float dt,aspect; uint32_t frame,reset; } SimUniforms;
typedef struct { float p[4],v[4]; } BodyData;

static void render(id<MTLTexture> texture,float t,id<CAMetalDrawable> drawable) {
    MTLRenderPassDescriptor *pass=[MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture=texture;
    pass.colorAttachments[0].loadAction=MTLLoadActionClear;
    pass.colorAttachments[0].storeAction=MTLStoreActionStore;
    pass.colorAttachments[0].clearColor=MTLClearColorMake(0,0,0,1);
    id<MTLCommandBuffer> cb=[queue commandBuffer];
    BOOL drawBodies=(t>=9.33&&t<27.95);
    if(drawBodies) {
        BOOL reset=!bodiesActive||t<lastBodyTime;
        float dt=reset?0.f:(float)fmin(.04,fmax(0.,t-lastBodyTime));
        SimUniforms su={dt,(float)texture.width/(float)texture.height,bodyFrame,reset?1u:0u};
        id<MTLComputeCommandEncoder> ce=[cb computeCommandEncoder];
        [ce setComputePipelineState:physicsPipeline];
        [ce setBuffer:bodyBuffers[bodyRead] offset:0 atIndex:0];
        [ce setBuffer:bodyBuffers[1-bodyRead] offset:0 atIndex:1];
        [ce setBytes:&su length:sizeof(su) atIndex:2];
        NSUInteger group=MIN((NSUInteger)64,physicsPipeline.maxTotalThreadsPerThreadgroup);
        [ce dispatchThreads:MTLSizeMake(2048,1,1) threadsPerThreadgroup:MTLSizeMake(group,1,1)];
        [ce endEncoding];
        bodyRead=1-bodyRead;bodiesActive=YES;lastBodyTime=t;
        if(reset)bodyFrame=0;else bodyFrame++;
    } else bodiesActive=NO;
    id<MTLRenderCommandEncoder> enc=[cb renderCommandEncoderWithDescriptor:pass];
    Uniforms u={(float)texture.width,(float)texture.height,t,0};
    [enc setVertexBytes:&u length:sizeof(u) atIndex:0];
    [enc setFragmentBytes:&u length:sizeof(u) atIndex:0];
    [enc setRenderPipelineState:basePipeline];
    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    if(drawBodies) {
        [enc setRenderPipelineState:shardPipeline];
        [enc setVertexBuffer:bodyBuffers[bodyRead] offset:0 atIndex:1];
        [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3 instanceCount:2048];
    }
    [enc endEncoding];
    if(drawable)[cb presentDrawable:drawable];
    [cb commit];
    [cb waitUntilCompleted];
}

@interface Demo:NSObject<NSApplicationDelegate>
@property(strong) NSWindow *window;
-(void)tick:(NSTimer*)timer;
@end
@implementation Demo
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app{return YES;}
-(void)tick:(NSTimer*)timer {
    float t=NSProcessInfo.processInfo.systemUptime-startTime;
    if(t>=totalDuration){[NSApp terminate:nil];return;}
    @autoreleasepool {
        NSSize s=self.window.contentView.bounds.size;
        CGFloat scale=self.window.backingScaleFactor;
        layer.frame=self.window.contentView.bounds;
        float factor=fmin(1.,1280./(s.width*scale));
        layer.drawableSize=CGSizeMake(s.width*scale*factor,s.height*scale*factor);
        id<CAMetalDrawable> d=[layer nextDrawable];
        if(d)render(d.texture,t,d);
    }
}
-(void)applicationDidFinishLaunching:(NSNotification*)n {
    self.window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,1152,648)
        styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title=@"Dem11 / 64K — ←/→ scenes · F fullscreen · Esc quit";
    layer=[CAMetalLayer layer];layer.device=gpu;layer.pixelFormat=MTLPixelFormatBGRA8Unorm;
    self.window.contentView.wantsLayer=YES;self.window.contentView.layer=layer;
    [self.window center];[self.window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent*(NSEvent *e) {
        NSString *key=e.charactersIgnoringModifiers.lowercaseString;
        if(e.keyCode==53||([key isEqualToString:@"q"]&&(e.modifierFlags&NSEventModifierFlagCommand))) {
            [NSApp terminate:nil];return nil;
        }
        if(e.keyCode==3||[key isEqualToString:@"f"]||[key isEqualToString:@"а"]) {
            [self.window toggleFullScreen:nil];return nil;
        }
        if(e.keyCode==123||e.keyCode==124) {
            double now=NSProcessInfo.processInfo.systemUptime;
            int current=(now-startTime>=27.95)?1:0;
            int target=e.keyCode==124?MIN(1,current+1):MAX(0,current-1);
            if(target!=current)startTime=now-(target?27.95:0.);
            return nil;
        }
        return e;
    }];
    AudioStreamBasicDescription f={44100,kAudioFormatLinearPCM,kAudioFormatFlagIsFloat|kAudioFormatFlagIsPacked,8,1,8,2,32,0};
    if(AudioQueueNewOutput(&f,ambient,0,0,0,0,&audio)==0){
        for(int i=0;i<3;i++){AudioQueueBufferRef b;AudioQueueAllocateBuffer(audio,32768,&b);ambient(0,audio,b);}
        AudioQueueStart(audio,0);
    }
    startTime=NSProcessInfo.processInfo.systemUptime;
    [NSTimer scheduledTimerWithTimeInterval:1./60 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
}
-(void)applicationWillTerminate:(NSNotification*)n { if(audio){AudioQueueStop(audio,true);AudioQueueDispose(audio,true);} }
@end

static id<MTLRenderPipelineState> makePipeline(id<MTLLibrary> lib,id<MTLFunction> vf,id<MTLFunction> ff,BOOL blend) {
    MTLRenderPipelineDescriptor *d=[MTLRenderPipelineDescriptor new];
    d.vertexFunction=vf;d.fragmentFunction=ff;d.colorAttachments[0].pixelFormat=MTLPixelFormatBGRA8Unorm;
    if(blend){
        d.colorAttachments[0].blendingEnabled=YES;
        d.colorAttachments[0].rgbBlendOperation=MTLBlendOperationAdd;
        d.colorAttachments[0].alphaBlendOperation=MTLBlendOperationAdd;
        d.colorAttachments[0].sourceRGBBlendFactor=MTLBlendFactorOne;
        d.colorAttachments[0].destinationRGBBlendFactor=MTLBlendFactorOneMinusSourceAlpha;
        d.colorAttachments[0].sourceAlphaBlendFactor=MTLBlendFactorOne;
        d.colorAttachments[0].destinationAlphaBlendFactor=MTLBlendFactorOneMinusSourceAlpha;
    }
    NSError *e=nil;id<MTLRenderPipelineState> p=[gpu newRenderPipelineStateWithDescriptor:d error:&e];
    if(!p)fprintf(stderr,"Pipeline error: %s\n",e.localizedDescription.UTF8String);
    return p;
}

int main(int argc,char **argv) {@autoreleasepool {
    gpu=MTLCreateSystemDefaultDevice();if(!gpu){fprintf(stderr,"Metal device unavailable\n");return 1;}
    NSError *err=nil;id<MTLLibrary> lib=[gpu newLibraryWithSource:@SHADER options:nil error:&err];
    if(!lib){fprintf(stderr,"Metal shader compile failed: %s\n",err.localizedDescription.UTF8String);return 2;}
    basePipeline=makePipeline(lib,[lib newFunctionWithName:@"vert"],[lib newFunctionWithName:@"frag"],NO);
    shardPipeline=makePipeline(lib,[lib newFunctionWithName:@"shardVert"],[lib newFunctionWithName:@"shardFrag"],YES);
    physicsPipeline=[gpu newComputePipelineStateWithFunction:[lib newFunctionWithName:@"updateBodies"] error:&err];
    if(!basePipeline||!shardPipeline||!physicsPipeline){fprintf(stderr,"Compute pipeline error: %s\n",err.localizedDescription.UTF8String);return 3;}
    bodyBuffers[0]=[gpu newBufferWithLength:sizeof(BodyData)*2048 options:MTLResourceStorageModeShared];
    bodyBuffers[1]=[gpu newBufferWithLength:sizeof(BodyData)*2048 options:MTLResourceStorageModeShared];
    if(!bodyBuffers[0]||!bodyBuffers[1]){fprintf(stderr,"Particle buffers unavailable\n");return 4;}
    queue=[gpu newCommandQueue];
    if(argc==4&&!strcmp(argv[1],"--capture")){
        MTLTextureDescriptor *td=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:1280 height:720 mipmapped:NO];
        td.usage=MTLTextureUsageRenderTarget;td.storageMode=MTLStorageModeShared;
        id<MTLTexture> tex=[gpu newTextureWithDescriptor:td];float captureTime=atof(argv[2]);
        if(captureTime>=9.35&&captureTime<24.85){
            for(float simTime=9.33;simTime<captureTime;simTime+=1.f/30.f)render(tex,simTime,nil);
        }
        render(tex,captureTime,nil);
        unsigned char *pixels=malloc(1280*720*4);[tex getBytes:pixels bytesPerRow:1280*4 fromRegion:MTLRegionMake2D(0,0,1280,720) mipmapLevel:0];
        NSBitmapImageRep *rep=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:NULL pixelsWide:1280 pixelsHigh:720 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:5120 bitsPerPixel:32];
        unsigned char *dst=rep.bitmapData;for(int i=0;i<1280*720;i++){dst[i*4]=pixels[i*4+2];dst[i*4+1]=pixels[i*4+1];dst[i*4+2]=pixels[i*4];dst[i*4+3]=255;}
        [[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}]writeToFile:@(argv[3]) atomically:YES];free(pixels);return 0;
    }
    [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    Demo *demo=[Demo new];NSApp.delegate=demo;[NSApp run];
}return 0;}
