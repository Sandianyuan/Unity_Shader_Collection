Shader "Unlit/UV"
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
        _Clip  ("Clip", Range(-0.1,0.8)) = 0

        [Space(20)]
        _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        _Power("Power", float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" }
        Blend Off
        Cull Back
        
        UsePass "Unlit/XRay/XRay"

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
                float4 final = 2 * tex + _Color;

                #if _DISSOLVEENABLED_ON

                float4 dissolve = tex2D(_DissolveTex, i.uv.zw);
                clip (dissolve.r - _Clip);
                float dissolveuv = saturate ( (dissolve.r - _Clip) / (_Clip+0.1 - _Clip) );
                float4 ramp = tex1D(_RampTex,dissolveuv); 
                final *= ramp;
                
                #endif

                return final;
                
            }
            ENDCG
        }
    }
    FallBack "Diffuse" 
}
