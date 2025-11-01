Shader "Unlit/LightModel"
{
    Properties
    {
        _DiffuseIntensity("Diffuse Intensity", float) = 1.0
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecularIntensity("Specular Intensity", float) = 1.0
        _Shininess("Shininess", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        

        Pass
        {
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc" //灯光封装
            #pragma multi_compile_fwdbase

            half _DiffuseIntensity;
            half4 _SpecularColor;
            half _SpecularIntensity;
            half _Shininess;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {    
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float4 posWS : TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.posWS = mul(unity_ObjectToWorld,v.vertex);  
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Diffuse = Ambient + Kd * LightColor * max(0, dot(N, L))
                // half4 ambient = unity_AmbientSky;   //环境光颜色
                // half Kd = _DiffuseIntensity;        //光强
                half4 LightColor = _LightColor0;    //灯光颜色
                half3 N = normalize(i.nDirWS); //法线
                half3 L = normalize(_WorldSpaceLightPos0.xyz); //光源方向
                //half4 diffuse = ambient + Kd * LightColor * dot(N, L) * 0.5 + 0.5;
                half4 diffuse = _DiffuseIntensity * LightColor * max(0, dot(N, L)); 

                //Spcular = Ks * SpecularColor * pow(max(0, dot(R, V)), Shininess)
                half3 V = normalize(_WorldSpaceCameraPos - i.posWS.xyz); 
                half3 R = reflect(-L, N); 
                half4 specular = _SpecularIntensity * _SpecularColor * pow(max(0, dot(R, V)), _Shininess);
                
                //Spcular = Ks * SpecularColor * pow(max(0, dot(N, H)), Shininess)
                half3 H = normalize(L + V); 
                half4 Blinnspecular = _SpecularIntensity * _SpecularColor * pow(max(0, dot(N, H)), _Shininess);

                half4 finalColor = diffuse + Blinnspecular;
                return fixed4(finalColor.rgb,1);
            }
            ENDCG
        }

        Pass
        {
            Tags{"LightMode"="ForwardAdd"}
            Blend One One //默认是One Zero，这样会把平行光的效果遮挡住

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            // #pragma multi_compile POINT SPOT
            #include "AutoLight.cginc" //访问衰减
            #include "UnityCG.cginc"
            #include "Lighting.cginc" //灯光封装


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 nDirWS : TEXCOORD1;
                float4 posWS : TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.posWS = mul(unity_ObjectToWorld,v.vertex);  //世界坐标
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // float3 lightCoord = mul(unity_WorldToLight, float4(i.posWS,1)).xyz; //世界坐标转光源坐标
                // fixed2 atten = tex2D(_LightAttenTex, dot(lightCoord,lightCoord)); //采样衰减贴图
                UNITY_LIGHT_ATTENUATION(atten,i,i.posWS.xyz); //计算衰减

                //Diffuse = Ambient + Kd * LightColor * max(0, dot(N, L))
                // half4 ambient = unity_AmbientSky;   //环境光颜色
                // half Kd = _DiffuseIntensity;        //光强
                half4 LightColor = _LightColor0 * atten;    //灯光颜色
                half3 N = normalize(i.nDirWS); //法线
                half3 L = normalize(_WorldSpaceLightPos0.xyz - i.posWS.xyz); //光源方向
                // half4 diffuse = ambient + Kd * LightColor * max(0, dot(N, L));
                half4 diffuse = LightColor * max(0, dot(N, L));
                return fixed4(diffuse.rgb,1);
            }
            ENDCG
        }
    }
}
