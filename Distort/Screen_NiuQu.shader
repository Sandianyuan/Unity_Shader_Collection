Shader "Unlit/Screen_NiuQu"
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
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
            };


            v2f vert (
                float4 vertex : POSITION,
                float2 uv : TEXCOORD0,
                out float4 pos : SV_POSITION
            )
            {
                v2f o;
                pos = UnityObjectToClipPos(vertex);
                o.uv = TRANSFORM_TEX(uv, _DistortTex) + float2(_UVSpeedX, _UVSpeedY) * _Time.x;
                return o;
            }

            fixed4 frag (v2f i,UNITY_VPOS_TYPE screenPos:VPOS) : SV_Target
            {
                half2 screenUV = screenPos.xy/_ScreenParams;

                half2 distortUV = tex2D(_DistortTex,i.uv).r;
                half2 uv = lerp(screenUV,distortUV, _Distort);

                half4 grabTex = tex2D(_GrabTex,uv);

                return grabTex;
            }
            ENDCG
        }
    }
}
