Shader "Unlit/Globaillumination"
{
    Properties
    {
        _Albedo("Albedo", range(0,1)) = 1
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityLightingCommon.cginc"
            #include "UnityStandardUtils.cginc"
            #include "../Mycginc/MyGlobaillumination.cginc"

            fixed _Albedo; 

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;

                //当Baked GI 或 Realtime GI 开启
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                float4 texcoord1: TEXCOORD1; 
                #endif

                float4 texcoord2: TEXCOORD2; //用于实时阴影采样的UV
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 posWS : TEXCOORD0; 
                float3 normalWS : NORMAL;

                #if defined(LIGHTMAP_ON)  || defined(DYNAMICLIGHTMAP_ON)
                float4 lightmapUV : TEXCOORD1; 
                #endif

                //同时定义灯光衰减以及实时阴影采样所需的插值器
                UNITY_LIGHTING_COORDS(2,3)

                #ifndef LIGHTMAP_ON  //当此对象没有开启静态烘焙
                    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                float3 sh : TEXCOORD4; 
                    #endif
                #endif
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex); 
                o.normalWS = UnityObjectToWorldNormal(v.normal);

                //Baked GI的 Tilling和Offset
                #if defined(LIGHTMAP_ON)
                o.lightmapUV.xy = v.texcoord1 * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif

                //Realtime GI的 Tilling和Offset
                #if defined(DYNAMICLIGHTMAP_ON)
                o.lightmapUV.zw = v.texcoord1 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif

                //处理灯光衰减以及实时阴影采样
                UNITY_TRANSFER_LIGHTING(o, v.texcoord2.xy);

                //球谐光照和顶点光照的计算
                //Sh/ambient and vertex lights
                #ifndef LIGHTMAP_ON  //当此对象没有开启静态烘焙
                    #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                        o.sh = 0;
                        //近似模拟非重要级别的点光在逐顶点上的光照效果
                        #ifdef VERTEXLIGHT_ON
                            o.sh += Shade4PointLights(
                            unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
                            unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
                            unity_4LightAtten0,o.posWS,o.normalWS
                        );
                        #endif
                        o.sh = ShadeSHPerVertex(o.normalWS,o.sh);
                    #endif
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
               //1.计算灯光衰减
               //2.实时阴影的采样
                UNITY_LIGHT_ATTENUATION(atten, i, i.posWS);

                SurfaceOutput o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutput, o);  //初始化
                o.Normal = i.normalWS; 
                o.Albedo = _Albedo; 

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.light.color = _LightColor0;
                gi.light.dir = normalize(_WorldSpaceLightPos0.xyz);
                gi.indirect.diffuse = 0;
                gi.indirect.specular = 0;

                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = i.posWS;
                giInput.worldViewDir = normalize(_WorldSpaceCameraPos - i.posWS);
                giInput.atten = atten; 

                #if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
                giInput.ambient = i.sh;
                #else
                giInput.ambient = 0;
                #endif

                #if defined(LIGHTMAP_ON)  || defined(DYNAMICLIGHTMAP_ON)
                giInput.lightmapUV = i.lightmapUV;
                #endif

                //GI间接光照计算，数据存储在gi中
                // LightingLambert_GI1(o,giInput,gi);
                gi = UnityGI_Base1(giInput,1, i.normalWS);


                //GI直接光照计算
                fixed4 c = LightingLambert1 (o, gi);
                return c;

                //     #if UNITY_SHOULD_SAMPLE_SH
                //     float3 shColor = ShadeSHPerPixel(i.normalWS, 0, i.posWS);
                //     return fixed4(shColor, 1); // 直接输出球谐颜色
                // #else
                //     return fixed4(0,0,1,1); // 蓝色表示没有SH
                // #endif
                
            }
            ENDCG
        }

        //投射阴影的Pass
        Pass
        {
            Tags {"LightMode" = "ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _shadowcaster
            #pragma multi_compile _ _DISSOLVEENABLED_ON 
            #include "UnityCG.cginc"
                
    
            sampler2D _DissolveTex;
            float4 _DissolveTex_ST;
            fixed  _Clip;
    
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float4 uv : TEXCOORD0;
            };
    
            struct v2f
            {
                float4 uv : TEXCOORD0;
                V2F_SHADOW_CASTER;
            };
    
            v2f vert (appdata v)
            {
                v2f o;
                o.uv.zw = TRANSFORM_TEX(v.uv, _DissolveTex);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }
    
            fixed4 frag (v2f i) : SV_Target
            {
                #if _DISSOLVEENABLED_ON

                float4 dissolve = tex2D(_DissolveTex, i.uv.zw);
                clip (dissolve.r - _Clip);
                #endif

                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
    
        }

        //此Pass用于计算光照的间接光反弹
        //在正常渲染不会使用此 就烘焙的时候使用
        Pass
        {
            Name "META"
            Tags { "LightMode" = "Meta" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"
            #include "UnityMetaPass.cginc"

            
            fixed4 _Color;

            struct v2f
            {
                float4 pos : SV_POSITION;
            };


            v2f vert (appdata_full v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f,o);
                o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);
                return o;
            }


            half4 frag (v2f i) : SV_Target
            {
                UnityMetaInput metaIN;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);

                metaIN.Albedo = 1;
                metaIN.Emission = _Color;

                return UnityMetaFragment(metaIN);
            }
            ENDCG
        }
        
    }
    CustomEditor "LegacyIlluminShaderGUI"
}
