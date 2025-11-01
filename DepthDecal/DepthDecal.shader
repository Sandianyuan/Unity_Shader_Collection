Shader "URP/DepthDecal"
{
     Properties
    {
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
    }

    SubShader
    {
       Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "Queue" = "Transparent+0"
        }
        Cull Off
        ZWrite Off

        Pass
        {
            Blend One One
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
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
            };

            struct Varyings
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexOS: TEXCOORD1;
                float3 vertexVS : TEXCOORD3;

                //雾效
                float fogCoord : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;
            CBUFFER_END
            
            TEXTURE2D (_BaseMap);//SAMPLER(sampler_BaseMap);
            #define smp _linear_clamp
            SAMPLER(smp);
            TEXTURE2D (_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                o.vertexCS = TransformObjectToHClip(v.vertexOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

                o.vertexOS = v.vertexOS;

                o.vertexVS = TransformWorldToView(TransformObjectToWorld(v.vertexOS.xyz));

                o.fogCoord = ComputeFogFactor(o.vertexCS.z);
                //通过裁剪空间的z值计算雾效的远近关系
                
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                //通过深度图求出像素所在VS中的z值
                //通过当前渲染的面片求出像素在VS下的坐标
                //通过以上两者求出深度图中的像素的XYZ坐标
                //通过此坐标转换面片模型的OS,把XY当作UV采样

                float2 screenUV = i.vertexCS.xy / _ScreenParams.xy;
                half depthMap = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV).r;
                half depthZ = LinearEyeDepth(depthMap, _ZBufferParams);

                float3 depthVS = 1;
                depthVS.xy = (i.vertexVS.xy * depthZ) / -i.vertexVS.z;
                depthVS.z = depthZ;

                //float3 depthWS = mul(unity_CameraToWorld,depthVS);
                float3 depthWS = ComputeWorldSpacePosition(screenUV, depthMap, UNITY_MATRIX_I_VP);
                float3 depthOS = mul(unity_WorldToObject, float4(depthWS, 1.0)).xyz;
                float2 uv = depthOS.xz + 0.5;

                half4 c;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, smp, uv);
                c = baseMap * _BaseColor;
                //雾效
                // c.rgb = MixFog(c, i.fogCoord);/作用于不透明对象
                //针对Blend One One模式
                c.rgb *= saturate(lerp(1,0,i.fogCoord)); //模拟雾效作用于透明对象
                return c;
            }
            ENDHLSL
        }
    }

    // SubShader
    // {
    //    Tags 
    //     {
    //         "IgnoreProjector" = "True"
    //         "RenderType" = "Transparent"
    //         "Queue" = "Transparent+0"
    //     }
    //     Cull Off
    //     ZWrite Off

    //     GrabPass{"_GrabTex"}

    //     Pass
    //     {
    //         Blend One One

    //         CGPROGRAM
    //         #pragma vertex vert
    //         #pragma fragment frag
    //         #pragma multi_compile_fog
    //         #include "UnityCG.cginc"

    //         struct Attributes
    //         {
    //             float4 vertexOS : POSITION;
    //             float2 uv : TEXCOORD0;
    //         };

    //         struct Varyings
    //         {
    //             float4 vertexCS : SV_POSITION;
    //             float2 uv : TEXCOORD0;
    //             float4 vertexOS: TEXCOORD1;
    //             float3 vertexVS : TEXCOORD3;

    //             //雾效
    //             UNITY_FOG_COORDS(2)
    //         };


    //         half4 _BaseColor;
    //         float4 _BaseMap_ST;
            
    //         sampler2D _BaseMap;
    //         sampler2D _CameraDepthTexture;
    //         sampler2D _GrabTex;

    //         Varyings vert (Attributes v)
    //         {
    //             Varyings o = (Varyings)0;

    //             o.vertexCS = UnityObjectToClipPos(v.vertexOS.xyz);
    //             o.uv = TRANSFORM_TEX(v.uv, _BaseMap);

    //             o.vertexOS = v.vertexOS;

    //             float3 vertexWS = mul(unity_ObjectToWorld,v.vertexOS);
    //             o.vertexVS = mul(unity_WorldToCamera,float4(vertexWS,1)).xyz;

    //             UNITY_TRANSFER_FOG(o,o.vertexCS);
                
                
    //             return o;
    //         }

    //         half4 frag (Varyings i) : SV_Target
    //         {
    //             //通过深度图求出像素所在VS中的z值
    //             //通过当前渲染的面片求出像素在VS下的坐标
    //             //通过以上两者求出深度图中的像素的XYZ坐标
    //             //通过此坐标转换面片模型的OS,把XY当作UV采样

    //             float2 screenUV = i.vertexCS.xy / _ScreenParams.xy;
    //             half depthMap = tex2D(_CameraDepthTexture, screenUV).r;
    //             half depthZ = LinearEyeDepth(depthMap.r);

    //             float3 depthVS = 1;
    //             depthVS.xy = (i.vertexVS.xy * depthZ) / -i.vertexVS.z;
    //             depthVS.z = depthZ;

    //             //float3 depthWS = mul(unity_CameraToWorld,depthVS);
    //             float3 depthWS = ComputeWorldSpacePosition(screenUV, depthMap, UNITY_MATRIX_I_VP);
    //             float3 depthOS = mul(unity_WorldToObject, float4(depthWS, 1.0)).xyz;
    //             float2 uv = depthOS.xz + 0.5;

    //             half4 c;
    //             half4 baseMap = tex2D(_BaseMap, uv);
    //             c = baseMap * _BaseColor;
    //             //雾效
    //             UNITY_APPLY_FOG(i.fogCoord, c);
    //             c.rgb *= saturate(lerp(1,0,i.fogCoord)); //模拟雾效作用于透明对象
    //             return c;
    //         }
    //         ENDCG
    //     }
    // }
}
