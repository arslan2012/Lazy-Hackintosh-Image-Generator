// Author: Thomas Goossens
// Copyright (c) 2006 Apple 

uniform vec3 FogColor;
uniform sampler2DRect Texture;
uniform float FogCoef;

//varying float GradientCoef;
varying float Alpha;
varying vec2 TexCoord;

void main (void)
{
    vec4 t = texture2DRect(Texture, TexCoord);	

	float coef = 1.0 - FogCoef;
	float inv = FogCoef;
		
	gl_FragColor = vec4(FogColor.r*inv + t.r*coef, FogColor.g*inv + t.g*coef, FogColor.b*inv + t.b*coef, 1.0) * (t.a * Alpha);
 }