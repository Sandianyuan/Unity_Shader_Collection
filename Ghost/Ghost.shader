Shader "URP/Ghost"
{
    Properties
    {
        _FresnelColor("Color", Color) = (1, 1, 1, 1)
        _Fresnel("Fade(X) Intensity(Y) Offset(Z) MaskIntensity(Z)",vector) = (5,2,0,0)
        _Adimation("Repeat(XZ) Inensity(YW)", vector) = (3,0.001,3,0.001)
    }
    SubShader
    {
        Tags 
        {
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType"="Transparent" //告诉unity是透明渲染
            "Queue" = "Transparent" //渲染队列
        }
        Blend One One
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            struct Attributes
            {
                float4 vertexOS: POSITION;
                half3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 vertexCS: SV_POSITION;
                half3 normalWS : TEXCOORD0;
                float3 vertexWS: TEXCOORD1;
                float4 vertexOS: TEXCOORD2; 

            };

            CBUFFER_START(UnityPerMaterial)
            half4 _Fresnel;
            half4 _FresnelColor;
            half4 _Adimation;
            CBUFFER_END


            Varyings vert (Attributes v)
            {
                Varyings o;

                //顶点偏移动画
                v.vertexOS.x += sin(( v.vertexOS.y * 100 +_Time.y )* _Adimation.x) * _Adimation.y;
                v.vertexOS.z += sin((v.vertexOS.y * 100 + _Time.y )* _Adimation.z) * _Adimation.w;

                // Bulid-in
                // o.vertexCS = UnityObjectToClipPos(v.vertex);
                // o.normalWS = UnityObjectToWorldNormal(v.normalOS);
                o.vertexCS= TransformObjectToHClip(v.vertexOS);
                o.vertexWS = TransformObjectToWorld(v.vertexOS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                o.vertexOS = v.vertexOS;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                
                half3 N = normalize(i.normalWS);
                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.vertexWS.xyz);
                half dotNV = 1 - saturate(dot(N, V));
                half4 fresnel = pow(dotNV, _Fresnel.x) * _Fresnel.y * _FresnelColor;

                //创建从上到下的黑白遮罩
                half mask =  saturate(i.vertexOS.y * 100 + i.vertexOS.z * 100 + _Fresnel.z); 
                fresnel = lerp(fresnel, _FresnelColor*mask, mask*_Fresnel.w);

                half4 c = fresnel * mask;

                return c;
            }
            ENDHLSL
        }
    }

    SubShader
    {
        Tags 
        {
            "RenderType"="Transparent" //告诉unity是透明渲染
            "Queue" = "Transparent" //渲染队列
        }
        Blend One One
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct Attributes
            {
                float4 vertexOS: POSITION;
                half3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 vertexCS: SV_POSITION;
                half3 normalWS : TEXCOORD0;
                float3 vertexWS: TEXCOORD1;
                float4 vertexOS: TEXCOORD2; 

            };

            half4 _Fresnel;
            half4 _FresnelColor;
            half4 _Adimation;


            Varyings vert (Attributes v)
            {
                Varyings o;

                //顶点偏移动画
                v.vertexOS.x += sin(( v.vertexOS.y * 100 +_Time.y )* _Adimation.x) * _Adimation.y;
                v.vertexOS.z += sin((v.vertexOS.y * 100 + _Time.y )* _Adimation.z) * _Adimation.w;

                // Bulid-in
                o.vertexCS = UnityObjectToClipPos(v.vertexOS);
                o.normalWS = UnityObjectToWorldNormal(v.normalOS);
                o.normalWS = mul(unity_ObjectToWorld,v.normalOS);

                o.vertexOS = v.vertexOS;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                
                half3 N = normalize(i.normalWS);
                half3 V = normalize(_WorldSpaceCameraPos.xyz - i.vertexWS.xyz);
                half dotNV = 1 - saturate(dot(N, V));
                half4 fresnel = pow(dotNV, _Fresnel.x) * _Fresnel.y * _FresnelColor;

                //创建从上到下的黑白遮罩
                half mask =  saturate(i.vertexOS.y * 100 + i.vertexOS.z * 100 + _Fresnel.z); 
                fresnel = lerp(fresnel, _FresnelColor*mask, mask*_Fresnel.w);

                half4 c = fresnel * mask;

                return c;
            }
            ENDCG
        }
    }
}
