library nes.ppu;

import 'dart:html' show CanvasElement, CanvasRenderingContext2D, ImageData;
import 'dart:typed_data';

import '../cpu/cpu.dart';

part 'ppu_memory.dart';
part 'color_palette.dart';
part 'background.dart';
part 'sprites.dart';

/// simulate a NES PPU
class PPU {
  /// The Canvas element to draw to
  /// May add an abstraction layer to it in order to use it in Flutter
  CanvasElement _canvasToDraw;

  /// 2D Rendering context of [_canvasToDraw]
  CanvasRenderingContext2D _ctx;

  /// Store the screen being rendered
  /// the screen is an NTSC screen : 256x240
  ImageData _screen;

  /// temporary canvas used for scaling
  final CanvasElement _temp_scaling =
      new CanvasElement(width: 256, height: 240);

  /// Load the background
  final Background _background = new Background();

  /// load the sprites
  final Sprites _sprites = new Sprites();

  /// Store the PPU memory
  final PPUMemory memory = new PPUMemory();

  /// return the pattern table the background is stored in
  /// 0 : $0000; 1 : $1000
  /// located in control register 1 bit 4
  int get pattern_background_location => (memory.control_register_1 >> 4) & 1;

  /// return the pattern table the sprites are stored in
  /// 0 : $0000; 1 : $1000
  /// located in control register 1 bit 3
  int get pattern_sprites_location => (memory.control_register_1 >> 3) & 1;

  /// return if sprites should be displayed
  /// located in control register 2 bit 4
  bool get displaySprite => ((memory.control_register_2 >> 4) & 1) == 1;

  /// return if the background should be displayed
  /// located in control register 2 bit 3
  bool get displayBackground => ((memory.control_register_2 >> 3) & 1) == 1;

  /// See [PPUMemory.x_scroll]
  int get x_scroll => memory.x_scroll;

  /// See [PPUMemory.y_scroll]
  int get y_scroll => memory.y_scroll;

  /// if the sprites are 8x8 or 8x16
  /// located in control register 1 bit 5
  bool get has8x16Sprites => ((memory.control_register_1 >> 5) & 1) == 1;

  /// located in control register 2 bit 3
  bool get background_enabled => ((memory.control_register_2 >> 3) & 1) == 1;

  /// located in control register 2 bit 2
  bool get sprites_enabled => ((memory.control_register_2 >> 2) & 1) == 1;

  /// set the sprite 0 hit flag
  /// located in bit 6 status register
  set sprite0_hit_flag(bool flag) => flag
      ? memory.status_register |= (1 << 6)
      : memory.status_register &= ~(1 << 6);

  /// set the overflow flag
  /// located in bit 5 status register
  set overflow_flag(bool flag) => flag
      ? memory.status_register |= (1 << 5)
      : memory.status_register &= ~(1 << 5);

  /// set the V-blank flag
  /// located in bit 7 status register
  set v_blank_flag(bool flag) => flag
      ? memory.status_register |= (1 << 7)
      : memory.status_register &= ~(1 << 7);

  /// return the CPU related to this PPU
  CPU get cpu => _cpu;
  CPU _cpu;

  PPU(this._canvasToDraw) {
    _background._ppu = this;
    _ctx = _canvasToDraw.context2D;
    _screen = _ctx.createImageData(256, 240);
  }

  int _curr_scanline = 0;
  int _pixels_left = 0;

  /// make one CPU tick
  void tick() {
    if (_pixels_left == 0) {
      // start a new scanline
      _curr_scanline++;
      _curr_scanline %= 262;

      _pixels_left = 256;

      if (_curr_scanline == 0) {
        // start a new frame
        _background._render();
        _sprites._render();
      }

      if (_curr_scanline >= 240) {
        // non-rendered line

        if (_curr_scanline == 240) {
          // the frame is totally rendered, now show it
          _temp_scaling.context2D.putImageData(_screen, 0, 0);
          _ctx.drawImageScaled(
              _temp_scaling, 0, 0, _canvasToDraw.width, _canvasToDraw.height);
        }

        // flag update is done during the first tick and not the second
        // hopefully this doesn't have an effect
        if (_curr_scanline == 241) {
          v_blank_flag = true;
          // causes an NMI
          _cpu.interrupt(InterruptType.NMI);
        } else if (_curr_scanline == 261) {
          v_blank_flag = false;
          overflow_flag = false;
          sprite0_hit_flag = false;
        }
      } else {
        _render_line();
      }
    }

    _pixels_left--;
  }

  /// render the current line
  void _render_line() {
    if (_sprites._nb_sprites[_curr_scanline] > 8) {
      overflow_flag = true;
    }

    for (int x = 0; x < 256; x++) {
      Color rendered = _background._result[_curr_scanline * 256 + x];
      if (_sprites._result[_curr_scanline * 256 + x] != _transparent &&
          _sprites._has_priority[_curr_scanline * 256 + x]) {
        // the color rendered is the one of the sprite

        // check sprite 0 collision
        if (_sprites._sprite0_opaque_pixels[_curr_scanline * 256 + x]) {
          sprite0_hit_flag = true;
        }
        rendered = _sprites._result[_curr_scanline * 256 + x];
      }
      int screen_pos = (_curr_scanline * 256 + x) * 4;
      _screen.data[screen_pos] = rendered.r;
      _screen.data[screen_pos + 1] = rendered.v;
      _screen.data[screen_pos + 2] = rendered.b;
      _screen.data[screen_pos + 3] = 0xFF; // no alpha channel
    }
  }
}
