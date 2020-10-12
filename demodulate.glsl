const float FSC = 3579545.5; //5e6*63.0/88.0;
const float PI = 3.1415927410125732;
const float M = 2.7936508217862865e-7; // 1.0/FSC;
const float T_LINE = 5.26e-5;
const float L_TIME = 6.35555e-5;
const float P_TIME = 5.26e-5;
const float RSQ3 = 0.5773502588272095; // 1.0/sqrt(3.0);

#pragma glslify: yiq_to_rgb = require('./yiq-to-rgb.glsl')

vec4 read(float t, float n_lines, sampler2D signal) {
  return texture2D(signal, vec2(
    mod(t,T_LINE)/T_LINE,
    floor(t/T_LINE)/(n_lines-1.0)
  ));
}

vec3 demodulate_t(float t, float n_lines, sampler2D signal) {
  float f = 1.0, m = 2.0*f;
  float ti = t - mod(t,M/m);
  float tq = t - mod(t,M/m) + M*0.25/f;
  float ta = t - mod(t,M/m) + M*0.50/f;

  float signal_i = read(ti, n_lines, signal).x*(120.0+40.0)-40.0;
  float signal_q = read(tq, n_lines, signal).x*(120.0+40.0)-40.0;
  float signal_a = read(ta, n_lines, signal).x*(120.0+40.0)-40.0;
  float signal_b = read(t, n_lines, signal).x*(120.0+40.0)-40.0;

  float min_y = min(signal_i,signal_q);
  min_y = min(min_y,signal_a);
  float max_y = max(signal_i, signal_q);
  max_y = max(max_y,signal_a);
  float y = min_y*0.5 + max_y*0.5;

  float s = sin(2.0*PI*FSC*t*f);
  float c = cos(2.0*PI*FSC*t*f);
  vec3 yiq = vec3(
    (y-7.5)/(100.0-7.5),
    (signal_i-y)/20.0 * sign(s),
    (signal_q-y)/20.0 * sign(s)
  );
  vec3 rgb = clamp(vec3(0), vec3(1), yiq_to_rgb(yiq));
  float d = max(rgb.x,max(rgb.y,rgb.z))-min(rgb.x,min(rgb.y,rgb.z));
  float v = (signal_b-7.5+(c*yiq.y+s*yiq.z)*20.0)/(100.0-7.5)*2.0-1.0;
  float p = pow(abs(v),2.2)*sign(v)*pow(max(d,length(rgb)*RSQ3),2.2);
  return clamp(vec3(0), vec3(1), mix(rgb,vec3(p*0.5+0.5),abs(p)));
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
