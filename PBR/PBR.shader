Shader "Unlit/PBR"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [Normal]_NormalTex ("NormalMap", 2D) = "bump" {}
        _MetallicTex ("Metallic(R) Smoothness(G) AO(B)", 2D) = "white" {}
        _Metallic ("Metallic", Range(0, 1)) = 0.0
        _Glossiness ("Smoothness", Range(0, 1)) = 0.5
        _AO ("AO", Range(0, 1)) = 1.0

    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200

        Pass {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0C
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            #include "../Mycginc/MyPBR.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            sampler2D _MetallicTex;
            half _Metallic;
            half _Glossiness;
            fixed4 _Color;
            half _AO;


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 texcoord2 : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0; // _MainTex
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                #if UNITY_SHOULD_SAMPLE_SH
                half3 sh : TEXCOORD3; // SH
                #endif

                float3 tSpace0 : TEXCOORD4; // Tangent space
                float3 tSpace1 : TEXCOORD5; // Tangent space
                float3 tSpace2 : TEXCOORD6; // Tangent space

                UNITY_FOG_COORDS(7)
                UNITY_SHADOW_COORDS(8)
            };


            v2f vert (appdata v) {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o); //初始化
                o.pos = UnityObjectToClipPos(v.vertex); //将模型从OS>>CS齐次裁剪空间
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);

                //切线转置矩阵的计算
                //切线从局部空间转到世界空间
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                //tangent.w决定副切线方向
                fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                //由叉积计算副切线
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
                //切线矩阵
                o.tSpace0 = float3(worldTangent.x, worldBinormal.x, worldNormal.x);
                o.tSpace1 = float3(worldTangent.y, worldBinormal.y, worldNormal.y);
                o.tSpace2 = float3(worldTangent.z, worldBinormal.z, worldNormal.z);
                

                o.worldPos.xyz = worldPos;

                // SH / ambient and vertex lights
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                o.sh = 0;
                // Approximated illumination from non - important point lights
                #ifdef VERTEXLIGHT_ON
                o.sh += Shade4PointLights (
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, worldPos, worldNormal);
                #endif
                o.sh = ShadeSHPerVertex (worldNormal, o.sh);
                #endif


                UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy); 
                UNITY_TRANSFER_FOG(o, o.pos); 

                return o;
            }

            
            fixed4 frag (v2f i) : SV_Target {

                UNITY_EXTRACT_FOG(i);

                float3 worldPos = i.worldPos.xyz;


                SurfaceOutputStandard o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o); 
                fixed4 albedoTex = tex2D(_MainTex, i.uv.xy);
                o.Albedo = albedoTex.rgb * _Color.rgb;
                float3 normalTex = UnpackNormal(tex2D(_NormalTex, i.uv));
                float3 worldNormal = float3(dot(i.tSpace0, normalTex),dot(i.tSpace1, normalTex),dot(i.tSpace2, normalTex));
                o.Normal = worldNormal;
                o.Emission = 0.0;
                fixed4 metallicTex = tex2D(_MetallicTex, i.uv.xy);
                o.Metallic = metallicTex.r * _Metallic;
                o.Smoothness = metallicTex.g * _Glossiness;
                o.Occlusion = metallicTex.b * _AO; 
                o.Alpha = 1.0;
                

                // compute lighting & shadowing factor
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos)


                // Setup lighting environment
                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;
                gi.light.color = _LightColor0.rgb;
                gi.light.dir = _WorldSpaceLightPos0.xyz;
                
                // Call GI (lightmaps / SH / reflections) lighting function
                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                giInput.atten = atten;
                giInput.lightmapUV = 0.0;
                
                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                giInput.ambient = i.sh;
                #else
                giInput.ambient.rgb = 0.0;
                #endif

                giInput.probeHDR[0] = unity_SpecCube0_HDR;
                giInput.probeHDR[1] = unity_SpecCube1_HDR;
                //如果开启了反射探针的混合功能 和 反射探针的BoxProjection
                #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
                giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
                #endif
                #ifdef UNITY_SPECCUBE_BOX_PROJECTION
                giInput.boxMax[0] = unity_SpecCube0_BoxMax;
                giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
                giInput.boxMax[1] = unity_SpecCube1_BoxMax;
                giInput.boxMin[1] = unity_SpecCube1_BoxMin;
                giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif

                LightingStandard_GI1(o, giInput, gi);
                // return fixed4(gi.indirect.specular,1);

                //PBS的核心计算>LightingStandard
                fixed4 c = LightingStandard1 (o, giInput.worldViewDir, gi);

                //雾效
                UNITY_APPLY_FOG(_unity_fogCoord, c); 
                
                return c;
            }


            ENDCG

        }

    }
    FallBack "Diffuse"
}