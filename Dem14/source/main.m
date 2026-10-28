#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <AudioToolbox/AudioToolbox.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "shader.h"

static id<MTLDevice> gpu;static id<MTLCommandQueue> queue;static id<MTLRenderPipelineState> renderPipe;
static CAMetalLayer *layer;static double startTime;static AudioQueueRef audio;static unsigned long sampleIndex;
static const double duration=57.;
typedef struct{float w,h,t,pad;}U;
static void sound(void*ctx,AudioQueueRef q,AudioQueueBufferRef b){
 float*o=b->mAudioData;
 for(int i=0;i<4096;i++,sampleIndex++){
  double t=sampleIndex/44100.,fade=fmin(1.,t/3.)*fmax(0.,fmin(1.,(duration-t)/6.));
  double air=sin(6.2831853*173.*t+.24*sin(t*.07))*.004+sin(6.2831853*261.63*t+.2*sin(t*.06+1.))*.003;
  double drone=sin(6.2831853*49.*t+.15*sin(t*.05))*.025+sin(6.2831853*73.416*t+.12*sin(t*.04+1.))*.015;
  double transition=fmin(1.,fmax(0.,(t-27.)/7.));double shimmer=sin(6.2831853*(330.+90.*transition)*t+.2*sin(t*.11))*.004;
  double steps=0.;for(int k=0;k<28;k++){double at=2.+k*1.75;double x=(t-at)/.13;steps+=exp(-x*x)*sin(6.2831853*(155.+(k%4)*28.)*t)*.0025;}
  double s=(air+drone+shimmer+steps)*fade;o[2*i]=s;o[2*i+1]=s*.94;
 }
 b->mAudioDataByteSize=32768;AudioQueueEnqueueBuffer(q,b,0,0);
}
static void render(id<MTLTexture>tex,float t,id<CAMetalDrawable>d){
 MTLRenderPassDescriptor*rp=[MTLRenderPassDescriptor renderPassDescriptor];rp.colorAttachments[0].texture=tex;rp.colorAttachments[0].loadAction=MTLLoadActionClear;rp.colorAttachments[0].storeAction=MTLStoreActionStore;rp.colorAttachments[0].clearColor=MTLClearColorMake(0,0,0,1);
 id<MTLCommandBuffer>cb=[queue commandBuffer];id<MTLRenderCommandEncoder>e=[cb renderCommandEncoderWithDescriptor:rp];U u={(float)tex.width,(float)tex.height,t,0};
 [e setRenderPipelineState:renderPipe];[e setFragmentBytes:&u length:sizeof(u) atIndex:0];[e drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];[e endEncoding];if(d)[cb presentDrawable:d];[cb commit];[cb waitUntilCompleted];
}
@interface Demo:NSObject<NSApplicationDelegate>
@property(strong)NSWindow*window;
-(void)tick:(NSTimer*)timer;
@end
@implementation Demo
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)a{return YES;}
-(void)tick:(NSTimer*)timer{
 float t=NSProcessInfo.processInfo.systemUptime-startTime;if(t>=duration){[NSApp terminate:nil];return;}
 NSSize s=self.window.contentView.bounds.size;CGFloat scale=self.window.backingScaleFactor;layer.frame=self.window.contentView.bounds;float f=fmin(1.,880./(s.width*scale));layer.drawableSize=CGSizeMake(s.width*scale*f,s.height*scale*f);id<CAMetalDrawable>d=[layer nextDrawable];if(d)render(d.texture,t,d);
}
-(void)applicationDidFinishLaunching:(NSNotification*)n{
 self.window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,1152,648)styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];self.window.title=@"Dem14 / 64K — F fullscreen · Esc quit";
 layer=[CAMetalLayer layer];layer.device=gpu;layer.pixelFormat=MTLPixelFormatBGRA8Unorm;self.window.contentView.wantsLayer=YES;self.window.contentView.layer=layer;[self.window center];[self.window makeKeyAndOrderFront:nil];[NSApp activateIgnoringOtherApps:YES];
 [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent*(NSEvent*e){NSString*k=e.charactersIgnoringModifiers.lowercaseString;if(e.keyCode==53||([k isEqualToString:@"q"]&&(e.modifierFlags&NSEventModifierFlagCommand))){[NSApp terminate:nil];return nil;}if(e.keyCode==3||[k isEqualToString:@"f"]||[k isEqualToString:@"а"]){[self.window toggleFullScreen:nil];return nil;}return e;}];
 AudioStreamBasicDescription f={44100,kAudioFormatLinearPCM,kAudioFormatFlagIsFloat|kAudioFormatFlagIsPacked,8,1,8,2,32,0};if(AudioQueueNewOutput(&f,sound,0,0,0,0,&audio)==0){for(int i=0;i<3;i++){AudioQueueBufferRef b;AudioQueueAllocateBuffer(audio,32768,&b);sound(0,audio,b);}AudioQueueStart(audio,0);}
 startTime=NSProcessInfo.processInfo.systemUptime;[NSTimer scheduledTimerWithTimeInterval:1./60 target:self selector:@selector(tick:)userInfo:nil repeats:YES];
}
-(void)applicationWillTerminate:(NSNotification*)n{if(audio){AudioQueueStop(audio,true);AudioQueueDispose(audio,true);}}
@end
static id<MTLRenderPipelineState>makePipe(id<MTLLibrary>lib){MTLRenderPipelineDescriptor*d=[MTLRenderPipelineDescriptor new];d.vertexFunction=[lib newFunctionWithName:@"vert"];d.fragmentFunction=[lib newFunctionWithName:@"frag"];d.colorAttachments[0].pixelFormat=MTLPixelFormatBGRA8Unorm;NSError*e=nil;id<MTLRenderPipelineState>p=[gpu newRenderPipelineStateWithDescriptor:d error:&e];if(!p)fprintf(stderr,"Pipeline: %s\n",e.localizedDescription.UTF8String);return p;}
int main(int argc,char**argv){@autoreleasepool{
 gpu=MTLCreateSystemDefaultDevice();if(!gpu){fprintf(stderr,"Metal device unavailable\n");return 1;}NSError*err=nil;id<MTLLibrary>lib=[gpu newLibraryWithSource:@SHADER options:nil error:&err];if(!lib){fprintf(stderr,"Metal shader compile failed: %s\n",err.localizedDescription.UTF8String);return 2;}renderPipe=makePipe(lib);if(!renderPipe)return 3;queue=[gpu newCommandQueue];
 if(argc==4&&!strcmp(argv[1],"--capture")){MTLTextureDescriptor*td=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:1280 height:720 mipmapped:NO];td.usage=MTLTextureUsageRenderTarget;td.storageMode=MTLStorageModeShared;id<MTLTexture>tex=[gpu newTextureWithDescriptor:td];render(tex,atof(argv[2]),nil);unsigned char*pixels=malloc(1280*720*4);[tex getBytes:pixels bytesPerRow:5120 fromRegion:MTLRegionMake2D(0,0,1280,720)mipmapLevel:0];NSBitmapImageRep*rep=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:NULL pixelsWide:1280 pixelsHigh:720 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:5120 bitsPerPixel:32];unsigned char*dst=rep.bitmapData;for(int i=0;i<1280*720;i++){dst[i*4]=pixels[i*4+2];dst[i*4+1]=pixels[i*4+1];dst[i*4+2]=pixels[i*4];dst[i*4+3]=255;}[[rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}]writeToFile:@(argv[3]) atomically:YES];free(pixels);return 0;}
 [NSApplication sharedApplication];[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];Demo*d=[Demo new];NSApp.delegate=d;[NSApp run];
}return 0;}
