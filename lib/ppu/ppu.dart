library nes.ppu;

import 'dart:html' show CanvasElement, CanvasRenderingContext2D, ImageData;
import 'dart:typed_data';

part 'ppu_memory.dart';

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

  /// Store the PPU memory
  final PPUMemory memory = new PPUMemory();

  PPU(this._canvasToDraw) {
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

      if (_curr_scanline >= 240) {
        // non-rendered line

        // flag update is done during the first tick and not the second
        // hopefully this doesn't have an effect
        if (_curr_scanline == 241) {
          //TODO: set V_Blank flag
        } else if (_curr_scanline == 261) {
          //TODO: clear V_Blank, Sprite 0 and overflow flag
        }
      } else {}
    }

    _pixels_left--;
  }

  /// render the current line
  void _render_line() {}
}
