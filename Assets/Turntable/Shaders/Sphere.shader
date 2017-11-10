Shader "Turntable/Sphere"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1, 1, 1, 1)

        [Header(Noise Field)]
        _NoiseFreq("Frequency", Float) = 1
        _NoiseMotion("Motion", Vector) = (0, 0, 1, 0)
        _NoiseAmp("Amplitude", Float) = 1
        _NoiseBias("Bias", Float) = 0
    }

    CGINCLUDE

    #include "UnityCG.cginc"
    #include "SimplexNoise3D.hlsl"

    half4 _Color;

    float _NoiseFreq;
    float3 _NoiseMotion;
    float _NoiseAmp;
    float _NoiseBias;

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

    [maxvertexcount(6)]
    void Geometry
    (
        triangle float4 input[3] : POSITION,
        inout LineStream<Varyings> outStream
    )
    {
        float3 p0 = input[0].xyz;
        float3 p1 = input[1].xyz;
        float3 p2 = input[2].xyz;

        float3 c = (p0 + p1 + p2) / 3;
        float ns = snoise(c * _NoiseFreq + _NoiseMotion * _Time.y);
        ns = saturate(_NoiseBias + ns * _NoiseAmp);

        p0 = lerp(c, p0, ns);
        p1 = lerp(c, p1, ns);
        p2 = lerp(c, p2, ns);

        // Triangle
        outStream.Append(GeometryOut(p0, 1));
        outStream.Append(GeometryOut(p1, 1));
        outStream.Append(GeometryOut(p2, 1));
        outStream.Append(GeometryOut(p0, 1));
        outStream.RestartStrip();

        // Line
        outStream.Append(GeometryOut(lerp(c, 0, ns * 0.7), 0));
        outStream.Append(GeometryOut(lerp(0, c, 1 + 0.2 * ns), ns / 2));
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
            ENDCG
        }
    }
}
