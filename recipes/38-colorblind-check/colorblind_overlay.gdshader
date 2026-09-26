shader_type canvas_item;
// Full-screen colour-vision-deficiency preview. Put it on a ColorRect (full rect, mouse filter ignore) in a
// CanvasLayer above everything; mode 0 = off, 1 = deuteranopia, 2 = protanopia, 3 = tritanopia.
// Same matrices as colorblind.gd (Machado et al. 2009, severity 1.0, linear RGB).

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform int mode = 0;

vec3 to_linear(vec3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c)); }
vec3 to_srgb(vec3 c) { return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(0.0031308, c)); }

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	if (mode == 0) {
		COLOR = src;
	} else {
		mat3 m;
		if (mode == 1) m = mat3(vec3(0.367322, 0.280085, -0.011820), vec3(0.860646, 0.672501, 0.042940), vec3(-0.227968, 0.047413, 0.968881));
		else if (mode == 2) m = mat3(vec3(0.152286, 0.114503, -0.003882), vec3(1.052583, 0.786281, -0.048116), vec3(-0.204868, 0.099216, 1.051998));
		else m = mat3(vec3(1.255528, -0.078411, 0.004733), vec3(-0.076749, 0.930809, 0.691367), vec3(-0.178779, 0.147602, 0.303900));
		COLOR = vec4(to_srgb(clamp(m * to_linear(src.rgb), 0.0, 1.0)), src.a);
	}
}
