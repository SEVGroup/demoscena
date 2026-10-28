#include <metal_stdlib>
using namespace metal;
struct U{float w,h,t,pad;};struct V{float4 p [[position]];};
vertex V vert(uint id [[vertex_id]]){V o;o.p=float4(id==1?3.:-1.,id==2?3.:-1.,0,1);return o;}
float sdBox(float3 p,float3 b){float3 q=abs(p)-b;return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);}
float sdCyl(float3 p,float r,float h){float2 d=float2(length(p.xz)-r,abs(p.y)-h);return min(max(d.x,d.y),0.)+length(max(d,0.));}
float sdCap(float3 p,float3 a,float3 b,float r){float3 q=p-a,v=b-a;return length(q-v*clamp(dot(q,v)/max(dot(v,v),1e-5),0.,1.))-r;}
float smin(float a,float b,float k){float h=max(k-abs(a-b),0.)/k;return min(a,b)-h*h*k*.25;}
float modp(float x,float y){return x-y*floor(x/y);}
float hash3(float3 p){p=fract(p*.1031);p+=dot(p,p.yxz+33.33);return fract((p.x+p.y)*p.z);}
float2 op(float2 a,float d,float m,float k){return float2(smin(a.x,d,k),d<a.x?m:a.y);}
float halfEllipticArch(float2 p,float rx,float rise,float spring){float2 q=float2(p.x/rx,(p.y-spring)/rise);float d=(length(q)-1.)*rise;if(p.y<spring){d=length(float2(abs(p.x)-rx,p.y-spring));}return d;}

float2 firstHall(float3 p){
 float2 m=float2(1e4,1.);float rz=modp(p.z+4.,8.)-4.;
 // Paired round columns: one fluted shaft, two moulded rings, and a square abacus.
 for(int side=-1;side<=1;side+=2){
  float cx=p.x-float(side)*11.25;float rr=length(float2(cx,rz));float a=atan2(rz,cx);
  float radius=.57+.025*cos(a*12.);
  float shaft=max(rr-radius, max(.48-p.y,p.y-7.55));
  float base=sdCyl(float3(cx,p.y-.30,rz),.91,.29);
  float baseMould=sdCyl(float3(cx,p.y-.64,rz),.72,.07);
  float ring=sdCyl(float3(cx,p.y-7.66,rz),.78,.16);
  float capital=sdBox(float3(cx,p.y-8.0,rz),float3(.87,.27,.78));
  float capTop=sdBox(float3(cx,p.y-8.30,rz),float3(.94,.08,.84));
  float d=smin(shaft,base,.11);d=smin(d,baseMould,.09);d=smin(d,ring,.10);d=smin(d,capital,.11);d=smin(d,capTop,.08);
  m=op(m,d,1.,.035);
 }
 // Deep side walls with shallow pilasters and recessed bays.
 float wall=min(sdBox(float3(p.x-13.55,p.y-4.85,p.z+16.),float3(.45,4.85,24.)),sdBox(float3(p.x+13.55,p.y-4.85,p.z+16.),float3(.45,4.85,24.)));
 float bayZ=modp(p.z+2.,16.)-8.;float pilaster=sdBox(float3(abs(p.x)-13.05,p.y-4.8,bayZ),float3(.42,4.8,.66));
 wall=smin(wall,pilaster,.08);m=op(m,wall,1.,.04);
 // Barrel vault ribs, repeated along the hall and sprung from the side supports.
 float ad=halfEllipticArch(float2(p.x,p.y),12.7,3.15,7.25);
 float rib=max(ad,abs(rz)-.27);m=op(m,rib,1.,.08);
 float ceiling=sdBox(float3(p.x,p.y-10.35,p.z+20.),float3(13.7,.20,20.));
 m=op(m,ceiling,1.,.05);
 // Narrow upper light wells, physically set into the vault.
 float wx=modp(p.x+12.,6.)-3.;float wz=modp(p.z+4.,8.)-4.;
 float well=max(abs(wx)-.68,max(abs(wz)-.72,abs(p.y-10.0)-.08));
 m=op(m,well,4.,.02);
 return m;
}

