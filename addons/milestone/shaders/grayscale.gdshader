shader_type canvas_item;

uniform bool use_grayscale = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (use_grayscale) {
		float gray = tex_color.r * 0.299 + tex_color.g * 0.587 + tex_color.b * 0.114;
		tex_color.rgb = vec3(gray);
	}

	COLOR = tex_color;
}