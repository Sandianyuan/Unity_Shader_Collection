Shader "URP/EngineShield"
{
    Properties
    {
        [Header(Base)]
        _BaseMap ("BaseMap", 2D) = "white" {}
        _FresnelColor ("FresnelColor", Color) = (0,1,1,1)
        [PowerSlider(3)]_FresnelPower ("FresnelPower", Range(0,10)) = 3

        [Header(HighLight)]
        _HighLightColor ("HighLightColor", Color) = (0,1,1,1)
        _HighLightFade ("HighlightFade", Range(0,10)) = 3

        [Header(Distort)]
        _Tiling ("DistortTiling", Range(1,10)) = 5
        _Distort("Distort", Range(0,1)) = 0.4
    }

    SubShader
    {
       Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent+0"
            // "IgnoreProjector" = "True"
            // "ForceNoShadowCasting" = "True"
        }
        // Cull Back
        ZWrite Off
        // ZTest LEqual
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            // Blend One One
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct Attributes
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 vertexCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 vertexOS: TEXCOORD1;
                float3 vertexVS: TEXCOORD3;
                float3 normalWS : TEXCOORD4;
                float3 viewWS : TEXCOORD5;

                //雾效
                float fogCoord : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _HighLightColor;
            half _HighLightFade;
            half4 _FresnelColor;
            half _FresnelPower;
            half _Tiling;
            half _Distort;
            float4 _BaseMap_ST;
            CBUFFER_END
            
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D (_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D (_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                //获取能量罩观察空间的z值
                float3 vertexWS = TransformObjectToWorld(v.vertexOS.xyz);
                o.vertexVS = TransformWorldToView(vertexWS);

                o.viewWS = normalize(_WorldSpaceCameraPos - vertexWS);
                o.normalWS = TransformObjectToWorldNormal(v.normal);

                o.vertexCS = TransformObjectToHClip(v.vertexOS.xyz);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BaseMap);

                o.uv.xy = v.uv;

                o.fogCoord = ComputeFogFactor(o.vertexCS.z);
                //通过裁剪空间的z值计算雾效的远近关系
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float4 c;
                float2 screenUV = i.vertexCS.xy / _ScreenParams.xy;
                half4 depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                //获取片段对应深度图中的像素在观察空间的Z值
                half depth = LinearEyeDepth(depthMap.r, _ZBufferParams);
                 
                //如果能量罩片段的Z值小于深度图对应像素的Z值，说明能量罩片段在物体前面
                half4 hightlight = depth + i.vertexVS.z;
                //depth是正值，i.vertexVS.z是负值(因为在观察空间中，z轴是从屏幕指向场景的,右手坐标系)
                hightlight *= _HighLightFade;
                hightlight = 1-hightlight;
                hightlight *= _HighLightColor;
                hightlight = saturate(hightlight);
                hightlight.a = hightlight.r;
                c = hightlight;

                //fresnel外发光
                //pow(max(0,dot(N,V)),intensity)
                half3 N = i.normalWS; 
                half3 V = i.viewWS;
                half NdotV = 1 - max(0,dot(N,V));
                half4 fresnel = pow(abs(NdotV), _FresnelPower);
                fresnel *= _FresnelColor;
                c += fresnel;
                

                half4 baseMap = SAMPLE_TEXTURE2D(1-_BaseMap, sampler_BaseMap, i.uv.zw + float2(0,_Time.y));
                c += baseMap * 0.01;

                //当前帧的抓屏
                float2 distortUV = lerp(screenUV,baseMap.rr,_Distort);
                half4 opaqueTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, distortUV);
                half flowMask = frac(i.uv.y * _Tiling + _Time.y);
                half4 distort = opaqueTex * flowMask; //扭曲
                c += distort;
                
                return c;

                // //雾效
                // // c.rgb = MixFog(c, i.fogCoord);
            }
            ENDHLSL
        }
    }

    SubShader
    {
       Tags 
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent+0"
            // "IgnoreProjector" = "True"
            // "ForceNoShadowCasting" = "True"
        }
        // Cull Back
        ZWrite Off
        // ZTest LEqual

        GrabPass{"_GrabTex"}

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            // Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct Attributes
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 vertexCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 vertexOS: TEXCOORD1;
                float3 vertexVS: TEXCOORD3;
                float3 normalWS : TEXCOORD4;
                float3 viewWS : TEXCOORD5;

                //雾效
                float fogCoord : TEXCOORD2;
            };

            
            half4 _HighLightColor;
            half _HighLightFade;
            half4 _FresnelColor;
            half _FresnelPower;
            half _Tiling;
            half _Distort;
            
            sampler2D _BaseMap;float4 _BaseMap_ST;
            sampler2D _CameraDepthTexture;
            sampler2D _GrabTex;

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                //获取能量罩观察空间的z值
                float3 vertexWS = mul(unity_ObjectToWorld,v.vertexOS);
                o.vertexVS = mul(unity_WorldToCamera,float4(vertexWS,1)).xyz;

                o.viewWS = normalize(_WorldSpaceCameraPos - vertexWS);
                o.normalWS = UnityObjectToWorldNormal(v.normal);

                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.uv.zw = TRANSFORM_TEX(v.uv, _BaseMap);

                o.uv.xy = v.uv;

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float4 c;
                float2 screenUV = i.vertexCS.xy / _ScreenParams.xy;
                half4 depthMap = tex2D(_CameraDepthTexture, screenUV);
                //获取片段对应深度图中的像素在观察空间的Z值
                half depth = LinearEyeDepth(depthMap.r);
                 
                //如果能量罩片段的Z值小于深度图对应像素的Z值，说明能量罩片段在物体前面
                half4 hightlight = depth + i.vertexVS.z;
                //depth是正值，i.vertexVS.z是负值(因为在观察空间中，z轴是从屏幕指向场景的,右手坐标系)
                hightlight *= _HighLightFade;
                hightlight = 1-hightlight;
                hightlight *= _HighLightColor;
                hightlight = saturate(hightlight);
                hightlight.a = hightlight.r;
                c = hightlight;

                //fresnel外发光
                //pow(max(0,dot(N,V)),intensity)
                half3 N = i.normalWS; 
                half3 V = i.viewWS;
                half NdotV = 1 - max(0,dot(N,V));
                half4 fresnel = pow(abs(NdotV), _FresnelPower);
                fresnel *= _FresnelColor;
                c += fresnel;
                

                half4 baseMap = tex2D(_BaseMap, i.uv.zw + float2(0,_Time.y));
                c += (baseMap) * 0.01;

                //当前帧的抓屏
                float2 distortUV = lerp(screenUV,baseMap.rr,_Distort);
                half4 opaqueTex = tex2D(_GrabTex, distortUV);
                half flowMask = frac(i.uv.y * _Tiling + _Time.y);
                half4 distort = opaqueTex * flowMask; //扭曲
                c += distort;
                
                return c;

                // //雾效
                // // c.rgb = MixFog(c, i.fogCoord);
            }
            ENDCG
        }
    }
}
