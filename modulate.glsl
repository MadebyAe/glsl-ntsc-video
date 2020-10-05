const float CARRIER_HZ = 3579545.0;
const float PI = 3.1415927410125732;

#pragma glslify: rgb_to_yiq = require('./rgb_to_yiq.glsl')

float modulate(float t, vec3 rgb) {
  vec3 yiq = rgb_to_yiq(rgb);
  float s = sin(2.0*PI*t*CARRIER_HZ);
  float c = cos(2.0*PI*t*CARRIER_HZ);
  return yiq.x*(100.0-7.5) + (c*yiq.y + s*yiq.z)*10.0 + 7.5;
}
#pragma glslify: export(modulate)
