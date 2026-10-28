#include <metal_stdlib>
using namespace metal;

struct V { float4 p [[position]]; };
struct F { float4 p [[position]]; float3 color; float alpha; float3 bary; };
struct U { float2 size; float time; float pad; };
struct Body { float4 p; float4 v; };
struct SimU { float dt; float aspect; uint frame; uint reset; };

vertex V vert(uint i [[vertex_id]]) {
    float2 p=float2((i<<1)&2,i&2);
    return {float4(p*2.-1.,0.,1.)};
}

float hash(float x) { return fract(sin(x*127.1+311.7)*43758.5453); }
uint hashInt(uint x) { x^=x>>16;x*=0x7feb352dU;x^=x>>15;x*=0x846ca68bU;x^=x>>16;return x; }
float random01(uint x) { return float(hashInt(x))*(1./4294967295.); }
float2 rot2(float2 p,float a) { float c=cos(a),s=sin(a); return float2(c*p.x-s*p.y,s*p.x+c*p.y); }
float3 palette(float x) { return .5+.5*cos(6.28318*(x+float3(0.,.33,.67))); }

kernel void updateBodies(device const Body *src [[buffer(0)]], device Body *dst [[buffer(1)]], constant SimU& u [[buffer(2)]], uint id [[thread_position_in_grid]]) {
    if(id>=2048u)return;
    Body b;
    if(u.reset!=0u) {
        uint cell=id>>1u,tri=id&1u,gx=cell%32u,gy=cell/32u;
        float2 centroid=tri==0u?float2(1./6.,-1./6.):float2(-1./6.,1./6.);
        float2 local=(float2((float(gx)+.5)/32.-.5,(float(gy)+.5)/32.-.5)+centroid/32.)*.89;
        float2 p=rot2(local,35.);
        float2 radial=normalize(p+float2(.0001,.0002));
        float2 tangent=float2(-radial.y,radial.x);
        float r0=random01(id*7u+11u),r1=random01(id*13u+31u);
        float speed=.55+1.35*r0;
        b.p=float4(p,0.,0.);
        b.v=float4(radial*speed+tangent*((r1-.5)*.75),r0,(r1-.5)*3.2);
        dst[id]=b;
        return;
    }
    b=src[id];
    float dt=clamp(u.dt,0.,.04);
    b.p.w*=exp(-dt*7.5);
    uint seed=id*747796405u+u.frame*2891336453u;
    float2 noise=float2(random01(seed)*2.-1.,random01(seed+0x9e3779b9u)*2.-1.);
    b.v.xy+=noise*(.95*dt);
    b.v.xy*=exp(-.035*dt);
    b.p.xy+=b.v.xy*dt;

    float radius=.008+b.p.z*.008;
    for(uint j=0u;j<2048u;j++) {
        if(j==id)continue;
        Body other=src[j];
        float2 delta=b.p.xy-other.p.xy;
        float d2=dot(delta,delta),minD=radius+(.008+other.p.z*.008);
        if(d2<minD*minD&&d2>1.e-8) {
            float d=sqrt(d2);float2 n=delta/d;
            float closing=dot(b.v.xy-other.v.xy,n);
            float overlap=minD-d;
            if(closing<0.) {
                b.v.xy+=n*(-closing*.88);
                float hit=clamp(-closing*.30+.18,.18,1.);
                b.p.w=max(b.p.w,hit);
                b.p.z=min(.82,b.p.z+.008*hit);
            }
            b.p.xy+=n*overlap*.30;
        }
    }

    float bx=u.aspect-.045,by=.955;
    if(b.p.x < -bx){b.p.x=-bx;b.v.x=abs(b.v.x)*.91;b.p.w=max(b.p.w,.9);b.p.z=min(.82,b.p.z+.009);}
    if(b.p.x >  bx){b.p.x= bx;b.v.x=-abs(b.v.x)*.91;b.p.w=max(b.p.w,.9);b.p.z=min(.82,b.p.z+.009);}
    if(b.p.y < -by){b.p.y=-by;b.v.y=abs(b.v.y)*.91;b.p.w=max(b.p.w,.9);b.p.z=min(.82,b.p.z+.009);}
    if(b.p.y >  by){b.p.y= by;b.v.y=-abs(b.v.y)*.91;b.p.w=max(b.p.w,.9);b.p.z=min(.82,b.p.z+.009);}
    float speed2=dot(b.v.xy,b.v.xy);
    if(speed2>14.44)b.v.xy*=3.8/sqrt(speed2);
    dst[id]=b;
}
float sdTri(float2 p,float r) {
    float2 a=float2(-.5*r,-.29*r), b=float2(.5*r,-.29*r), c=float2(0.,.577*r);
    float2 e0=b-a,e1=c-b,e2=a-c;
    float2 v0=p-a,v1=p-b,v2=p-c;
    float h0=clamp(dot(v0,e0)/dot(e0,e0),0.,1.);
    float h1=clamp(dot(v1,e1)/dot(e1,e1),0.,1.);
    float h2=clamp(dot(v2,e2)/dot(e2,e2),0.,1.);
    float d=min(length(v0-e0*h0),min(length(v1-e1*h1),length(v2-e2*h2)));
    bool inside=(e0.x*v0.y-e0.y*v0.x>=0.)&&(e1.x*v1.y-e1.y*v1.x>=0.)&&(e2.x*v2.y-e2.y*v2.x>=0.);
    return inside ? -d : d;
}

