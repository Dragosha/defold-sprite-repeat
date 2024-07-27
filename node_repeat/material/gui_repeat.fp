varying mediump vec2 var_texcoord0;
varying lowp vec4 var_color;

uniform lowp sampler2D texture_sampler;
varying highp vec4 var_uv;
varying highp vec4 var_repeat;
varying highp vec4 var_rotated;

void main()
{

    float local_position_x = (var_uv.z - var_texcoord0.x) / (var_uv.z - var_uv.x);
    float local_position_y = (var_uv.w - var_texcoord0.y) / (var_uv.w - var_uv.y);
    vec2 var_boo = vec2(local_position_x, local_position_y);
    float u = var_boo.x * var_repeat.x - floor(var_boo.x * var_repeat.x);
    float v = var_boo.y * var_repeat.y - floor(var_boo.y * var_repeat.y);
    // It looks like the V coordinate axis in atlas space and shader space are in opposite directions.
    // In case the atlas has a sprite rotated clockwise we need to swap U and V.
    vec2 uv = vec2( 
        mix(var_uv.x, var_uv.z, 1. -(u * var_rotated.x  + v * var_rotated.y)),
        mix(var_uv.y, var_uv.w, 1. -(u * var_rotated.y  + v * var_rotated.x))
    );
    
    lowp vec4 tex = texture2D(texture_sampler, uv);
    gl_FragColor = tex * var_color;
}
