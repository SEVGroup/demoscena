#include <metal_stdlib>
using namespace metal;
struct V{float4 p [[position]];};
vertex V vert(uint i [[vertex_id]]){float2 p=float2((i<<1)&2,i&2);return {float4(p*2-1,0,1)};}
float2 rot(float2 p,float a){return float2(cos(a)*p.x-sin(a)*p.y,sin(a)*p.x+cos(a)*p.y);}
float3 ink(float x){return float3(x);}
float3 pal(float x){return ink(.5+.5*cos(6.28318*x));}
float box(float2 p,float2 b){float2 d=abs(p)-b;return length(max(d,0.))+min(max(d.x,d.y),0.);}
fragment float4 frag(V v [[stage_in]],constant float3 &u [[buffer(0)]]){
 float t=u.z;float2 uv=(v.p.xy*2-u.xy)/u.y;float r=length(uv),a=atan2(uv.y,uv.x);float3 c=0;float s=floor(t/32.),lt=fmod(t,32.);
 if(s<1.){
  float slit=abs(uv.x-.34*sin(lt*.12+uv.y*1.8)-.12*sin(lt*.31));
  float aperture=exp(-slit*(13.+8.*(.5+.5*sin(lt*.3))))*(1.-smoothstep(.12,1.25,abs(uv.y)));
  float blade=box(rot(uv,lt*.025)-float2(.18*sin(lt*.09),0),float2(.012,.72));
  float cut=exp(-abs(blade)*95.);
  float ripple=abs(r-.22-.035*sin(a*7.-lt*.24));
  float rings=exp(-ripple*65.)*smoothstep(0.,.8,lt);
  float flash=exp(-r*7.)*exp(-pow((lt-15.)/1.6,2.));
  c+=ink(aperture*.8+cut*.55+rings*.25+flash);
 }else if(s<2.){
  float2 p=rot(uv,lt*.04);p.x+=.12*sin(p.y*2.+lt*.11);
  float fold=sin(p.x*7.+p.y*2.-lt*.16);
  float seam=abs(fract((p.x*3.+fold*.22)*.5)-.5);
  float planes=step(.5,fold)*.13;
  float creases=exp(-seam*190.)*(.5+.5*sin(p.y*3.+lt*.17));
  float2 q=rot(p,lt*.07);float frame=abs(box(q,float2(.68,.42)));
  float frameLine=exp(-frame*90.);
  float inner=exp(-abs(box(q,float2(.43,.24)))*110.);
  float shadow=exp(-abs(box(q-float2(.075,-.075),float2(.68,.42)))*24.)*.22;
  float orbit=exp(-abs(length(q)-(.84+.06*sin(atan2(q.y,q.x)*5.+lt*.13)))*75.);
  c+=ink(planes+creases*.48+frameLine*.8+inner*.65+shadow+orbit*.35);
 }else{
  float2 p=uv;float twist=lt*.045+1.4/(r+.22);p=rot(p,twist);
  float spiral=abs(sin(8.*log(r+.08)-a*3.-lt*.14));
  float bands=smoothstep(.72,.9,spiral)*exp(-r*.32);
  float horizon=exp(-abs(p.y-.15*sin(p.x*2.+lt*.12))*100.);
  float voidCore=smoothstep(.2,.06,r);
  float shard=0.;
  for(int i=0;i<28;i++){float f=float(i);float ang=f*2.399+lt*(.08+.003*f);float rr=.2+fract(f*.618+lt*.018)*1.1;float2 z=p-float2(cos(ang),sin(ang))*rr;float d=abs(z.x+z.y*.31*sin(f+lt*.1));shard+=.009/(d+.012)*exp(-length(z)*2.);}
  float noise=fract(sin(dot(floor(uv*220.),float2(12.9898,78.233)))*43758.5453);
  float stipple=step(.91,noise)*(.25+.75*bands)*exp(-r*.22);
  c+=ink(bands*.55+horizon*.45+shard*.24+stipple*.16);
  c*=1.-voidCore*.82;
 }
 float vignette=(1.-smoothstep(.25,1.65,r));c*=.72+.28*vignette;
 c=1.-exp(-max(c,0.)*2.4);c=smoothstep(.17,.72,c);
 float fade=smoothstep(0.,2.,t)*(1.-smoothstep(94.,96.,t));
 c*=fade;
 return float4(c,1);
}
