const float FSC = 5e6*63.0/88.0;
const float PI = 3.1415927410125732;
const float M = 1.0/FSC;
const float T_LINE = 5.26e-5;
const float L_TIME = 6.35555e-5;
const float P_TIME = 5.26e-5;
const float RSQ3 = 1.0/sqrt(3.0);

#pragma glslify: yiq_to_rgb = require('./yiq-to-rgb.glsl')

vec4 read(float t, float n_lines, sampler2D signal) {
  return texture2D(signal, vec2(
    mod(t,T_LINE)/T_LINE,
    floor(t/T_LINE)/(n_lines-1.0)
  ));
}

vec3 demodulate_t(float t, float n_lines, sampler2D signal) {
  float m = 2.0;
  float ti = t - mod(t,M/m);
  float tq = t - mod(t,M/m) + M*0.25;
  float ta = t - mod(t,M/m) + M*0.50;

  float signal_i = read(ti, n_lines, signal).x;
  float signal_q = read(tq, n_lines, signal).x;
  float signal_a = read(ta, n_lines, signal).x;
  float signal_b = read(t, n_lines, signal).x;

  float min_y = min(signal_i,signal_q);
  min_y = min(min_y,signal_a);
  float max_y = max(signal_i, signal_q);
  max_y = max(max_y,signal_a);
  float y = min_y*0.5 + max_y*0.5;

  float s = sin(2.0*PI*FSC*t);
  float c = cos(2.0*PI*FSC*t);
  vec3 yiq = vec3(
    (y-7.5)/(100.0-7.5),
    (signal_i-y)/20.0 * sign(s),
    (signal_q-y)/20.0 * sign(s)
  );
  vec3 rgb = yiq_to_rgb(yiq);
  float v = (signal_b-7.5)/(100.0-7.5)*2.0-1.0;
  return clamp(vec3(0), vec3(1), rgb
    + pow(vec3(abs(v)),vec3(2.2))*sign(v)*length(rgb)*RSQ3*0.5
  );
}

vec3 demodulate_uv(vec2 uv, float n_lines, sampler2D signal) {
  float v_lines = n_lines - 20.0;
  float t = uv.x*T_LINE + floor(uv.y*(v_lines-1.0)+0.5)*T_LINE;
  return demodulate_t(t, v_lines, signal);
}

vec3 demodulate(vec2 v, vec3 n, sampler2D signal) {
  float v_lines = n.x - 20.0;
  vec2 uv = v * vec2(P_TIME/L_TIME, v_lines/n.x) - vec2(P_TIME/L_TIME, 0);
  float odd = floor(mod(uv.x*n.y,2.0));
  float sy = odd/n.z*0.5;
  vec2 ruv = vec2(
    floor(uv.x*n.y+0.5)/n.y,
    floor(uv.y*n.z+odd*0.5)/n.z
  );
  return demodulate_uv(ruv, n.x, signal);
}

#pragma glslify: export(demodulate)
