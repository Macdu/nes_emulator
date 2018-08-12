library nes.ppu;

import 'dart:html' show CanvasElement, CanvasRenderingContext2D, ImageData;
import 'dart:typed_data';
import 'dart:developer';

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
  int get pattern_background_location => (memory.control_register >> 4) & 1;

  /// return the pattern table the sprites are stored in
  /// 0 : $0000; 1 : $1000
  /// located in control register 1 bit 3
  int get pattern_sprites_location => (memory.control_register >> 3) & 1;

  /// return if sprites should be displayed
  /// located in control register 2 bit 4
  bool get display_sprite => ((memory.mask_register >> 4) & 1) == 1;

  /// return if the background should be displayed
  /// located in control register 2 bit 3
  bool get display_background => ((memory.mask_register >> 3) & 1) == 1;

  /// See [PPUMemory.x_scroll]
  /// Add also scrolling based on control register bit 0
  int get x_delta => memory.x_scroll + (memory.control_register & 1) * 256;

  /// See [PPUMemory.y_scroll]
  /// Add also scrolling based on control register bit 1
  int get y_delta => memory.y_scroll + (memory.control_register & 2) * 120;

  /// if the sprites are 8x8 or 8x16
  /// located in control register 1 bit 5
  bool get has8x16Sprites => ((memory.control_register >> 5) & 1) == 1;

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

  void init(CanvasElement target, CPU cpu) {
    _canvasToDraw = target;
    _background._ppu = this;
    _sprites._ppu = this;
    _ctx = _canvasToDraw.context2D;
    _screen = _ctx.createImageData(256, 240);
    this._cpu = cpu;
  }

  // starts the first tick at scanline 0
  int _curr_scanline = 261;
  int _cycles_left = 0;

  /// make one CPU tick
  void tick() {
    if (_cycles_left <= 0) {
      // notify the (potential) mapper
      cpu.mapper.count_scanline();

      // start a new scanline
      _curr_scanline++;
      if (_curr_scanline == 262) _curr_scanline = 0;

      _cycles_left = 341;

      if (_curr_scanline == 0) {
        // start a new frame
        if (display_background) {
          _background._render();
        } else {
          _transparent = nes_palette[memory[0x3F00]];
          _background._result
              .fillRange(0, _background._result.length, _transparent);
        }
        if (display_sprite) {
          _sprites._render();
        } else {
          _transparent = nes_palette[memory[0x3F00]];
          _sprites._result.fillRange(0, _sprites._result.length, _transparent);
          _sprites._sprite0_opaque_pixels
              .fillRange(0, _sprites._sprite0_opaque_pixels.length, false);
        }
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

    // there are 3 ppu cycles per cpu cycle
    _cycles_left -= 3;
  }

  /// render the current line
  void _render_line() {
    if (_sprites._nb_sprites[_curr_scanline] > 8) {
      overflow_flag = true;
    }
    int curr_y = (_curr_scanline + y_delta) % 480;

    for (int x = 0; x < 256; x++) {
      int curr_x = (x + x_delta) % (256 * 2);
      Color rendered = _background._result[curr_y * 256 * 2 + curr_x];

      // check sprite 0 collision
      if (_sprites._sprite0_opaque_pixels[_curr_scanline * 256 + x] &&
          rendered != _transparent) {
        sprite0_hit_flag = true;
      }

      if (_sprites._result[_curr_scanline * 256 + x] != _transparent &&
          (rendered == _transparent ||
              _sprites._has_priority[_curr_scanline * 256 + x])) {
        // the color rendered is the one of the sprite
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
