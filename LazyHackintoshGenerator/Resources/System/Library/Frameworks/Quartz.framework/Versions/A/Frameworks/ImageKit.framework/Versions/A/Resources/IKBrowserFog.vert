// Author: Thomas Goossens
// Copyright (c) 2006 Apple

varying vec2 TexCoord;
//varying float GradientCoef;
varying float Alpha;

void main(void)
{
    TexCoord        = gl_MultiTexCoord0.st;
//    GradientCoef    = gl_Color.r;
    Alpha			= gl_Color.a;
    gl_Position     = ftransform();
}