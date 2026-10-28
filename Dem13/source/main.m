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
static const double duration=64.;
typedef struct{float w,h,t,pad;}U;
static double bell(double t,double at,double width){double x=(t-at)/width;return exp(-x*x);}
static void sound(void*ctx,AudioQueueRef q,AudioQueueBufferRef b){
 float*o=b->mAudioData;
 for(int i=0;i<4096;i++,sampleIndex++){
  double t=sampleIndex/44100.,fade=fmin(1.,t/3.)*fmax(0.,fmin(1.,(duration-t)/6.));
  double air=sin(6.2831853*174.*t+.32*sin(t*.08))*.005+sin(6.2831853*261.63*t+.21*sin(t*.06+1.))*.0035;
  double drone=sin(6.2831853*55.*t+.24*sin(t*.075))*.025+sin(6.2831853*82.4069*t+.17*sin(t*.061+1.))*.018+sin(6.2831853*110.*t+.19*sin(t*.052+2.))*.011;
  double heart=0.;double beats[]={7.2,9.9,13.8,16.3,19.7,22.1,25.6,28.1,31.5,34.0,37.4,39.7,43.2,46.4,49.4,52.1};
  for(int k=0;k<16;k++){double env=bell(t,beats[k],.34);heart+=env*sin(6.2831853*(196.+(k%4)*49.)*t)*.005;}
  double steps=0.;double stepTimes[]={15.,17.8,20.6,23.4,26.2,29.};
  for(int k=0;k<6;k++)steps+=bell(t,stepTimes[k],.22)*sin(6.2831853*(392.+(k%3)*65.)*t)*.003;
  double crescendo=.45+.24*sin(t*.1)+.14*sin(t*.057+1.)+.24*bell(t,50.,5.);
  double s=(air+drone*crescendo+heart+steps)*fade;o[2*i]=s;o[2*i+1]=s*.94;
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
 NSSize s=self.window.contentView.bounds.size;CGFloat scale=self.window.backingScaleFactor;layer.frame=self.window.contentView.bounds;float f=fmin(1.,900./(s.width*scale));layer.drawableSize=CGSizeMake(s.width*scale*f,s.height*scale*f);id<CAMetalDrawable>d=[layer nextDrawable];if(d)render(d.texture,t,d);
}
-(void)applicationDidFinishLaunching:(NSNotification*)n{
 self.window=[[NSWindow alloc]initWithContentRect:NSMakeRect(0,0,1152,648)styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];self.window.title=@"Dem13 / 64K — F fullscreen · Esc quit";
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