fragment float4 frag(V in [[stage_in]], constant U& u [[buffer(0)]]) {
    float t=u.time;
    float2 uv=(in.p.xy*2.-u.size)/u.size.y;
    float3 col=float3(0.);

    // Dem0 scene 4, preserved as the closing 24-second segment.
    if(t>=27.95) {
        float sourceTime=72.+t-27.95;
        float reveal=smoothstep(0.,10.,t-27.95);
        float lineWidth=mix(.0012,.009,reveal);
        float lineBrightness=mix(.035,1.,reveal);
        float2 p=rot2(uv,sourceTime*.08);
        float3 endColor=0.;
        for(int i=0;i<9;i++) {
            float f=float(i);
            float2 q=p;
            q.y+=.22*sin(q.x*2.+sourceTime*.45+f*.55);
            float d=abs(q.y-(f-4.)*.17);
            endColor+=palette(f*.08+q.x*.12+sourceTime*.025)*(lineWidth*lineBrightness)/(d+lineWidth);
            p=rot2(p,.09);
        }
        float local=fmod(sourceTime,24.);
        float endFade=smoothstep(0.,2.,sourceTime)*(1.-smoothstep(92.,96.,sourceTime));
        endFade*=smoothstep(0.,.6,local)*(1.-smoothstep(23.4,24.,local));
        endColor=1.-exp(-endColor*1.15);
        endColor*=max(0.,1.-.18*dot(uv,uv));
        endColor=pow(max(endColor,0.),float3(.85));
        float grain=fract(sin(dot(in.p.xy,float2(12.9898,78.233)))*43758.5453);
        endColor=(endColor+(grain-.5)*.018)*endFade;
        return float4(endColor,1.);
    }

    float debrisAge=t-9.35;
    if(debrisAge>=0.) {
        float progress=smoothstep(0.,15.,debrisAge);
        float3 sparks=float3(.05*progress);
        for(int i=0;i<16;i++) {
            float f=float(i),phase=hash(f*7.13)*6.283185;
            float rate=.32+hash(f*11.7)*1.15+progress*1.25;
            float2 center=float2(1.62*sin(debrisAge*rate+phase),.86*sin(debrisAge*(rate*.73+.19)+phase*1.71));
            float2 delta=uv-center;
            float radius=.022+progress*(.035+.065*hash(f*3.31));
            float pulse=pow(max(0.,sin(debrisAge*(1.1+progress*2.8)+phase)),14.);
            float flash=exp(-dot(delta,delta)/(radius*radius))*pulse*(.055+.30*progress);
            sparks+=palette(hash(f*5.37)+debrisAge*.075)*flash;
        }
        sparks=1.-exp(-max(sparks,0.)*(1.1+progress*.55));
        float whiteIn=smoothstep(12.,15.,debrisAge);
        float fadeToBlack=smoothstep(16.,18.6,debrisAge);
        float3 result=mix(sparks,float3(1.),whiteIn)*(1.-fadeToBlack);
        return float4(result,1.);
    }

    // The six arrivals get closer together and hit with a shorter, brighter flash.
    const float starts[6]={.34,1.57,2.53,3.29,3.90,4.39};
    const float spans[6]={.96,.76,.63,.51,.42,.34};
    const float3 colors[6]={float3(1.),float3(1.,.78,.015),float3(1.,.025,.018),float3(.01,1.,.08),float3(.015,.22,1.),float3(1.,.30,.008)};
    for(int i=0;i<6;i++) {
        float age=t-starts[i];
        if(age>=0. && age<spans[i]) {
            float q=clamp(age/spans[i],0.,1.);
            float radius=.001+4.6*q*q;
            float d=sdTri(uv,radius);
            float outline=exp(-abs(d)*max(110.,210./max(radius,.02)));
            float edge=exp(-abs(d)*max(24.,52./max(radius,.02)));
            float vanish=1.-smoothstep(.87,1.,q);
            float energy=(1.-smoothstep(.78,1.,q))*.7;
            col+=colors[i]*(outline+edge*.8)*vanish;
            col+=colors[i]*exp(-dot(uv,uv)*150.)*energy*.22;
        }
        float impact=exp(-pow((t-(starts[i]+spans[i]))/.065,2.));
        col+=colors[i]*impact*.075*exp(-dot(uv,uv)*4.);
    }
    // A pinprick of light establishes the vanishing point before the first shape.
    float point=exp(-dot(uv,uv)*15000.)*(1.-smoothstep(.12,.38,t));
    col+=float3(1.)*point;

    float age=t-5.05;
    float squareAlpha=1.-smoothstep(9.31,9.46,t);
    if(age>0. && t<9.46) {
        float appear=smoothstep(0.,.16,age);
        float wobble=age>.55 ? .045*sin((age-.55)*6.283185*1.18)*smoothstep(.55,.8,age) : 0.;
        float spinAge=max(age-2.12,0.);
        float spinQ=clamp(spinAge/2.15,0.,1.);
        float angle=wobble+35.*spinQ*spinQ*spinQ;
        float2 p=rot2(uv,-angle);
        float halfSide=.445*(appear+.08*exp(-age*13.)*sin(age*28.));
        float d=max(abs(p.x),abs(p.y))-halfSide;
        float edge=exp(-abs(d)*150.);
        float core=1.-smoothstep(.0015,.0045,abs(d));
        float shine=smoothstep(-halfSide,halfSide,p.x)*.025;
        col+=float3(1.)*(edge*.34+core*.8+shine*core)*squareAlpha;
    }

    float fade=1.-smoothstep(13.1,14.5,t);
    col*=fade;
    // Keep the black genuinely black and let whites retain detail during the flash.
    col=1.-exp(-max(col,0.)*1.18);
    return float4(col,1.);
}

