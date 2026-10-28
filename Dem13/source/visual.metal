#include <metal_stdlib>
using namespace metal;
struct U { float w,h,t,pad; };
struct V { float4 p [[position]]; };
vertex V vert(uint id [[vertex_id]]) { V o; o.p=float4(id==1?3.:-1.,id==2?3.:-1.,0,1); return o; }

float sdEll(float3 p,float3 r){float k0=length(p/r),k1=length(p/(r*r));return k0*(k0-1.)/max(k1,1e-5);}
float sdCap(float3 p,float3 a,float3 b,float r){float3 q=p-a,v=b-a;return length(q-v*clamp(dot(q,v)/max(dot(v,v),1e-5),0.,1.))-r;}
float smin(float a,float b,float k){float h=max(k-abs(a-b),0.)/k;return min(a,b)-h*h*k*.25;}
float hash3(float3 p){p=fract(p*.1031);p+=dot(p,p.yxz+33.33);return fract((p.x+p.y)*p.z);}
float2 op(float2 a,float d,float m,float k){return float2(smin(a.x,d,k),d<a.x?m:a.y);}

float person(float3 q,float t){
 float kneel=max(smoothstep(23.,29.,t)*(1.-smoothstep(39.,43.,t)),1.0*smoothstep(52.,58.,t));
 float rootDrop=.34*kneel, torsoY=mix(1.08,.85,kneel), shoulderY=mix(1.34,1.12,kneel);
 float d=sdEll(q-float3(0,torsoY,0),float3(.245,.39,.17));
 d=smin(d,sdEll(q-float3(0,.76-rootDrop,0),float3(.205,.22,.15)),.13);
 d=smin(d,sdEll(q-float3(0,1.63-rootDrop,0),float3(.145,.19,.14)),.105);
 d=smin(d,sdCap(q,float3(0,1.42-rootDrop,0),float3(0,1.52-rootDrop,0),.085),.08);
 // A clear nose bridge and cheek plane, kept within a sculpted head.
 d=smin(d,sdEll(q-float3(.115,1.60-rootDrop,.035),float3(.09,.065,.075)),.045);
 // Relaxed far arm.
 d=smin(d,sdCap(q,float3(-.20,shoulderY,0),float3(-.29,1.05-rootDrop,0),.075),.07);
 d=smin(d,sdCap(q,float3(-.29,1.05-rootDrop,0),float3(-.22,.83-rootDrop,0),.058),.055);
 d=smin(d,sdEll(q-float3(-.21,.79-rootDrop,0),float3(.06,.09,.06)),.045);
 // Right arm reaches toward the dog, then settles near the chest.
 float reach=smoothstep(24.,32.,t)*(1.-.25*smoothstep(39.,45.,t));
 float3 elbow=mix(float3(.28,1.06-rootDrop,.01),float3(.39,1.06-rootDrop,.02),reach);
 float3 wrist=mix(float3(.24,.86-rootDrop,.03),float3(.91,.91-rootDrop,.03),reach);
 d=smin(d,sdCap(q,float3(.19,shoulderY,.01),elbow,.073),.065);
 d=smin(d,sdCap(q,elbow,wrist,.052),.05);
 d=smin(d,sdEll(q-(wrist+float3(.055,-.015,0)),float3(.085,.052,.058)),.045);
 // Two legs with one bending under the body as the person kneels.
 float stride=sin(t*3.2)*.075*smoothstep(43.,48.,t);
 float3 hipL=float3(-.095,.67-rootDrop,-.015), hipR=float3(.095,.67-rootDrop,.02);
 float3 kneeL=mix(float3(-.13,.34-rootDrop,-.03),float3(-.22,.38-rootDrop,-.03),kneel);
 float3 kneeR=mix(float3(.13,.34-rootDrop,.03),float3(.26,.18-rootDrop,.07),kneel);
 float3 footL=mix(float3(-.16,.08-rootDrop,.08),float3(-.35,.08-rootDrop,.13),kneel);
 float3 footR=mix(float3(.14,.08-rootDrop,.12),float3(.40,.08-rootDrop,.15),kneel);
 kneeL.x+=stride;kneeR.x-=stride;footL.x+=stride;footR.x-=stride;
 d=smin(d,sdCap(q,hipL,kneeL,.095),.07);d=smin(d,sdCap(q,kneeL,footL,.068),.06);
 d=smin(d,sdCap(q,hipR,kneeR,.095),.07);d=smin(d,sdCap(q,kneeR,footR,.068),.06);
 d=smin(d,sdEll(q-footL-float3(0,.005,.04),float3(.105,.055,.12)),.05);
 d=smin(d,sdEll(q-footR-float3(0,.005,.04),float3(.105,.055,.12)),.05);
 return d;
}

