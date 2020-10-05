#pragma glslify: demodulate = require('./demodulate.glsl')

const float T_LINE = 5.26e-5;

vec3 demodulate_uv(vec2 uv, float n_lines, sampler2D signal) {
  float t = uv.x*T_LINE + floor(uv.y*(n_lines-1.0)+0.5)*T_LINE;
  return demodulate(t, n_lines, signal);
}
#pragma glslify: export(demodulate_uv)
