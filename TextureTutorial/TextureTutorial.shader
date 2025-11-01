Shader "Unlit/TextureTutorial"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [IntRange]_MipMap ("MipMap", Range(0, 10)) = 0.0
        [KeywordEnum(Repeat,Clamp)]_WrapMode("WrapMode",int) = 0

        _CubeMap ("CubeMap", Cube) = "white" {}

        [Normal]_NormalTex ("NormalMap", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _WRAPMODE_REPEAT _WRAPMODE_CLAMP

            #include "UnityCG.cginc"
            #include "HLSLSupport.cginc"
            #include "UnityShaderVariables.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _MipMap;

            samplerCUBE _CubeMap;

            sampler2D _NormalTex;

            // samplerCUBE unity_SpecCube0;
            // float4 unity_SpecCube0_HDR;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                float3 normal : NORMAL;

                float4 tangent : TANGENT; //w储存tangent的方向
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                float3 posOS : TEXCOORD1; 
                float3 posWS : TEXCOORD2;
                float3 norWS : TEXCOORD3; 

                //三个float3向量组合成转置矩阵
                float3 tSpace0 : TEXCOORD4; 
                float3 tSpace1 : TEXCOORD5;
                float3 tSpace2 : TEXCOORD6;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.posOS = v.vertex.xyz;
                o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.norWS = UnityObjectToWorldNormal(v.normal);

                //切线转置矩阵的计算
                //切线从局部空间转到世界空间
                half3 tangentWS = UnityObjectToWorldDir(v.tangent.xyz);
                //tangent.w决定副切线方向
                fixed tangenSign = v.tangent.w * unity_WorldTransformParams.w;
                //由叉积计算副切线
                half3 BinormalWS = cross(o.norWS, tangentWS) * tangenSign;
                //切线矩阵
                o.tSpace0 = float3(tangentWS.x, BinormalWS.x, o.norWS.x);
                o.tSpace1 = float3(tangentWS.y, BinormalWS.y, o.norWS.y);
                o.tSpace2 = float3(tangentWS.z, BinormalWS.z, o.norWS.z);


                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                #if _WRAPMODE_REPEAT 
                i.uv = frac(i.uv);
                #elif _WRAPMODE_CLAMP
                //方法一
                i.uv = clamp(i.uv,0,1);
                //方法二
                //i.uv = saturate(i.uv);
                #endif

                //法线纹理
                float3 normalTex = UnpackNormal(tex2D(_NormalTex, i.uv));
                //max(0,dot(N,L))
                float3 N1 = normalize(normalTex);
                float3 L = _WorldSpaceLightPos0.xyz;
                // float NdotL = max(0, dot(N1, L));
                // return NdotL;

                //矩阵相乘,使得法线纹理下的法线从切线空间转到世界空间
                float3 N1WS = float3(
                    dot(i.tSpace0, normalTex),
                    dot(i.tSpace1, normalTex),
                    dot(i.tSpace2, normalTex)
                );
                float NdotL = max(0, dot(N1WS, L));
                // return NdotL;

                //MipMap
                float4 uvMipMap = float4(i.uv, 0, _MipMap);
                fixed4 c = tex2Dlod(_MainTex, uvMipMap);
                
                //CubeMap
                float4 CubeMap = texCUBE(_CubeMap, i.posOS);
                //环境映射
                float3 V = normalize(UnityWorldSpaceViewDir(i.posWS));
                float3 N = normalize(N1WS);
                float3 R = reflect(-V, N);
                CubeMap = texCUBE(_CubeMap, R);
                return CubeMap;


                // half3 cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, R);
                // half4 skyColor = DecodeHDR(cubemap,unity_SpecCube0_HDR).rgb;
                // return skyColor;
                
            }
            ENDCG
        }
    }
}