float dog(float3 q,float t){
 float settle=smoothstep(52.,58.,t);
 float walk=(1.-settle)*smoothstep(12.,16.,t);
 float bob=walk*(.025+.025*sin(t*7.));
 float headTilt=.08*sin(t*1.2)*smoothstep(26.,33.,t)*(1.-settle);
 float dogY=mix(.66,.49,settle);float3 head=q-float3(-.48,mix(1.0,.82,settle)+bob,0);float d=sdEll(q-float3(0,dogY+bob,0),mix(float3(.49,.285,.215),float3(.46,.30,.215),settle));
 d=smin(d,sdEll(q-float3(-.28,mix(.70,.53,settle)+bob,0),float3(.29,.31,.235)),.12);
 d=smin(d,sdEll(q-float3(.30,mix(.68,.52,settle)+bob,0),float3(.29,.31,.22)),.13);
 float3 hq=head;float cs=cos(headTilt),sn=sin(headTilt);hq.xy=float2(hq.x*cs-hq.y*sn,hq.x*sn+hq.y*cs);
 d=smin(d,sdEll(hq,float3(.225,.205,.19)),.14);
 d=smin(d,sdEll(q-float3(-.665,mix(.91,.75,settle)+bob,0),float3(.20,.105,.135)),.10);
 d=smin(d,sdEll(q-float3(-.812,mix(.924,.765,settle)+bob,0),float3(.055,.047,.062)),.035);
 // Folded ears and broad, smoothly joined neck.
 d=smin(d,sdEll(q-float3(-.39,mix(1.145,.96,settle)+bob,.125),float3(.11,.185,.075)),.06);
 d=smin(d,sdEll(q-float3(-.39,mix(1.145,.96,settle)+bob,-.125),float3(.11,.185,.075)),.06);
 d=smin(d,sdCap(q,float3(-.27,.82+bob,0),float3(-.39,.94+bob,0),.16),.14);
 // Four articulated legs with a soft walking cycle.
 for(int i=0;i<4;i++){
  float fore=i<2?1.:0.;float side=(i%2==0)?1.:-1.;
  float x=fore?-.31:.31,z=side*.145;float phase=t*7.+(fore?0.:2.4)+(side>0.?0.:3.14);
  float swing=walk*sin(phase)*.105, lift=walk*max(0.,cos(phase))*.09;
  float3 hip=float3(x,mix(.58,.45,settle)+bob,z), knee=float3(x+swing*.45,mix(.32,.25,settle)+bob+lift*.5,z);
  if(!fore&&settle>.01){knee.x+=.18*settle;knee.y=mix(knee.y,.20,settle);}
  float3 ankle=float3(x+swing,.085+bob+lift,z+.018);if(!fore)ankle.x+=.12*settle;
  d=smin(d,sdCap(q,hip,knee,.09),.07);d=smin(d,sdCap(q,knee,ankle,.064),.055);
  d=smin(d,sdEll(q-ankle-float3(-.035,-.005,.02),float3(.105,.065,.075)),.05);
 }
 float wag=sin(t*5.2)*.16*(.25+walk+settle*.25);
 float3 tailA=float3(.36,mix(.77,.61,settle)+bob,0),tailB=float3(.57,mix(.91,.76,settle)+bob+wag*.22,0),tailC=float3(.75,mix(.80,.68,settle)+bob+wag,0);
 d=smin(d,sdCap(q,tailA,tailB,.055),.045);d=smin(d,sdCap(q,tailB,tailC,.042),.035);
 return d;
}

float heartShape(float3 p){
 float x=p.x/.34,y=p.y/.40;float k=x*x+y*y-1.;
 float f=k*k*k-x*x*y*y*y;
 float2 grad=float2(6.*x*k*k-2.*x*y*y*y,6.*y*k*k-3.*x*x*y*y);
 float d=f*.36/max(length(grad),.16);
 float2 w=float2(d,abs(p.z)-.12);
 return length(max(w,0.))+min(max(w.x,w.y),0.);
}

