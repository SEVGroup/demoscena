#include <metal_stdlib>
using namespace metal;
struct V{float4 p [[position]];};
vertex V vert(uint i [[vertex_id]]){float2 p=float2((i<<1)&2,i&2);return {float4(p*2-1,0,1)};}
float2 rot(float2 p,float a){return float2(cos(a)*p.x-sin(a)*p.y,sin(a)*p.x+cos(a)*p.y);}
float3 gray(float x){return float3(x);}
float line(float d,float w){return w/(abs(d)+w);}
fragment float4 frag(V v [[stage_in]],constant float3 &u [[buffer(0)]]){
 float t=u.z;float2 uv=(v.p.xy*2-u.xy)/u.y;float r=length(uv);float scene=floor(t/32.);float lt=fmod(t,32.);float3 c=0.;
 if(scene<1.){
  // A flock of migrating rings crosses the frame on independent looping paths.
  for(int i=0;i<17;i++){
   float f=float(i),phase=f*.71;
   float2 center=float2(.72*sin(lt*(.17+.009*f)+phase),.43*sin(lt*(.23+.006*f)+phase*1.7));
   float size=.028+.013*(.5+.5*sin(lt*.8+f));
   float2 q=uv-center;
   float orbit=abs(length(q)-size*(1.+.22*sin(lt*.9+f)));
   float ring=line(orbit,.0025);
   float spoke=abs(q.y-.3*sin(q.x*18.+lt*1.4+f)*size);
   c+=gray(ring*.22+line(spoke,.0012)*.07);
   c+=gray(exp(-length(q)*30.)*.018);
  }
  float sweep=abs(uv.y-.24*sin(uv.x*3.-lt*.5)-.08*sin(lt*.2));
  c+=gray(line(sweep,.003)*.13);
 }else if(scene<2.){
  // Fast paper-like solids travel diagonally, rotate, then leave the frame.
  for(int i=0;i<13;i++){
   float f=float(i),phase=f*.83;
   float2 center=float2(fract(.5+f*.137+lt*(.026+.001*f))-.5,fract(.5+f*.271-lt*(.021+.0007*f))-.5)*float2(2.5,1.65);
   center+=float2(.12*sin(lt*.42+phase),.08*cos(lt*.31+phase));
   float2 q=rot(uv-center,lt*(.24+.022*f)+phase);
   float2 b=float2(.055+.018*sin(f*2.),.032+.013*cos(f*1.3));
   float d=abs(max(abs(q.x)-b.x,abs(q.y)-b.y));
   float edges=line(d,.0035);
   float diagonal=line(abs(q.x+q.y*.72),.0018)*step(abs(q.x),b.x)*step(abs(q.y),b.y);
   c+=gray(edges*.28+diagonal*.12);
   float glint=exp(-length(q-float2(b.x,b.y))*45.);
   c+=gray(glint*.11);
  }
  float2 cursor=uv-float2(.68*sin(lt*.18),.45*cos(lt*.22));
  float cross=line(abs(cursor.x),.002)*step(abs(cursor.y),.32)+line(abs(cursor.y),.002)*step(abs(cursor.x),.32);
  c+=gray(cross*.14);
 }else{
  // Bright particles stream from a moving source and arc to an opposite sink.
  float2 source=float2(.65*sin(lt*.2),.42*cos(lt*.16));
  float2 sink=-source*.72+float2(.08*sin(lt*.37),.05*cos(lt*.31));
  for(int i=0;i<64;i++){
   float f=float(i),phase=f*2.399;
   float age=fract(f*.137+lt*(.055+.001*(i%9)));
   float2 a=source*(1.-age)+sink*age;
   a+=float2(.18*sin(phase+age*6.+lt*.3),.15*cos(phase*1.3+age*5.-lt*.22))*sin(age*3.14159);
   float radius=.0025+.002*(.5+.5*sin(f+lt*1.4));
   float d=length(uv-a);
   c+=gray(line(d,radius)*.18* (1.-age*.55));
   c+=gray(exp(-d*24.)*.025);
  }
  float2 flow=uv-source;float a=atan2(flow.y,flow.x);float swirl=abs(sin(a*7.+r*9.-lt*.46));
  c+=gray(smoothstep(.76,.97,swirl)*exp(-length(flow)*.8)*.11);
  c+=gray(line(length(uv-sink),.003)*.16);
 }
 float vignette=1.-.18*smoothstep(.2,1.5,r);c*=vignette;
 c=1.-exp(-max(c,0.)*2.1);c=smoothstep(.1,.67,c);
 float fade=smoothstep(0.,2.,t)*(1.-smoothstep(94.,96.,t));c*=fade;
 return float4(c,1.);
}
