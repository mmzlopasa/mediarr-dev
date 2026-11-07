#version 460 core

// Shows an equirectangular 360° photo as seen from the middle of a sphere, looking towards yaw and
// pitch, with a vertical field of view of fov.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uYaw;
uniform float uPitch;
uniform float uFov;
uniform sampler2D uImage;

out vec4 fragColor;

const float PI = 3.14159265359;

void main() {
  vec2 p = FlutterFragCoord().xy / uSize;
  vec2 ndc = vec2(p.x * 2.0 - 1.0, 1.0 - p.y * 2.0);
  float t = tan(uFov * 0.5);
  vec3 dir = normalize(vec3(ndc.x * t * (uSize.x / uSize.y), ndc.y * t, -1.0));
  float cp = cos(uPitch);
  float sp = sin(uPitch);
  dir = vec3(dir.x, dir.y * cp - dir.z * sp, dir.y * sp + dir.z * cp);
  float cy = cos(uYaw);
  float sy = sin(uYaw);
  dir = vec3(dir.x * cy + dir.z * sy, dir.y, -dir.x * sy + dir.z * cy);
  float lon = atan(dir.x, -dir.z);
  float lat = asin(clamp(dir.y, -1.0, 1.0));
  vec2 uv = vec2(fract(lon / (2.0 * PI) + 0.5), 0.5 - lat / PI);
  fragColor = texture(uImage, uv);
}