float2 mapScene(float3 p,float t){
 float heat=max(smoothstep(30.,39.,t)*(1.-smoothstep(50.,60.,t)),.45*smoothstep(54.,59.,t)*(1.-smoothstep(63.,64.,t)));
 float wave=.018*sin(p.x*2.3-p.z*1.4-t*.75)+heat*.045*sin(p.z*2.4-t*2.2)*exp(-abs(p.x)*.25);
 float2 m=float2(p.y-wave,0.);
 float personPresence=smoothstep(1.,6.,t);float3 hp=p-float3(-.70,0,0);if(personPresence>.005)m=op(m,person(hp/max(personPresence,.005),t)*personPresence,1.,.10);
 float arrival=smoothstep(13.,22.,t);
 float dogX=mix(2.35,.82,smoothstep(10.,26.,t));dogX=mix(dogX,.72,smoothstep(37.,43.,t));
 float dogZ=mix(-5.,0.,smoothstep(10.,26.,t));
 float orbit=smoothstep(42.,46.,t)*(1.-smoothstep(49.,53.,t));float runAngle=t*1.7;
 dogX=mix(dogX,-.70+1.25*cos(runAngle),orbit);dogZ=mix(dogZ,1.15*sin(runAngle),orbit);
 dogX=mix(dogX,.20,smoothstep(50.,55.,t));dogZ*=1.-smoothstep(50.,55.,t);
 float3 dp=p-float3(dogX,0,dogZ);if(arrival>.005){m=op(m,dog(dp/max(arrival,.005),t)*arrival,2.,.11*arrival);m=op(m,sdEll((p-float3(dogX-.812,.924,dogZ+.02))/arrival,float3(.042,.037,.045))*arrival,4.,.012*arrival);m=op(m,sdEll((p-float3(dogX-.545,1.055,dogZ+.184))/arrival,float3(.027,.024,.018))*arrival,4.,.01*arrival);}
 float touch=smoothstep(28.,33.,t)*(1.-smoothstep(48.,54.,t));
 float heartPulse=1.+.055*sin(t*3.2)*touch;
 float heartScale=smoothstep(29.,34.,t)*(1.-smoothstep(49.,56.,t));
 if(heartScale>.001){float3 q=(p-float3(.03,1.48,0))/(heartPulse*heartScale);float hd=heartShape(q)*heartPulse*heartScale;m=op(m,hd,3.,.025);}
 return m;
}

float3 normalAt(float3 p,float t){float e=.0025;float2 k=float2(1.,-1.);return normalize(k.xyy*mapScene(p+k.xyy*e,t).x+k.yyx*mapScene(p+k.yyx*e,t).x+k.yxy*mapScene(p+k.yxy*e,t).x+k.xxx*mapScene(p+k.xxx*e,t).x);}
float3 palette(float x){return .5+.5*cos(6.28318*(x+float3(.04,.36,.68)));}
float line(float d,float w){return 1.-smoothstep(w,w+fwidth(d)*1.5,d);}

