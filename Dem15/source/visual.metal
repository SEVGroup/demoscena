#include <metal_stdlib>
using namespace metal;
struct U{float w,h,t,pad;};struct V{float4 p [[position]];};
vertex V vert(uint id [[vertex_id]]){V o;o.p=float4(id==1?3.:-1.,id==2?3.:-1.,0,1);return o;}
float sdBox(float3 p,float3 b){float3 q=abs(p)-b;return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);}
float sdEll(float3 p,float3 r){float k0=length(p/r),k1=length(p/(r*r));return k0*(k0-1.)/max(k1,1e-5);}
float sdCap(float3 p,float3 a,float3 b,float r){float3 q=p-a,v=b-a;return length(q-v*clamp(dot(q,v)/max(dot(v,v),1e-5),0.,1.))-r;}
float sdTorus(float3 p,float2 r){return length(float2(length(p.xz)-r.x,p.y))-r.y;}
float sdOct(float3 p,float s){p=abs(p);float m=p.x+p.y+p.z-s;float3 q;if(3.*p.x<m)q=p.xyz;else if(3.*p.y<m)q=p.yzx;else if(3.*p.z<m)q=p.zxy;else return m*.5773503;float k=clamp(.5*(q.z-q.y+s),0.,s);return length(float3(q.x,q.y-s+k,q.z-k));}
float smin(float a,float b,float k){float h=max(k-abs(a-b),0.)/k;return min(a,b)-h*h*k*.25;}
float hash3(float3 p){p=fract(p*.1031);p+=dot(p,p.yxz+33.33);return fract((p.x+p.y)*p.z);}
float modp(float x,float y){return x-y*floor(x/y);}
float2 op(float2 a,float d,float id,float k){return float2(smin(a.x,d,k),d<a.x?id:a.y);}

float landHeight(float2 xz,float t){
 float n=.10*sin(xz.x*1.2+xz.y*.42)+.065*cos(xz.y*1.1-xz.x*.7);
 float ridge=.28*exp(-pow((xz.x-.9*sin(xz.y*.25))/.85,2.));
 float impact=0.;for(int i=0;i<3;i++){float2 c=float2((float(i)-1.)*1.25,-4.-float(i)*1.5);float r=length(xz-c);float pulse=exp(-pow((t-(18.+float(i)*1.8))/.95,2.));impact+=.15*sin(r*7.-(t-18.-float(i)*1.8)*4.)*exp(-r*1.2)*pulse;}
 return n+ridge+impact;
}
float dinosaur(float3 q,float t){
 float walk=sin(t*3.6);float bob=.035*sin(t*7.2);float d=sdEll(q-float3(0,1.04+bob,0),float3(.72,.43,.34));
 d=smin(d,sdEll(q-float3(-.42,1.15+bob,.0),float3(.34,.43,.31)),.18);
 float3 head=q-float3(.48,1.51+bob,.0);d=smin(d,sdEll(head,float3(.31,.27,.27)),.12);
 d=smin(d,sdEll(q-float3(.69,1.43+bob,.0),float3(.25,.15,.22)),.1);
 // A low, heavy tail and four articulated legs form a readable quadruped.
 d=smin(d,sdCap(q,float3(-.45,1.0+bob,0),float3(-1.18,.63+bob,0),.15),.08);
 for(int i=0;i<4;i++){float x=i<2?-.43:.40;float z=(i%2==0)?.23:-.23;float ph=t*3.6+(i<2?0.:2.4)+(z>0.?0.:3.14);float sw=.12*sin(ph);float3 hip=float3(x, .83+bob,z),knee=float3(x+sw*.45,.46+bob+max(0.,cos(ph))*.04,z),foot=float3(x+sw,.08+bob,z+.04);d=smin(d,sdCap(q,hip,knee,.145),.09);d=smin(d,sdCap(q,knee,foot,.105),.075);}
 float crest=smin(sdEll(q-float3(.10,1.49+bob,.18),float3(.19,.12,.12)),sdEll(q-float3(-.18,1.47+bob,.18),float3(.15,.10,.11)),.06);d=smin(d,crest,.05);
 return d;
}
float person(float3 q,float t){
 float walk=smoothstep(42.,48.,t);float stride=walk*sin(t*3.5)*.11;
 float d=sdEll(q-float3(0,1.11,0),float3(.23,.37,.16));d=smin(d,sdEll(q-float3(0,.76,0),float3(.20,.20,.14)),.11);
 d=smin(d,sdEll(q-float3(0,1.62,0),float3(.14,.18,.14)),.09);
 d=smin(d,sdCap(q,float3(-.18,1.35,0),float3(-.27,1.02,0),.067),.06);d=smin(d,sdCap(q,float3(-.27,1.02,0),float3(-.20,.84,0),.052),.05);
 d=smin(d,sdCap(q,float3(.18,1.35,0),float3(.29,1.05,0),.067),.06);d=smin(d,sdCap(q,float3(.29,1.05,0),float3(.23,.84,0),.052),.05);
 for(int i=0;i<2;i++){float side=i==0?-1.:1.;float3 h=float3(side*.10,.67,0),k=float3(side*.12+stride*(i==0?1.:-1.),.36,0),f=float3(side*.14+stride*(i==0?1.:-1.),.08,.08);d=smin(d,sdCap(q,h,k,.088),.06);d=smin(d,sdCap(q,k,f,.062),.05);d=smin(d,sdEll(q-f,float3(.105,.05,.12)),.04);}
 return d;
}

