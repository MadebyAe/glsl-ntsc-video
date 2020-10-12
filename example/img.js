var glsl = require('glslify')
var regl = require('regl')()
var fbopts = [
  { color: regl.texture({ format: 'rgba', width: 720*2, height: 262 }) },
  { color: regl.texture({ format: 'rgba', width: 720*2, height: 263 }) }
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
          #pragma glslify: modulate = require('../modulate.glsl')
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
          #pragma glslify: demodulate = require('../demodulate.glsl')
          uniform sampler2D signal0, signal1;
          varying vec2 vpos;
          uniform float tick;
          const float PI = ${Math.PI};
          void main () {
            vec2 v = vpos*0.5+0.5;
            vec2 r = vec2(720,485);
            vec3 rgb0 = demodulate(v, vec3(262.0,r), signal0);
            vec3 rgb1 = demodulate(v, vec3(263.0,r), signal1);
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
    window.addEventListener('resize', () => { frame(); frame() })
    function frame () {
      regl.poll()
      fbo[tick%2](fbopts[tick%2])
      draw.modulate({ framebuffer: fbo[tick%2], n_lines: tick%2 ? 263 : 262 })
      regl.clear({ color: [0,0,0,1], depth: true })
      draw.demodulate({ signal0: fbo[0], signal1: fbo[1] })
      tick++
    }
  }
})
