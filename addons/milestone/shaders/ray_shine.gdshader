shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D gradient;
uniform float spread = 0.5;
uniform float cutoff = 0.1;
uniform float size = 1.0;
uniform float speed = 1.0;
uniform float ray1_density = 8.0;
uniform float ray2_density = 30.0;
uniform float ray2_intensity = 0.3;
uniform float core_intensity = 2.0;
uniform bool hdr = false;
uniform float seed = 5.0;

float random(vec2 _uv) {
    return fract(sin(dot(_uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(in vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec4 screen(vec4 base, vec4 blend) {
    return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment() {
    vec2 centered_uv = (UV - 0.5) * size;
	
    float square_dist = max(abs(centered_uv.x), abs(centered_uv.y));
    float angle = atan(centered_uv.y, centered_uv.x) + PI;

    vec2 ray1 = vec2(angle * ray1_density + TIME * speed + seed + sin(angle * 3.0), square_dist * 2.0);
    vec2 ray2 = vec2(angle * ray2_density + TIME * speed * 1.5 + seed + cos(angle * 2.0), square_dist * 2.0);

    float cut = 1.0 - smoothstep(cutoff, cutoff + 0.2, square_dist);
    ray1 *= cut;
    ray2 *= cut;

    float rays = hdr ?
        noise(ray1) + (noise(ray2) * ray2_intensity) :
        clamp(noise(ray1) + (noise(ray2) * ray2_intensity), 0., 1.);

    rays *= smoothstep(spread, spread * 0.3, square_dist);
    float core = smoothstep(0.2, 0.0, square_dist) * core_intensity;
    rays += core;

    vec4 gradient_color = texture(gradient, vec2(rays, 0.5));
    vec3 shine = vec3(rays) * gradient_color.rgb;

    float blur_amount = square_dist * 0.1;
    vec2 blur_uv = SCREEN_UV + centered_uv * blur_amount;
    vec4 blurred = vec4(0.1, 0.1, 0.1, 1.0);
    shine = screen(blurred, vec4(shine, rays)).rgb;

    COLOR = vec4(shine, rays * gradient_color.a);
}
