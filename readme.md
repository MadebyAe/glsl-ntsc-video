# glsl-ntsc-video

modulate and demodulate an ntsc video signal in a shader

compile with [glslify][]

ntsc was a broadcast television standard used in north america, the caribbean, parts of south
america, and a few places in east asia and the pacific. ntsc was mostly discontinued in 2009 for
over-the-air use but lives on in legacy consumer electronics such as game consoles and vhs tapes
made for ntsc regions.

this module has not been tested against an actual ntsc signal, but it can decode its own signals
with some fidelity.

[glslify]: https://github.com/glslify/glslify

# example

this example modulates and then demodulates a picture from an image file.

check the example directory for a demo that reads from a visual effect written to framebuffer and
then modulated and demodulated.

``` js
var glsl = require('glslify')
var regl = require('regl')({
  extensions: [ 'oes_texture_float', 'oes_texture_float_linear', 'webgl_color_buffer_float' ]
})
var fbopts = [
  { color: regl.texture({ format: 'rgba', type: 'float', width: 720*2, height: 262 }) },
  { color: regl.texture({ format: 'rgba', type: 'float', width: 720*2, height: 263 }) }
]
var fbo = [
  regl.framebuffer(fbopts[0]),
  regl.framebuffer(fbopts[1])
]

require('resl')({
  manifest: { picture: { type: 'image', src: 'smpte.png' } },
  onDone: (assets) => {
    var draw = {
      modulate: regl({
        frag: glsl`
          precision highp float;
          #pragma glslify: modulate = require('glsl-ntsc-video/modulate')
          varying vec2 vpos;
          uniform float n_lines;
          uniform sampler2D picture;
          void main () {
            float signal = modulate(vpos*0.5+0.5, n_lines, picture);
            gl_FragColor = vec4(signal,0,0,1);
          }
        `,
        vert: `
          precision highp float;
          attribute vec2 position;
          varying vec2 vpos;
          void main () {
            vpos = position;
            gl_Position = vec4(position,0,1);
          }
        `,
        attributes: { position: [-4,-4,-4,+4,+4,+0] },
        elements: [0,1,2],
        framebuffer: regl.prop('framebuffer'),
        uniforms: {
          n_lines: regl.prop('n_lines'),
          picture: regl.texture({ data: assets.picture, flipY: true })
        }
      }),
      demodulate: regl({
        frag: glsl`
          precision highp float;
          #pragma glslify: demodulate = require('glsl-ntsc-video/demodulate')
          uniform sampler2D signal0, signal1;
          varying vec2 vpos;
          uniform float tick;
          const float PI = ${Math.PI};
          void main () {
            vec2 v = vpos*0.5+0.5;
            vec2 r = vec2(720,485);
            vec3 rgb0 = demodulate(v, vec3(242,r), signal0);
            vec3 rgb1 = demodulate(v, vec3(243,r), signal1);
            vec3 rgb = mix(rgb0,rgb1,sin(v.y*PI*2.0*242.5)*0.5+0.5);
            gl_FragColor = vec4(rgb,1);
          }
        `,
        vert: `
          precision highp float;
          attribute vec2 position;
          varying vec2 vpos;
          void main () {
            vpos = position;
            gl_Position = vec4(position,0,1);
          }
        `,
        attributes: { position: [-4,-4,-4,+4,+4,+0] },
        elements: [0,1,2],
        uniforms: {
          signal0: regl.prop('signal0'),
          signal1: regl.prop('signal1'),
          tick: regl.context('tick')
        }
      })
    }
    var tick = 0
    frame(); frame()
    window.addEventListener('resize', () => {
      frame(); frame()
    })
    function frame () {
      regl.poll()
      fbo[tick%2](fbopts[tick%2])
      draw.modulate({ framebuffer: fbo[tick%2], n_lines: tick%2 ? 243 : 242 })
      regl.clear({ color: [0,0,0,1], depth: true })
      draw.demodulate({ signal0: fbo[0], signal1: fbo[1] })
      tick++
    }
  }
})
```

# api

```
#pragma glslify: modulate = require('glsl-ntsc-video/modulate')
#pragma glslify: demodulate = require('glsl-ntsc-video/demodulate')
```

## `float signal = modulate(vec2 uv, float n_lines, sampler2D picture)`

return the modulated floating point `signal` in IRE (`-40` to `+120`) for `uv` in unit coordinates
(values from 0 to 1, inclusive) where `(0,0)` is the bottom-left. the `picture` texture should have
its `(0,0)` at the bottom-left too.

`n_lines` is the total number of lines (262 or 263).

## `vec3 rgb = demodulate(uv, vec3(n_lines,width,height), sampler2D signal)`

decode a texture `signal` with its red channel set as modulated ntsc in IRE (`-40` to `+120`) for
`uv` in unit coordinates (values from 0 to 1, inclusive) where `(0,0)` is the bottom-left.

`n_lines` is the number of lines (262 or 263).

`width` and `height` are the decoded size of the resulting visual image (use `720,485`).

# license

bsd

# install

```
npm install glsl-ntsc-video
```
