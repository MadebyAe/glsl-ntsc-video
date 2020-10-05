var glsl = require('glslify')
var regl = require('regl')({
  extensions: [
    'oes_texture_float',
    'oes_texture_float_linear',
    'webgl_color_buffer_float'
  ]
})

var fbopts = {
  color: regl.texture({
    format: 'rgba',
    type: 'float',
    width: 720*4,
    height: 262
  }),
  depth: true
}
var fbo = regl.framebuffer(fbopts)

var draw = {
  modulate: regl({
    frag: glsl`
      precision highp float;
      #pragma glslify: modulate = require('../modulate.glsl')
      varying vec2 vpos;
      uniform float time;
      const float N_LINES = 262.0;
      const float T_LINE = 5.26e-5;
      void main () {
        vec2 uv = vpos*vec2(1,-1)*0.5+0.5;
        float t = uv.x*T_LINE + floor(uv.y*(N_LINES-1.0)+0.5)*T_LINE;
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
      time: regl.context('time')
    }
  }),
  demodulate: regl({
    frag: glsl`
      precision highp float;
      #pragma glslify: demodulate = require('../demodulate.glsl')
      uniform sampler2D signal;
      varying vec2 vpos;
      uniform float time;
      const float N_LINES = 262.0;
      const float T_LINE = 5.26e-5;
      void main () {
        vec2 uv = vpos*vec2(1,-1)*0.5+0.5;
        float t = uv.x*T_LINE + floor(uv.y*(N_LINES-1.0)+0.5)*T_LINE;
        vec3 rgb = demodulate(t, signal);
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
      signal: regl.prop('signal')
    }
  })
}
var tick = 0
frame()
//window.addEventListener('resize', frame)
//regl.frame(frame)

function frame() {
  regl.poll()
  fbo(fbopts)
  draw.modulate({ framebuffer: fbo })
  regl.clear({ color: [0,0,0,1], depth: true })
  draw.demodulate({ signal: fbo })
  window.requestAnimationFrame(frame)
}
