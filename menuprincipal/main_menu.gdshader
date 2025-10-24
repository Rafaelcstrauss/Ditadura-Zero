shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float radius : hint_range(1.0, 12.0) = 8.0; // tamanho do blur
uniform float strength : hint_range(0.0, 1.0) = 0.0; // intensidade do efeito

void fragment() {
    vec2 texel = SCREEN_PIXEL_SIZE;

    vec4 base_color = textureLod(screen_tex, SCREEN_UV, 0.0);

    // calcula blur bruto
    vec4 sum = vec4(0.0);
    for (float x = -radius; x <= radius; x += 1.0) {
        for (float y = -radius; y <= radius; y += 1.0) {
            sum += textureLod(screen_tex, SCREEN_UV + vec2(x, y) * texel, 0.0);
        }
    }

    float denom = (radius * 2.0 + 1.0) * (radius * 2.0 + 1.0);
    vec4 blurred = sum / denom;

    // mistura suave entre normal e borrado
    COLOR = mix(base_color, blurred, strength);
}
