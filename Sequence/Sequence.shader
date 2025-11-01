Shader "URP/Sequence"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcFactor ("SrcFactor", int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstFactor ("DstFactor", int) = 0
        _BaseColor ("BaseColor", Color) = (1,1,1,1)
        [NoScaleOffset]_BaseMap ("BaseMap", 2D) = "white" {}
        _Sequence ("Row(X) Cloum(Y) Speed(U)", vector) = (4,4,2,0)

        _Position("Position", Vector) = (0,0,0,1)
    }

    SubShader
    {
       Tags 
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
        }

        Cull Off
        Blend [_SrcFactor] [_DstFactor]
        Pass
        {
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
            };

            struct Varyings
            {
                float4 vertexCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexOS: TEXCOORD1;

                //雾效
                float fogCoord : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half4 _Sequence;
            half4 _Position;
            CBUFFER_END
            
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST;

            Varyings vert (Attributes v)
            {
                Varyings o;

                //求三个基向量
                // float3 cameraPosOS = mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos,1)).xyz;
                // float3 viewDirt = cameraPosOS - float3(0,0,0);
                float3 viewDirt = mul(GetWorldToObjectMatrix(), _Position);
                //计算摄像机在物体本地空间的向量
                viewDirt = normalize(viewDirt);
                float3 upDirt = float3(0,1,0);
                float3 rightDirt = cross(viewDirt, upDirt);
                upDirt = cross(rightDirt, viewDirt);

                //矩阵的写法
                // float4x4 M = float4x4(
                //     rightDirt.x,upDirt.x,viewDirt.x,0,
                //     rightDirt.y,upDirt.y,viewDirt.y,0,
                //     rightDirt.z,upDirt.z,viewDirt.z,0,
                //     0,0,0,1
                // );
                // float4x4 M = float4x4(
                //     rightDirt,0,
                //     upDirt,0,
                //     viewDirt,0,
                //     0,0,0,1
                // );

                // float3 newVertex = mul(M, v.vertexOS);

                // //向量乘法的写法
                float3 newVertex = rightDirt * v.vertexOS.x + upDirt * v.vertexOS.y + viewDirt * v.vertexOS.z;


                o.vertexCS = TransformObjectToHClip(newVertex);
                o.uv = float2(v.uv.x/_Sequence.y , v.uv.y/_Sequence.x + 1/_Sequence.x * (_Sequence.x-1)); 
                o.uv.x += frac(1/_Sequence.y * floor(_Time.y * _Sequence.z));
                o.uv.y -= frac(1/_Sequence.x * floor(_Time.y * _Sequence.z/_Sequence.y));


                o.fogCoord = ComputeFogFactor(o.vertexCS.z);
                //通过裁剪空间的z值计算雾效的远近关系
                
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 c;
                half4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseCol * _BaseColor;
                //雾效
                // c.rgb = MixFog(c, i.fogCoord);
                return c;
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
        }

        Cull Off
        Blend [_SrcFactor] [_DstFactor]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertexOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertexCS: SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            };

            
            sampler2D _BaseMap;
            half4 _BaseColor;
            half4 _Sequence;
            half4 _Position;
            

            v2f vert (appdata v)
            {
                
                v2f o;

                float3 viewDirt = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                viewDirt = normalize(viewDirt);
                float3 upDirt = float3(0,1,0);
                float3 rightDirt = cross(viewDirt, upDirt);
                upDirt = cross(rightDirt, viewDirt);
                float3 newVertex = rightDirt * v.vertexOS.x + upDirt * v.vertexOS.y + viewDirt * v.vertexOS.z;

                o.vertexCS = UnityObjectToClipPos(newVertex);

                o.uv = float2(v.uv.x/_Sequence.y , v.uv.y/_Sequence.x + 1/_Sequence.x * (_Sequence.x-1)); 
                o.uv.x += frac(1/_Sequence.y * floor(_Time.y * _Sequence.z));
                o.uv.y -= frac(1/_Sequence.x * floor(_Time.y * _Sequence.z/_Sequence.y));

                UNITY_TRANSFER_FOG(o,o.vertexCS);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 c = tex2D(_BaseMap, i.uv);

                // UNITY_APPLY_FOG(i.fogCoord, c);

                return c;
            }
            ENDCG
        }
    }
}
