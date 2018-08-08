// Author: Thomas Goossens
// Copyright (c) 2006 Apple 


uniform vec4 ClampArea;
uniform sampler2DRect Texture;
varying vec2  TexCoord;

void main (void)
{
	vec2 t;

	t.x = clamp(TexCoord.x, ClampArea.r, ClampArea.b); 
	t.y = clamp(TexCoord.y, ClampArea.g, ClampArea.a); 

	//if(TexCoord.x <= ClampArea.r)
	//	t.x += 0.5;
	//else{
	//	if(TexCoord.x >= ClampArea.b)
	//		t.x -= 0.5;
	//}
		 
	//if(TexCoord.y >= ClampArea.a)
	//	t.y -= 0.5;
	//else{
	//	if(TexCoord.y <= ClampArea.g)
	//		t.y += 0.5;
	//}

	gl_FragColor = texture2DRect(Texture, t);	
}