vertex F shardVert(uint vertexID [[vertex_id]], uint instanceID [[instance_id]], constant U& u [[buffer(0)]], device const Body *bodies [[buffer(1)]]) {
    uint cell=instanceID/2u, triHalf=instanceID&1u;
    uint gx=cell%32u,gy=cell/32u;
    float cellSize=.89/32.;
    Body body=bodies[instanceID];
    float2 a=float2(-.5,-.5)*cellSize, b=float2(.5,-.5)*cellSize, c=float2(.5,.5)*cellSize, d=float2(-.5,.5)*cellSize;
    float2 local;
    if(triHalf==0u) local=vertexID==0u?a:(vertexID==1u?b:c);
    else local=vertexID==0u?a:(vertexID==1u?c:d);
    float2 bary=vertexID==0u?float2(1.,0.):(vertexID==1u?float2(0.,1.):float2(0.,0.));
    float age=max(0.,u.time-9.35);
    float2 centroid=triHalf==0u?float2(1./6.,-1./6.):float2(-1./6.,1./6.);
    local-=centroid*cellSize;
    float piece=hash(float(instanceID)*2.31+7.);
    float angle=35.+body.v.w*age+(piece-.5)*min(age*1.2,2.2);
    float scale=1.+body.p.z*.55;
    float2 pos=body.p.xy+rot2(local*scale,angle);
    float aspect=u.size.x/u.size.y;
    float4 clip=float4(pos.x/aspect,pos.y,0.,1.);
    float alpha=1.-smoothstep(14.5,15.5,age);
    float hue=hash(float(instanceID)*.71)+age*.065;
    float3 tint=mix(float3(.66+.27*piece),palette(hue),clamp(age*.10+body.p.w*.85,0.,.86));
    tint*=.82+body.p.w*1.55+smoothstep(1.2,7.2,age)*.22;
    return {clip,tint,alpha,float3(bary,0.)};
}

fragment float4 shardFrag(F in [[stage_in]]) {
    float edge=1.-smoothstep(0.,.10,min(in.bary.x,min(in.bary.y,1.-in.bary.x-in.bary.y)));
    float3 c=in.color*(.82+.18*edge);
    return float4(c*in.alpha,in.alpha);
}
