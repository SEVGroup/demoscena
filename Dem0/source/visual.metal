#include <metal_stdlib>
using namespace metal;
struct V{float4 p [[position]];};
vertex V vert(uint i [[vertex_id]]){float2 p=float2((i<<1)&2,i&2);return {float4(p*2-1,0,1)};}
float2 rot(float2 p,float a){return float2(cos(a)*p.x-sin(a)*p.y,sin(a)*p.x+cos(a)*p.y);}
float3 palette(float x){return .5+.5*cos(6.28318*(x+float3(0,.33,.67)));}
fragment float4 frag(V v [[stage_in]],constant float3 &u [[buffer(0)]]){
 float t=u.z;float2 uv=(v.p.xy*2-u.xy)/u.y;float beat=exp(-5*fract(t*2));
 float3 c=0;float scene=floor(t/24);float fade=smoothstep(0.,2.,t)*(1-smoothstep(92.,96.,t));
 if(scene<1){
 float2 p=rot(uv,t*.12);float z=0;
 for(int i=0;i<7;i++){float fi=float(i);float2 q=rot(p,t*.13+fi*.43);q.x+=.22*sin(t*.4+fi);float r=length(q);float a=atan2(q.y,q.x);float shape=r-(.24+fi*.12+.045*sin(a*6+t*.65+fi));float line=.004/(abs(shape)+.004);c+=palette(fi*.11+t*.025)*line*(.65+.2*beat);}
 c+=.06*palette(length(p)-t*.06)/(length(p)+.3);
 }else if(scene<2){
 float2 p=rot(uv,.2*sin(t*.2));float a=atan2(p.y,p.x);float r=length(p);float z=1./max(r,.035)+t*.65;
 float angular=a*3.1831+.35*sin(z*.5);
 float2 grid=float2(angular,z);float2 g=abs(fract(grid)-.5);
 float af=fract(angular);float seam=min(af,1.-af);
 float line=.018/(min(g.x,g.y)+.018);
 float sectorMix=smoothstep(.34,.66,af);
 float3 sectorA=palette(floor(angular)+z*.035+t*.065);
 float3 sectorB=palette(floor(angular)+1.+z*.035+t*.065);
 float3 hue=mix(sectorA,sectorB,sectorMix);
 c=hue*line*smoothstep(0.,.35,r);
 c+=palette(t*.03)*.025/(r+.08);
 c*=smoothstep(0.,.08,seam);
 }else if(scene<3){
 float3 ro=float3(0,0,-3.6),rd=normalize(float3(uv,1.6));float travel=0;
 for(int i=0;i<64;i++){float3 p=ro+rd*travel;p.xz=rot(p.xz,t*.21);p.yz=rot(p.yz,t*.16);float3 q=p;
 for(int j=0;j<3;j++){q=abs(q)-float3(.63,.48,.52);q.xy=rot(q.xy,.6+.15*sin(t*.2));q.xz=rot(q.xz,.8);}
 float d=(length(q)-.23)/3.;c+=palette(length(p)*.2+t*.03)*.008/(.04+abs(d))*exp(-travel*.3);travel+=max(abs(d)*.7,.018);if(travel>7)break;
 }
 }else{
 float2 p=rot(uv,t*.08);for(int i=0;i<9;i++){float f=float(i);float2 q=p;q.y+=.22*sin(q.x*2+t*.45+f*.55);float d=abs(q.y-(f-4)*.17);c+=palette(f*.08+q.x*.12+t*.025)*.009/(d+.009);p=rot(p,.09);}
 }
 fade*=smoothstep(0.,.6,fmod(t,24.))*(1-smoothstep(23.4,24.,fmod(t,24.)));
 float grain=fract(sin(dot(v.p.xy,float2(12.9898,78.233)))*43758.5453);
 c=1-exp(-c*1.15);c*=max(0.,1-.18*dot(uv,uv));c=pow(max(c,0.),float3(.85));c=(c+(grain-.5)*.018)*fade;
 return float4(c,1);
}
