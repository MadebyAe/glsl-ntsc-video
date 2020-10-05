const float CARRIER_HZ = 3579545.0;
const float PI = 3.1415927410125732;
float M = 1.0/CARRIER_HZ;
const float T_LINE = 5.26e-5;

#pragma glslify: yiq_to_rgb = require('./yiq-to-rgb.glsl')

vec4 read(float t, float n_lines, sampler2D signal) {
  return texture2D(signal, vec2(
    mod(t/T_LINE,1.0),
    1.0-floor(t/T_LINE)/(n_lines-1.0)
  ));
}

vec3 demodulate(float t, float n_lines, sampler2D signal) {
  float ti = t - mod(t,M) + M;
  float tq = t - mod(t,M) + M + M*0.25;
  float ta = t - mod(t,M) + M + M*0.65;
  float signal_i = read(ti, n_lines, signal).x;
  float signal_q = read(tq, n_lines, signal).x;
  float signal_a = read(ta, n_lines, signal).x;
  float min_y = min(signal_i,signal_q);
  min_y = min(min_y,signal_a);
  float max_y = max(signal_i, signal_q);
  max_y = max(max_y,signal_a);
  float y = min_y*0.5 + max_y*0.5;
  return yiq_to_rgb(vec3(
    (y-7.5)/(100.0-7.5),
    (signal_i-y)/10.0,
    (signal_q-y)/10.0
  ));
}
#pragma glslify: export(demodulate)
