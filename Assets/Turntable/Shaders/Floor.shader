Shader "Turntable/Floor"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1, 1, 1, 1)

        [Header(Rings)]
        _RingWidth("Width", Float) = 0.1
        _RingFreq("Frequency", Float) = 4
        _RingSpeed("Animation Speed", Float) = 1

        [Header(Animation)]
        [Toggle(_USE_SYSTEM_TIME)] _UseSystemTime("Use System Time", Int) = 1
        _LocalTime("Material Time", Float) = 0
    }

    CGINCLUDE

    #include "UnityCG.cginc"
    #include "SimplexNoise2D.hlsl"

    float4 _Color;

    float _RingWidth;
    float _RingFreq;
    float _RingSpeed;
    float _LocalTime;

    float Rings(float2 p, float t)
    {
        float l = length(p);
        float n = snoise(float2(l * _RingFreq, t * _RingSpeed));
        float y = smoothstep(-_RingWidth, 0, n);
        y *= smoothstep(0, _RingWidth, _RingWidth - n);
        return y * (1 - smoothstep(0.95, 1, l));
    }

    float2 Vertex(
        float4 position : POSITION,
        float2 texcoord : TEXCOORD,
        out float4 outPosition : SV_Position
    ) : TEXCOORD
    {
        outPosition = UnityObjectToClipPos(position);
        return texcoord;
    }

    half4 Fragment(float2 uv : TEXCOORD) : SV_Target
    {
    #if _USE_SYSTEM_TIME
        float t = _Time.y;
    #else
        float t = _LocalTime;
    #endif

        // Antialiasing with multi-point sampling

        float2 duv_dx = ddx(uv);
        float2 duv_dy = ddy(uv);

        uint2 fw = clamp(float2(length(duv_dx), length(duv_dy)) * 1024, 1, 8);

        duv_dx /= fw.x;
        duv_dy /= fw.y;

        uv += duv_dx / 2;
        uv += duv_dy / 2;

        float o = 0;

        UNITY_LOOP for (uint iy = 0; iy < fw.y; iy++)
        {
            UNITY_LOOP for (uint ix = 0; ix < fw.x; ix++)
            {
                float2 uv2 = uv + duv_dx * ix + duv_dy * iy;
                o += Rings(uv2 * 2 - 1, t);
            }
        }

        return _Color * o / (fw.x * fw.y);
    }

    ENDCG

    SubShader
    {
        Tags { "Queue"="Transparent" }
        Pass
        {
            Blend One One
            ZWrite Off
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma shader_feature _USE_SYSTEM_TIME
            ENDCG
        }
    }
}