fragment float4 frag(V in [[stage_in]],constant U&u [[buffer(0)]]){
 float t=u.t;float2 uv=float2((in.p.x*2.-u.w)/u.h,(u.h-in.p.y*2.)/u.h);float aspect=u.w/u.h;
 float3 ro=float3(0,2.05,7.0),target=float3(0,1.0,0);
 float orbit=smoothstep(43.,52.,t);float ang=t*.26*orbit;ro.x=sin(ang)*1.15;ro.z=7.-orbit*.55;
 float3 fw=normalize(target-ro),right=normalize(cross(fw,float3(0,1,0))),up=cross(right,fw);
 float zoom=1.+.12*smoothstep(0.,16.,t)-.1*smoothstep(44.,54.,t);
 float3 rd=normalize(fw+(uv.x*aspect*right+uv.y*up)*(.47/zoom));
 float3 col=float3(.002,.004,.009);float travel=0.;float2 hit=float2(0.);
 for(int i=0;i<76;i++){float3 p=ro+rd*travel;hit=mapScene(p,t);if(hit.x<.0015||travel>24.)break;travel+=max(hit.x*.82,.006);}
 if(travel<24.){
  float3 p=ro+rd*travel,n=normalAt(p,t);float3 light=normalize(float3(-.48,.82,.62));
  float smoothDiff=max(dot(n,light),0.);float3 facetNormal=normalize(round(n*3.)/3.);float flatDiff=floor(max(dot(facetNormal,light),0.)*5.)/5.;float diff=mix(smoothDiff,flatDiff,.72);float back=max(dot(n,normalize(float3(.5,.2,-.8))),0.);
  float3 base=hit.y<.5?float3(.035,.085,.13):(hit.y<1.5?float3(.36,.50,.60):(hit.y<2.5?float3(.37,.25,.17):(hit.y<3.5?float3(1.,.25,.10):float3(.025,.018,.014))));
  if(hit.y<.5){
   float2 g=p.xz*1.55;float2 c=fract(g)-.5;
   float triLine=max(line(abs(c.y+.5),.008),max(line(abs(c.x*.5+c.y*.5),.008),line(abs(c.x*.5-c.y*.5),.008)));
   float wave=sin(length(p.xz-float2(0.,-1.))*7.-t*2.2);
   base+=float3(.025,.12,.22)*triLine*(.30+.35*max(0.,wave));
  }
  float3 shaded=base*(.22+1.05*diff)+float3(.12,.25,.39)*pow(back,3.)*.28;
  // Broad, orderly facet shading follows the sculpt rather than random noise.
  float facet=hash3(floor(p*float3(10.,13.,10.)));
  float bands=floor((.5+.5*dot(n,light))*6.)/6.;
  shaded*=.98+.02*facet;shaded+=base*bands*.38;
  if(hit.y>2.5&&hit.y<3.5){float pulse=.72+.28*sin(t*3.1);shaded=float3(.88,.34,.10)*(.22+.85*diff)*pulse*(.84+.16*facet);shaded+=float3(1.,.48,.17)*pow(max(dot(reflect(-light,n),normalize(-rd)),0.),10.)*.25;shaded+=float3(1.,.35,.10)*.12;}
  float fog=1.-exp(-travel*.045);col=mix(shaded,col,fog*.72);
 }
 // Soft pulse in the air, with triangular apertures that gather overhead.
 float heart=smoothstep(27.,32.,t)*(1.-smoothstep(48.,53.,t));float hpulse=pow(.5+.5*sin(t*3.2),5.);
 float2 q=uv-float2(0.,.02);float rr=length(q);float portal=smoothstep(41.,49.,t)*(1.-smoothstep(54.,60.,t));
 float3 portalCol=palette(.58+t*.006);
 for(int k=0;k<5;k++){
  float s=.12+float(k)*.09+.018*sin(t*1.8+float(k));float2 a=float2(0.,s),b=float2(-s*.866,-s*.5),c=float2(s*.866,-s*.5);
  float td=min(length(q-(a+(b-a)*clamp(dot(q-a,b-a)/max(dot(b-a,b-a),1e-4),0.,1.))),min(length(q-(b+(c-b)*clamp(dot(q-b,c-b)/max(dot(c-b,c-b),1e-4),0.,1.))),length(q-(c+(a-c)*clamp(dot(q-c,a-c)/max(dot(a-c,a-c),1e-4),0.,1.)))));
  col+=portalCol*line(td,.0025)*portal*.17;
 }
 col+=float3(1.,.43,.13)*exp(-rr*16.)*heart*(.04+.13*hpulse);
 float chestBeat=smoothstep(5.,8.,t)*(1.-smoothstep(28.,32.,t))*pow(.5+.5*sin(t*3.1+sin(t*.4)),10.);col+=float3(1.,.32,.08)*exp(-length((uv-float2(-.14,.06))*float2(1.,1.5))*78.)*chestBeat*.22;
 float lastBeat=smoothstep(54.,59.,t)*(1.-smoothstep(62.,64.,t))*pow(.5+.5*sin(t*3.2),9.);col+=float3(1.,.34,.08)*exp(-rr*68.)*lastBeat*.16;
 float climax=smoothstep(48.,52.,t)*(1.-smoothstep(53.,60.,t));col+=float3(.65,.42,.95)*exp(-rr*5.)*climax*.18;
 float stars=pow(max(0.,sin(uv.x*173.+uv.y*227.+t*.12)),80.)*.025;col+=stars;
 float fade=1.-smoothstep(62.,64.,t);col*=fade;
 return float4(col,1.);
}
