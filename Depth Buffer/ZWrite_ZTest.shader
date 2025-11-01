Shader "Unlit/ZWrite_ZTest"
{
    Properties
    {
        [Header(Rending Options)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("SrcBlend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("DstBlend", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)]_Cull ("Cull", Float) = 2

        [Space(20)]
        [Enum(Off,0,On,1)]_ZWrite ("ZWrite", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_ZTest ("ZTest", Float) = 0

        [Space(20)]
        [Header(Main)]
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Intensity ("Intensity", Range(-4, 4)) = 1.0
        [Space(10)]
        _MainUVSpeedX ("MainUVSpeedX", Range(-10, 10)) = 0.0
        _MainUVSpeedY ("MainUVSpeedY", Range(-10, 10)) = 0.0

        [Space(20)]
        [Header(Mask)] //遮罩
        [Toggle]_MaskEnabled ("Mask Enabled", Float) = 0
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _MaskUVSpeedX ("MaskUVSpeedX", Range(-10, 10)) = 0.0
        _MaskUVSpeedY ("MaskUVSpeedY", Range(-10, 10)) = 0.0

        [Space(20)]
        [Header(Distort)]
        [MaterialToggle(DISTORTENABLED)]_DistortEnabled ("Distort Enabled", Float) = 0
        _DistortTex ("Distort Texture", 2D) = "white" {}
        _Distort("Distort", Range(0, 1)) = 0.0
        _DistortUVSpeedX ("DistortUVSpeedX", Range(-10, 10)) = 0.0
        _DistortUVSpeedY ("DistortUVSpeedY", Range(-10, 10)) = 0.0 //类似热扭曲的效果


    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Blend [_SrcBlend] [_DstBlend]
        Cull [_Cull]
        ZWrite [_ZWrite]
        ZTest [_ZTest]

        //去除背面
        // Pass{
        //     ZWrite ON
        //     ColorMask 0
        // }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ _MASKENABLED_ON
            #pragma shader_feature _ DISTORTENABLED
            #include "UnityCG.cginc"

            half4 _SrcBlend;
            half4 _DstBlend;
            half4 _Cull;

            sampler2D _MainTex; float4 _MainTex_ST;
            float4 _Color;
            half _Intensity;
            half _MainUVSpeedX;
            half _MainUVSpeedY;

            half _MaskEnabled;
            sampler2D _MaskTex; float4 _MaskTex_ST;
            half _MaskUVSpeedX;
            half _MaskUVSpeedY;

            half _DistortEnabled;
            sampler2D _DistortTex; float4 _DistortTex_ST;
            half _Distort;
            half _DistortUVSpeedX;
            half _DistortUVSpeedY;



            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex) + float2(_MainUVSpeedX, _MainUVSpeedY) * _Time.x; 
                //o.uv.xy = v.uv + _MainTex.xy + _MainTex.zw + float2(_MainUVSpeedX, _MainUVSpeedY) * _Time.y;
                
                #if _MASKENABLED_ON
                    o.uv.zw = TRANSFORM_TEX(v.uv, _MaskTex) + float2(_MaskUVSpeedX, _MaskUVSpeedY) * _Time.x*5;
                #endif

                #if DISTORTENABLED
                    o.uv2 = TRANSFORM_TEX(v.uv, _DistortTex) + float2(_DistortUVSpeedX, _DistortUVSpeedY) * _Time.x;
                #endif
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 distort = i.uv.xy;

                #if DISTORTENABLED
                    float4 distortTex = tex2D (_DistortTex, i.uv2).g;
                    distort = lerp(i.uv,distortTex, _Distort);
                #endif

                float4 tex = tex2D (_MainTex, distort).r; //扰动
                float4 final = tex * _Color * _Intensity;

                #if _MASKENABLED_ON
                    float4 maskTex = tex2D (_MaskTex, i.uv.zw).g;
                    final = final * maskTex;
                #endif
                
                return final;
                
            }
            ENDCG
        }
    }
    FallBack "Diffuse" 
}
