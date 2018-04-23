library nes.ppu;

import 'dart:html' show CanvasElement, CanvasRenderingContext2D, ImageData;
import 'dart:typed_data';

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
  int get pattern_background_location => 0;

  /// return the pattern table the sprites are stored in
  /// 0 : $0000; 1 : $1000
  int get pattern_sprites_location => 0;

  /// return if sprites should be displayed
  bool get displaySprite => false;

  /// return if the background should be displayed
  bool get displayBackground => false;

  int get x_scroll => 0;

  int get y_scroll => 0;

  /// true : horizontal scrolling
  /// false : vertical scrolling
  bool get isHorizontalScroll => true;

  /// if the sprites are 8x8 or 8x16
  bool get has8x16Sprites => false;

  /// set the sprite 0 hit flag
  set sprite0_hit_flag(bool flag) => null;

  /// set the overflow flag
  set overflow_flag(bool flag) => null;

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
          //TODO: set V_Blank flag
        } else if (_curr_scanline == 261) {
          //TODO: clear V_Blank, Sprite 0 and overflow flag
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
