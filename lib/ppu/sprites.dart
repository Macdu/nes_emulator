part of nes.ppu;

/// load the sprites
class Sprites {
  final List<Color> _result = new List(256 * 240 * 4);

  /// number of sprites in a scanline
  final List<int> _nb_sprites = new List.filled(240, 0);

  /// priority of a pixel
  final List<bool> _has_priority = new List.filled(256 * 240, false);

  /// sprite 0 opaque pixels
  final List<bool> _sprite0_opaque_pixels = new List.filled(256 * 240, false);

  PPU _ppu;

  /// return the palette for the sprites
  List<Color> _read_palette() {
    List<Color> res = new List<Color>(16);
    for (int i = 0; i < 16; i++) {
      res[i] = nes_palette[
          _ppu.memory[0x3F10 + i] & 0x3F]; // sprite palette starts at 0x3F10
    }
    // update the transparent color
    _transparent = res[0];
    return res;
  }

  /// the sprites are rendered each frame
  void _render() {
    List<Color> palette = _read_palette();
    _result.fillRange(0, _result.length, _transparent);
    _nb_sprites.fillRange(0, _nb_sprites.length, 0);
    _has_priority.fillRange(0, _has_priority.length, false);
    _sprite0_opaque_pixels.fillRange(0, _sprite0_opaque_pixels.length, false);

    int pattern_address = _ppu.pattern_sprites_location * 0x1000;
    final bool is8x16 = _ppu.has8x16Sprites;

    for (int id = 0; id < 64; id++) {
      int addr = id * 4;
      int start_y = _ppu.memory._spr_ram[addr] + 1;
      int start_x = _ppu.memory._spr_ram[addr + 3];
      int pattern_index = _ppu.memory._spr_ram[addr + 1];
      int attributes = _ppu.memory._spr_ram[addr + 2];
      int high_palette = (attributes & 3) << 2;
      bool priority = (attributes & (1 << 5)) != 0;
      bool swap_verti = (attributes & (1 << 6)) != 0;
      bool swap_hori = (attributes & (1 << 7)) != 0;

      int pattern_start = is8x16
          ? 0x1000 * (pattern_index & 1) | (pattern_index * 0x10)
          : pattern_address | (pattern_index * 0x10);

      for (int x = start_x; x < start_x + 8; x++) {
        if (x >= 256) break;
        for (int y = start_y; y < start_y + (is8x16 ? 16 : 8); y++) {
          if (y >= 240) break;

          _nb_sprites[y]++;

          if (_nb_sprites[y] > 8) {
            // sprite overflow, will be set when rendering the scanline
            continue;
          }

          // sprite priority
          if (_result[y * 256 + x] != palette[0]) {
            continue;
          }

          int x_pattern_pos = swap_hori ? (7 - (x - start_x)) : (x - start_x);
          int y_pattern_pos =
              swap_verti ? ((is8x16 ? 15 : 7) - (y - start_y)) : (y - start_y);

          if (is8x16 && y_pattern_pos >= 8) {
            y_pattern_pos += 8;
          }

          // same part as in background
          // auto_format isn't looking really well here
          int color = high_palette |
              ((_ppu.memory[pattern_start + y_pattern_pos] >>
                      (7 - x_pattern_pos)) &
                  1) |
              (((_ppu.memory[pattern_start + 8 + y_pattern_pos] >>
                          (7 - x_pattern_pos)) &
                      1) <<
                  1);
          _result[y * 256 + x] = palette[color];
          _has_priority[y * 256 + x] = priority;
          if (id == 0 && palette[color] != palette[0]) {
            // sprite 0 hit check
            _sprite0_opaque_pixels[y * 256 + x] = true;
          }
        }
      }
    }
  }
}
