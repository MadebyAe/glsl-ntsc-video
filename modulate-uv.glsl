const float CARRIER_HZ = 3579545.0;
const float PI = 3.1415927410125732;
const float T_LINE = 5.26e-5;

#pragma glslify: rgb_to_yiq = require('./rgb-to-yiq.glsl')

float modulate_uv(vec2 uv, float n_lines, vec3 rgb) {
  float t = uv.x*T_LINE + floor(uv.y*(n_lines-1.0)+0.5)*T_LINE;
  vec3 yiq = rgb_to_yiq(rgb);
  float s = sin(2.0*PI*t*CARRIER_HZ);
  float c = cos(2.0*PI*t*CARRIER_HZ);
  return yiq.x*(100.0-7.5) + (c*yiq.y + s*yiq.z)*10.0 + 7.5;
}
#pragma glslify: export(modulate_uv)
