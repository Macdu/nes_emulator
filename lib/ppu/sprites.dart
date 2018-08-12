part of nes.ppu;

/// load the sprites
class Sprites {
  final Uint8List _result = new Uint8List(256 * 240 * 4);

  /// number of sprites in a scanline
  final List<int> _nb_sprites = new List.filled(240, 0);

  /// priority of a pixel
  final List<bool> _has_priority = new List.filled(256 * 240, false);

  /// sprite 0 opaque pixels
  final List<bool> _sprite0_opaque_pixels = new List.filled(256 * 240, false);

  PPU _ppu;

  /// the sprites are rendered each frame
  void _render() {
    _result.fillRange(0, _result.length, 0);
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
      bool priority = (attributes & (1 << 5)) == 0;
      bool swap_hori = (attributes & (1 << 6)) != 0;
      bool swap_verti = (attributes & (1 << 7)) != 0;

      int pattern_start = is8x16
          ? 0x1000 * (pattern_index & 1) | (pattern_index * 0x10)
          : pattern_address | (pattern_index * 0x10);

      for (int y = start_y; y < start_y + (is8x16 ? 16 : 8); y++) {
        if (y >= 240) break;
        _nb_sprites[y]++;
        if (_nb_sprites[y] > 8) {
          // sprite overflow, will be set when rendering the scanline
          continue;
        }
        int y_pattern_pos =
            swap_verti ? ((is8x16 ? 15 : 7) - (y - start_y)) : (y - start_y);

        if (is8x16 && y_pattern_pos >= 8) {
          y_pattern_pos += 8;
        }

        for (int x = start_x; x < start_x + 8; x++) {
          if (x >= 256) break;

          // sprite priority
          if (_result[y * 256 + x] != 0) {
            continue;
          }

          int x_pattern_pos = swap_hori ? (7 - (x - start_x)) : (x - start_x);

          // same part as in background
          // auto_format isn't looking really well here
          int color = high_palette |
              ((_ppu.memory._data[pattern_start + y_pattern_pos] >>
                      (7 - x_pattern_pos)) &
                  1) |
              (((_ppu.memory._data[pattern_start + 8 + y_pattern_pos] >>
                          (7 - x_pattern_pos)) &
                      1) <<
                  1);
          if ((color & 3) == 0) color = 0;
          _result[y * 256 + x] = (color == 0) ? 0 : (color + 16);
          _has_priority[y * 256 + x] = priority;
          if (id == 0 && color != 0) {
            // sprite 0 hit check
            _sprite0_opaque_pixels[y * 256 + x] = true;
          }
        }
      }
    }
  }
}
