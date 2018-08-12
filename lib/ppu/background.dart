part of nes.ppu;

/// render the background
class Background {
  Uint8List _result = new Uint8List(256 * 240 * 4);

  PPU _ppu;

  /// the background is rendered each frame
  void _render() {
    int pattern_loc = _ppu.pattern_background_location * 0x1000;
    int table_offset = 0; // offset from $2000

    for (int delta_line = 0; delta_line < 31; delta_line++) {
      for (int old_col = 0; old_col < 64; old_col++) {
        table_offset = 0;
        int line = (delta_line + (_ppu.y_delta >> 3)) % 60;
        int col = old_col;
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
        int high_bit = ((_ppu.memory._data[addr] >> (2 * square)) & 3) << 2;

        int pattern =
            (_ppu.memory._data[0x2000 + table_offset + real_tile] << 4) +
                pattern_loc;

        // Now we can render the pixels
        for (int x = 0; x < 8; x++) {
          for (int y = 0; y < 8; y++) {
            int color = high_bit |
                ((_ppu.memory._data[pattern + y] >> (7 - x)) & 1) |
                (((_ppu.memory._data[pattern + 8 + y] >> (7 - x)) & 1) << 1);

            _result[(old_line * 8 + y) * 256 * 2 + (old_col * 8 + x)] = color;
          }
        }
      }
    }
  }
}
