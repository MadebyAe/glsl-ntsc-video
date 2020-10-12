var glsl = require('glslify')
var regl = require('regl')({
  extensions: [ 'oes_texture_float', 'oes_texture_float_linear', 'webgl_color_buffer_float' ]
})
var fbopts = [
  { color: regl.texture({ format: 'rgba', type: 'float', width: 720*2, height: 485 }) },
  { color: regl.texture({ format: 'rgba', type: 'float', width: 720*2, height: 262 }) },
  { color: regl.texture({ format: 'rgba', type: 'float', width: 720*2, height: 263 }) }
]
var fbo = [
  regl.framebuffer(fbopts[0]),
  regl.framebuffer(fbopts[1]),
  regl.framebuffer(fbopts[2])
]

var draw = {
  picture: regl({
    frag: `
      precision highp float;
      uniform float time;
      void main() {
        gl_FragColor = vec4(mix(
          vec3(0,1,1),
          vec3(1,0,1),
          sin(time)*0.5+0.5
        ), 1);
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
      time: regl.context('time')
    }
  }),
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
      picture: regl.prop('picture')
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
        vec3 rgb0 = demodulate(v, vec3(242,r), signal0);
        vec3 rgb1 = demodulate(v, vec3(243,r), signal1);
        vec3 rgb = mix(rgb0,rgb1,sin(v.y*PI*2.0*242.5)*0.5+0.5);
        gl_FragColor = vec4(rgb0,1);
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

regl.frame(({tick}) => {
  fbo[0](fbopts[0])
  fbo[1+tick%2](fbopts[1+tick%2])
  draw.picture({ framebuffer: fbo[0] })
  draw.modulate({
    picture: fbo[0],
    framebuffer: fbo[1+tick%2], n_lines: tick%2 ? 243 : 242
  })
  regl.clear({ color: [0,0,0,1], depth: true })
  draw.demodulate({
    signal0: fbo[1],
    signal1: fbo[2],
  })
})
