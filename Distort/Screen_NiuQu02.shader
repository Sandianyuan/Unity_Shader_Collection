Shader "Unlit/Screen_NiuQu02"
{
    Properties
    {
        _DistortTex ("Distort Texture", 2D) = "white" {}
        _Distort("Distort", Range(0, 1)) = 0.0 
        _UVSpeedX ("UVSpeedX", Range(-10, 10)) = 0.0
        _UVSpeedY ("UVSpeedY", Range(-10, 10)) = 0.0
    }
    SubShader
    {
        GrabPass{"_GrabTex"} //抓取屏幕为一张贴图
        Tags { "Queue" = "Transparent" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _GrabTex;
            sampler2D _DistortTex; float4 _DistortTex_ST;
            fixed _Distort;
            half _UVSpeedX;
            half _UVSpeedY;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 screenUV : TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);  //裁剪空间
                // o.pos = o.pos.xyz / o.pos.w;   //齐次裁剪空间（-1,1）立方体
                // o.pos = o.pos * 0.5 + 0.5;     //齐次裁剪空间》》屏幕（0,1）
                o.screenUV = ComputeScreenPos(o.pos); //屏幕坐标

                o.uv = TRANSFORM_TEX(v.uv, _DistortTex) + float2(_UVSpeedX, _UVSpeedY) * _Time.x;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // float2 screenUV = (i.screenUV.xy / i.screenUV.w) *0.5 +0.5;

                // half2 screenUV = screenPos.xy/_ScreenParams;

                half2 distortUV = tex2D(_DistortTex,i.uv).r;
                half2 uv = lerp(i.screenUV.xy/i.screenUV.w,distortUV, _Distort);

                half4 grabTex = tex2D(_GrabTex,uv);

                return grabTex;
            }
            ENDCG
        }
    }
}