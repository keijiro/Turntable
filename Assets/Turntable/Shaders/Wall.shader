Shader "Turntable/Wall"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1, 1, 1, 1)

        [Header(Noise Field)]
        _NoiseFreq("Frequency", Float) = 1
        _NoiseMotion("Motion", Vector) = (0, 0, 1, 0)
        _NoiseAmp("Amplitude", Float) = 1
        _NoiseBias("Bias", Float) = 0

        [Header(Animation)]
        [Toggle(_USE_SYSTEM_TIME)] _UseSystemTime("Use System Time", Int) = 1
        _LocalTime("Material Time", Float) = 0
    }

    CGINCLUDE

    #include "UnityCG.cginc"
    #include "SimplexNoise3D.hlsl"

    half4 _Color;

    float _NoiseFreq;
    float3 _NoiseMotion;
    float _NoiseAmp;
    float _NoiseBias;
    float _LocalTime;

    struct Attributes
    {
        float4 position : POSITION;
    };

    struct Varyings
    {
        float4 position : SV_POSITION;
        half intensity : COLOR;
    };

    void Vertex(inout float4 position : POSITION) {}

    Varyings GeometryOut(float3 position, half intensity)
    {
        Varyings o;
        o.position = UnityObjectToClipPos(float4(position, 1));
        o.intensity = intensity;
        return o;
    }

    [maxvertexcount(4)]
    void Geometry
    (
        triangle float4 input[3] : POSITION,
        inout LineStream<Varyings> outStream
    )
    {
    #if _USE_SYSTEM_TIME
        float t = _Time.y;
    #else
        float t = _LocalTime;
    #endif

        float3 p0 = input[0].xyz;
        float3 p1 = input[1].xyz;
        float3 p2 = input[2].xyz;

        float3 c = (p0 + p1 + p2) / 3;
        float ns = snoise(c * _NoiseFreq + _NoiseMotion * t);
        ns = saturate(_NoiseBias + ns * _NoiseAmp);

        p0 = lerp(c, p0, ns);
        p1 = lerp(c, p1, ns);
        p2 = lerp(c, p2, ns);

        outStream.Append(GeometryOut(p0, 1));
        outStream.Append(GeometryOut(p1, 1));
        outStream.Append(GeometryOut(p2, 1));
        outStream.Append(GeometryOut(p0, 1));
        outStream.RestartStrip();
    }

    half4 Fragment(Varyings input) : SV_Target
    {
        return _Color * input.intensity;
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
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma shader_feature _USE_SYSTEM_TIME
            ENDCG
        }
    }
}
