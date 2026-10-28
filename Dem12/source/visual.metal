#include <metal_stdlib>
using namespace metal;
struct U { float w,h,t,pad; };
struct V { float4 p [[position]]; };
vertex V vert(uint id [[vertex_id]]) { V o; o.p=float4((id==1?3.:-1.),(id==2?3.:-1.),0,1); return o; }
float seg(float2 p,float2 a,float2 b){float2 v=b-a;return length(p-(a+v*clamp(dot(p-a,v)/max(dot(v,v),1e-5),0.,1.)));}
float tri(float2 p,float2 a,float2 b,float2 c){return min(seg(p,a,b),min(seg(p,b,c),seg(p,c,a)));}
float hash(float2 p){return fract(sin(dot(p,float2(127.1,311.7)))*43758.5453);}
float3 palette(float x){return .5+.5*cos(6.28318*(x+float3(.05,.34,.68)));}
float line(float d,float width){return 1.-smoothstep(width,width+fwidth(d)*1.5,d);}
fragment float4 frag(V in [[stage_in]], constant U&u [[buffer(0)]]) {
 float t=u.t; float2 p=(in.p.xy*2.-float2(u.w,u.h))/u.h; float r=length(p);
 float3 col=float3(0.); float fade=smoothstep(0.,.8,t)*(1.-smoothstep(50.5,54.,t));
 float warm=smoothstep(19.,34.,t); float3 cold=float3(.12,.48,.85),amber=float3(1.,.55,.19);
 float3 ink=mix(cold,amber,warm);
 // The first triangle is the only landmark in the opening void.
 float emerge=smoothstep(.8,3.2,t); float triSize=mix(.025,1.08,smoothstep(.6,6.,t));
 float2 a=float2(0.,-triSize*.78), b=float2(-triSize*.68,triSize*.48), c=float2(triSize*.68,triSize*.48);
 float pulse=.5+.5*sin(t*1.1); float td=tri(p,a,b,c);
 float triVis=(1.-smoothstep(6.8,8.8,t))+.42*smoothstep(40.,42.,t)*(1.-smoothstep(48.,50.8,t));
 col+=ink*(line(td,.005+.001*pulse)*(.2+.8*emerge)*triVis);
 col+=float3(.26,.65,1.)*exp(-td*38.)*.12*emerge*triVis;
 // A tiny, faceted human silhouette, animated from a raised hand into a walk.
 float walk=smoothstep(13.,17.,t); float stride=sin(t*3.5)*.045*walk;
 float2 h=float2(p.x,-p.y)-float2(.0,-.12+walk*.12); float body=0.;
 body=max(body,line(length(h-float2(0.,.30))-.045,.003));
 body=max(body,line(seg(h,float2(0.,.25),float2(0.,.02))-.018,.003));
 float touch=smoothstep(5.6,7.8,t)*(1.-smoothstep(9.,11.,t));
 float armX=mix(.12,.02,touch); float armY=mix(.18,.36,touch);
 body=max(body,line(seg(h,float2(0.,.22),float2(armX,armY))-.012,.0025));
 body=max(body,line(seg(h,float2(0.,.22),float2(-.07,.10))-.012,.0025));
 body=max(body,line(seg(h,float2(0.,.02),float2(-.06+stride,-.16))-.014,.0025));
 body=max(body,line(seg(h,float2(0.,.02),float2(.06-stride,-.16))-.014,.0025));
 col+=float3(.72,.88,1.)*body*(.72+.28*sin(t*2.));
 // Infinite triangular mesh, displaced outward from the point of contact.
 float2 g=p; float touchWave=sin(length(g-float2(.12,-.30))*18.-(t-6.)*3.2);
 float touchEnv=exp(-max(0.,t-6.)*.16)*smoothstep(5.7,6.5,t);
 g.y+=.035*touchEnv*touchWave;
 float depth=smoothstep(1.05,-.35,p.y); float2 grid=g*float2(15.,20.+depth*18.);
 float2 cell=fract(grid)-.5; float2 base=floor(grid); float edge=min(seg(cell,float2(-.5,-.5),float2(.5,-.5)),min(seg(cell,float2(.5,-.5),float2(0.,.5)),seg(cell,float2(0.,.5),float2(-.5,-.5))));
 float gridOn=smoothstep(-.1,.42,p.y)*(1.-smoothstep(.35,1.1,p.y));
 float glint=pow(max(0.,sin((base.x+base.y)*.55-t*2.4)),10.)*.55;
 col+=mix(cold,amber,warm)*line(edge,.006)*gridOn*(.055+.12*glint+.23*touchEnv*max(0.,touchWave));
 // Travelling ribbons: ground wave, rising curtain, and a loop around the walker.
 float move=max(0.,t-13.); float env=smoothstep(12.,16.,t)*(1.-smoothstep(38.,41.,t));
 for(int k=0;k<3;k++){
   float phase=t*(1.05+.16*k)-p.x*(2.3+.45*k)+sin(p.x*2.+k)*.5;
   float y0=-.48+.47*sin(phase+k*2.1)+.13*sin(phase*.47+p.x*3.);
   if(k==1)y0=.05+.52*sin(phase*.72+p.x*1.1);
   if(k==2)y0=-.12+.38*cos(phase*.78+p.x*1.7);
   float d=abs(p.y-y0); float ribbon=line(d,.009+.009*env)*(1.-smoothstep(1.2,2.2,abs(p.x)));
   float shimmer=.5+.5*sin(phase*2.4+k);
   col+=mix(cold,amber,warm)*ribbon*env*(.18+.55*shimmer);
 }
 // Distant aperture assembled from luminous triangular rings.
 float converge=smoothstep(28.,33.,t)*(1.-smoothstep(39.5,42.,t));
 float2 z=p-float2(.0,.22); float rr=length(z); float ang=atan2(z.y,z.x);
 float rot=t*(.12+smoothstep(29.,35.,t)*.8); float pulsePortal=.5+.5*sin(t*2.3);
 float ring=abs(fract((rr*(5.5+converge*3.)+ang*.045-rot)*1.25)-.5);
 float spokes=abs(sin(ang*9.+rot+rr*4.));
 float portal=(line(ring,.07)+line(spokes,.035)*.42)*converge*exp(-rr*.65);
 col+=mix(cold,amber,warm)*portal*(.1+.55*pulsePortal);
 for(int k=0;k<6;k++){
   float s=.12+float(k)*.145+.012*sin(t*2.1+float(k));
   float cs=cos(rot*.35),sn=sin(rot*.35);
   float2 v0=float2(0.,-s),v1=float2(-.866*s,.5*s),v2=float2(.866*s,.5*s);
   v0=float2(v0.x*cs-v0.y*sn,v0.x*sn+v0.y*cs);
   v1=float2(v1.x*cs-v1.y*sn,v1.x*sn+v1.y*cs);
   v2=float2(v2.x*cs-v2.y*sn,v2.x*sn+v2.y*cs);
   float tdPortal=tri(z,v0,v1,v2);
   col+=mix(cold,amber,warm)*line(tdPortal,.0045)*converge*(.18+.5*pulsePortal);
 }
 col+=mix(float3(.14,.4,.68),float3(1.,.58,.24),warm)*exp(-rr*3.)*converge*.13;
 // A soft converging flare, followed by a broad wave that erases the geometry.
 float climax=smoothstep(37.8,39.1,t)*(1.-smoothstep(39.2,40.3,t));
 col+=float3(.48,.72,1.)*exp(-r*7.)*climax*.9;
 float calm=smoothstep(40.,43.,t); float surface=abs(p.y-(.04*sin(p.x*2.3-t*.85)));
 col=mix(col,ink*line(surface,.009)*(.13+.18*exp(-abs(p.x)*.4)),calm*.7);
 col*=fade; col+=float3(.32,.58,.85)*exp(-r*9.)*smoothstep(48.5,50.5,t)*.15;
 return float4(col,1.);
}
