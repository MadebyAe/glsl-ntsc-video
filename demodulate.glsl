const float CARRIER_HZ = 3579545.0;
const float PI = 3.1415927410125732;
const float N_LINES = 262.0;
float M = 1.0/CARRIER_HZ;
const float T_LINE = 5.26e-5;

#pragma glslify: yiq_to_rgb = require('./yiq_to_rgb.glsl')
#pragma glslify: modulate = require('./modulate.glsl')

vec4 read(float t, sampler2D signal) {
  return texture2D(signal, vec2(
    mod(t/T_LINE,1.0),
    1.0-floor(t/T_LINE)/(N_LINES-1.0)
  ));
}

vec3 demodulate(float t, sampler2D signal) {
  float ti = t - mod(t,M) + M;
  float tq = t - mod(t,M) + M + M*0.25;
  float ts = t - mod(t,M) + M + M*0.65;
  float signal_i = read(ti, signal).x;
  float signal_q = read(tq, signal).x;
  float signal_s = read(ts, signal).x;
  float y = min(signal_i,min(signal_q,signal_s)) * 0.5
    + max(signal_i,max(signal_q,signal_s)) * 0.5;
  return yiq_to_rgb(vec3(
    (y-7.5)/(100.0-7.5),
    (signal_i-y)/10.0,
    (signal_q-y)/10.0
  ));
}
#pragma glslify: export(demodulate)
