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

    // Vertex input attributes
    struct Attributes
    {
        float4 position : POSITION;
    };

    // Fragment varyings
    struct Varyings
    {
        float4 position : SV_POSITION;
        half4 color : COLOR;
    };

    // Vertex stage
    void Vertex(inout float4 position : POSITION)
    {
        position = mul(unity_ObjectToWorld, position);
    }

    [maxvertexcount(3)]
    void Geometry
    (
        triangle float4 input[3] : POSITION,
        inout TriangleStream<Varyings> outStream
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

        Varyings o;
        o.color = _Color;

        o.position = UnityWorldToClipPos(float4(p0, 1));
        outStream.Append(o);

        o.position = UnityWorldToClipPos(float4(p1, 1));
        outStream.Append(o);

        o.position = UnityWorldToClipPos(float4(p2, 1));
        outStream.Append(o);

        outStream.RestartStrip();
    }

    half4 Fragment(Varyings input) : SV_Target
    {
        return input.color;
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
