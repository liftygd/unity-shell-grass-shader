Shader "Custom/Shell Shading/Lifty's Shell Shader"
{
    Properties
    {
        _HighlightPattern ("Highlight Pattern Texture", 2D) = "white" {}
        [HDR] _MainCol ("Main Color", Color) = (1, 1, 1, 1)
        [HDR] _SecondaryCol ("Secondary Color", Color) = (1, 1, 1, 1)
        _NoiseSize ("Noise Size", Float) = 1
        _NoiseOffset ("Noise Offset", Vector) = (0, 0, 0, 0)
        _NoisePower ("Noise Power", Range(0, 10)) = 1
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.2
        _WindDirection ("Wind Direction", Vector) = (1, 1, 1, 1)
        _WindSpeed ("Wind Speed", Float) = 1
        _WindHeight("Wind Height", Range(0.5, 2)) = 1.5
        _HeightValue ("Height Value", Float) = 1
        _CircleRadius("Circle Radius", Range(0, 1)) = 1
        _CircleRadiusHeightChange ("Circle Radius By Height", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Hashes.hlsl"
            
            float Unity_SimpleNoise_ValueNoise_Deterministic_float (float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);
                uv = abs(frac(uv) - 0.5);
                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0; Hash_Tchou_2_1_float(c0, r0);
                float r1; Hash_Tchou_2_1_float(c1, r1);
                float r2; Hash_Tchou_2_1_float(c2, r2);
                float r3; Hash_Tchou_2_1_float(c3, r3);
                float bottomOfGrid = lerp(r0, r1, f.x);
                float topOfGrid = lerp(r2, r3, f.x);
                float t = lerp(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            void Unity_SimpleNoise_Deterministic_float(float2 UV, float Scale, out float Out)
            {
                float freq, amp;
                Out = 0.0f;
                freq = pow(2.0, float(0));
                amp = pow(0.5, float(3-0));
                Out += Unity_SimpleNoise_ValueNoise_Deterministic_float(float2(UV.xy*(Scale/freq)))*amp;
                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3-1));
                Out += Unity_SimpleNoise_ValueNoise_Deterministic_float(float2(UV.xy*(Scale/freq)))*amp;
                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3-2));
                Out += Unity_SimpleNoise_ValueNoise_Deterministic_float(float2(UV.xy*(Scale/freq)))*amp;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };
            
            float4 _MainCol;
            float4 _SecondaryCol;

            sampler2D _HighlightPattern;

            float _NoiseSize;
            float4 _NoiseOffset;
            float _NoisePower;
            float _Cutoff;

            float4 _WindDirection;
            float _WindSpeed;
            float _WindHeight;

            float _HeightValue;

            float _CircleRadius;
            float _CircleRadiusHeightChange;

            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex) - 1; //object to world

                //float circleUv = length(v.uv * 2 - 1);
                //float wave = sin(circleUv * 20 - _Time.y * 2) * 0.5 + 0.5;
                //v.vertex.y = saturate(wave * 0.1);

                float2 topDownProjection = o.worldPos.xz + _NoiseOffset.xy;
                
                float windNoise;
                Unity_SimpleNoise_Deterministic_float(topDownProjection + _Time.y * _WindSpeed * 0.1, 16 * 0.25, windNoise);
                
                o.vertex = UnityObjectToClipPos(
                    v.vertex + float4(
                        _Time.y * _WindDirection.x * windNoise * 0.001 * saturate(_HeightValue + _WindHeight),
                        _Time.y * _WindDirection.y * windNoise * 0.001 * saturate(_HeightValue + _WindHeight),
                        _Time.y * _WindDirection.z * windNoise * 0.001 * saturate(_HeightValue + _WindHeight),
                        0));
                
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float2 topDownProjection = i.worldPos.xz + _NoiseOffset.xy;
                float2 pixelProjection = floor(topDownProjection * _NoiseSize) / _NoiseSize;

                float noise;
                Unity_SimpleNoise_Deterministic_float(pixelProjection, _NoiseSize, noise);

                float circle_radius = length(frac(topDownProjection * _NoiseSize) * _NoiseSize - _NoiseSize / 2);
                float4 pattern = saturate(pow(noise, _NoisePower) * (1 - _HeightValue - 1.5));

                _CircleRadius -= _CircleRadiusHeightChange * (1.2 - abs(_HeightValue)) * 5;
                pattern *= 1 - step(_CircleRadius * _NoiseSize, circle_radius);
                
                clip(pattern.a - _Cutoff);

                //float circleUv = length(i.uv * 2 - 1);
                //float wave = sin(circleUv * 5 - _Time.y * 2) * 0.5 + 0.1;

                float highlightTexture = tex2Dlod(_HighlightPattern, float4(topDownProjection.x * 0.25 + _Time.y * 0.15, topDownProjection.y * 0.15, 0, 0)).r;
                
                return saturate(lerp(_MainCol, _SecondaryCol, pow(highlightTexture, 0.25)) * (_HeightValue + 1.3));
            }
            ENDCG
        }
    }
}
