// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*Avatar uber shader. Uses multiple UV channels and textures to composite avatar facial features together.
Uses a single per-pixel toon shaded light and up to 4 vertex lights.

Usage: This is the shader that should be applied to run-time avatars.

*/

Shader "Altspace/ToonShaded" {
	Properties
	{
		_MainTex("Base Color Texture", 2D) = "white" {}
		_Color("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)

		_AoMetalRoughRimTex("AO (R), Metallic (G), Roughness (B), Rim Width (A)", 2D) = "red"{}
		[FloatRange]_AoIntensity("Ambient Occlusion Strength", Range(0, 1)) = 1
		_LightThreshold("Cel Shading Threshold", Range(0, 2)) = 0.15
		[FloatRange]_ShadowWidth("Shadow Fade Width", Range(0, 1)) = 0.075
		_SecondaryLightThreshold("Secondary Light Cel Shading Threshold", Range(0, 2)) = 0.15
		[FloatRange]_SecondaryShadowWidth("Secondary Light Shadow Fade Width", Range(0, 1)) = 0.075
		[FloatRange]_LightBlackpoint("Shadow Black Point", Range(0, 1.0)) = 0.5
		[FloatRange]_AmbientStrength("Ambient Lighting Strength", Range(0, 1.0)) = 0.7
	}

		SubShader
		{
			Tags { "RenderMode" = "Opaque" "Queue" = "Geometry"}

			Pass {
				Tags { "LightMode" = "UniversalForward" }

				HLSLPROGRAM
					#pragma vertex vert
					#pragma fragment frag
					#pragma multi_compile_fog
					#pragma multi_compile_instancing

					//
					// Unity includes
					//


					#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
					#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
					#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
					#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

					//
					// Textures
					//

					TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
					TEXTURE2D(_AoMetalRoughRimTex); SAMPLER(sampler_AoMetalRoughRimTex);

					//
					// Shader variables
					//

					CBUFFER_START(UnityPerMaterial)
						float4 _Color;

						//texture samplers
						float4 _MainTex_ST;
						float4 _AoMetalRoughRimTex_ST;

						//lighting inputs
						float _LightBlackpoint;
						float _AoIntensity;
						float _LightThreshold;
						float _ShadowWidth;
						int _ShadowSteps;
						float _SecondaryLightThreshold;
						float _SecondaryShadowWidth;
						float _AmbientStrength;
					CBUFFER_END

					struct Attributes
					{
						float4 vertex      : POSITION;
						float3 normal      : NORMAL;
						float3 color       : COLOR0;
						float2 uv          : TEXCOORD0;

						UNITY_VERTEX_INPUT_INSTANCE_ID
					};

					struct Varyings
					{
						float4 vertex       : SV_POSITION;
						float3 normal       : NORMAL;
						float3 posWS        : TEXCOORD0;
						half4 uv            : TEXCOORD1;
						float4 viewDir_fog  : TEXCOORD5;
						UNITY_VERTEX_INPUT_INSTANCE_ID
						UNITY_VERTEX_OUTPUT_STEREO
					};

					float remap(float value, float fromA, float toA, float fromB, float toB)
					{
						return (value - fromA) / (toA - fromA) * (toB - fromB) + fromB;
					}

					float maxLuminance(float3 rgb)
					{
						return max(rgb.r, max(rgb.g, rgb.b));
					}

					Varyings vert(Attributes v)
					{
						Varyings o = (Varyings)0;
						UNITY_SETUP_INSTANCE_ID(v);
						UNITY_TRANSFER_INSTANCE_ID(v, o);
						UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

						o.posWS = TransformObjectToWorld(v.vertex.xyz);
						o.normal = TransformObjectToWorldNormal(v.normal);

						o.viewDir_fog.xyz = GetWorldSpaceViewDir(o.posWS.xyz);
						o.vertex = TransformWorldToHClip(o.posWS.xyz);
						o.viewDir_fog.w = ComputeFogFactor(o.vertex.z);

						o.uv.xy = v.uv;

						return o;
					}

					half4 frag(Varyings i) : SV_Target
					{
						UNITY_SETUP_INSTANCE_ID(i);
						half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy) * _Color;

						//Begin per-pixel toon shading
						float4 MainLightPos = _MainLightPosition;
						//Mix ambient sky with the main directional light so ambient gradient can impact final color
						float4 MainLightColor = _MainLightColor;
						float3 normal = normalize(i.normal);

						float3 lightDir = normalize(MainLightPos.xyz - (i.vertex.xyz * MainLightPos.w));

						//get the hue of the color, used for ambient and metallic color contributions
						float maxValue = maxLuminance(col.rgb);
						half4 normalizedHue = saturate(half4(col.rgb * (half3(1, 1, 1) / maxValue), 1));

						//Calculate main toon lighting
						float4 _AoMetalRoughRim = SAMPLE_TEXTURE2D(_AoMetalRoughRimTex, sampler_AoMetalRoughRimTex, i.uv.xy);
						float AO = lerp(1.0, _AoMetalRoughRim.r, _AoIntensity);
						float NdotL = dot(lightDir, normal);
						float lightIntensity = smoothstep(_LightThreshold, _LightThreshold + _ShadowWidth, NdotL * (AO));
						float adjustedLightIntensity = remap(lightIntensity, 0, 1, _LightBlackpoint, 1);
						float shadow = (1.0 - adjustedLightIntensity);
						half4 light = (adjustedLightIntensity)*MainLightColor;

						//rim light
						float Metallic = saturate(_AoMetalRoughRim.g);
						float Smoothness = (1 - saturate(_AoMetalRoughRim.b));
						float RimWidth = saturate(_AoMetalRoughRim.a);
						float fresnel = 1 - dot(normalize(i.viewDir_fog.xyz), normalize(normal));
						fresnel = step(1 - RimWidth, fresnel);
						half4 rimColor = lerp(half4(1, 1, 1, 1), 2 * normalizedHue, Metallic) * light;

						//Final rim light is lerped between pure rim color and base color for artistic control
						col = lerp(col, rimColor, fresnel * lightIntensity * Smoothness);

						//Ambient sky contributions. These are made stronger when the main lighting is dimmer to support UGC with bright ambient and dim directionals.
						half4 ambientSky = (unity_AmbientSky + unity_AmbientEquator + unity_AmbientGround) / 3;
						half4 ambientShadow = MainLightColor * (0.5 * (unity_AmbientGround + normalizedHue)) * maxValue * shadow;
						light += _AmbientStrength * (ambientSky + ambientShadow);

						col.rgb *= light.rgb;

						//apply fog
						col.rgb = MixFog(col.rgb, i.viewDir_fog.w);

						return col;
					}

				ENDHLSL
			}
		}
}
