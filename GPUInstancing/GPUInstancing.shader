Shader "Unlit/GPU"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing        //1.开启GPU实例化
            #include "UnityCG.cginc"

            // float4 _Color;
            UNITY_INSTANCING_BUFFER_START(prop)     //4.名为prop常量寄存器开始  BUFFER(寄存器)
            UNITY_DEFINE_INSTANCED_PROP(float4, _Color)     //5.存入需要的实例化的属性
            UNITY_INSTANCING_BUFFER_END(prop)       //4.名为prop常量寄存器结束

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID //2.定义instanceID来储存每个对象的顶点属性
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 wPos : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID  //2.             
            };

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);  //3.访问instanceID
                v2f o;
                UNITY_TRANSFER_INSTANCE_ID(v,o);  //6.将instanceID传递给输出结构体(o.instanceID = v.instanceID)

                
                o.pos = UnityObjectToClipPos(v.vertex);
                o.wPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);  //3.在片段着色器用上的时候再加
                float4 col = UNITY_ACCESS_INSTANCED_PROP(prop, _Color);  //7.访问实例化的属性

                return i.wPos.y*0.15 + col;
            }
            ENDCG
        }
    }
}