float2 mapScene(float3 p,float t){
 float2 m=float2(1e3,0.);float cosmic=1.-smoothstep(6.,10.,t);
 float world=smoothstep(6.,11.,t);
 // Rotating young planet, visible as the camera draws close.
 if(cosmic>.005){float3 q=p-float3(0,0,-4.8);float a=t*.11;q.xz=float2(q.x*cos(a)-q.z*sin(a),q.x*sin(a)+q.z*cos(a));float planet=sdEll(q,float3(2.15,1.95,2.15));m=op(m,planet,1.,.02);}
 if(world>.005){
  float water=smoothstep(23.,31.,t),heat=1.-smoothstep(23.,31.,t);
  float h=landHeight(p.xz,t)*(1.-water)+water*(.07*sin(p.x*1.2-t*.8)+.045*sin(p.z*1.8+t*.65));
  m=op(m,(p.y-h)*world,water>.55?4.:8.,.025);
  // Broad, terraced cone with a glowing crater and flowing lava channels.
  float volcano=smoothstep(7.,11.,t)*(1.-smoothstep(21.,25.,t));
  if(volcano>.005){float3 v=p-float3(0,0,-9.0);float rad=.22+max(0.,4.5-v.y)*.58;float cone=max(length(v.xz)-rad,max(-v.y,v.y-4.5));float terraces=abs(fract((v.y+.12)*3.)-.5);cone+=max(0.,.025-terraces*.02);m=op(m,cone*volcano,2.,.07);float crater=sdTorus(v-float3(0,4.22,0),float2(.48,.075));m=op(m,crater*volcano,2.,.04);}
  // Individual faceted meteors enter, graze the terrain, and recede.
  float meteors=smoothstep(16.,18.,t)*(1.-smoothstep(22.5,25.,t));
  if(meteors>.005)for(int i=0;i<3;i++){float fi=float(i);float k=modp(t-17.+fi*1.55,5.4)/5.4;float3 c=float3(2.5-fi*2.3,6.8-k*6.,-2.2-fi*1.6-k*4.);float3 z=p-c;float spin=t*(.7+fi*.13);z.xz=float2(z.x*cos(spin)-z.z*sin(spin),z.x*sin(spin)+z.z*cos(spin));float met=sdOct(z,.46+.05*fi);m=op(m,met,3.,.04);float trail=sdCap(p,c+float3(.0,.58,.18),c+float3(.0,1.65,.45),.045);m=op(m,trail,3.,.012);}
  // A submerged and then emerged animal silhouette, smoothly appearing.
  float fauna=smoothstep(31.,35.,t)*(1.-smoothstep(41.,45.,t));if(fauna>.005){float3 dq=p-float3(-.55,0,-5.8);m=op(m,dinosaur(dq,t),5.,.055);}
  float human=smoothstep(41.,46.,t);if(human>.005){float3 hq=p-float3(.08,0,-3.0);m=op(m,person(hq,t),6.,.035);}
  // A stone path becomes a luminous bridge as the camera rises toward space.
  float future=smoothstep(48.,54.,t);if(future>.005){float pathX=.23*sin(p.z*.22);float pathY=.02+future*max(0.,(-p.z-1.)*.21);float path=max(abs(p.x-pathX)-(.58+future*.15),abs(p.y-pathY)-.10);path=max(path,-(p.z+17.));m=op(m,path,7.,.04);}
 }
 return m;
}
float3 normalAt(float3 p,float t){float e=.0025;float dx=mapScene(p+float3(e,0,0),t).x-mapScene(p-float3(e,0,0),t).x;float dy=mapScene(p+float3(0,e,0),t).x-mapScene(p-float3(0,e,0),t).x;float dz=mapScene(p+float3(0,0,e),t).x-mapScene(p-float3(0,0,e),t).x;return normalize(float3(dx,dy,dz));}
float3 pal(float x){return .5+.5*cos(6.28318*(x+float3(.02,.33,.67)));}
float line(float d,float w){return 1.-smoothstep(w,w+fwidth(d)*1.5,d);}

