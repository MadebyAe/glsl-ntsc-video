var glsl = require('glslify')
var regl = require('regl')({
  extensions: [
    'oes_texture_float',
    'oes_texture_float_linear',
    'webgl_color_buffer_float'
  ]
})

var fbopts = [
  {
    color: regl.texture({
      format: 'rgba',
      type: 'float',
      width: 720*4-4,
      height: 262
    }),
    depth: true
  },
  {
    color: regl.texture({
      format: 'rgba',
      type: 'float',
      width: 720*4-12,
      height: 263
    }),
    depth: true
  }
]
var fbo = [ regl.framebuffer(fbopts[0]), regl.framebuffer(fbopts[1]) ]

var draw = {
  modulate: regl({
    frag: glsl`
      precision highp float;
      #pragma glslify: modulate = require('../modulate.glsl')
      varying vec2 vpos;
      uniform float time, tick, n_lines;
      const float T_LINE = 5.26e-5;
      void main () {
        vec2 uv = vpos*vec2(1,-1)*0.5+0.5;
        float t = uv.x*T_LINE + floor(uv.y*(n_lines-1.0)+0.5)*T_LINE;
        vec3 rgb = mix(
          vec3(0,1,1),
          vec3(1,0,1),
          //sin(time)*0.5+0.5
          0.0
        );
        float signal = modulate(t,rgb);
        gl_FragColor = vec4(signal,t,0,1);
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
      time: regl.context('time'),
      n_lines: regl.prop('n_lines')
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
      const float N_LINES = 262.0;
      const float T_LINE = 5.26e-5;
      void main () {
        vec2 uv = vpos*vec2(1,-1)*0.5+0.5;
        float t0 = uv.x*T_LINE + floor(uv.y*(262.0-1.0)+0.5)*T_LINE;
        float t1 = uv.x*T_LINE + floor(uv.y*(263.0-1.0)+0.5)*T_LINE;
        vec3 rgb0 = demodulate(t0, 262.0, signal0) * mix(0.95,1.0,mod(tick,2.0));
        vec3 rgb1 = demodulate(t1, 263.0, signal1) * mix(1.0,0.95,mod(tick,2.0));
        vec3 rgb = mix(rgb0,rgb1,sin(uv.y*PI*2.0*262.5)*0.5+0.5);
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
frame()
//window.addEventListener('resize', frame)
//regl.frame(frame)

function frame() {
  regl.poll()
  fbo[tick%2](fbopts[tick%2])
  draw.modulate({ framebuffer: fbo[tick%2], n_lines: tick%2 ? 263 : 262 })
  regl.clear({ color: [0,0,0,1], depth: true })
  draw.demodulate({
    signal0: fbo[0],
    signal1: fbo[1],
  })
  tick++
  window.requestAnimationFrame(frame)
}
