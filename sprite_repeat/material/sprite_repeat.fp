varying mediump vec2 var_texcoord0;

uniform lowp sampler2D texture_sampler;
uniform lowp vec4 tint;

uniform lowp vec4 direction;


varying highp vec2 var_boo;
varying highp vec4 var_uv;
varying highp vec4 var_repeat;
varying highp vec4 var_rotated;

void main()
{
    // Pre-multiply alpha since all runtime textures already are
    lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);

    // Calculate the final UV coord based on local fragment position and texture UV space.
    float u = mod((var_boo.x + direction.x*direction.w) * var_repeat.x, 1);
    float v = mod((var_boo.y + direction.y*direction.w) * var_repeat.y, 1);

    // It looks like the V coordinate axis in atlas space and shader space are in opposite directions.
    // In case the atlas has a sprite rotated clockwise we need to swap U and V.
    vec2 uv = vec2( 
        mix(var_uv.x, var_uv.z,       u * var_rotated.x  + v * var_rotated.y),
        mix(var_uv.y, var_uv.w, 1. - (u * var_rotated.y  + v * var_rotated.x))
    );
    
    gl_FragColor = texture2D(texture_sampler, uv) * tint_pm;
}
