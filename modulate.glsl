#pragma glslify: rgb_to_yiq = require('./rgb-to-yiq.glsl')

//const float FSC = 5e6*63.0/88.0;
const float FSC = 3579545.5; // 5e6*63.0/88.0
const float PI = 3.1415927410125732;
const float L_TIME = 6.35555e-5;
const float P_TIME = 5.26e-5;
const float FP_TIME = 1.5e-6;
const float SP_TIME = 4.7e-6;
const float BW_TIME = 0.6e-6;
const float CB_TIME = 2.5e-6;
const float BP_TIME = 1.6e-6;
const float Q_TIME = 2.71e-5;
const float EQ_TIME = 2.3e-6;

float modulate_t(float t, vec3 rgb) {
  vec3 yiq = rgb_to_yiq(rgb);
  float s = sin(2.0*PI*t*FSC);
  float c = cos(2.0*PI*t*FSC);
  return yiq.x*(100.0-7.5) + (c*yiq.y + s*yiq.z)*20.0 + 7.5;
}

float modulate_uv(vec2 uv, float n_lines, vec3 rgb) {
  float v_lines = n_lines - 20.0;
  float t = uv.x*P_TIME + floor(uv.y*(v_lines-1.0)+0.5)*P_TIME;
  return modulate_t(t, rgb);
}

float modulate(vec2 v, float n_lines, sampler2D picture) {
  float v_lines = n_lines - 20.0;
  float line = floor((1.0-v.y)*n_lines+0.5);
  vec2 uv = v
    * vec2(L_TIME/P_TIME, n_lines/v_lines)
    - vec2((L_TIME-P_TIME)/P_TIME, 0);
  float hblank = step(v.x, (L_TIME-P_TIME)/L_TIME);
  float vblank = step(1.0-(n_lines-v_lines)/n_lines, v.y);

  float odd = mod(n_lines,2.0);
  float vsync_pre = step(0.0,line)*step(line, 3.0);
  float vsync_pulse = step(3.0,line)*step(line,6.0);
  float vsync_post = step(6.0,line)*step(line,9.0);

  float vt = 0.0;
  float fporch = step(v.x,FP_TIME/L_TIME);
  vt += FP_TIME/L_TIME;
  float syncpulse = step(vt,v.x) * step(v.x,vt+SP_TIME/L_TIME);
  vt += SP_TIME/L_TIME;
  float breezeway = step(vt,v.x) * step(v.x,vt+BW_TIME/L_TIME);
  vt += BW_TIME/L_TIME;
  float colorburst = step(vt,v.x) * step(v.x,vt+CB_TIME/L_TIME);
  vt += CB_TIME/L_TIME;
  float bporch = step(vt,v.x) * step(v.x,vt+BP_TIME/L_TIME);
  vec3 rgb = texture2D(picture,uv).xyz;
  float signal = modulate_uv(v, n_lines, rgb);
  signal *= 1.0 - hblank;
  signal -= 40.0 * syncpulse;
  signal += sin(2.0*PI*FSC)*20.0*colorburst;
  signal *= 1.0 - vblank;
  signal -= 40.0 * vsync_pre * step(mod(v.x,0.5)*L_TIME,EQ_TIME);
  signal -= 40.0 * vsync_pulse * step(mod(v.x,0.5)*L_TIME,Q_TIME);
  signal -= 40.0 * vsync_post * step(mod(v.x,0.5)*L_TIME,EQ_TIME);
  return (signal + 40.0) / (120.0+40.0);
}

#pragma glslify: export(modulate)
