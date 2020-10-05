vec3 rgb_to_yiq(vec3 rgb) {
  float y = 0.30*rgb.x + 0.59*rgb.y + 0.11*rgb.z;
  return vec3(
    y,
    -0.27*(rgb.z-y) + 0.74*(rgb.x-y),
    0.41*(rgb.z-y) + 0.48*(rgb.x-y)
  );
}
#pragma glslify: export(rgb_to_yiq)
