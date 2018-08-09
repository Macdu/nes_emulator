part of nes.ppu;

/// render the background
class Background {
  List<Color> _result = new List<Color>(256 * 240 * 4);

  PPU _ppu;

  /// return the palette for the background
  List<Color> _read_palette() {
    List<Color> res = new List<Color>(16);
    for (int i = 0; i < 16; i++) {
      res[i] = nes_palette[
          _ppu.memory[0x3F00 + i] & 0x3F]; // image palette starts at 0x3F00
    }
    // update the transparent color
    _transparent = res[0];
    return res;
  }

  /// the background is rendered each frame
  void _render() {
    int pattern_loc = _ppu.pattern_background_location * 0x1000;
    int table_offset = 0; // offset from $2000

    List<Color> palette = _read_palette();

    for (int tile = 0; tile < 32 * 30 * 4; tile++) {
      table_offset = 0;
      int col = tile & ((1 << 6) - 1);
      int line = tile >> 6;
      int old_col = col;
      int old_line = line;
      if (line >= 30) {
        line -= 30;
        table_offset |= 0x800;
      }
      if (col >= 32) {
        col -= 32;
        table_offset |= 0x400;
      }
      int real_tile = line * 32 + col;
      // get the high bit
      int square = ((col & 2) >> 1) + (line & 2);
      int number = (col >> 2) + ((line >> 2) << 3);
      int addr = 0x23C0 + table_offset + number;
      int high_bit = ((_ppu.memory[addr] >> (2 * square)) & 3) << 2;

      int pattern =
          (_ppu.memory[0x2000 + table_offset + real_tile] << 4) + pattern_loc;

      // Now we can render the pixels
      for (int x = 0; x < 8; x++) {
        for (int y = 0; y < 8; y++) {
          int color = high_bit |
              ((_ppu.memory[pattern + y] >> (7 - x)) & 1) |
              (((_ppu.memory[pattern + 8 + y] >> (7 - x)) & 1) << 1);

          _result[(old_line * 8 + y) * 256 * 2 + (old_col * 8 + x)] =
              palette[color];
        }
      }
    }
  }
}