float2 secondHall(float3 p){
 float2 m=float2(1e4,3.);float rz=modp(p.z+44.5,9.)-4.5;
 float shiftL=.72*sin((p.z+42.)*.115),shiftR=.52*cos((p.z+45.)*.09);
 // Asymmetric rectangular piers, with broad feet and bearing stones.
 float left=sdBox(float3(p.x-(-8.7+shiftL),p.y-5.25,rz),float3(.72,5.25,.64));
 left=smin(left,sdBox(float3(p.x-(-8.7+shiftL),p.y-.36,rz),float3(1.08,.36,.88)),.1);
 left=smin(left,sdBox(float3(p.x-(-8.7+shiftL),p.y-10.55,rz),float3(1.0,.48,.84)),.1);
 float right=sdBox(float3(p.x-(8.3+shiftR),p.y-5.35,rz),float3(.63,5.35,.60));
 right=smin(right,sdBox(float3(p.x-(8.3+shiftR),p.y-.37,rz),float3(.95,.37,.84)),.1);
 right=smin(right,sdBox(float3(p.x-(8.3+shiftR),p.y-10.7,rz),float3(.94,.40,.8)),.1);
 float piers=smin(left,right,.08);
 // Diagonal load-bearing ribs cross above the nave and meet the piers.
 float crossA=sdCap(p,float3(-8.1,5.8,rz),float3(7.6,8.8,rz),.27);
 float crossB=sdCap(p,float3(-8.1,8.8,rz),float3(7.6,5.8,rz),.27);
 piers=smin(piers,crossA,.12);piers=smin(piers,crossB,.12);m=op(m,piers,3.,.045);
 // Offset side walls and unequal, high vaults make the second chamber distinct.
 float wall=min(sdBox(float3(p.x-10.8,p.y-6.05,p.z+62.),float3(.55,6.05,23.)),sdBox(float3(p.x+10.8,p.y-6.05,p.z+62.),float3(.55,6.05,23.)));
 float bay=modp(p.z+46.,18.)-9.;wall=smin(wall,sdBox(float3(abs(p.x)-10.2,p.y-5.7,bay),float3(.64,5.7,.72)),.09);
 m=op(m,wall,3.,.04);
 float vault=halfEllipticArch(float2(p.x-.7*sin((p.z+40.)*.06),p.y),10.0,4.0,8.2);
 float rib=max(vault,abs(rz)-.22);m=op(m,rib,3.,.08);
 m=op(m,sdBox(float3(p.x,p.y-12.35,p.z+62.),float3(10.6,.22,22.)),3.,.05);
 // One roof-hung stone canopy, supported by two deep ribs.
 float canopyZ=p.z+72.;float canopy=sdBox(float3(p.x-.8,p.y-9.9,canopyZ),float3(4.8,.32,2.4));
 canopy=smin(canopy,sdBox(float3(p.x+3.6,p.y-11.05,canopyZ),float3(.32,1.15,.34)),.08);
 canopy=smin(canopy,sdBox(float3(p.x-5.2,p.y-11.05,canopyZ),float3(.32,1.15,.34)),.08);
 m=op(m,canopy,3.,.04);
 // Narrow light slits cut into the side walls.
 float slit=sdBox(float3(abs(p.x)-10.2,p.y-8.3,modp(p.z+51.,13.)-6.5),float3(.07,2.0,.22));
 m=op(m,slit,4.,.015);
 return m;
}

float2 mapScene(float3 p){
 float2 m=float2(1e4,0.);
 // A single thick stone platform flows continuously through both rooms.
 m=op(m,sdBox(float3(p.x,p.y+.28,p.z+35.),float3(15.,.28,75.)),0.,.025);
 float d1=firstHall(p).x;float gate1=max(-40.2-p.z,p.z-7.);d1=max(d1,gate1);m=op(m,d1,1.,.05);
 // A solid gold portal: inner and outer faces, return depth, and attached piers.
 float z=p.z+40.5,arc=halfEllipticArch(float2(p.x,p.y),5.65,4.65,2.45);
 float outer=max(abs(arc)-.36,abs(z)-.34);
 float innerEdge=max(abs(arc+.36)-.035,abs(z)-.30);
 float gold=smin(outer,innerEdge,.04);
 gold=smin(gold,sdBox(float3(p.x-5.65,p.y-1.2,z),float3(.39,1.2,.34)),.12);
 gold=smin(gold,sdBox(float3(p.x+5.65,p.y-1.2,z),float3(.39,1.2,.34)),.12);
 m=op(m,gold,2.,.025);
 float d2=secondHall(p).x;float gate2=max(-86.-p.z,p.z+40.4);d2=max(d2,gate2);m=op(m,d2,3.,.05);
 return m;
}

float3 normalAt(float3 p){float e=.003;float2 k=float2(1.,-1.);return normalize(k.xyy*mapScene(p+k.xyy*e).x+k.yyx*mapScene(p+k.yyx*e).x+k.yxy*mapScene(p+k.yxy*e).x+k.xxx*mapScene(p+k.xxx*e).x);}
float boxTile(float2 p,float2 b){float2 q=abs(p)-b;return length(max(q,0.))+min(max(q.x,q.y),0.);}

