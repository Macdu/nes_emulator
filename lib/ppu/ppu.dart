library nes.ppu;

import 'dart:html' show CanvasElement, CanvasRenderingContext2D, ImageData;
import 'dart:typed_data';

part 'ppu_memory.dart';
part 'color_palette.dart';
part 'background.dart';

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

  /// Load the background
  final Background _background = new Background();

  /// Store the PPU memory
  final PPUMemory memory = new PPUMemory();

  /// return the pattern table the background is stored in
  /// 0 : $0000; 1 : $1000
  int get pattern_background_location => 0;

  /// return if sprites should be displayed
  bool get displaySprite => false;

  /// return if the background should be displayed
  bool get displayBackground => false;

  int get x_scroll => 0;

  int get y_scroll => 0;

  /// true : horizontal scrolling
  /// false : vertical scrolling
  bool get isHorizontalScroll => true;

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
      }

      if (_curr_scanline >= 240) {
        // non-rendered line

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
  void _render_line() {}
}
