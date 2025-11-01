Shader "Unlit/Shadow"
{
    Properties
    {
        [Header(Base)]
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.0,0.0,0.0,0.0)

        [Space(20)]
        [Header(Dissolve)]
        [Toggle] _DissolveEnabled ("Dissolve Enabled ", int) = 1.0
        _DissolveTex ("Dissolve Texture", 2D) = "white" {}
        [NoScaleOffset]_RampTex ("Ramp Texture", 2D) = "white" {}
        _Clip  ("Clip", Range(-0.1,0.9)) = 0

        [Space(20)]
        [Header(Fresnel)]
        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _Power("Power", float) = 1

        [Space(20)]
        [Header(Shadow)]
        _Shadow("Shadow",float) = 0
        _X("X",float) = 0
        _Z("Z",float) = 0
        _ShadowAlpha("Shadow Alpha",Range(0,1)) = 0.5
        //实际上，最好放在一个vector中
    }

    // Unity内置阴影
    // SubShader
    // {
    //     Lod 600
    //     Tags { "Queue" = "Geometry" }
    //     Blend Off
    //     Cull Back
        
    //     UsePass "Unlit/XRay/XRay"

    //     Pass
    //     {
            
    //         CGPROGRAM
    //         #pragma vertex vert
    //         #pragma fragment frag
    //         #pragma multi_compile _ _DISSOLVEENABLED_ON 
    //         #pragma multi_compile_fwdbase
    //         #include "UnityCG.cginc"
    //         #include "AutoLight.cginc"

    //         sampler2D _MainTex;
    //         float4 _Color;

    //         sampler2D _DissolveTex;
    //         float4 _DissolveTex_ST;
    //         sampler _RampTex;
    //         fixed  _Clip;

    //         struct appdata
    //         {
    //             float4 vertex : POSITION;
    //             float2 uv : TEXCOORD0;
    //         };

    //         struct v2f
    //         {
    //             float4 pos : SV_POSITION;
    //             float4 uv : TEXCOORD0;
    //             float4 posWS : TEXCOORD1;
    //             UNITY_SHADOW_COORDS(2)
    //         };

    //         v2f vert (appdata v)
    //         {
    //             v2f o;
    //             o.pos = UnityObjectToClipPos(v.vertex);
    //             o.posWS = mul(unity_ObjectToWorld, v.vertex);
    //             o.uv.xy = v.uv;
    //             o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);  
    //             //v.uv*_DissolveTex_ST.xy + _DissolveTex_ST.zw;

    //             TRANSFER_SHADOW(o);
    //             return o;
    //         }

    //         fixed4 frag (v2f i) : SV_Target
    //         {
    //             UNITY_LIGHT_ATTENUATION(atten,i,i.posWS);

    //             float4 tex = tex2D (_MainTex, i.uv.xy);
    //             float4 final = atten * tex * 2 + _Color;

    //             #if _DISSOLVEENABLED_ON

    //             float4 dissolve = tex2D(_DissolveTex, i.uv.zw);
    //             clip (dissolve.r - _Clip);
    //             float dissolveuv = saturate ( (dissolve.r - _Clip) / (_Clip+0.1 - _Clip) );
    //             float4 ramp = tex1D(_RampTex,dissolveuv); 
    //             final *= ramp;
    //             return final;
    //             #endif

    //             return final;
                
    //         }
    //         ENDCG
    //     }

    //     Pass
    //     {
    //         Tags {"LightMode" = "ShadowCaster"}
    //         CGPROGRAM
    //         #pragma vertex vert
    //         #pragma fragment frag
    //         #pragma multi_compile _ _shadowcaster
    //         #pragma multi_compile _ _DISSOLVEENABLED_ON 
    //         #include "UnityCG.cginc"
            

    //         sampler2D _DissolveTex;
    //         float4 _DissolveTex_ST;
    //         fixed  _Clip;

    //         struct appdata
    //         {
    //             float4 vertex : POSITION;
    //             float3 normal: NORMAL;
    //             float4 uv : TEXCOORD0;
    //         };

    //         struct v2f
    //         {
    //             float4 uv : TEXCOORD0;
    //             V2F_SHADOW_CASTER;
    //         };

    //         v2f vert (appdata v)
    //         {
    //             v2f o;
    //             o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);
    //             TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
    //             return o;
    //         }

    //         fixed4 frag (v2f i) : SV_Target
    //         {
    //             #if _DISSOLVEENABLED_ON

    //             float4 dissolve = tex2D(_DissolveTex, i.uv.zw);
    //             clip (dissolve.r - _Clip);
    //             #endif

    //             SHADOW_CASTER_FRAGMENT(i);
    //         }
    //         ENDCG

    //     }

    // }

    //手动写出的阴影
    SubShader
    {
        Lod 400

        Pass
        {
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _DISSOLVEENABLED_ON 

            #include "UnityCG.cginc"
            

            sampler2D _MainTex;
            float4 _Color;

            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            sampler _RampTex;
            fixed  _Clip;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 posWS : TEXCOORD1;
            
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.uv.xy = v.uv;
                o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);  
                //v.uv*_DissolveTex_ST.xy + _DissolveTex_ST.zw;

                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               

                float4 tex = tex2D (_MainTex, i.uv.xy);
                float4 final = tex * 2 + _Color;

                #if _DISSOLVEENABLED_ON

                float4 dissolve = tex2D(_DissolveTex, i.uv.zw);
                clip (dissolve.r - _Clip);
                float dissolveuv = saturate ( (dissolve.r - _Clip) / (_Clip+0.1 - _Clip) );
                float4 ramp = tex1D(_RampTex,dissolveuv); 
                final *= ramp;
                return final;
                #endif

                return final;
                
            }
            ENDCG
        }

        Pass
        {
            Stencil
        {
            Ref 100
            Comp NotEqual
            Pass Replace 
        }

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Shadow;
            float _X;
            float _Z;
            float _ShadowAlpha;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                float4 posWS = mul(unity_ObjectToWorld, v.vertex);
                float posWSY = posWS.y;
                posWS.y = _Shadow;
                posWS.xz += fixed2(_X,_Z) * (posWSY - _Shadow);
                
                o.pos = mul(UNITY_MATRIX_VP, posWS);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 c = 0;
                c.a = _ShadowAlpha;
                return c;
                
            }
            ENDCG
        }

     }

    // Fallback "Legacy Shaders/VertexLit"
    FallBack "Diffuse" 
}