fragment float4 frag(V in [[stage_in]],constant U&u [[buffer(0)]]){
 float t=u.t;
 // 57-second eased path: inspect the first nave, pass the portal, then enter the altered hall.
 float z;
 if(t<23.)z=mix(4.,-30.,smoothstep(0.,23.,t));
 else if(t<31.5)z=mix(-30.,-40.7,smoothstep(23.,31.5,t));
 else z=mix(-40.7,-77.,smoothstep(31.5,55.,t));
 float glanceL=exp(-pow((t-6.)/2.1,2.)),glanceR=exp(-pow((t-13.)/2.2,2.));
 float lookUp=exp(-pow((t-9.)/2.1,2.)),lookDown=exp(-pow((t-17.)/2.5,2.)),lookSecond=exp(-pow((t-43.5)/3.2,2.));
 float yaw=.16*sin(t*.19)*(glanceL+glanceR)-.12*glanceR;
 float pitch=.11*lookUp-.075*lookDown+.46*lookSecond+.035*sin(t*.12);
 float step=.024*sin(t*6.1)*smoothstep(1.,4.,t)*(1.-smoothstep(52.,57.,t));
 float3 ro=float3(.12*sin(t*.14),1.66+step,z);
 float3 fw=normalize(float3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch)));
 float3 right=normalize(cross(fw,float3(0,1,0))),up=normalize(cross(right,fw));
 float2 uv=float2((in.p.x*2.-u.w)/u.h,(u.h-in.p.y*2.)/u.h);float aspect=u.w/u.h;
 float3 rd=normalize(fw+(uv.x*aspect*right+uv.y*up)*.48);
 float3 col=float3(.006,.008,.011);float travel=0.;float2 hit=float2(0.);
 for(int i=0;i<92;i++){float3 p=ro+rd*travel;hit=mapScene(p);if(hit.x<.002||travel>95.)break;travel+=max(hit.x*.78,.012);}
 if(travel<95.){
  float3 p=ro+rd*travel,n=normalAt(p);float second=smoothstep(29.,37.,t);
  float3 ld1=normalize(float3(-.35,.89,-.27)),ld2=normalize(float3(.83,.46,-.31));float3 light=normalize(mix(ld1,ld2,second));
  float diff=max(dot(n,light),0.);float rim=pow(1.-max(dot(n,-rd),0.),3.);float3 base;
  if(hit.y<.5){
   float2 g=p.xz*.42;float2 f=abs(fract(g)-.5);float seam=1.-smoothstep(.009,.028,min(f.x,f.y));
   float tile=hash3(float3(floor(g.x),0.,floor(g.y)));
   base=mix(float3(.31,.29,.25),float3(.25,.24,.22),seam*.72);base*=.94+.10*tile;
   float goldGlow=exp(-abs(p.z+40.5)*.48)*exp(-abs(p.x)*.06);base+=float3(.15,.078,.018)*goldGlow;
  }else if(hit.y<1.5){float stone=.5+.5*sin(p.y*1.6+p.z*.19);base=float3(.40,.37,.32)*(.96+.06*stone);}
  else if(hit.y<2.5){float rough=.5+.5*sin(p.x*2.3+p.y*.7);base=float3(.63,.36,.095)*(.95+.08*rough);}
  else if(hit.y<3.5){float rough=.5+.5*cos(p.x*.45+p.z*.14);base=float3(.43,.45,.43)*(.95+.07*rough);}
  else base=float3(.78,.68,.42);
  float shade=.34+.86*diff+rim*.18;
  if(hit.y>3.5)shade=1.0;
  col=base*shade;
  if(hit.y>1.5&&hit.y<2.5)col+=float3(.22,.105,.022)*(1.-smoothstep(.02,.30,abs(hit.x)));
  if(hit.y>3.5)col+=float3(.32,.24,.10);
  float fog=1.-exp(-travel*.012);col=mix(col,float3(.012,.016,.021),fog*.52);
 }
 // Restrained upper-window shafts, fading into side slits in the second nave.
 float2 v=uv;float beams=(exp(-pow((v.x-.26)/.075,2.))+exp(-pow((v.x+.31)/.09,2.)))*(.045+.025*sin(t*.08));
 float second=smoothstep(29.,37.,t);float3 shaft=mix(float3(.50,.40,.23),float3(.28,.39,.48),second);
 col+=shaft*beams*(1.-abs(v.y)*.42);
 float vignette=smoothstep(1.55,.35,length(uv*float2(.72,1.)));
 col*=.78+.22*vignette;
 return float4(col,1.);
}