fragment float4 frag(V in [[stage_in]],constant U&u [[buffer(0)]]){
 float t=u.t;float2 uv=float2((in.p.x*2.-u.w)/u.h,(u.h-in.p.y*2.)/u.h);float aspect=u.w/u.h;
 float water=smoothstep(23.,31.,t),fauna=smoothstep(31.,35.,t),human=smoothstep(41.,46.,t),cosmos=smoothstep(51.,56.,t);
 float3 ro=float3(0,1.65,7.);float3 target=float3(0,1.,-3.);
 // Camera advances continuously, lowering over water and lifting into the final orbit.
 float advance=smoothstep(0.,60.,t);ro.z=mix(7.,-1.5,advance);ro.y=mix(1.65,.56,smoothstep(22.,28.,t))+1.45*smoothstep(49.,57.,t);
 target.z=ro.z-8.;target.y=mix(.7,1.5,smoothstep(30.,42.,t));
 float yaw=.10*sin(t*.17)*(1.-cosmos)+.12*sin(t*.11)*cosmos;float pitch=.03*sin(t*.13)-.035*water+.10*cosmos;
 float3 fw=normalize(target-ro+float3(yaw,pitch,0)),right=normalize(cross(fw,float3(0,1,0))),up=normalize(cross(right,fw));
 float3 rd=normalize(fw+(uv.x*aspect*right+uv.y*up)*.50);
 float3 col=mix(float3(.004,.007,.018),float3(.012,.025,.045),smoothstep(-.4,.8,uv.y));
 // Sparse, fixed stars and a few orbit traces.
 float2 starCell=floor(uv*float2(85.,55.));float stars=step(.993,hash3(float3(starCell,1.)))*(.3+.7*hash3(float3(starCell,3.)));
 float starTime=(1.-smoothstep(7.,11.,t))+cosmos;col+=float3(.25,.38,.62)*stars*starTime*(1.-water);
 float travel=0.;float2 hit=float2(1e3,0.);
 for(int i=0;i<86;i++){float3 p=ro+rd*travel;hit=mapScene(p,t);if(hit.x<.0017||travel>70.)break;travel+=max(hit.x*.78,.009);}
 float3 hitPos=ro+rd*travel;
 if(travel<70.){
  float3 n=normalAt(hitPos,t),light=normalize(float3(-.43,.82,.38));float diff=max(dot(n,light),0.);float rim=pow(1.-max(dot(n,-rd),0.),3.);
  float3 base=float3(.18,.20,.24);if(hit.y<1.5){float crack=abs(sin(atan2(hitPos.z,hitPos.x)*9.+hitPos.y*2.))*abs(sin(hitPos.y*7.+hitPos.x));base=float3(.065,.14,.27)+float3(.035,.05,.07)*crack;}
  else if(hit.y<2.5){float lava=pow(max(0.,sin(hitPos.x*3.+hitPos.z*1.6+sin(hitPos.z))),9.);base=mix(float3(.075,.055,.047),float3(1.,.31,.045),lava*.86);}
  else if(hit.y<3.5){base=float3(.76,.34,.09)+float3(.18,.12,.025)*hash3(floor(hitPos*5.));}
  else if(hit.y<4.5){float shimmer=.5+.5*sin(hitPos.x*5.+hitPos.z*3.-t*2.);base=mix(float3(.018,.13,.23),float3(.055,.34,.52),shimmer*.45);}
  else if(hit.y<5.5){float f=.5+.5*sin(hitPos.x*4.+hitPos.y*3.);base=mix(float3(.17,.22,.26),float3(.46,.35,.22),f*.24);}
  else if(hit.y<6.5){base=float3(.60,.68,.72);}
  else if(hit.y<7.5){base=mix(float3(.15,.25,.37),float3(.74,.52,.20),cosmos);}
  else {float cracks=pow(max(0.,sin(hitPos.x*2.1+sin(hitPos.z*.7))*sin(hitPos.z*1.3)),8.);base=mix(float3(.10,.085,.075),float3(.26,.13,.075),cracks*.55);}
  float faceted=floor((.5+.5*diff)*5.)/5.;float3 shade=base*(.32+.70*faceted)+base*rim*.12;
  if(hit.y>2.5&&hit.y<3.5)shade+=float3(.75,.18,.025)*.12;
  if(hit.y>6.5)shade+=float3(.16,.10,.025)*(.3+.4*sin(t*2.));
  col=mix(shade,col,1.-exp(-travel*.035));
 }
 // Impact rings travel across the floor as the falling polyhedra touch down.
 for(int k=0;k<3;k++){float age=t-(18.+float(k)*1.8);float r=.18+max(0.,age)*.75;float d=abs(length(uv-float2((float(k)-1.)*.22,-.18))-r*.13);col+=pal(.08)*line(d,.002)*exp(-max(0.,age)*.6)*smoothstep(0.,.15,age);}
 // Water gleam, vapor folds, and the continuous road into the final sky.
 col+=float3(.02,.20,.32)*water*(.08+.10*sin(uv.x*12.-t*1.4));
 float vapor=exp(-pow((uv.y+.12-.12*sin(uv.x*8.+t))/.022,2.));col+=float3(.36,.48,.54)*vapor*water*(1.-fauna)*.07;
 float future=smoothstep(48.,54.,t);float road=abs(uv.x-.04*sin(uv.y*4.+t*.15));col+=mix(float3(.18,.28,.34),float3(.82,.55,.22),cosmos)*line(road,.006)*(.10+.18*future);
 // Quiet orbital geometry returns the origin of the journey at the end.
 float2 c=uv-float2(0.,.08);float rr=length(c);float orbit=smoothstep(51.,56.,t);
 for(int k=0;k<3;k++){float r=.16+.13*float(k);float d=abs(length(c*float2(1.35,.65))-r);col+=pal(.1+float(k)*.15)*line(d,.0025)*orbit*.10;}
 float finalForm=exp(-rr*13.)*orbit*(.42+.20*sin(t*2.));col+=mix(float3(.03,.18,.31),float3(.88,.56,.20),.5+.5*sin(t*.2))*finalForm*.24;
 float flash=smoothstep(5.,6.8,t)*(1.-smoothstep(7.,9.,t));col+=float3(.56,.68,.92)*exp(-length(uv)*8.)*flash*.55;
 float fade=1.-smoothstep(58.,60.,t);col*=fade;
 return float4(col,1.);
}
