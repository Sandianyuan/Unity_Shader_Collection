Shader "Unlit/XRay"
{
    Properties
    {
        _FresnelColor("Color", Color) = (1,1,1,1)
        _Power("Power", float) = 1
    }
    SubShader
    {
        // ZWrite Off
        Offset 0, 0
       
        Pass
        {   
            Name "XRay"
            
            Tags { "Quene"="Transparent" }
            Blend One One
            ZTest Greater
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            

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
                float3 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
            };
            
            half4 _FresnelColor;
            float _Power;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half3 V = normalize(_WorldSpaceCameraPos - i.posWS);
                half3 N = normalize(i.nDirWS); 
                half VdotN = dot(V, N);
                half fresnel = pow(1 - VdotN, _Power);
                half4 final = _FresnelColor * fresnel;
                // final.a = fresnel;

                half v = frac(i.posWS.y * 5 * _Time.x);
                final *= v;
                
                return final;
            }
            ENDCG
        }
    }
}
