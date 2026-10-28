#include <metal_stdlib>
using namespace metal;
struct V{float4 p [[position]];};
vertex V vert(uint i [[vertex_id]]){float2 p=float2((i<<1)&2,i&2);return {float4(p*2-1,0,1)};}
float2 rot(float2 p,float a){return float2(cos(a)*p.x-sin(a)*p.y,sin(a)*p.x+cos(a)*p.y);}
float3 pal(float x){return .5+.5*cos(6.283185*(x+float3(0.,.33,.67)));}
float ln(float d,float w){return w/(abs(d)+w);}
fragment float4 frag(V v [[stage_in]],constant float3 &u [[buffer(0)]]){
 float t=u.z;float2 uv=(v.p.xy*2-u.xy)/u.y;float r=length(uv),a=atan2(uv.y,uv.x);float scene=floor(t/32.),lt=fmod(t,32.);float3 c=0.;
 if(scene<1.){
  float2 p=rot(uv,lt*.045);
  for(int i=0;i<12;i++){float f=float(i),phase=f*.53+lt*(.13+.004*f);float2 ctr=float2(.55*sin(phase),.42*cos(phase*1.27));float2 q=p-ctr;float wave=q.y-.11*sin(q.x*4.+lt*.34+f);float d=abs(wave);float strand=ln(d,.006+.002*sin(lt*.8+f));float glow=exp(-d*18.)*exp(-length(q)*.55);c+=pal(f*.075+lt*.012)*(strand*.016+glow*.045);}
  float curl=abs(sin(a*5.+r*8.-lt*.28));c+=pal(r*.12+lt*.015)*smoothstep(.88,.99,curl)*exp(-r*.65)*.08;
 }else if(scene<2.){
  for(int i=0;i<18;i++){float f=float(i),ph=f*2.399+lt*(.17+.006*f);float2 ctr=float2(.95*sin(ph),.65*cos(ph*1.19));float2 q=rot(uv-ctr,ph+lt*.12);float2 shape=float2(.045+.018*sin(lt*.5+f),.026+.018*cos(lt*.37+f));float d=abs(max(abs(q.x)-shape.x,abs(q.y)-shape.y));float edge=ln(d,.003);float facet=step(abs(q.x+q.y*.6),.002)*step(abs(q.x),shape.x)*step(abs(q.y),shape.y);c+=pal(f*.065+lt*.02)*(edge*.04+facet*.018);c+=pal(f*.065+lt*.02)*exp(-length(q)*18.)*.006;}
  float orbit=abs(length(uv-float2(.12*sin(lt*.12),0))-(.35+.05*sin(a*4.+lt*.2)));c+=pal(a*.1+lt*.02)*ln(orbit,.004)*.025;
 }else{
  float2 p=rot(uv,lt*.035);float warp=.11*sin(p.y*4.+lt*.2)+.07*sin(p.x*6.-lt*.31);p+=warp;
  float field=sin(p.x*4.+sin(p.y*3.+lt*.18))*cos(p.y*5.-lt*.22);
  float contours=abs(fract((field+1.)*7.)-.5);float ridge=ln(contours,.055)*.045;
  float bands=abs(sin((p.x+p.y*.6)*6.+lt*.17+2.*sin(p.y*2.)));float filament=smoothstep(.93,.995,bands)*.22;
  c+=pal(field*.09+lt*.016)*(ridge+filament);
  for(int i=0;i<16;i++){float f=float(i),phase=f*2.399+lt*(.09+.004*f);float2 q=p-float2(.72*sin(phase),.5*cos(phase*1.31));float d=length(q);c+=pal(f*.08+lt*.014)*.004/(d+.006);}
 }
 c*=1.-.18*smoothstep(.25,1.7,r);c=1.-exp(-max(c,0.)*1.8);c=pow(c,float3(.82));float fade=smoothstep(0.,2.,t)*(1.-smoothstep(94.,96.,t));c*=fade;
 return float4(c,1.);
}
