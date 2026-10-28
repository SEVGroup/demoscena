#include <metal_stdlib>
using namespace metal;
struct V{float4 p [[position]];};
vertex V vert(uint i [[vertex_id]]){float2 p=float2((i<<1)&2,i&2);return {float4(p*2-1,0,1)};}
float2 rot(float2 p,float a){return float2(cos(a)*p.x-sin(a)*p.y,sin(a)*p.x+cos(a)*p.y);}
float3 pal(float x){return .5+.5*cos(6.283185*(x+float3(0.,.33,.67)));}
float ln(float d,float w){return w/(abs(d)+w);}
fragment float4 frag(V v [[stage_in]],constant float3 &u [[buffer(0)]]){
 float t=u.z;float2 uv=(v.p.xy*2-u.xy)/u.y;float r=length(uv);float scene=floor(t/32.),lt=fmod(t,32.);float3 c=0.;
 if(scene<1.){for(int i=0;i<36;i++){float f=float(i),x=fract(f*.618)*2.4-1.2;float speed=.12+fract(f*.31)*.35;float y=fract(f*.137-lt*speed/3.)*2.2-1.1;float2 q=uv-float2(x+.04*sin(lt*.5+f),y);float tail=abs(q.x-.025*sin(q.y*4.+f));c+=pal(f*.1+lt*.012)*ln(tail,.0025)*.045*step(0.,q.y)*step(q.y,.35+fract(f*.37)*.4);c+=pal(f*.1)*exp(-length(q)*22.)*.02;}}else if(scene<2.){float2 p=uv;for(int i=0;i<15;i++){float f=float(i),x=fract(f*.414+lt*(.025+f*.0006))*2.8-1.4;float y=sin(x*2.+lt*.14+f)*.42;float2 q=rot(p-float2(x,y),lt*.22+f);float d=abs(max(abs(q.x)-.035,abs(q.y)-.09));c+=pal(f*.07+lt*.017)*ln(d,.003)*.05;}}else{float2 p=uv;float flow=sin(p.x*3.+lt*.12+sin(p.y*5.-lt*.16));float contour=ln(abs(fract((flow+p.y)*9.)-.5),.025);c+=pal(flow*.13+lt*.01)*contour*.13;for(int i=0;i<24;i++){float f=float(i),x=fract(f*.37+lt*.018)*2.6-1.3,y=sin(x*3.-lt*.15+f)*.5;float d=length(uv-float2(x,y));c+=pal(f*.08+lt*.01)*exp(-d*30.)*.06;}}
 c*=1.-.18*smoothstep(.25,1.7,r);c=1.-exp(-max(c,0.)*1.8);c=pow(c,float3(.82));float fade=smoothstep(0.,2.,t)*(1.-smoothstep(94.,96.,t));c*=fade;return float4(c,1.);}
