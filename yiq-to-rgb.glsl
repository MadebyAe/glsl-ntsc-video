vec3 yiq_to_rgb(vec3 yiq) {
  return vec3(
    yiq.x + 0.9469*yiq.y + 0.6236*yiq.z,
    yiq.x - 0.2748*yiq.y - 0.6357*yiq.z,
    yiq.x - 1.1*yiq.y + 1.7*yiq.z
  );
}
#pragma glslify: export(yiq_to_rgb)
